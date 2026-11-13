# Full-sample base: count blanks (questions never asked) in the denominator.
# Reached through run_group_analysis_pipeline(full_sample_base = TRUE).

#' Count Proportions Out of the Full Sample
#'
#' By default a respondent with no answer to a question - typically because
#' skip logic never asked it - is outside the denominator of that question, so a
#' question asked of 600 of 1,000 respondents reports \code{n_total = 600}.
#' This puts those respondents back in the base:
#'
#' \describe{
#'   \item{select_one}{A blank answer becomes \code{label} (by default
#'     \emph{Not asked / no response}), so it is reported as its own row and
#'     the question's rows add up to the whole sample.}
#'   \item{select_multiple}{A blank child (the question was not asked) becomes
#'     \code{0} (not selected), so every choice is a share of the full
#'     sample. A child column named \code{label} is added, 1 for respondents
#'     never asked and 0 for everyone else, so the not-asked share is its own
#'     row, last, in every column. The parent is filled with \code{label} too,
#'     because the survey engine reads who was asked from the parent.}
#' }
#'
#' Means, medians and ratios are left alone: a blank number cannot be averaged
#' without inventing a value for it.
#'
#' Run it after \code{\link{ck_sm_children_to_binary}} and before
#' \code{\link{ck_exclude_choices}}, so that a choice excluded on purpose still
#' leaves the denominator. A variable that is also a grouping variable is
#' skipped, so the "Missing" group of a disaggregation is not renamed.
#'
#' @param dataset The analysis dataset.
#' @param loa The list of analyses, used to find the variables to act on.
#' @param group_variables Grouping variables; these are never filled.
#' @param label Row label for respondents with no answer, in select_one and
#'   select_multiple questions. Default \code{"Not asked / no response"}.
#' @param sm_separator Separator between parent and choice. Default \code{"/"}.
#' @param verbose Logical. Default \code{TRUE}.
#' @return A list with \code{dataset}, \code{filled} (one row per variable:
#'   \code{analysis_var}, \code{analysis_type}, \code{n_filled}) and
#'   \code{filled_vars} (the variables that were filled).
#' @keywords internal
ck_full_sample_base <- function(
  dataset,
  loa,
  group_variables = NULL,
  label = "Not asked / no response",
  sm_separator = "/",
  verbose = TRUE
) {
  label <- trimws(as.character(label))
  if (length(label) != 1 || is.na(label) || label == "") {
    stop(
      "full_sample_label must be a single, non-empty piece of text, ",
      "for example \"Not asked / no response\".",
      call. = FALSE
    )
  }

  loa_vars <- function(type) {
    v <- unique(loa$analysis_var[
      !is.na(loa$analysis_type) & tolower(loa$analysis_type) == type
    ])
    v[!is.na(v)]
  }

  group_cols <- unique(c(
    setdiff(group_variables, "Overall"),
    if ("group_var" %in% names(loa)) loa$group_var else NULL
  ))
  group_cols <- group_cols[!is.na(group_cols)]

  log_rows <- list()
  add_log <- function(var, type, n) {
    log_rows[[length(log_rows) + 1]] <<- data.frame(
      analysis_var = var,
      analysis_type = type,
      n_filled = n,
      stringsAsFactors = FALSE
    )
  }

  # --- select_one ------------------------------------------------------------
  so_vars <- intersect(loa_vars("prop_select_one"), names(dataset))
  skipped <- intersect(so_vars, group_cols)
  so_vars <- setdiff(so_vars, group_cols)

  if (length(skipped) > 0) {
    ck_warn(
      "full_sample_base: ",
      paste(skipped, collapse = ", "),
      " is also a grouping variable, so its blanks were left as they are and ",
      "it is still reported out of those who answered."
    )
  }

  for (v in so_vars) {
    x <- dataset[[v]]
    values <- trimws(as.character(x))
    blank <- is.na(values) | values == "" | values == "NA"
    if (!any(blank)) {
      next
    }

    if (is.factor(x)) {
      levels(x) <- unique(c(levels(x), label))
      x[blank] <- label
      dataset[[v]] <- x
    } else {
      x <- as.character(x)
      x[blank] <- label
      dataset[[v]] <- x
    }
    add_log(v, "prop_select_one", sum(blank))
  }

  # --- select_multiple -------------------------------------------------------
  for (p in setdiff(loa_vars("prop_select_multiple"), group_cols)) {
    children <- names(ck_sm_child_suffixes(p, names(dataset), sm_separator))
    if (length(children) == 0) {
      next
    }

    # Who was not asked, read before the children are filled: after
    # ck_sm_children_to_binary() every child of a never-asked respondent is NA.
    not_asked <- Reduce(
      `&`,
      lapply(children, function(cc) is.na(dataset[[cc]]))
    )

    n_blank <- 0L
    for (cc in children) {
      x <- dataset[[cc]]
      blank <- is.na(x)
      if (!any(blank)) {
        next
      }
      n_blank <- max(n_blank, sum(blank))
      x[blank] <- if (is.character(x)) "0" else 0
      dataset[[cc]] <- x
    }

    # The survey engine decides who was asked from the parent column, so a
    # blank parent would still take the respondent out of its base. Only the
    # children are ever tabulated, so the parent's text is never reported.
    if (p %in% names(dataset)) {
      parent <- trimws(as.character(dataset[[p]]))
      blank <- is.na(parent) | parent == "" | parent == "NA"
      if (any(blank)) {
        parent[blank] <- label
        dataset[[p]] <- parent
        n_blank <- max(n_blank, sum(blank))
      }
    }

    # The not-asked share as one more choice, so it is reported as its own row
    # in every column, overall and disaggregated, like the select_one row. It is
    # an ordinary child column - 1 for not asked, 0 otherwise - added last so it
    # is tabulated last, and blanked with the rest by exclude_choices.
    if (any(not_asked)) {
      na_col <- paste0(p, sm_separator, label)
      if (na_col %in% names(dataset)) {
        ck_warn(
          "full_sample_base: '",
          p,
          "' already has a choice called '",
          label,
          "', so no separate not-asked row was added for it. Set ",
          "full_sample_label to a different text."
        )
      } else {
        dataset[[na_col]] <- as.numeric(not_asked)
      }
      n_blank <- max(n_blank, sum(not_asked))
    }

    if (n_blank > 0) add_log(p, "prop_select_multiple", n_blank)
  }

  filled <- if (length(log_rows) > 0) {
    dplyr::bind_rows(log_rows)
  } else {
    data.frame(
      analysis_var = character(0),
      analysis_type = character(0),
      n_filled = integer(0),
      stringsAsFactors = FALSE
    )
  }

  ck_note(
    "full sample base: blanks counted in the denominator for ",
    nrow(filled),
    " variable(s); blanks reported as '",
    label,
    "'",
    verbose = verbose
  )

  list(
    dataset = dataset,
    filled = filled,
    filled_vars = filled$analysis_var
  )
}


#' Put the "Not Asked / No Response" Row Last
#'
#' The wide table lists a question's choices in the order they first appear in
#' the long results, and the survey engine sorts choices alphabetically, so the
#' row added by \code{\link{ck_full_sample_base}} could land anywhere among
#' them. This moves it to the end of its question without disturbing any other
#' row.
#'
#' @param results_long Long results.
#' @param vars The select_one and select_multiple variables that were filled.
#' @param label The row label used for them.
#' @return \code{results_long}, reordered.
#' @keywords internal
ck_no_response_last <- function(results_long, vars, label) {
  if (length(vars) == 0 || nrow(results_long) == 0) {
    return(results_long)
  }

  type <- tolower(as.character(results_long$analysis_type))
  var <- as.character(results_long$analysis_var)
  value <- as.character(results_long$analysis_var_value)

  is_label <- type %in%
    c("prop_select_one", "prop_select_multiple") &
    var %in% vars &
    !is.na(value) &
    value == label
  if (!any(is_label)) {
    return(results_long)
  }

  block <- paste(type, var, sep = "\r")
  block_pos <- match(block, unique(block))

  results_long[
    order(block_pos, is_label, seq_len(nrow(results_long))),
    ,
    drop = FALSE
  ]
}
