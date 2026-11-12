# read_analysis_dataset(path, loa = ) reads only the columns the List of
# Analysis refers to. The promise is that an analysis cannot tell the
# difference: same names, same values, same results - just less read.

columns_dataset <- function() {
  data.frame(
    uuid = c("uuid", "a", "b", "c", "d"),
    Q13 = c("Country of interview", "Mali", "Niger", "Mali", "Niger"),
    Q27 = c("What is your gender?", "Female", "Male", "Female", "Male"),
    Q78 = c("Drivers", "Economic", "Economic Conflict", "Conflict", "Economic"),
    `Q78/Economic` = c("Economic", "Economic", "Economic", NA, "Economic"),
    `Q78/Conflict` = c("Conflict", NA, "Conflict", "Conflict", NA),
    Q78_other = c("Other, specify", NA, NA, "x", NA),
    Q29 = c("Age", "20", "31", "44", "27"),
    Q99 = c("Not analysed", "p", "q", "r", "s"),
    `Q99/p` = c("p", "p", NA, NA, NA),
    wgt = c("Weight", "1", "2", "1", "2"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}


columns_loa <- function() {
  list(
    analysis = data.frame(
      analysis_type = c("prop_select_one", "prop_select_multiple", "ratio"),
      analysis_var = c("Q27", "Q78", NA),
      analysis_var_numerator = c(NA, NA, "Q29"),
      analysis_var_denominator = c(NA, NA, "wgt"),
      stringsAsFactors = FALSE
    ),
    group_analysis = data.frame(
      raw_data_name = "Q13", new_name = "Country", include = TRUE,
      stringsAsFactors = FALSE
    )
  )
}


test_that("the columns a List of Analysis refers to are found, children included", {
  header <- names(columns_dataset())
  keep <- loa_dataset_columns(columns_loa(), header)

  expect_setequal(
    header[keep],
    c("Q13", "Q27", "Q78", "Q78/Economic", "Q78/Conflict", "Q29", "wgt")
  )
  # Q78_other is a different question that happens to share a prefix, and Q99
  # is not in the List of Analysis at all.
  expect_false(any(c("Q78_other", "Q99", "Q99/p", "uuid") %in% header[keep]))
})


test_that("weight, strata and uuid are kept when the settings ask for them", {
  loa <- columns_loa()
  loa$settings <- data.frame(
    setting = c("weight_column", "recreate_sm_parents"),
    value = c("wgt", "TRUE"),
    stringsAsFactors = FALSE
  )
  loa$analysis <- loa$analysis[1, ]

  header <- names(columns_dataset())
  expect_setequal(
    header[loa_dataset_columns(loa, header)],
    c("Q13", "Q27", "wgt", "uuid")
  )
})


test_that("a filtered read gives the same columns a full read would", {
  skip_if_not_installed("writexl")
  skip_if_not_installed("readxl")

  for (extension in c("xlsx", "csv")) {
    path <- tempfile(fileext = paste0(".", extension))
    if (extension == "xlsx") {
      writexl::write_xlsx(columns_dataset(), path)
    } else {
      utils::write.csv(columns_dataset(), path, row.names = FALSE, na = "")
    }

    full <- read_analysis_dataset(path)
    some <- read_analysis_dataset(path, loa = columns_loa())

    expect_equal(some$columns_in_file, ncol(full$data))
    expect_equal(full$columns_in_file, ncol(full$data))
    expect_identical(some$data, full$data[, names(some$data), drop = FALSE])
    expect_lt(ncol(some$data), ncol(full$data))
    expect_true(is.na(some$duplicate_rows))
    expect_false(is.na(full$duplicate_rows))

    overview <- dataset_overview(some)
    expect_match(overview$Value[overview$Measure == "Columns"], "^11 \\(7 read")
    expect_match(overview$Value[overview$Measure == "Duplicate rows"], "not counted")
    unlink(path)
  }
})


test_that("a filter that selects nothing reads the whole file", {
  path <- tempfile(fileext = ".csv")
  utils::write.csv(columns_dataset(), path, row.names = FALSE, na = "")

  loa <- columns_loa()
  loa$analysis$analysis_var <- c("NOPE", "NADA", NA)
  loa$analysis$analysis_var_numerator <- NA
  loa$analysis$analysis_var_denominator <- NA
  loa$group_analysis$raw_data_name <- "NEITHER"

  dataset <- read_analysis_dataset(path, loa = loa)
  expect_equal(ncol(dataset$data), ncol(columns_dataset()))
  expect_false(is.na(dataset$duplicate_rows))
  unlink(path)
})


test_that("a run from a path gives the results a run from the full data gives", {
  skip_if_not_installed("writexl")
  skip_if_not_installed("readxl")

  path <- tempfile(fileext = ".xlsx")
  writexl::write_xlsx(columns_dataset(), path)

  loa <- columns_loa()
  loa$analysis <- loa$analysis[1:2, 1:2]

  from_path <- suppressWarnings(run_analysis_locally(path, loa, verbose = FALSE))
  from_full <- suppressWarnings(
    run_analysis_locally(read_analysis_dataset(path), loa, verbose = FALSE)
  )

  expect_lt(from_path$dataset$columns_in_file, Inf)
  expect_equal(from_path$dataset$columns_in_file, ncol(columns_dataset()))
  expect_identical(
    from_path$results$combined_results,
    from_full$results$combined_results
  )
  expect_identical(from_path$results$results_long, from_full$results$results_long)
  unlink(path)
})
