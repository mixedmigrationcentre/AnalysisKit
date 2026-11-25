# ak_write_loa(), the description row, and the shipped template.

written_loa <- function(sheets = fixture_sheets(), ...) {
  path <- tempfile(fileext = ".xlsx")
  ak_write_loa(sheets, path, ...)
  path
}

# Every data validation of one sheet, as list("A3:A1002" = "\"a,b\"").
#
# Two XML forms are read: the extension form openxlsx writes
# (<x14:dataValidation> with <xm:f> and <xm:sqref>), and the standard form
# Excel writes when the workbook is saved there (<dataValidation sqref="...">
# with <formula1>). Both are the same drop-down to the person using it.
sheet_dropdowns <- function(path, sheet) {
  dir <- tempfile()
  utils::unzip(path, exdir = dir)
  i <- match(sheet, readxl::excel_sheets(path))
  xml <- paste(
    readLines(
      file.path(dir, "xl", "worksheets", paste0("sheet", i, ".xml")),
      warn = FALSE,
      encoding = "UTF-8"
    ),
    collapse = ""
  )
  blocks <- regmatches(
    xml,
    gregexpr(
      "<(x14:)?dataValidation [^>]*>.*?</(x14:)?dataValidation>",
      xml,
      perl = TRUE
    )
  )[[1]]
  first <- function(x, pattern) {
    hit <- regmatches(x, regexpr(pattern, x, perl = TRUE))
    if (length(hit) == 0L) NA_character_ else hit
  }
  ranges <- vapply(
    blocks,
    function(b) {
      r <- first(b, "(?<=<xm:sqref>)[^<]+")
      if (is.na(r)) first(b, "(?<=sqref=\")[^\"]+") else r
    },
    ""
  )
  values <- vapply(
    blocks,
    function(b) first(b, "(?<=<xm:f>|<formula1>)[^<]+"),
    ""
  )
  values <- gsub("&quot;", "\"", values, fixed = TRUE)
  stats::setNames(as.list(unname(values)), unname(ranges))
}

test_that("a written workbook reads back into the same specification", {
  sheets <- fixture_sheets()
  sheets$analysis_variables$level <- c(0.95, NA, NA)
  path <- written_loa(sheets)

  back <- read_loa_workbook(path)
  expect_equal(
    readxl::excel_sheets(path)[1:3],
    c("readme", "analysis_variables", "disaggregation_variables")
  )
  expect_equal(back$header_rows[["analysis_variables"]], 2L)
  expect_equal(back$header_rows[["disaggregation_variables"]], 2L)
  expect_equal(back$header_rows[["count_selections"]], 1L)

  a <- build_analysis_spec(fixture_workbook(sheets), fixture_dataset())
  b <- build_analysis_spec(back, fixture_dataset())
  expect_false(loa_has_errors(b$problems))
  expect_equal(b$loa$analysis_var, a$loa$analysis_var)
  expect_equal(b$group_variables, a$group_variables)
  expect_equal(b$settings, a$settings)
  expect_equal(b$count_combinations, a$count_combinations)
  # level stays numeric: the description row is skipped before types are
  # guessed, not dropped after.
  expect_type(b$loa$level, "double")
})

test_that("the description row is skipped, and problems name the Excel row", {
  sheets <- fixture_sheets()
  sheets$analysis_variables$analysis_type[2] <- "percentage"
  sheets$disaggregation_variables$new_name[2] <- NA
  sheets$settings <- rbind(
    sheets$settings,
    data.frame(setting = "not_a_setting", value = "1")
  )
  path <- written_loa(sheets)

  problems <- validate_loa(read_loa_workbook(path))
  row_of <- function(sheet, pattern) {
    problems$row[problems$sheet == sheet & grepl(pattern, problems$message)]
  }
  # Header on row 1, descriptions on row 2: the second analysis is on row 4.
  expect_equal(row_of("analysis_variables", "percentage"), 4L)
  expect_equal(row_of("disaggregation_variables", "required"), 4L)
  expect_equal(
    row_of("settings", "not_a_setting"),
    nrow(fixture_sheets()$settings) + 3L
  )
})

test_that("a description row that has been typed over is read as data", {
  row <- as.data.frame(
    as.list(loa_column_descriptions()$analysis_variables[c(
      "analysis_type",
      "analysis_var"
    )]),
    stringsAsFactors = FALSE
  )
  expect_true(loa_is_description_row("analysis_variables", row))

  row$analysis_var <- "Q27"
  expect_false(loa_is_description_row("analysis_variables", row))

  # Blank cells are allowed; a row of nothing but blanks is not a description.
  row$analysis_var <- NA
  expect_true(loa_is_description_row("analysis_variables", row))
  row$analysis_type <- NA
  expect_false(loa_is_description_row("analysis_variables", row))

  # Whitespace and case do not matter; the former column names still match.
  row <- data.frame(
    full_sample_base = toupper(
      paste0(" ", loa_column_descriptions()$analysis_variables[["sample_base"]])
    ),
    stringsAsFactors = FALSE
  )
  expect_true(loa_is_description_row("analysis_variables", row))
})

test_that("a sheet with nothing under the description row reads as empty", {
  sheets <- fixture_sheets()
  sheets$disaggregation_variables <- sheets$disaggregation_variables[0, ]
  sheets$disaggregation_variables[1, ] <- NA
  path <- tempfile(fileext = ".xlsx")
  ak_write_loa(
    list(analysis_variables = sheets$analysis_variables[0, ]),
    path
  )
  back <- read_loa_workbook(path)
  expect_equal(nrow(back$sheets$analysis_variables), 0L)
  expect_true(all(
    c("analysis_type", "analysis_var") %in%
      names(back$sheets$analysis_variables)
  ))
})

test_that("former column names are written under their current names", {
  sheets <- fixture_sheets()
  sheets$analysis_variables$full_sample_base <- c("TRUE", NA, NA)
  sheets$analysis_variables$full_sample_label <- c("Skipped", NA, NA)
  path <- written_loa(sheets)
  an <- read_loa_workbook(path)$sheets$analysis_variables
  expect_true(all(c("sample_base", "na_label") %in% names(an)))
  expect_false(any(c("full_sample_base", "full_sample_label") %in% names(an)))
  expect_equal(an$sample_base[1], TRUE)
  expect_equal(an$na_label[1], "Skipped")
})

test_that("settings get a description column; a written one is kept", {
  sheets <- fixture_sheets()
  sheets$settings$description <- c("My own note", NA, NA)
  path <- written_loa(sheets)
  s <- read_loa_workbook(path)$sheets$settings
  expect_equal(names(s), c("setting", "value", "description"))
  expect_equal(s$description[1], "My own note")
  expect_equal(
    s$description[2],
    unname(loa_setting_descriptions()[s$setting[2]])
  )
})

test_that("every setting has a description", {
  expect_setequal(
    names(loa_setting_descriptions()),
    loa_settings_schema()$setting
  )
})

test_that("drop-down lists cover analysis_type, sample_base and include", {
  sheets <- fixture_sheets()
  sheets$analysis_variables <- sheets$analysis_variables[c(
    "analysis_type",
    "analysis_var",
    "section"
  )]
  sheets$analysis_variables$sample_base <- NA
  sheets$disaggregation_variables$include <- TRUE
  path <- written_loa(sheets, dropdown_rows = 500)

  an <- sheet_dropdowns(path, "analysis_variables")
  expect_equal(
    an[["A3:A502"]],
    "\"prop_select_one,prop_select_multiple,mean,median,ratio\""
  )
  expect_equal(an[["D3:D502"]], "\"TRUE,FALSE\"")
  expect_equal(
    sheet_dropdowns(path, "disaggregation_variables")[["C3:C502"]],
    "\"TRUE,FALSE\""
  )

  # One rule per column whatever the range, so covering more rows costs
  # nothing in file size.
  small <- file.size(written_loa(sheets, dropdown_rows = 30))
  large <- file.size(written_loa(sheets, dropdown_rows = 5000))
  expect_lt(abs(large - small), 50)
})

test_that("the readme has one section per sheet, in sheet order", {
  rows <- loa_readme_rows(c(
    "analysis_variables",
    "disaggregation_variables",
    "route_analysis",
    "settings"
  ))
  sections <- rows$a[rows$type == "section"]
  expect_equal(
    sub(":.*", "", sections),
    c(
      "analysis_variables",
      "disaggregation_variables",
      "route_analysis",
      "settings"
    )
  )
  expect_match(sections[1], "list of variables to analyse")
  text <- paste(c(rows$a, rows$b), collapse = " ")
  expect_false(grepl("exclude_choices", text))
  expect_false(grepl("yellow", text, ignore.case = TRUE))
  # The analysis types are explained under analysis_variables, before the
  # next section starts.
  types_at <- which(rows$a == "prop_select_one")
  expect_true(types_at > which(rows$type == "section")[1])
  expect_true(types_at < which(rows$type == "section")[2])

  # No padding with runs of spaces.
  expect_false(any(grepl("  ", c(rows$a, rows$b))))
})

test_that("an unknown sheet is not written", {
  expect_error(
    ak_write_loa(
      list(
        analysis = fixture_sheets()$analysis_variables,
        foo = data.frame(x = 1)
      ),
      tempfile()
    ),
    "foo"
  )
})

test_that("the shipped template is the layout ak_write_loa() writes", {
  template <- system.file(
    "extdata",
    "loa_template.xlsx",
    package = "analysiskit"
  )
  skip_if(!nzchar(template), "not testing an installed package")

  expect_equal(
    readxl::excel_sheets(template),
    c(
      "readme",
      "analysis_variables",
      "disaggregation_variables",
      "route_analysis",
      "settings"
    )
  )
  wb <- read_loa_workbook(template)
  expect_equal(nrow(validate_loa(wb)), 0L)
  expect_equal(
    wb$header_rows,
    c(
      analysis_variables = 2L,
      disaggregation_variables = 2L,
      route_analysis = 1L,
      settings = 2L
    )
  )
  expect_equal(
    names(wb$sheets$analysis_variables),
    c("analysis_type", "analysis_var", "section", "sample_base", "na_label")
  )
  expect_equal(names(wb$sheets$settings), c("setting", "value", "description"))
  expect_false(anyNA(wb$sheets$settings$description))
  expect_equal(
    wb$sheets$settings$value[wb$sheets$settings$setting == "extra_columns"],
    "section"
  )

  # No yellow fill left anywhere.
  styles <- openxlsx::loadWorkbook(template)$styleObjects
  fills <- unlist(lapply(styles, function(s) s$style$fill))
  expect_false(any(grepl("FFFF00", fills, ignore.case = TRUE)))

  expect_true(length(sheet_dropdowns(template, "analysis_variables")) >= 2L)
  expect_true(
    length(sheet_dropdowns(template, "disaggregation_variables")) >= 1L
  )
})
