# =============================================================================
# Running an analysis locally
# =============================================================================
#
# The Analysis Kit server function, as one call. The application's Run handler
# does five things in order - check the destination, run the pipeline, capture
# the pipeline's own messages as a log, export, report - and every one of them
# is as useful in a script as it is behind a button. run_analysis_locally()
# does the same five things in the same order.
#
# Two properties of the app are kept on purpose:
#
#   * Nothing is written unless the analysis completes without error. If the
#     analysis succeeds and only the save fails, the results are still
#     returned and the failure is reported as a save failure, so a long run is
#     never thrown away over a bad folder.
#   * The pipeline reports its own progress through message(). Those messages
#     carry the diagnostics an analyst needs - variables skipped, choices
#     excluded, small groups set aside - so they are kept as a run log rather
#     than left to vanish up the console.
# =============================================================================


#' Accept a Dataset in Any of the Three Useful Shapes
#'
#' A path, the list [read_analysis_dataset()] returns, or a bare data frame.
#' The last is what makes an in-memory dataset - one already cleaned in the
#' session - usable without writing it out to a file first.
#'
#' @param dataset A path, a dataset list, or a data frame.
#' @param name Name to record when a bare data frame is given.
#' @return A dataset list with `data`, `extension`, `filename` and `size`.
#' @keywords internal
as_analysis_dataset <- function(dataset, name = NULL) {
  if (is.data.frame(dataset)) {
    return(list(
      data = dataset,
      extension = "DATA.FRAME",
      filename = name %||% "dataset",
      size = as.numeric(utils::object.size(dataset))
    ))
  }

  if (is.list(dataset) && "data" %in% names(dataset)) {
    if (!is.data.frame(dataset$data)) {
      stop("dataset$data must be a data frame.", call. = FALSE)
    }
    return(dataset)
  }

  if (is.character(dataset) && length(dataset) == 1L) {
    return(read_analysis_dataset(dataset))
  }

  stop(
    paste0(
      "dataset must be a path to a .csv or .xlsx file, the list returned by ",
      "read_analysis_dataset(), or a data frame."
    ),
    call. = FALSE
  )
}


#' Accept a List of Analysis as a Path or an Already-Read Workbook
#'
#' @param loa A path, or the list from [read_loa_workbook()].
#' @return A workbook list.
#' @keywords internal
as_loa_workbook <- function(loa) {
  if (is.list(loa) && "sheets" %in% names(loa)) {
    return(loa)
  }

  if (is.character(loa) && length(loa) == 1L) {
    if (!file.exists(loa)) {
      stop(
        paste0("The List of Analysis '", loa, "' does not exist."),
        call. = FALSE
      )
    }
    return(read_loa_workbook(loa))
  }

  # A bare named list of sheets is what the tests build, and it is a reasonable
  # thing to hand in by hand, so it is accepted rather than refused.
  if (is.list(loa) && length(loa) > 0 && !is.null(names(loa))) {
    return(list(
      sheets = loa,
      format = "LIST",
      filename = "loa",
      sheet_names = names(loa),
      unknown_sheets = character(0),
      ignored_sheets = character(0)
    ))
  }

  stop(
    paste0(
      "loa must be a path to a .xlsx or .csv file, or the list returned by ",
      "read_loa_workbook()."
    ),
    call. = FALSE
  )
}


#' Collect a Function's Messages and Warnings Into a Log
#'
#' The pipeline's `message()` output is its progress report and its
#' diagnostics. Captured rather than muffled, it becomes the run log; captured
#' rather than printed, a `verbose` run does not bury the console.
#'
#' Warnings are collected too, prefixed so they stand out, and are *not*
#' re-raised: a run that skipped three variables should say so once in the log,
#' not fire three warnings at the end when it is too late to read them in
#' order.
#'
#' @param expr The expression to evaluate.
#' @param echo Logical. Also print each line as it arrives.
#' @return A list with `value` and `log`.
#' @keywords internal
with_run_log <- function(expr, echo = TRUE) {
  log <- character(0)

  note <- function(text) {
    text <- trimws(sub("^-->\\s*", "", text))
    if (nzchar(text)) {
      log <<- c(log, text)
      if (isTRUE(echo)) cat("  ", text, "\n", sep = "")
    }
    invisible(NULL)
  }

  value <- withCallingHandlers(
    expr,
    message = function(m) {
      note(conditionMessage(m))
      invokeRestart("muffleMessage")
    },
    warning = function(w) {
      note(paste0("Warning: ", conditionMessage(w)))
      invokeRestart("muffleWarning")
    }
  )

  list(value = value, log = log)
}


#' Run an Analysis Locally, From Two Files to a Results Workbook
#'
#' The whole Analysis Kit workflow as one call: read the dataset and the List
#' of Analysis, check them against each other, run every analysis the workbook
#' asks for across every disaggregation it declares, and write the results to
#' an MMC-branded Excel workbook.
#'
#' @section What it will not do:
#'
#' The run **stops before doing any work** when the List of Analysis has a
#' fatal problem, and the error names every one of them. That is deliberate:
#' the alternative is a workbook full of plausible numbers attributed to the
#' wrong disaggregation. Call [check_analysis_inputs()] first to see the
#' problems without triggering the run.
#'
#' Warnings do not stop a run - they mean less output, not wrong output - and
#' they arrive in `$log`, which is worth reading rather than skipping. A
#' grouping variable absent from the dataset, a `Don't know` label that matched
#' nothing, a town set aside for having four interviews: all of them are
#' warnings, and all of them change what is in the file.
#'
#' @section The output file:
#'
#' Named `analysiskit_<dataset stem>_<YYYYmmdd-HHMMSS>.xlsx`, and an existing
#' file is never overwritten - a second run in the same second gets a `_1`
#' suffix. The workbook's readme sheet records the dataset, the List of
#' Analysis, the disaggregations and every setting that was applied, so a file
#' found six months later can be traced back to what produced it.
#'
#' Pass `output_folder = NULL` to run without writing anything. The results are
#' returned either way.
#'
#' @param dataset A dataset path (`.csv` / `.xlsx`), the list from
#'   [read_analysis_dataset()], or a data frame with the ONA label row still on
#'   top.
#' @param loa A List of Analysis path, or the list from [read_loa_workbook()].
#'   A `.csv` carries no sheets and is read as the `analysis` table alone, so a
#'   configured run needs `.xlsx`.
#' @param output_folder Folder to write the results workbook into. It must
#'   already exist and be writable, and both are checked before the analysis
#'   starts. `NULL` runs the analysis and writes nothing.
#' @param verbose Logical. Print the pipeline's progress as it arrives. The log
#'   is kept in the result either way.
#' @param ... Further arguments for [run_group_analysis_pipeline()], overriding
#'   the workbook. Use for run-time concerns the workbook should not own; a
#'   setting the workbook is meant to carry belongs in its `settings` sheet, so
#'   that the file remains a complete description of the run.
#' @return An object of class `analysis_run`: a list with `results` (the full
#'   pipeline result), `spec`, `dataset`, `coverage`, `problems`,
#'   `output_path`, `log`, `elapsed` and `save_error`. Print it for a summary.
#' @seealso [check_analysis_inputs()] to look before you leap,
#'   [run_analysis_spec()] to run an already-built specification,
#'   [run_group_analysis_pipeline()] to bypass the workbook entirely.
#' @export
#' @examples
#' \dontrun{
#' # The usual case
#' run <- run_analysis_locally(
#'   dataset       = "data/mmr_analysis_data_25_26.xlsx",
#'   loa           = "resources/loa_template.xlsx",
#'   output_folder = "output"
#' )
#'
#' run                      # summary, including the saved path
#' run$output_path          # the workbook that was written
#' run$log                  # what the pipeline reported
#' run$results$combined_results[1:5, 1:6]
#'
#' # Check first, run second
#' checks <- check_analysis_inputs("data/export.xlsx", "resources/loa.xlsx")
#' if (checks$ready) {
#'   run <- run_analysis_locally(checks$dataset, "resources/loa.xlsx", "output")
#' }
#'
#' # Analyse without writing anything
#' run <- run_analysis_locally("data/export.xlsx", "resources/loa.xlsx")
#'
#' # The same List of Analysis over a folder of exports
#' runs <- lapply(
#'   list.files("data", pattern = "[.]xlsx$", full.names = TRUE),
#'   run_analysis_locally,
#'   loa = "resources/loa.xlsx",
#'   output_folder = "output"
#' )
#' }
run_analysis_locally <- function(dataset,
                                 loa,
                                 output_folder = NULL,
                                 verbose = TRUE,
                                 ...) {
  started <- Sys.time()

  dataset <- as_analysis_dataset(dataset)
  workbook <- as_loa_workbook(loa)

  spec <- build_analysis_spec(workbook, dataset$data)
  coverage <- loa_variable_coverage(workbook, dataset$data)

  # The destination is checked before the analysis rather than after, so a run
  # that cannot be saved is refused in a second instead of an hour.
  if (!is.null(output_folder)) {
    folder_problem <- ak_check_folder(output_folder)
    if (!is.null(folder_problem)) {
      stop(folder_problem, call. = FALSE)
    }
  }

  # run_analysis_spec() raises on a fatal problem, naming every one. Nothing
  # below runs on a workbook that would produce misleading output.
  if (isTRUE(verbose)) {
    message(sprintf(
      "Running %d analyses across %d grouping variable(s)",
      nrow(spec$loa), length(spec$group_variables)
    ))
  }

  run <- with_run_log(
    run_analysis_spec(dataset$data, spec, verbose = TRUE, ...),
    echo = verbose
  )
  results <- run$value
  log <- run$log

  # Only now, with a completed run in hand, is anything written to disk.
  output_path <- NULL
  save_error <- NULL

  if (!is.null(output_folder)) {
    export <- with_run_log(
      tryCatch(
        ak_export_results(
          results = results,
          spec = spec,
          folder = output_folder,
          dataset_name = dataset$filename,
          verbose = TRUE
        ),
        error = function(error) {
          structure(list(message = conditionMessage(error)), class = "ak_save_error")
        }
      ),
      echo = verbose
    )

    log <- c(log, export$log)

    if (inherits(export$value, "ak_save_error")) {
      # The analysis succeeded; only the saving failed. The results are kept so
      # the work is not thrown away over a bad folder, and the caller is told
      # loudly - a warning rather than a line in the log, because a run that
      # produced no file looks exactly like one that did in every other respect.
      save_error <- export$value$message
      warning(
        paste0(
          "The analysis finished, but the results could not be saved: ",
          save_error, " The results are in $results."
        ),
        call. = FALSE
      )
    } else {
      output_path <- export$value
      log <- c(log, paste0("Saved to ", output_path))
      if (isTRUE(verbose)) cat("  Saved to ", output_path, "\n", sep = "")
    }
  }

  out <- list(
    results = results,
    spec = spec,
    dataset = dataset[setdiff(names(dataset), "data")],
    coverage = coverage,
    problems = spec$problems,
    output_path = output_path,
    save_error = save_error,
    log = log,
    elapsed = difftime(Sys.time(), started, units = "secs")
  )

  class(out) <- c("analysis_run", "list")
  out
}


#' @param x An `analysis_run` object.
#' @param ... Ignored.
#' @export
#' @rdname run_analysis_locally
print.analysis_run <- function(x, ...) {
  wide <- x$results$combined_results

  cat("<analysis_run>\n")
  cat("  dataset      :", x$dataset$filename, "\n")
  cat("  analyses     :", nrow(x$spec$loa), "\n")
  cat("  disaggregated:", paste(x$spec$group_variables, collapse = ", "), "\n")
  cat("  result table :", format(nrow(wide), big.mark = ","), "rows x",
      format(ncol(wide), big.mark = ","), "columns\n")
  cat("  elapsed      :", format(round(as.numeric(x$elapsed), 1)), "seconds\n")

  counts <- ak_problem_counts(x$problems)
  if (counts[["warning"]] > 0L) {
    cat("  warnings     :", counts[["warning"]], "- see $problems\n")
  }

  cat("  saved        :", x$output_path %||% "nothing written", "\n")
  if (!is.null(x$save_error)) {
    cat("  save failed  :", x$save_error, "\n")
  }

  # Printed rather than logged: these percentages get published, and the caveat
  # has to reach whoever is about to send the file on.
  notes <- unique(c(
    ak_exclusive_base_note(x$results$choice_combinations),
    ak_exclusive_base_note(x$results$exclusive_combinations)
  ))
  if (length(notes) > 0) {
    cat("\n  The choice-combination rows use a smaller denominator than the rest of the workbook:\n")
    for (note in notes) cat("    -", note, "\n")
    cat("  Footnote this wherever the combination percentages are published.\n")
  }

  invisible(x)
}


# -----------------------------------------------------------------------------
# Getting started
# -----------------------------------------------------------------------------

#' Copy the List of Analysis Template
#'
#' A workbook with every sheet the reader recognises, to fill in and upload.
#' The schema behind it is documented in `inst/extdata/loa-schema.md`.
#'
#' @param dir Folder to copy the template into. Created if it does not exist.
#' @param filename Name to give the copy.
#' @param overwrite Logical. Replace an existing file of that name.
#' @return The path written, invisibly.
#' @export
#' @examples
#' copy_loa_template(tempdir())
copy_loa_template <- function(dir = ".",
                              filename = "loa_template.xlsx",
                              overwrite = FALSE) {
  template <- system.file("extdata", "loa_template.xlsx",
                          package = "analysiskit")
  if (!nzchar(template) || !file.exists(template)) {
    stop("The List of Analysis template is missing from the installation.", call. = FALSE)
  }

  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }

  path <- file.path(dir, filename)
  if (file.exists(path) && !isTRUE(overwrite)) {
    stop(
      paste0("'", path, "' already exists. Pass overwrite = TRUE to replace it."),
      call. = FALSE
    )
  }

  file.copy(template, path, overwrite = TRUE)
  message("List of Analysis template written to ", path)
  invisible(path)
}


#' What the Package Needs, and What Is Installed
#'
#' `need = "required"` means every run uses it and it is installed with the
#' package. `need = "optional"` means one feature needs it, and that feature is
#' the survey engine: an analysis row with a `level` set asks for a confidence
#' interval, which routes that row through \pkg{srvyr} and
#' \pkg{analysistools}. Leave every `level` cell empty and the fast tabulation
#' engine handles the whole run, needing neither - and, on a large
#' disaggregation, taking seconds rather than minutes.
#'
#' Nothing is installed here. The two optional GitHub packages are not on CRAN,
#' so the `install` column gives the command to run. [load_packages()] does the
#' installing.
#'
#' The roster itself lives in [ak_package_roster()], so this function and
#' [load_packages()] cannot disagree about what is optional or where the GitHub
#' packages come from.
#'
#' @return A data frame with `package`, `need`, `installed`, `version`,
#'   `install` and `purpose`.
#' @seealso [load_packages()] to install what is missing.
#' @export
#' @examples
#' check_analysis_packages()
check_analysis_packages <- function() {
  required <- ak_package_roster()

  installed <- vapply(
    required$package,
    function(p) requireNamespace(p, quietly = TRUE),
    logical(1),
    USE.NAMES = FALSE
  )

  version <- vapply(
    seq_along(required$package),
    function(i) {
      if (!installed[i]) return(NA_character_)
      as.character(utils::packageVersion(required$package[i]))
    },
    character(1)
  )

  install <- ifelse(
    installed,
    "",
    ifelse(
      is.na(required$repo),
      paste0("install.packages('", required$package, "')"),
      paste0("remotes::install_github('", required$repo, "')")
    )
  )

  data.frame(
    package = required$package,
    need = required$need,
    installed = installed,
    version = version,
    install = install,
    purpose = required$purpose,
    stringsAsFactors = FALSE
  )
}
