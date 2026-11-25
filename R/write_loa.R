# =============================================================================
# Writing a List of Analysis workbook
# =============================================================================
#
# ak_write_loa() is the inverse of read_loa_workbook(): the sheets it writes
# read back into the same specification. It lays the workbook out the way the
# template is laid out - a readme by sheet, a description row under the
# header, drop-down lists for the cells with a fixed set of values - so the
# template (built by dev/build_loa_template.R) and a setup saved from the app
# look the same.
# =============================================================================

#' The Order Sheets Are Written In
#'
#' The template's own sheets first, in the order they are filled in, with the
#' optional sheets the template leaves out placed where they belong.
#'
#' @return A character vector of sheet names.
#' @keywords internal
loa_write_order <- function() {
  c(
    "analysis_variables",
    "disaggregation_variables",
    "count_selections",
    "count_combinations",
    "count_exclusive_combinations",
    "exclude_choices",
    "route_analysis",
    "settings"
  )
}


#' Write a List of Analysis Workbook
#'
#' Writes the sheets as a styled List of Analysis workbook: a `readme` sheet
#' with one section per sheet, in sheet order; a navy header; an italic row
#' of column descriptions under the header of `analysis_variables`,
#' `disaggregation_variables` and `settings` (skipped by
#' [read_loa_workbook()]); a `description` column in `settings` and
#' `route_analysis`; and drop-down lists for `analysis_type`, `sample_base`
#' and `include`.
#'
#' A drop-down list is one rule over a range of cells, so its size in the file
#' does not depend on how many rows it covers.
#'
#' @param sheets A named list of data frames, named by sheet
#'   (`analysis_variables`, `disaggregation_variables`, `settings`, ...).
#'   Former column names (`full_sample_base`, `full_sample_label`) are written
#'   under their current names. Empty optional sheets are left out.
#' @param path Where to write the `.xlsx`.
#' @param dropdown_rows Number of data rows the drop-down lists cover.
#' @return `path`, invisibly.
#' @export
#' @examples
#' sheets <- list(
#'   analysis_variables = data.frame(
#'     analysis_type = "prop_select_one",
#'     analysis_var = "Q27",
#'     section = "Demographics"
#'   ),
#'   settings = data.frame(setting = "sm_separator", value = "/")
#' )
#' ak_write_loa(sheets, tempfile(fileext = ".xlsx"))
ak_write_loa <- function(sheets, path, dropdown_rows = 1000L) {
  if (!is.list(sheets) || is.null(names(sheets))) {
    stop(
      "sheets must be a named list of data frames, one per sheet of the ",
      "List of Analysis.",
      call. = FALSE
    )
  }
  names(sheets) <- loa_normalise_sheet_name(names(sheets))
  unknown <- setdiff(names(sheets), loa_write_order())
  if (length(unknown) > 0) {
    stop(
      "Cannot write sheet(s) ",
      paste0("'", unknown, "'", collapse = ", "),
      ": not part of the List of Analysis. Expected one of: ",
      paste(loa_write_order(), collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  keep <- vapply(
    names(sheets),
    function(nm) {
      nm == "analysis_variables" ||
        (!is.null(sheets[[nm]]) && nrow(sheets[[nm]]) > 0)
    },
    logical(1)
  )
  sheets <- sheets[keep]
  if (is.null(sheets$analysis_variables)) {
    sheets$analysis_variables <- data.frame(
      analysis_type = character(0),
      analysis_var = character(0)
    )
  }
  order <- intersect(loa_write_order(), names(sheets))
  sheets <- sheets[order]

  for (nm in names(sheets)) {
    df <- as.data.frame(
      sheets[[nm]],
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    df <- loa_apply_column_aliases(df, nm)$df
    if (nm %in% c("settings", "route_analysis")) {
      df <- loa_with_setting_descriptions(df)
    }
    sheets[[nm]] <- loa_logical_columns(df)
  }

  wb <- openxlsx::createWorkbook()
  loa_write_readme(wb, names(sheets))
  for (nm in names(sheets)) {
    loa_write_sheet(wb, nm, sheets[[nm]], dropdown_rows)
  }
  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
  invisible(path)
}


#' Fill In a Settings Sheet's Description Column
#'
#' Adds the column when it is missing and fills only its blank cells, so a
#' description someone wrote is kept.
#'
#' @param df A `setting` / `value` data frame.
#' @return The data frame with a `description` column after `value`.
#' @keywords internal
loa_with_setting_descriptions <- function(df) {
  if (!"setting" %in% names(df)) {
    return(df)
  }
  known <- loa_setting_descriptions()
  given <- if ("description" %in% names(df)) {
    as.character(df$description)
  } else {
    rep(NA_character_, nrow(df))
  }
  blank <- is.na(given) | !nzchar(trimws(given))
  given[blank] <- unname(known[trimws(as.character(df$setting[blank]))])
  df$description <- given
  df[c(setdiff(names(df), "description"), "description")]
}


#' Write TRUE / FALSE Columns as Excel Logicals
#'
#' The columns that take a drop-down of `TRUE` and `FALSE` are written as
#' logicals when every value in them is one, so they look the same as a value
#' picked from the list.
#'
#' @param df A sheet.
#' @return The sheet.
#' @keywords internal
loa_logical_columns <- function(df) {
  for (col in intersect(names(df), loa_logical_column_names())) {
    v <- loa_trim(df[[col]])
    if (all(is.na(v) | toupper(v) %in% c("TRUE", "FALSE"))) {
      df[[col]] <- loa_as_logical(v)
    }
  }
  df
}


#' Columns That Hold TRUE or FALSE
#' @return A character vector.
#' @keywords internal
loa_logical_column_names <- function() {
  c("sample_base", "include", "numerator_NA_to_0", "filter_denominator_0")
}


#' The Drop-Down Lists of a Sheet
#' @param sheet The sheet's name.
#' @return A named list: column name to the values offered.
#' @keywords internal
loa_dropdowns <- function(sheet) {
  tf <- c("TRUE", "FALSE")
  switch(
    sheet,
    analysis_variables = list(
      analysis_type = loa_known_analysis_types(),
      sample_base = tf,
      numerator_NA_to_0 = tf,
      filter_denominator_0 = tf
    ),
    disaggregation_variables = list(include = tf),
    count_selections = list(include = tf),
    count_combinations = list(include = tf),
    count_exclusive_combinations = list(include = tf),
    exclude_choices = list(include = tf),
    list()
  )
}


#' Shared Cell Styles
#' @return A named list of openxlsx styles.
#' @keywords internal
loa_write_styles <- function() {
  navy <- "#003D58"
  list(
    header = openxlsx::createStyle(
      fontColour = "#FFFFFF",
      fgFill = navy,
      textDecoration = "bold",
      valign = "center",
      wrapText = TRUE
    ),
    description = openxlsx::createStyle(
      fontColour = "#4D5D6B",
      fgFill = "#EEF2F5",
      textDecoration = "italic",
      valign = "top",
      wrapText = TRUE
    ),
    body = openxlsx::createStyle(valign = "top"),
    body_wrap = openxlsx::createStyle(valign = "top", wrapText = TRUE),
    title = openxlsx::createStyle(
      fontColour = navy,
      fontSize = 16,
      textDecoration = "bold"
    ),
    section = openxlsx::createStyle(
      fontColour = "#FFFFFF",
      fgFill = navy,
      fontSize = 12,
      textDecoration = "bold",
      valign = "center"
    ),
    text = openxlsx::createStyle(valign = "top", wrapText = TRUE),
    table_head = openxlsx::createStyle(
      fontColour = navy,
      fgFill = "#DCE6EC",
      textDecoration = "bold",
      valign = "top"
    ),
    table_key = openxlsx::createStyle(
      fontColour = navy,
      textDecoration = "bold",
      valign = "top",
      wrapText = TRUE
    )
  )
}


#' Column Width for a Sheet Column
#' @param sheet The sheet's name.
#' @param column The column name.
#' @return A width in Excel character units.
#' @keywords internal
loa_column_width <- function(sheet, column) {
  widths <- c(
    analysis_type = 24,
    analysis_var = 20,
    section = 20,
    sample_base = 18,
    na_label = 26,
    level = 16,
    analysis_var_numerator = 22,
    analysis_var_denominator = 22,
    numerator_NA_to_0 = 18,
    filter_denominator_0 = 18,
    group_var = 18,
    raw_data_name = 24,
    new_name = 32,
    include = 18,
    choice_label = 40,
    display_name = 24,
    setting = 40,
    value = 34,
    description = if (sheet %in% c("settings", "route_analysis")) 90 else 40
  )
  if (column %in% names(widths)) widths[[column]] else 22
}


#' Height for a Row of Wrapped Text
#' @param text The cells' text.
#' @param widths Their column widths.
#' @return A height in points.
#' @keywords internal
loa_row_height <- function(text, widths) {
  text[is.na(text)] <- ""
  lines <- ceiling(nchar(text) / pmax(widths - 2, 1))
  15 * max(1, lines)
}


#' Write One Sheet of the Workbook
#' @param wb An openxlsx workbook.
#' @param sheet The sheet's name.
#' @param df Its data.
#' @param dropdown_rows Number of data rows the drop-down lists cover.
#' @return `wb`, invisibly.
#' @keywords internal
loa_write_sheet <- function(wb, sheet, df, dropdown_rows) {
  st <- loa_write_styles()
  openxlsx::addWorksheet(wb, sheet, gridLines = TRUE)
  columns <- names(df)
  n_col <- length(columns)
  widths <- vapply(columns, function(cc) loa_column_width(sheet, cc), 1)

  descriptions <- loa_column_descriptions()[[sheet]]
  has_desc <- !is.null(descriptions)
  first_data <- if (has_desc) 3L else 2L

  openxlsx::writeData(wb, sheet, df[0, , drop = FALSE], colNames = TRUE)
  openxlsx::addStyle(wb, sheet, st$header, rows = 1, cols = seq_len(n_col))

  if (has_desc) {
    desc <- unname(descriptions[columns])
    desc[is.na(desc)] <- ""
    openxlsx::writeData(
      wb,
      sheet,
      as.data.frame(t(desc), stringsAsFactors = FALSE),
      startRow = 2,
      colNames = FALSE
    )
    openxlsx::addStyle(
      wb,
      sheet,
      st$description,
      rows = 2,
      cols = seq_len(n_col)
    )
    openxlsx::setRowHeights(
      wb,
      sheet,
      rows = 2,
      heights = loa_row_height(desc, widths)
    )
  }

  if (nrow(df) > 0) {
    openxlsx::writeData(wb, sheet, df, startRow = first_data, colNames = FALSE)
    wrap <- columns == "description"
    rows <- first_data + seq_len(nrow(df)) - 1L
    if (any(!wrap)) {
      openxlsx::addStyle(
        wb,
        sheet,
        st$body,
        rows = rows,
        cols = which(!wrap),
        gridExpand = TRUE
      )
    }
    if (any(wrap)) {
      openxlsx::addStyle(
        wb,
        sheet,
        st$body_wrap,
        rows = rows,
        cols = which(wrap),
        gridExpand = TRUE
      )
      text <- as.character(df[[which(wrap)[1]]])
      heights <- vapply(
        text,
        function(x) loa_row_height(x, widths[which(wrap)[1]]),
        1
      )
      openxlsx::setRowHeights(wb, sheet, rows = rows, heights = unname(heights))
    }
  }

  dropdowns <- loa_dropdowns(sheet)
  span <- seq(first_data, length.out = max(dropdown_rows, nrow(df)))
  for (cc in intersect(names(dropdowns), columns)) {
    openxlsx::dataValidation(
      wb,
      sheet,
      cols = match(cc, columns),
      rows = span,
      type = "list",
      value = paste0("\"", paste(dropdowns[[cc]], collapse = ","), "\"")
    )
  }

  openxlsx::setColWidths(wb, sheet, cols = seq_len(n_col), widths = widths)
  openxlsx::freezePane(wb, sheet, firstActiveRow = first_data)
  invisible(wb)
}


#' Write the Readme Sheet
#'
#' One section per sheet, in the order the sheets are written, after a short
#' introduction.
#'
#' @param wb An openxlsx workbook.
#' @param sheets The names of the sheets being written, in order.
#' @return `wb`, invisibly.
#' @keywords internal
loa_write_readme <- function(wb, sheets) {
  st <- loa_write_styles()
  openxlsx::addWorksheet(wb, "readme", gridLines = FALSE)
  widths <- c(30, 100)
  openxlsx::setColWidths(wb, "readme", cols = 1:2, widths = widths)

  rows <- loa_readme_rows(sheets)
  for (i in seq_len(nrow(rows))) {
    type <- rows$type[i]
    a <- rows$a[i]
    b <- rows$b[i]
    if (type == "blank") {
      next
    }
    if (type %in% c("title", "section", "text")) {
      openxlsx::writeData(wb, "readme", a, startRow = i, startCol = 1)
      openxlsx::mergeCells(wb, "readme", cols = 1:2, rows = i)
      style <- switch(type, title = st$title, section = st$section, st$text)
      openxlsx::addStyle(wb, "readme", style, rows = i, cols = 1:2)
      height <- switch(
        type,
        title = 24,
        section = 20,
        loa_row_height(a, sum(widths))
      )
      openxlsx::setRowHeights(wb, "readme", rows = i, heights = height)
      next
    }
    openxlsx::writeData(
      wb,
      "readme",
      data.frame(a = a, b = b),
      startRow = i,
      colNames = FALSE
    )
    if (type == "th") {
      openxlsx::addStyle(wb, "readme", st$table_head, rows = i, cols = 1:2)
    } else {
      openxlsx::addStyle(wb, "readme", st$table_key, rows = i, cols = 1)
      openxlsx::addStyle(wb, "readme", st$text, rows = i, cols = 2)
      openxlsx::setRowHeights(
        wb,
        "readme",
        rows = i,
        heights = max(
          loa_row_height(b, widths[2]),
          loa_row_height(a, widths[1])
        )
      )
    }
  }
  invisible(wb)
}


#' The Readme, Row by Row
#'
#' @param sheets The names of the sheets being written, in order.
#' @return A data frame with `type` (`title`, `section`, `text`, `th`, `tr`,
#'   `blank`), `a` and `b`.
#' @keywords internal
loa_readme_rows <- function(sheets) {
  out <- list()
  add <- function(type, a = NA_character_, b = NA_character_) {
    out[[length(out) + 1L]] <<- data.frame(
      type = type,
      a = a,
      b = b,
      stringsAsFactors = FALSE
    )
  }
  text <- function(...) add("text", paste0(...))
  th <- function(a, b) add("th", a, b)
  tr <- function(a, b) add("tr", a, b)
  gap <- function() add("blank")
  section <- function(sheet, what) {
    gap()
    add("section", paste0(sheet, ": ", what))
  }

  add("title", "Analysis Kit: List of Analysis")
  gap()
  text(
    "This workbook describes one analysis: which variables to analyse, how ",
    "to break them down, and the settings to use. Upload it with the dataset ",
    "in the Analysis Kit app, or pass it to run_analysis_locally(). No R code ",
    "needs editing."
  )
  text(
    "Each sheet has a section below, in the same order as the sheets. Only ",
    "analysis_variables is required."
  )
  text(
    "Write every variable by its raw code in the dataset, such as Q27 or Q78, ",
    "in every sheet. The names given in disaggregation_variables appear in the ",
    "results only."
  )
  if (any(sheets %in% names(loa_column_descriptions()))) {
    text(
      "Row 2 of ",
      paste(
        intersect(sheets, names(loa_column_descriptions())),
        collapse = ", "
      ),
      ", in italics, describes each column. It is skipped when the workbook is ",
      "read: leave it, or delete it. Start your own rows below it."
    )
  }
  text(
    "The rows already filled in are examples. Replace them with your own."
  )
  text(
    "The full specification is loa-schema.md in the analysiskit package ",
    "(system.file(\"extdata\", \"loa-schema.md\", package = \"analysiskit\"))."
  )

  for (sheet in sheets) {
    switch(
      sheet,
      analysis_variables = {
        section(sheet, "the list of variables to analyse")
        text(
          "One row per analysis. The results list them in the same order."
        )
        th("Column", "What to put in it")
        tr(
          "analysis_type",
          "Required. How to analyse the variable: pick one from the drop-down list. The types are explained below."
        )
        tr(
          "analysis_var",
          "Required. The variable's raw code in the dataset, such as Q27. For a multiple-choice question, the question's code (Q78), not one of its choices."
        )
        tr(
          "section",
          "Optional. A heading such as Demographics. Each section gets its own sheet in the results workbook."
        )
        tr(
          "sample_base",
          "Optional, percentages only. TRUE: out of everyone, with those not asked shown as a row of their own, so the question adds up to 100%. Blank or FALSE: out of those who answered. Pick from the drop-down list."
        )
        tr(
          "na_label",
          "Optional. The name of the row for those not asked, when sample_base is TRUE. Blank: Not asked / no response."
        )
        gap()
        th("analysis_type", "What it calculates")
        tr(
          "prop_select_one",
          "The % of respondents giving each answer to a single-choice question."
        )
        tr(
          "prop_select_multiple",
          "The % of respondents selecting each choice of a multiple-choice question."
        )
        tr("mean", "The average of a numeric question.")
        tr("median", "The median of a numeric question.")
        tr(
          "ratio",
          "The sum of one variable divided by the sum of another, per group, such as children per household. Add the columns analysis_var_numerator and analysis_var_denominator, and leave analysis_var empty."
        )
        gap()
        th("Optional column", "Add it when you need it")
        tr(
          "level",
          "A confidence level such as 0.95 adds a confidence interval, reported when settings value_columns includes stat_low,stat_upp. It slows the run down, so leave it blank unless you report the interval."
        )
        tr(
          "group_var",
          "A disaggregation for this row only. Usually not needed: use disaggregation_variables instead."
        )
        tr(
          "description",
          "A note for whoever reads the workbook. Ignored by the analysis."
        )
        tr(
          "any other column",
          "Carried into the results when its name is listed in settings extra_columns, as section is."
        )
      },
      disaggregation_variables = {
        section(sheet, "the variables to break the results down by")
        text(
          "One row per variable, such as gender or region. Every analysis is ",
          "reported overall and for each group of each variable listed here, ",
          "in the order of the rows."
        )
        th("Column", "What to put in it")
        tr(
          "raw_data_name",
          "Required. The variable's raw code in the dataset, such as Q27."
        )
        tr(
          "new_name",
          "Required. The name to show in the results, such as Respondent gender."
        )
        tr(
          "include",
          "TRUE uses the row; FALSE leaves it out without deleting it. Blank: TRUE. Pick from the drop-down list."
        )
        gap()
        text(
          "Do not add an Overall row: the overall figures are always included, ",
          "first. Two new names where one contains the other, such as Region ",
          "and Region_of_origin, are not allowed."
        )
      },
      count_selections = {
        section(sheet, "how many choices each respondent selected")
        text(
          "One row per multiple-choice question (analysis_var) for which to ",
          "report how many choices each respondent selected. include: TRUE or ",
          "FALSE. The labels and order are set in settings."
        )
      },
      count_combinations = {
        section(sheet, "combinations of choices")
        text(
          "For respondents who selected more than one choice: which listed ",
          "choices they selected together. One row per choice: analysis_var ",
          "(the question), choice_label (exactly as in the dataset), ",
          "display_name (optional short label) and include."
        )
      },
      count_exclusive_combinations = {
        section(sheet, "single choices")
        text(
          "For respondents who selected exactly one choice: which one. The ",
          "same columns as count_combinations. Together the two sheets add up ",
          "to 100%."
        )
      },
      exclude_choices = {
        section(sheet, "choices to leave out")
        text(
          "One choice_label per row, such as Don't know or Refused. A ",
          "respondent who selected one leaves the base of that question ",
          "altogether. include: TRUE or FALSE."
        )
      },
      route_analysis = {
        section(sheet, "the route questions")
        text(
          "Analyses the repeated 4Mi route questions, with every slot pooled. ",
          "No rows are needed in analysis_variables: the question codes are ",
          "fixed. One row per setting, as in the settings sheet; the ",
          "description column says what each one does."
        )
        th("Setting", "What it does")
        tr(
          "transit_country, places_stop, dangerous_location",
          "TRUE gives that block its own results sheet: Transit Countries, Places Stop, Dangerous Locations. FALSE by default."
        )
        tr(
          "route_full_sample_base",
          "TRUE (the default): the questions everyone is asked are out of the full sample. FALSE: out of those who answered."
        )
        tr(
          "route_gender_var",
          "The gender variable every route table is broken down by, alongside the disaggregation_variables. Default Q27."
        )
        tr(
          "route_top_countries",
          "How many countries are shown as columns, most named first. Default 10; 0 shows all of them."
        )
        tr(
          "route_top_locations",
          "How many places are shown per country. Default 4."
        )
      },
      settings = {
        section(sheet, "everything else")
        text(
          "One row per setting: its name in the setting column and your value ",
          "in the value column. The description column says what each one ",
          "does."
        )
        text(
          "Leave a value blank to use the default. Do not change the names in ",
          "the setting column: a name that is not recognised stops the run. ",
          "More settings exist than are listed; add a row for any of them ",
          "(see loa-schema.md)."
        )
        text(
          "To keep a space at the start or end of a value, wrap the value in ",
          "double quotes, as in \" only\" or \" + \". Excel drops the space ",
          "otherwise, and a label would read Economiconly instead of Economic only."
        )
      }
    )
  }

  do.call(rbind, out)
}
