# =============================================================================
# List of Analysis workbook layout: column names, description rows, help text
# =============================================================================
#
# The template carries a row of column descriptions directly under the header
# of analysis_variables, disaggregation_variables and settings, and a
# description column in settings and route_analysis. Both are for the person
# filling the workbook in. The reader recognises the description row and skips
# it (read_loa_workbook()); the writer puts it there (ak_write_loa()). The text
# lives here once, so the two always agree.
#
# Former column names are read as their current ones, so a workbook made before
# a rename still runs.
# =============================================================================

#' Former Column Names and the Names They Now Read As
#'
#' `full_sample_base` became `sample_base` and `full_sample_label` became
#' `na_label`. A workbook that still uses the former names reads exactly as
#' before.
#'
#' @return A named list, one element per sheet: a named character vector whose
#'   names are the former column names and values the current ones.
#' @keywords internal
loa_column_aliases <- function() {
  list(
    analysis_variables = c(
      full_sample_base = "sample_base",
      full_sample_label = "na_label"
    )
  )
}


#' Rename Former Columns to Their Current Names
#'
#' A sheet that carries both the former and the current name of one column is
#' left as it is, and the pair is returned in `clashes` for [validate_loa()]
#' to report: the reader cannot tell which one is meant.
#'
#' @param df A sheet's data frame, or `NULL`.
#' @param sheet The sheet's (normalised) name.
#' @return A list with `df` and `clashes` (character: "former / current").
#' @keywords internal
loa_apply_column_aliases <- function(df, sheet) {
  aliases <- loa_column_aliases()[[sheet]]
  clashes <- character(0)
  if (is.null(df) || is.null(aliases) || !is.data.frame(df)) {
    return(list(df = df, clashes = clashes))
  }
  for (old in names(aliases)) {
    new <- aliases[[old]]
    if (!old %in% names(df)) {
      next
    }
    if (new %in% names(df)) {
      clashes <- c(clashes, paste0(old, " / ", new))
      next
    }
    names(df)[names(df) == old] <- new
  }
  list(df = df, clashes = clashes)
}


#' What Each Column Is For, as Written in the Description Row
#'
#' The italic row directly under the header of three sheets. The writer
#' fills it in from here and the reader recognises it from here, so changing a
#' description here changes both.
#'
#' @return A named list, one element per sheet that has a description row: a
#'   named character vector, one description per column.
#' @export
loa_column_descriptions <- function() {
  list(
    analysis_variables = c(
      analysis_type = paste(
        "Required. How to analyse the variable. Pick from the list:",
        "prop_select_one, prop_select_multiple, mean, median or ratio."
      ),
      analysis_var = paste(
        "Required. The variable's name in the dataset, as a raw code such as",
        "Q27. For a multiple-choice question, the question itself, not one",
        "of its choices."
      ),
      section = paste(
        "Optional. A heading to group the results under. Each section gets",
        "its own sheet in the results workbook."
      ),
      sample_base = paste(
        "Optional, percentages only. TRUE: out of everyone, with those not",
        "asked shown as a row of their own. Blank or FALSE: out of those who",
        "answered."
      ),
      na_label = paste(
        "Optional. The name of the row for those not asked, when sample_base",
        "is TRUE. Blank: Not asked / no response."
      ),
      level = paste(
        "Optional. A confidence level such as 0.95 adds a confidence",
        "interval. Leave blank unless you report one: it slows the run down."
      ),
      analysis_var_numerator = paste(
        "Ratio only. The variable added up for the top of the ratio."
      ),
      analysis_var_denominator = paste(
        "Ratio only. The variable added up for the bottom of the ratio."
      ),
      numerator_NA_to_0 = paste(
        "Ratio only. TRUE counts a blank numerator as 0. Blank: FALSE."
      ),
      filter_denominator_0 = paste(
        "Ratio only. TRUE leaves out respondents whose denominator is 0.",
        "Blank: FALSE."
      ),
      group_var = paste(
        "Optional. A disaggregation for this row only. Usually blank: use the",
        "disaggregation_variables sheet instead."
      ),
      description = paste(
        "Optional. A note for whoever reads the workbook. Ignored by the",
        "analysis."
      )
    ),
    disaggregation_variables = c(
      raw_data_name = paste(
        "Required. The variable's name in the dataset, as a raw code such as",
        "Q27."
      ),
      new_name = paste(
        "Required. The name the variable gets in the results, such as",
        "Respondent gender."
      ),
      include = paste(
        "TRUE to use the variable, FALSE to leave it out without deleting the",
        "row. Blank: TRUE."
      )
    ),
    settings = c(
      setting = "The name of the setting. Do not change it.",
      value = "Your value. Leave blank to use the default.",
      description = "What the setting does."
    )
  )
}


#' Is This the Description Row
#'
#' The row directly under the header is the description row when every
#' non-blank cell in it is the description of its own column, and at least one
#' cell is filled. A row where any cell holds something else is data, so a
#' description row that has been typed over is read, and checked, like any
#' other row rather than silently dropped.
#'
#' @param sheet The sheet's (normalised) name.
#' @param row A one-row data frame read as text, named by the header.
#' @return `TRUE` or `FALSE`.
#' @keywords internal
loa_is_description_row <- function(sheet, row) {
  known <- loa_column_descriptions()[[sheet]]
  if (is.null(known) || is.null(row) || nrow(row) < 1L) {
    return(FALSE)
  }
  squish <- function(x) tolower(gsub("[[:space:]]+", " ", trimws(x)))
  cells <- vapply(row[1L, , drop = FALSE], function(x) as.character(x)[1], "")
  filled <- !is.na(cells) & nzchar(trimws(cells))
  if (!any(filled)) {
    return(FALSE)
  }
  # A column read under a former name still has its description.
  columns <- names(cells)
  aliases <- loa_column_aliases()[[sheet]]
  former <- columns %in% names(aliases)
  columns[former] <- aliases[columns[former]]

  expected <- unname(known[columns])
  all(
    !is.na(expected[filled]) & squish(cells[filled]) == squish(expected[filled])
  )
}


#' Rows Above the First Data Row of a Sheet
#'
#' The header, plus the description row when the sheet was read with one, so
#' a problem can name the row the user sees in Excel.
#'
#' @param workbook The list from [read_loa_workbook()], or a bare list of
#'   sheets.
#' @param sheet The sheet's (normalised) name.
#' @return An integer: 1 or 2.
#' @keywords internal
loa_header_rows <- function(workbook, sheet) {
  h <- workbook$header_rows
  if (!is.null(h) && sheet %in% names(h)) as.integer(h[[sheet]]) else 1L
}


#' What Each Setting Does
#'
#' One plain sentence or two per key of [loa_settings_schema()], written into
#' the `description` column of the `settings` and `route_analysis` sheets.
#'
#' @return A named character vector, one element per setting.
#' @export
loa_setting_descriptions <- function() {
  c(
    # data and design
    sm_separator = "The character between a multiple-choice question and its choice in the dataset's column names. ONA uses /.",
    skip_label_row = "TRUE: row 1 of the dataset holds the question labels, not a respondent.",
    blank_to_na = "TRUE: treat empty cells as missing.",
    prepare_sm = "TRUE: turn multiple-choice choice columns into 0/1, keeping track of who was not asked.",
    sm_child_style = "How the choice columns are written in the dataset: label, dummy (0/1), or auto to detect it.",
    recreate_sm_parents = "TRUE: rebuild each multiple-choice question from its choice columns. Needs the cleaningtools package and a column named uuid.",
    weight_column = "The dataset column holding the survey weights. Blank: an unweighted analysis.",
    strata_column = "The dataset column holding the strata. Changes confidence intervals only.",

    # estimation
    engine = "auto (recommended): only rows whose confidence interval is reported use the slower survey engine. fast or survey sends every row to one engine.",
    fallback_level = "The confidence level used for rows with no level. Their interval is left blank.",
    min_group_n = "Groups with fewer respondents than this are left out of a disaggregation. Blank: keep every group.",
    keep_missing_groups = "TRUE: respondents with no answer to a disaggregation variable get a column of their own.",
    slim_design = "TRUE: give the survey design only the columns it needs, which is faster.",
    lonely_psu = "How the survey engine treats a stratum with a single sampling unit (survey.lonely.psu).",

    # denominator
    exclude_ignore_case = "TRUE: match the choices in the exclude_choices sheet whatever their upper and lower case.",

    # output shape
    value_columns = "The columns written for each group, comma-separated. Add n_w,n_w_total when weighting, and stat_low,stat_upp for confidence intervals.",
    extra_columns = "Columns of the analysis_variables sheet to carry into the results, comma-separated, such as section.",
    missing_group_label = "The column heading for respondents with no answer to a disaggregation variable.",
    use_group_prefix = "Leave TRUE. FALSE can make the columns of two disaggregations collide.",
    summary_value_label = "The text written as the answer on mean, median and ratio rows.",
    drop_empty_prop_rows = "TRUE: drop the empty placeholder row that percentages produce.",
    add_analysis_type_label = "TRUE: add a readable analysis-type column to the results.",
    label_choices = "TRUE: show multiple-choice answers by their labels.",

    # selection counts
    count_selections_mode = "grouped: none, exactly one, more than one. exact: one row per number of choices selected.",
    count_selections_order = "The order of the selection-count rows: descending or ascending.",
    count_selections_heading = "The heading above the selection-count rows.",
    count_selections_spacer = "TRUE: leave a blank row above the selection-count rows.",
    count_selections_title_suffix = "Text added to the end of each selection-count title.",
    count_selections_label_none = "The row label for respondents who selected no choice.",
    count_selections_label_one = "The row label for respondents who selected exactly one choice.",
    count_selections_label_many = "The row label for respondents who selected more than one choice.",

    # choice combinations
    count_combinations_order = "The order of the combination rows: descending or ascending.",
    count_combinations_joiner = "The text between two choices in a combination label. Wrap it in double quotes to keep its spaces, as in \" + \".",
    count_combinations_only_suffix = "The text after a combination with nothing else selected. Wrap it in double quotes to keep its spaces.",
    count_combinations_other_label = "The label for choices outside the listed ones.",
    count_combinations_other_multiple_label = "The row label for more than one choice, none of them listed.",
    count_combinations_single_label = "A row label for respondents who selected only one choice. Blank: no such row.",
    count_combinations_heading = "The heading above the combination rows.",
    count_combinations_spacer = "TRUE: leave a blank row above the combination rows.",
    count_combinations_title_suffix = "Text added to the end of each combination title.",
    count_combinations_ignore_case = "TRUE: match choice labels whatever their upper and lower case.",
    max_combination_choices = "The most choices one question can list in count_combinations.",

    # single choices
    count_exclusive_combinations_only_suffix = "The text after a choice selected on its own. Wrap it in double quotes to keep its spaces, as in \" only\".",
    count_exclusive_combinations_other_label = "The row label for a single choice that is not listed.",
    count_exclusive_combinations_multiple_label = "A row label for respondents who selected more than one choice. Blank: no such row.",
    count_exclusive_combinations_heading = "The heading above the single-choice rows.",
    count_exclusive_combinations_spacer = "TRUE: leave a blank row above the single-choice rows.",
    count_exclusive_combinations_title_suffix = "Text added to the end of each single-choice title.",
    max_exclusive_choices = "The most choices one question can list in count_exclusive_combinations.",

    # results workbook
    include_dataset = "TRUE: add the dataset to the results workbook. It is personal data, so handle and share the workbook as such.",

    # route analysis
    transit_country = "TRUE adds a Transit Countries sheet: the countries passed through (Q47-Q54, all slots pooled), with why this route (Q72) and QN8, overall and per country.",
    places_stop = "TRUE adds a Places Stop sheet: where people stopped (Q56-Q70, five slots pooled), by country and place, with the reasons for stopping.",
    dangerous_location = "TRUE adds a Dangerous Locations sheet: the most dangerous places (Q98-Q117, five slots pooled), by country and place, with the incidents experienced and the perpetrators.",
    route_full_sample_base = "TRUE (the default; blank also means TRUE) counts the questions everyone is asked out of the full sample: each country ranking is out of all respondents (None and Refused are not listed), and Why did you take this route (Q72) is out of everyone, with those who did not answer as their own row. The other questions stay out of those asked. FALSE puts these on that footing too.",
    route_gender_var = "The gender question every route table is broken down by, as its raw code. The disaggregation_variables are added alongside it.",
    route_top_countries = "How many countries get their own columns, those named by the most respondents first. 0 shows every country. The ranking table at the top of each sheet always lists all of them.",
    route_top_locations = "How many places per country get their own columns, those named by the most respondents first. A whole number of 1 or more."
  )
}
