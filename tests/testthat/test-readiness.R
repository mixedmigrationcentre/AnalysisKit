# The readiness rules: what state each step of a run is in, and whether a run
# should go ahead. Pure functions, so no analysis and no files are involved.

problems_with <- function(...) {
  severities <- c(...)
  data.frame(
    sheet = rep("analysis_variables", length(severities)),
    row = seq_along(severities) + 1L,
    severity = severities,
    message = paste("problem", seq_along(severities)),
    stringsAsFactors = FALSE
  )
}


# A run is only offered once there is somewhere to put the result, so every
# "this should be runnable" case has to say where.
ready_states <- function(...) {
  ak_step_states(
    dataset_loaded = TRUE, loa_loaded = TRUE,
    problems = loa_no_problems(), destination_chosen = TRUE, ...
  )
}


test_that("the tracker starts on the dataset step", {
  states <- ak_step_states()

  expect_equal(states[["dataset"]], "active")
  expect_equal(states[["loa"]], "todo")
  expect_equal(states[["checks"]], "todo")
  expect_equal(states[["destination"]], "todo")
  expect_equal(states[["results"]], "todo")
  expect_false(ak_can_run(states))
})

test_that("a failed dataset upload marks the step and holds the rest back", {
  states <- ak_step_states(dataset_loaded = FALSE, dataset_failed = TRUE)

  expect_equal(states[["dataset"]], "error")
  expect_equal(states[["loa"]], "todo")
  expect_false(ak_can_run(states))
})

test_that("a loaded dataset moves the tracker on to the List of Analysis", {
  states <- ak_step_states(dataset_loaded = TRUE)

  expect_equal(states[["dataset"]], "done")
  expect_equal(states[["loa"]], "active")
  expect_equal(states[["checks"]], "todo")
  expect_false(ak_can_run(states))
})

test_that("checks stay pending until both files are in", {
  states <- ak_step_states(dataset_loaded = TRUE, loa_loaded = TRUE, problems = NULL)
  expect_equal(states[["checks"]], "todo")
  expect_false(ak_can_run(states))
})

test_that("a clean check asks for a destination, and nothing more until it has one", {
  states <- ak_step_states(
    dataset_loaded = TRUE, loa_loaded = TRUE, problems = loa_no_problems()
  )

  expect_equal(states[["checks"]], "done")
  expect_equal(states[["destination"]], "active")
  expect_equal(states[["results"]], "todo")
  expect_false(ak_can_run(states))
})

test_that("a chosen destination opens the run step", {
  states <- ready_states()

  expect_equal(states[["destination"]], "done")
  expect_equal(states[["results"]], "active")
  expect_true(ak_can_run(states))
})

test_that("an unusable destination blocks the run and marks the step", {
  states <- ak_step_states(
    dataset_loaded = TRUE, loa_loaded = TRUE, problems = loa_no_problems(),
    destination_failed = TRUE
  )

  expect_equal(states[["destination"]], "error")
  expect_equal(states[["results"]], "todo")
  expect_false(ak_can_run(states))
})

test_that("the destination is not asked for while a check is still fatal", {
  # Choosing a folder for a run that cannot happen is a wasted question.
  states <- ak_step_states(
    dataset_loaded = TRUE, loa_loaded = TRUE, problems = problems_with("error")
  )
  expect_equal(states[["destination"]], "todo")
})

test_that("warnings do not block the run, errors do", {
  warned <- ak_step_states(
    dataset_loaded = TRUE, loa_loaded = TRUE,
    problems = problems_with("warning"), destination_chosen = TRUE
  )
  expect_equal(warned[["checks"]], "warning")
  expect_true(ak_can_run(warned))

  failed <- ak_step_states(
    dataset_loaded = TRUE, loa_loaded = TRUE,
    problems = problems_with("warning", "error"), destination_chosen = TRUE
  )
  expect_equal(failed[["checks"]], "error")
  expect_equal(failed[["results"]], "todo")
  expect_false(ak_can_run(failed))
})

test_that("a run in progress shows as active, and a finished run as done", {
  base <- list(
    dataset_loaded = TRUE, loa_loaded = TRUE, problems = loa_no_problems(),
    destination_chosen = TRUE
  )

  running <- do.call(ak_step_states, c(base, list(running = TRUE)))
  expect_equal(running[["results"]], "active")
  # The button must not be offered again while a run is in flight; the server
  # combines ak_can_run() with the running flag.
  expect_true(ak_can_run(running))

  done <- do.call(ak_step_states, c(base, list(results_ready = TRUE)))
  expect_equal(done[["results"]], "done")
})

test_that("problem counts survive an empty or absent table", {
  expect_equal(ak_problem_counts(NULL), c(error = 0L, warning = 0L))
  expect_equal(ak_problem_counts(loa_no_problems()), c(error = 0L, warning = 0L))
  expect_equal(
    ak_problem_counts(problems_with("error", "warning", "warning")),
    c(error = 1L, warning = 2L)
  )
})

test_that("the problems table puts what must be fixed first", {
  display <- ak_problems_display(problems_with("warning", "error"))

  expect_equal(display$Severity, c("Must fix", "Warning"))
  # Matched rather than compared literally: the separator is a non-ASCII
  # character and the assertion should not depend on the file's encoding.
  expect_match(display$Where[1], "^analysis")
  expect_match(display$Where[1], "row 3$")
  expect_equal(names(display), c("Severity", "Where", "What to fix"))
})

test_that("a sheet-level problem shows no row number", {
  problems <- loa_problem("workbook", NA, "error", "unknown sheet")
  expect_equal(ak_problems_display(problems)$Where, "workbook")
})

test_that("the sheet summary distinguishes missing, empty and read", {
  sheets <- fixture_sheets()
  sheets$count_selections <- sheets$count_selections[0, , drop = FALSE]

  summary <- ak_sheet_summary(fixture_workbook(sheets))

  expect_equal(summary$Sheet, loa_known_sheets())
  expect_equal(summary$Status[summary$Sheet == "analysis_variables"], "Read")
  expect_equal(summary$Status[summary$Sheet == "count_selections"], "Empty - defaults apply")
  expect_equal(
    summary$Status[summary$Sheet == "exclude_choices"],
    "Not supplied - defaults apply"
  )
  expect_equal(summary$Rows[summary$Sheet == "analysis_variables"], 3L)
})

test_that("a missing analysis sheet is called required, not optional", {
  summary <- ak_sheet_summary(fixture_workbook(fixture_sheets(analysis_variables = NULL)))
  expect_equal(summary$Status[summary$Sheet == "analysis_variables"], "Missing - required")
})





