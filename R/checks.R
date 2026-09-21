# =============================================================================
# Readiness: is this dataset and this workbook fit to run
# =============================================================================
#
# The rules the Analysis Kit interface uses to decide what to show, with the
# tag-rendering half left behind. Everything here is pure - facts in, facts out
# - which is what lets a script ask the same questions the interface asks
# before it commits to a run.
#
# No analysis and no validation happens here: validate_loa() in read_loa.R owns
# the checks themselves. These functions only count, order and gate.
# =============================================================================


#' The Steps of the Workflow
#'
#' @param destination_label Label for the fourth step.
#' @return A named character vector: step id to label.
#' @keywords internal
ak_steps <- function(destination_label = "Output folder") {
  c(
    dataset = "Dataset",
    loa = "List of Analysis",
    checks = "Checks",
    destination = destination_label,
    results = "Results"
  )
}


#' Work Out the State of Each Step
#'
#' The single rule behind the readiness gate, kept separate from anything that
#' displays it so it can be tested directly.
#'
#' @param dataset_loaded,dataset_failed State of the dataset read.
#' @param loa_loaded,loa_failed State of the List of Analysis read.
#' @param problems The problems table, or `NULL` when the checks have not run.
#' @param destination_chosen,destination_failed State of the output folder.
#' @param results_ready Logical. Results exist.
#' @param running Logical. An analysis is in progress.
#' @return A named character vector of `"todo"`, `"active"`, `"done"`,
#'   `"warning"` or `"error"`, one per step.
#' @export
ak_step_states <- function(dataset_loaded = FALSE,
                           dataset_failed = FALSE,
                           loa_loaded = FALSE,
                           loa_failed = FALSE,
                           problems = NULL,
                           destination_chosen = FALSE,
                           destination_failed = FALSE,
                           results_ready = FALSE,
                           running = FALSE) {
  states <- c(
    dataset = "todo", loa = "todo", checks = "todo",
    destination = "todo", results = "todo"
  )

  states[["dataset"]] <- if (dataset_failed) {
    "error"
  } else if (dataset_loaded) {
    "done"
  } else {
    "active"
  }

  if (dataset_loaded) {
    states[["loa"]] <- if (loa_failed) {
      "error"
    } else if (loa_loaded) {
      "done"
    } else {
      "active"
    }
  }

  if (dataset_loaded && loa_loaded && !is.null(problems)) {
    states[["checks"]] <- if (loa_has_errors(problems)) {
      "error"
    } else if (nrow(problems) > 0) {
      "warning"
    } else {
      "done"
    }
  }

  # The folder only matters once there is something worth saving.
  if (states[["checks"]] %in% c("done", "warning")) {
    states[["destination"]] <- if (destination_failed) {
      "error"
    } else if (destination_chosen) {
      "done"
    } else {
      "active"
    }
  }

  states[["results"]] <- if (running) {
    "active"
  } else if (results_ready) {
    "done"
  } else if (identical(states[["destination"]], "done")) {
    "active"
  } else {
    "todo"
  }

  states
}


#' Can the Analysis Be Run
#'
#' Both files in, no fatal check, and somewhere to put the result. The
#' destination is part of the gate because a run that cannot be saved wastes
#' the wait.
#'
#' @param states A vector from [ak_step_states()].
#' @return `TRUE` when the run should go ahead.
#' @export
ak_can_run <- function(states) {
  identical(unname(states[["dataset"]]), "done") &&
    identical(unname(states[["loa"]]), "done") &&
    unname(states[["checks"]]) %in% c("done", "warning") &&
    identical(unname(states[["destination"]]), "done")
}


#' Count Problems by Severity
#' @param problems A problems data frame, or `NULL`.
#' @return A named integer vector with `error` and `warning`.
#' @export
ak_problem_counts <- function(problems) {
  out <- c(error = 0L, warning = 0L)
  if (is.null(problems) || nrow(problems) == 0) {
    return(out)
  }
  tab <- table(problems$severity)
  for (nm in intersect(names(tab), names(out))) {
    out[[nm]] <- as.integer(tab[[nm]])
  }
  out
}


#' Format the Problems Table for Reading
#'
#' Errors first, then warnings, each group in workbook order. `Where` collapses
#' the sheet and row into the one string needed to find the cell.
#'
#' @param problems A problems data frame, or `NULL`.
#' @return A data frame with `Severity`, `Where` and `What to fix`.
#' @export
ak_problems_display <- function(problems) {
  empty <- data.frame(
    Severity = character(0), Where = character(0),
    `What to fix` = character(0),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  if (is.null(problems) || nrow(problems) == 0) {
    return(empty)
  }

  ordered <- problems[order(problems$severity != "error"), , drop = FALSE]

  data.frame(
    Severity = ifelse(ordered$severity == "error", "Must fix", "Warning"),
    Where = paste0(
      ordered$sheet,
      ifelse(is.na(ordered$row), "", paste0(" \u00b7 row ", ordered$row))
    ),
    `What to fix` = ordered$message,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}


#' Summarise Which Sheets a Workbook Supplied
#' @param workbook The list from [read_loa_workbook()].
#' @return A data frame with `Sheet`, `Rows` and `Status`.
#' @export
ak_sheet_summary <- function(workbook) {
  known <- loa_known_sheets()
  sheets <- workbook$sheets %||% list()

  data.frame(
    Sheet = known,
    Rows = vapply(
      known,
      function(nm) if (is.null(sheets[[nm]])) 0L else nrow(sheets[[nm]]),
      integer(1),
      USE.NAMES = FALSE
    ),
    Status = vapply(
      known,
      function(nm) {
        if (is.null(sheets[[nm]])) {
          if (nm == "analysis") "Missing - required" else "Not supplied - defaults apply"
        } else if (nrow(sheets[[nm]]) == 0) {
          "Empty - defaults apply"
        } else {
          "Read"
        }
      },
      character(1),
      USE.NAMES = FALSE
    ),
    stringsAsFactors = FALSE
  )
}


#' The Combination Base, Spelled Out
#'
#' `count_combinations` and `count_exclusive_combinations` share one
#' denominator: everyone who answered the question and has at least one choice
#' recorded. A respondent who answered but has nothing recorded at all - never
#' asked, or asked and left blank - is outside that base, so the two blocks
#' describe slightly fewer people than the question's own choice percentages do.
#' That is invisible in the finished workbook, where the percentages simply look
#' like every other percentage.
#'
#' So the number is reported per question, as a share of everyone who answered.
#' [run_analysis_locally()] prints it after a run for the same reason.
#'
#' @param map The `choice_combinations` or `exclusive_combinations` element of a
#'   pipeline result: `analysis_var`, `n_in_base` and `n_no_selection`.
#' @return A character vector of sentences, or `character(0)` when every
#'   respondent who answered is in the base.
#' @export
ak_exclusive_base_note <- function(map) {
  if (is.null(map) || nrow(map) == 0) {
    return(character(0))
  }
  if (!all(c("analysis_var", "n_no_selection") %in% names(map))) {
    return(character(0))
  }

  outside <- as.numeric(map$n_no_selection)
  outside[is.na(outside)] <- 0
  in_base <- if ("n_in_base" %in% names(map)) {
    as.numeric(map$n_in_base)
  } else {
    rep(NA_real_, nrow(map))
  }

  keep <- outside > 0
  if (!any(keep)) {
    return(character(0))
  }

  answered <- outside + in_base
  share <- ifelse(is.finite(answered) & answered > 0, 100 * outside / answered, NA_real_)

  paste0(
    map$analysis_var[keep], ": ",
    format(outside[keep], big.mark = ",", trim = TRUE),
    " respondent(s)",
    ifelse(
      is.na(share[keep]),
      "",
      paste0(" (", format(round(share[keep], 1), nsmall = 1, trim = TRUE), "% of those who answered)")
    ),
    " answered but have no choice recorded, and are outside this base."
  )
}


# -----------------------------------------------------------------------------
# The readiness report
# -----------------------------------------------------------------------------

#' Check a Dataset and a List of Analysis Against Each Other
#'
#' Everything [run_analysis_locally()] checks before it commits to a run, with
#' nothing run. Use it to see what a workbook would do to a dataset - and what
#' it would refuse to do - without waiting for an analysis.
#'
#' **This never stops.** A workbook with fatal problems comes back described
#' rather than thrown, so every problem is visible at once instead of one per
#' attempt. `$ready` is the answer to "would a run go ahead".
#'
#' The severity rule, inherited from `validate_loa()`: **fatal** when the run
#' would produce wrong or misleading output, **warning** when it would only
#' produce less output. So a grouping variable that is missing from the dataset
#' warns - one fewer column block - while two `new_name` values where one
#' contains the other is fatal, because the column map would then attribute
#' columns to the wrong disaggregation.
#'
#' @param dataset A dataset path, the list from [read_analysis_dataset()], or a
#'   plain data frame with the ONA label row still on top.
#' @param loa A List of Analysis path, or the list from
#'   [read_loa_workbook()].
#' @param output_folder Optional folder the results would be written to. When
#'   given it is checked for existence and write access now, so a long run is
#'   never lost to a read-only destination.
#' @return An object of class `analysis_readiness`: a list with `ready`,
#'   `problems`, `counts`, `coverage`, `sheets`, `spec`, `dataset` and
#'   `folder_problem`. Print it for a summary.
#' @seealso [validate_loa()] for the checks themselves,
#'   [loa_variable_coverage()] for the per-reference variable table.
#' @export
#' @examples
#' \dontrun{
#' checks <- check_analysis_inputs(
#'   dataset = "data/mmr_analysis_data_25_26.xlsx",
#'   loa     = "resources/loa_template.xlsx"
#' )
#'
#' checks                              # the summary
#' ak_problems_display(checks$problems) # every problem, errors first
#' subset(checks$coverage, !present)    # variables the dataset does not have
#' }
check_analysis_inputs <- function(dataset, loa, output_folder = NULL) {
  dataset <- as_analysis_dataset(dataset)
  workbook <- as_loa_workbook(loa)

  spec <- build_analysis_spec(workbook, dataset$data)
  coverage <- loa_variable_coverage(workbook, dataset$data)
  folder_problem <- if (is.null(output_folder)) NULL else ak_check_folder(output_folder)

  out <- list(
    ready = !loa_has_errors(spec$problems) && is.null(folder_problem),
    problems = spec$problems,
    counts = ak_problem_counts(spec$problems),
    coverage = coverage,
    sheets = ak_sheet_summary(workbook),
    spec = spec,
    dataset = dataset,
    output_folder = output_folder,
    folder_problem = folder_problem
  )

  class(out) <- c("analysis_readiness", "list")
  out
}


#' @param x An `analysis_readiness` object.
#' @param ... Ignored.
#' @export
#' @rdname check_analysis_inputs
print.analysis_readiness <- function(x, ...) {
  cat("<analysis_readiness>\n")
  cat("  dataset          :", x$dataset$filename,
      paste0("(", format(nrow(x$dataset$data), big.mark = ","), " rows x ",
             ncol(x$dataset$data), " columns)"), "\n")
  cat("  List of Analysis :", x$spec$source$filename %||% "not recorded",
      paste0("(", nrow(x$spec$loa), " analyses)"), "\n")
  cat("  disaggregations  :", paste(x$spec$group_variables, collapse = ", "), "\n")
  cat("  problems         :", x$counts[["error"]], "must fix,",
      x$counts[["warning"]], "warning(s)\n")

  if (nrow(x$coverage) > 0) {
    absent <- unique(x$coverage$variable[!x$coverage$present])
    cat("  variables absent :", length(absent), "of",
        length(unique(x$coverage$variable)))
    if (length(absent) > 0) {
      cat(" -", paste(utils::head(absent, 6), collapse = ", "),
          if (length(absent) > 6) "..." else "")
    }
    cat("\n")
  }

  if (!is.null(x$folder_problem)) {
    cat("  output folder    :", x$folder_problem, "\n")
  }

  cat("  ready to run     :", if (isTRUE(x$ready)) "yes" else "no", "\n")

  if (!isTRUE(x$ready)) {
    cat("\nFix these first:\n")
    fatal <- x$problems[x$problems$severity == "error", , drop = FALSE]
    if (nrow(fatal) > 0) {
      display <- ak_problems_display(fatal)
      for (i in seq_len(nrow(display))) {
        cat("  -", display$Where[i], ":", display$`What to fix`[i], "\n")
      }
    }
    if (!is.null(x$folder_problem)) {
      cat("  -", x$folder_problem, "\n")
    }
  }

  invisible(x)
}
