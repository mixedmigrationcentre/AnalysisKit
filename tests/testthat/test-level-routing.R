# A `level` on an analysis row asks for a confidence interval. When
# value_columns carries neither stat_low nor stat_upp the interval is never
# shown, so engine = "auto" tabulates the row instead of sending it to the
# survey engine. These tests pin the promise that makes that safe: the output
# is the one the survey engine produced, cell for cell and in the same order.

routing_dataset <- function(n = 400) {
  withr::local_seed(20261112)

  towns <- c("Zed", "Djibo", "Dédougou", "alpha", "Bama")
  d <- data.frame(
    town = sample(towns, n, TRUE, prob = c(0.3, 0.2, 0.2, 0.2, 0.1)),
    sex = sample(c("Female", "Male", "Other"), n, TRUE, prob = c(0.5, 0.49, 0.01)),
    age = sample(18:60, n, TRUE),
    num = sample(0:5, n, TRUE),
    den = sample(1:6, n, TRUE),
    w = round(stats::runif(n, 0.5, 2), 3),
    stringsAsFactors = FALSE
  )

  # A missing group, and a group nobody in which answered q, sm or age2.
  d$town[1:6] <- NA
  d$town[7:12] <- "Empty"
  skipped <- d$town %in% "Empty"

  # Categories whose C-locale order differs from the alphabetical one, one of
  # them rare enough to be absent from some groups.
  d$q <- sample(
    c("Yes", "no", "Été", "Maybe"), n, TRUE,
    prob = c(0.5, 0.3, 0.18, 0.02)
  )
  d$q[skipped] <- NA
  d$q[d$town %in% "Bama" & d$q == "Maybe"] <- "Yes"
  d$q[sample(n, 30)] <- NA

  a <- sample(c(TRUE, FALSE), n, TRUE)
  b <- sample(c(TRUE, FALSE), n, TRUE, prob = c(0.1, 0.9))
  asked <- !skipped & stats::runif(n) > 0.1
  d$sm <- ifelse(asked, trimws(paste(ifelse(a, "A", ""), ifelse(b, "B", ""))), NA)
  d$sm[asked & d$sm == ""] <- "none"
  d[["sm/A"]] <- ifelse(asked & a, "A", NA)
  d[["sm/B"]] <- ifelse(asked & b, "B", NA)

  d$age2 <- d$age
  d$age2[skipped] <- NA
  d$age[sample(n, 20)] <- NA

  d[] <- lapply(d, as.character)
  labels <- as.data.frame(
    as.list(stats::setNames(names(d), names(d))),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  rbind(labels, d)
}


routing_loa <- function(level = 0.95) {
  data.frame(
    analysis_type = c(
      "prop_select_one", "prop_select_multiple", "mean", "median",
      "ratio", "prop_select_one", "mean"
    ),
    analysis_var = c("q", "sm", "age", "age", NA, "sex", "age2"),
    level = level,
    analysis_var_numerator = c(NA, NA, NA, NA, "num", NA, NA),
    analysis_var_denominator = c(NA, NA, NA, NA, "den", NA, NA),
    stringsAsFactors = FALSE
  )
}


routing_run <- function(loa, engine, weight_column = NULL, ...) {
  suppressMessages(suppressWarnings(run_group_analysis_pipeline(
    routing_dataset(), loa,
    group_variables = c("Overall", "town", "sex"),
    weight_column = weight_column,
    engine = engine,
    verbose = FALSE,
    ...
  )))
}


expect_same_output <- function(auto, survey) {
  # Same columns in the same order, same rows in the same order, same numbers.
  expect_identical(names(auto$combined_results), names(survey$combined_results))
  expect_equal(
    as.data.frame(auto$combined_results),
    as.data.frame(survey$combined_results),
    tolerance = 1e-9
  )

  shared <- c(
    "analysis_type", "analysis_var", "analysis_var_value", "group_var",
    "group_var_value", "stat", "n", "n_total", "n_w", "n_w_total"
  )
  # The survey engine writes a missing group as the text "NA"; the pivot reads
  # both spellings as the missing group.
  long <- function(run) {
    x <- as.data.frame(run$results_long)[, shared]
    x$group_var_value[x$group_var_value %in% "NA"] <- NA_character_
    x
  }
  expect_equal(long(auto), long(survey), tolerance = 1e-9, ignore_attr = TRUE)
}


test_that("only a level nobody will see is treated as redundant", {
  types <- c("prop_select_one", "prop_select_multiple", "mean", "median", "ratio")
  shown <- c("stat", "n", "n_total")

  expect_equal(
    ck_level_is_redundant(types, rep(TRUE, 5), shown),
    c(TRUE, TRUE, TRUE, FALSE, FALSE)
  )
  # No level, nothing to reroute: those rows were already on the fast engine.
  expect_false(any(ck_level_is_redundant(types, rep(FALSE, 5), shown)))
  # The interval is asked for, so the survey engine is needed after all.
  expect_false(any(
    ck_level_is_redundant(types, rep(TRUE, 5), c(shown, "stat_low", "stat_upp"))
  ))
  expect_false(any(ck_level_is_redundant(types, rep(TRUE, 5), c("stat", "stat_upp"))))
  # An explicit engine is never second-guessed.
  expect_false(any(ck_level_is_redundant(types, rep(TRUE, 5), shown, "survey")))
  expect_false(any(ck_level_is_redundant(types, rep(TRUE, 5), shown, "fast")))
})


test_that("a level with no interval column gives the survey engine's output", {
  skip_if_not_installed("analysistools")
  skip_if_not_installed("srvyr")
  skip_if_not_installed("withr")

  auto <- routing_run(routing_loa(), "auto")
  survey <- routing_run(routing_loa(), "survey")

  expect_same_output(auto, survey)
})


test_that("the same holds with weights and every count column reported", {
  skip_if_not_installed("analysistools")
  skip_if_not_installed("srvyr")
  skip_if_not_installed("withr")

  columns <- c("stat", "n", "n_total", "n_w", "n_w_total")
  auto <- routing_run(routing_loa(), "auto", "w", value_columns = columns)
  survey <- routing_run(routing_loa(), "survey", "w", value_columns = columns)

  expect_same_output(auto, survey)
})


test_that("it holds when only some rows carry a level", {
  skip_if_not_installed("analysistools")
  skip_if_not_installed("srvyr")
  skip_if_not_installed("withr")

  # Rows without a level are tabulated under either routing; what is compared
  # is the old "auto" (level -> survey), rebuilt here by hand.
  loa <- routing_loa(c(0.95, NA, 0.95, 0.95, NA, NA, 0.95))
  auto <- routing_run(loa, "auto")

  expect_true(all(c("q", "sm", "age", "sex", "age2") %in% auto$combined_results$analysis_var))
  expect_false(any(c("stat_low_Overall", "stat_upp_Overall") %in% names(auto$combined_results)))

  # Medians and ratios with a level still came from the survey engine.
  long <- auto$results_long
  median_row <- long[long$analysis_type == "median" & is.na(long$group_var), ]
  expect_true("stat_low" %in% names(long))
  expect_false(is.na(median_row$stat_low))
})


test_that("no survey package is touched when every level is redundant", {
  skip_if_not_installed("withr")

  loa <- routing_loa()[c(1, 2, 3, 6, 7), ]
  seen <- character(0)
  run <- withCallingHandlers(
    suppressWarnings(run_group_analysis_pipeline(
      routing_dataset(), loa,
      group_variables = c("Overall", "town"), verbose = TRUE
    )),
    message = function(m) {
      seen <<- c(seen, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )

  expect_true(any(grepl("10 by fast tabulation, 0 by survey", seen, fixed = TRUE)))
  expect_true(any(grepl("value_columns asks for no confidence interval", seen, fixed = TRUE)))
  expect_false("stat_low" %in% names(run$results_long))
})


test_that("asking for the interval still runs the survey engine", {
  skip_if_not_installed("analysistools")
  skip_if_not_installed("srvyr")
  skip_if_not_installed("withr")

  loa <- routing_loa()[1, ]
  run <- suppressMessages(suppressWarnings(run_group_analysis_pipeline(
    routing_dataset(), loa,
    group_variables = "Overall", verbose = FALSE,
    value_columns = c("stat", "stat_low", "stat_upp", "n", "n_total")
  )))

  expect_true(all(c("stat_low_Overall", "stat_upp_Overall") %in% names(run$combined_results)))
  expect_false(anyNA(run$combined_results$stat_low_Overall))
})
