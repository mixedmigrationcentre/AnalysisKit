# The `level` cell decides which estimation engine a row uses, and that is the
# largest performance decision in the application. loa_engine_split() reports
# it before the run; these tests pin it to the routing the pipeline actually
# performs.

# value_columns defaults to one that shows the interval, because a level only
# reaches the survey engine when the interval it asks for will be reported.
spec_with <- function(level,
                      engine = NULL,
                      groups = c("Overall", "G1", "G2"),
                      value_columns = c("stat", "stat_low", "stat_upp", "n", "n_total"),
                      type = "prop_select_one") {
  settings <- list()
  if (!is.null(engine)) settings$engine <- engine
  if (!is.null(value_columns)) settings$value_columns <- value_columns

  structure(
    list(
      loa = data.frame(
        analysis_type = rep(type, length.out = length(level)),
        analysis_var = paste0("Q", seq_along(level)),
        level = level,
        stringsAsFactors = FALSE
      ),
      group_variables = groups,
      settings = settings
    ),
    class = c("analysis_spec", "list")
  )
}


test_that("an empty level column keeps every analysis on the fast engine", {
  split <- loa_engine_split(spec_with(c(NA, NA, NA)))

  expect_equal(split$engine, "auto")
  expect_equal(split$analyses, 3L)
  expect_equal(split$survey, 0L)
  expect_equal(split$fast, 3L)
  expect_equal(split$survey_estimations, 0L)
})


test_that("a filled level sends that row to the survey engine, once per group", {
  split <- loa_engine_split(spec_with(c(0.95, NA, 0.9)))

  expect_equal(split$survey, 2L)
  expect_equal(split$fast, 1L)
  expect_equal(split$group_variables, 3L)
  # Two analyses across three grouping variables, Overall included.
  expect_equal(split$survey_estimations, 6L)
})


test_that("blank and 'NA' text are treated as no level", {
  split <- loa_engine_split(spec_with(c("", "NA", "  ", "0.95")))
  expect_equal(split$survey, 1L)
})


test_that("the engine setting overrides the level column in both directions", {
  expect_equal(loa_engine_split(spec_with(c(0.95, 0.95), "fast"))$survey, 0L)
  expect_equal(loa_engine_split(spec_with(c(NA, NA), "survey"))$survey, 2L)
})


test_that("a List of Analysis with no level column at all is entirely fast", {
  spec <- spec_with(c(NA, NA))
  spec$loa$level <- NULL

  split <- loa_engine_split(spec)
  expect_equal(split$survey, 0L)
  expect_equal(split$fast, 2L)
})


test_that("a level whose interval is not reported does not reach survey", {
  shown <- c("stat", "n", "n_total")

  # The settings sheet's default value_columns, and the same thing left unset.
  expect_equal(loa_engine_split(spec_with(c(0.95, 0.95), value_columns = shown))$survey, 0L)
  expect_equal(loa_engine_split(spec_with(c(0.95, 0.95), value_columns = NULL))$survey, 0L)

  # Medians and ratios keep the survey engine: moving them could change a value.
  split <- loa_engine_split(spec_with(
    rep(0.95, 5),
    value_columns = shown,
    type = c("prop_select_one", "prop_select_multiple", "mean", "median", "ratio")
  ))
  expect_equal(split$survey, 2L)
  expect_equal(split$fast, 3L)

  # engine = "survey" is still honoured to the letter.
  expect_equal(
    loa_engine_split(spec_with(c(0.95, NA), "survey", value_columns = shown))$survey,
    2L
  )
})


# The app turns this split into a note on its List of Analysis tab. In the
# package the same note is printed by check_analysis_inputs(); that is tested
# in test-run-locally.R.
