# full_sample_base: respondents skipped by skip logic stay in the denominator.

# Ten respondents. Q1 is asked of everyone; Q2 (select_one) and Q3
# (select_multiple) only of the six who answered "Yes" to Q1. Q4 is a number
# asked of the same six.
skip_dataset <- function() {
  yes <- c(rep(TRUE, 6), rep(FALSE, 4))
  data.frame(
    gender = rep(c("Female", "Male"), 5),
    Q1 = ifelse(yes, "Yes", "No"),
    Q2 = c("Bus", "Bus", "Car", "Car", "Car", "Don't know", rep(NA, 4)),
    Q3 = c("a", "a b", "b", "a", "b", "a", rep(NA, 4)),
    `Q3/a` = c(1, 1, 0, 1, 0, 1, rep(NA, 4)),
    `Q3/b` = c(0, 1, 1, 0, 1, 0, rep(NA, 4)),
    Q4 = c(10, 20, 30, 40, 50, 60, rep(NA, 4)),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

skip_loa <- function(level = NA_real_) {
  data.frame(
    analysis_type = c(
      "prop_select_one",
      "prop_select_one",
      "prop_select_multiple",
      "mean"
    ),
    analysis_var = c("Q1", "Q2", "Q3", "Q4"),
    level = level,
    stringsAsFactors = FALSE
  )
}

skip_labels <- function(dataset) {
  as.data.frame(
    stats::setNames(as.list(paste("Label of", names(dataset))), names(dataset)),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

run_skip <- function(
  ...,
  groups = "Overall",
  loa = skip_loa(),
  dataset = skip_dataset()
) {
  run_group_analysis_pipeline(
    dataset = dataset,
    loa = loa,
    group_variables = groups,
    skip_label_row = FALSE,
    label_row = skip_labels(dataset),
    verbose = FALSE,
    ...
  )
}

rows_for <- function(res, var, group = NA) {
  long <- res$results_long
  keep <- long$analysis_var == var &
    if (is.na(group)) {
      is.na(long$group_var)
    } else {
      (!is.na(long$group_var) & long$group_var == group)
    }
  long[keep, , drop = FALSE]
}


test_that("by default a skipped question is out of those who answered", {
  res <- run_skip()
  q2 <- rows_for(res, "Q2")

  expect_true(all(q2$n_total == 6))
  expect_false("Not asked / no response" %in% q2$analysis_var_value)
  expect_null(res$full_sample_filled)
})


test_that("full_sample_base counts a select_one out of the full sample", {
  res <- run_skip(full_sample_base = TRUE)
  q2 <- rows_for(res, "Q2")

  expect_true(all(q2$n_total == 10))
  expect_equal(sum(q2$stat), 1)

  nr <- q2[q2$analysis_var_value == "Not asked / no response", ]
  expect_equal(nr$n, 4)
  expect_equal(nr$stat, 0.4)
  expect_equal(q2$analysis_var_value[nrow(q2)], "Not asked / no response")

  # The row reaches the wide table too, last in its question.
  wide <- res$combined_results
  q2_wide <- wide$analysis_var_value[wide$analysis_var == "Q2"]
  expect_equal(q2_wide[length(q2_wide)], "Not asked / no response")
})


test_that("a question everyone answered gets no extra row", {
  res <- run_skip(full_sample_base = TRUE)
  q1 <- rows_for(res, "Q1")

  expect_true(all(q1$n_total == 10))
  expect_false("Not asked / no response" %in% q1$analysis_var_value)
})


test_that("full_sample_base counts a select_multiple blank as not selected", {
  res <- run_skip(full_sample_base = TRUE)
  q3 <- rows_for(res, "Q3")

  expect_true(all(q3$n_total == 10))
  expect_equal(q3$n[q3$analysis_var_value == "a"], 4)
  expect_equal(q3$stat[q3$analysis_var_value == "a"], 0.4)
})


test_that("means are left out of the full sample", {
  off <- rows_for(run_skip(), "Q4")
  on <- rows_for(run_skip(full_sample_base = TRUE), "Q4")

  expect_equal(on$stat, off$stat)
  expect_equal(on$n_total, 6)
})


test_that("the no-response label can be changed", {
  res <- run_skip(full_sample_base = TRUE, full_sample_label = "Skipped")
  q2 <- rows_for(res, "Q2")

  expect_true("Skipped" %in% q2$analysis_var_value)
  expect_false("Not asked / no response" %in% q2$analysis_var_value)
  expect_error(
    run_skip(full_sample_base = TRUE, full_sample_label = ""),
    "full_sample_label"
  )
})


test_that("exclude_choices still removes respondents from the full base", {
  res <- run_skip(full_sample_base = TRUE, exclude_choices = "Don't know")
  q2 <- rows_for(res, "Q2")

  expect_true(all(q2$n_total == 9))
  expect_equal(q2$n[q2$analysis_var_value == "Not asked / no response"], 4)
})


test_that("grouped results use the full group as the base", {
  res <- run_skip(full_sample_base = TRUE, groups = c("Overall", "gender"))
  q2 <- rows_for(res, "Q2", group = "gender")

  expect_true(all(q2$n_total == 5))
  sums <- tapply(q2$stat, q2$group_var_value, sum)
  expect_equal(as.vector(sums), c(1, 1))
})


test_that("a variable that is also a grouping variable is left alone", {
  ds <- skip_dataset()
  ds$gender[1] <- NA

  expect_warning(
    res <- run_skip(
      full_sample_base = TRUE,
      dataset = ds,
      groups = c("Overall", "gender"),
      loa = data.frame(
        analysis_type = c("prop_select_one", "prop_select_one"),
        analysis_var = c("gender", "Q2"),
        stringsAsFactors = FALSE
      )
    ),
    "also a grouping variable"
  )

  # gender is still out of those who answered it...
  expect_true(all(rows_for(res, "gender")$n_total == 9))
  # ...and its blank respondent is still the missing group, not a new one.
  q2_by_gender <- rows_for(res, "Q2", group = "gender")
  expect_true(any(is.na(q2_by_gender$group_var_value)))
  expect_false("Not asked / no response" %in% q2_by_gender$group_var_value)
})


test_that("the survey engine gets the same full base", {
  skip_if_not_installed("analysistools")
  skip_if_not_installed("srvyr")

  res <- run_skip(
    full_sample_base = TRUE,
    loa = skip_loa(level = 0.95),
    value_columns = c("stat", "stat_low", "stat_upp", "n", "n_total"),
    engine = "survey"
  )
  q2 <- rows_for(res, "Q2")

  expect_true(all(q2$n_total == 10))
  expect_equal(q2$stat[q2$analysis_var_value == "Not asked / no response"], 0.4)
  expect_equal(q2$analysis_var_value[nrow(q2)], "Not asked / no response")

  q3 <- rows_for(res, "Q3")
  expect_true(all(q3$n_total == 10))
  expect_equal(q3$stat[q3$analysis_var_value == "a"], 0.4)
})


test_that("the settings sheet accepts both keys", {
  parsed <- loa_parse_settings(data.frame(
    setting = c("full_sample_base", "full_sample_label"),
    value = c("TRUE", "Skipped"),
    stringsAsFactors = FALSE
  ))

  expect_false(loa_has_errors(parsed$problems))
  expect_identical(parsed$settings$full_sample_base, TRUE)
  expect_identical(parsed$settings$full_sample_label, "Skipped")
})
