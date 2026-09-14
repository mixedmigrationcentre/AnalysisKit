# The local runner: the five things the Analysis Kit Run handler did, as one
# call. What is worth pinning is the order and the refusals - that nothing is
# written before the analysis succeeds, that a fatal workbook never starts, and
# that a failed save does not throw the results away.

skip_if_no_xlsx <- function() {
  skip_if_not_installed("writexl")
  skip_if_not_installed("readxl")
}

# A dataset with the ONA label row on top, one select_one, one numeric and one
# select_multiple whose choice labels contain the separator and a comma.
run_dataset <- function(n = 40) {
  set.seed(7)
  label <- data.frame(
    Q27 = "What is your gender?",
    Q42 = "Where was the interview conducted?",
    Q29 = "How old are you?",
    Q78 = "Why did you leave?",
    `Q78/Economic reasons` = "Q78/Economic reasons",
    `Q78/Armed conflict, generalised violence, and insecurity` =
      "Q78/Armed conflict, generalised violence, and insecurity",
    check.names = FALSE, stringsAsFactors = FALSE
  )
  body <- data.frame(
    Q27 = rep(c("Female", "Male"), length.out = n),
    Q42 = rep(c("Bosaso", "Hargeisa"), length.out = n),
    Q29 = as.character(seq(20, length.out = n)),
    Q78 = rep("answered", n),
    `Q78/Economic reasons` = rep(c("Economic reasons", NA), length.out = n),
    `Q78/Armed conflict, generalised violence, and insecurity` =
      rep(c(NA, "Armed conflict, generalised violence, and insecurity"), length.out = n),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  out <- rbind(label, body)
  rownames(out) <- NULL
  out
}

run_loa_sheets <- function(...) {
  sheets <- list(
    analysis = data.frame(
      analysis_type = c("prop_select_one", "prop_select_multiple", "mean"),
      analysis_var = c("Q27", "Q78", "Q29"),
      sector = c("Demographics", "Drivers", "Demographics"),
      stringsAsFactors = FALSE
    ),
    group_analysis = data.frame(
      raw_data_name = "Q42",
      new_name = "Interview_Location",
      stringsAsFactors = FALSE
    ),
    settings = data.frame(
      setting = c("value_columns", "extra_columns", "engine"),
      value = c("stat,n,n_total", "sector", "fast"),
      stringsAsFactors = FALSE
    )
  )
  replacement <- list(...)
  for (nm in names(replacement)) sheets[[nm]] <- replacement[[nm]]
  sheets[!vapply(sheets, is.null, logical(1))]
}

write_run_files <- function(sheets = run_loa_sheets(), dataset = run_dataset()) {
  dir <- file.path(tempfile("run"), "in")
  dir.create(dir, recursive = TRUE)

  data_path <- file.path(dir, "export_25_26.xlsx")
  loa_path <- file.path(dir, "loa.xlsx")
  writexl::write_xlsx(dataset, data_path)
  writexl::write_xlsx(sheets, loa_path)

  out <- file.path(dirname(dir), "out")
  dir.create(out, recursive = TRUE)

  list(dataset = data_path, loa = loa_path, out = out)
}


# -----------------------------------------------------------------------------
# Accepting inputs
# -----------------------------------------------------------------------------

test_that("a dataset is accepted as a path, a reader result or a data frame", {
  skip_if_no_xlsx()
  files <- write_run_files()

  from_path <- as_analysis_dataset(files$dataset)
  from_list <- as_analysis_dataset(read_analysis_dataset(files$dataset))
  from_df <- as_analysis_dataset(run_dataset())

  expect_equal(from_path$filename, "export_25_26.xlsx")
  expect_equal(from_path$extension, "XLSX")
  expect_equal(from_list$data, from_path$data)

  # A bare data frame is what makes an already-cleaned in-session dataset
  # usable without writing it out first.
  expect_equal(nrow(from_df$data), nrow(run_dataset()))
  expect_equal(from_df$filename, "dataset")
})

test_that("an unusable dataset argument is refused by name", {
  expect_error(as_analysis_dataset(42), "must be a path")
  expect_error(as_analysis_dataset(list(nope = 1)), "must be a path")
  expect_error(as_analysis_dataset(list(data = "not a data frame")), "must be a data frame")
  expect_error(read_analysis_dataset("no/such/file.xlsx"), "does not exist")
})

test_that("a List of Analysis is accepted as a path, a workbook or a sheet list", {
  skip_if_no_xlsx()
  files <- write_run_files()

  expect_equal(as_loa_workbook(files$loa)$format, "XLSX")
  expect_equal(as_loa_workbook(read_loa_workbook(files$loa))$format, "XLSX")
  expect_equal(as_loa_workbook(run_loa_sheets())$format, "LIST")

  expect_error(as_loa_workbook("no/such/loa.xlsx"), "does not exist")
  expect_error(as_loa_workbook(42), "must be a path")
})


# -----------------------------------------------------------------------------
# Checking before running
# -----------------------------------------------------------------------------

test_that("a clean pair of inputs reports ready, and never stops", {
  skip_if_no_xlsx()
  files <- write_run_files()

  checks <- check_analysis_inputs(files$dataset, files$loa, files$out)

  expect_s3_class(checks, "analysis_readiness")
  expect_true(checks$ready)
  expect_equal(unname(checks$counts[["error"]]), 0L)
  expect_null(checks$folder_problem)
  expect_setequal(checks$spec$group_variables, c("Overall", "Interview_Location"))
  expect_true(all(checks$coverage$present))
  expect_output(print(checks), "ready to run     : yes")
})

test_that("a fatal workbook is described rather than thrown", {
  skip_if_no_xlsx()
  # Interview and Interview_Location: one name contained in the other, so the
  # column map would attribute the wrong columns to the wrong disaggregation.
  files <- write_run_files(run_loa_sheets(
    group_analysis = data.frame(
      raw_data_name = c("Q42", "Q27"),
      new_name = c("Interview", "Interview_Location"),
      stringsAsFactors = FALSE
    )
  ))

  checks <- check_analysis_inputs(files$dataset, files$loa)

  expect_false(checks$ready)
  expect_gt(checks$counts[["error"]], 0L)
  expect_output(print(checks), "ready to run     : no")
  expect_output(print(checks), "Fix these first")
})

test_that("an absent output folder is reported as a problem, not an error", {
  skip_if_no_xlsx()
  files <- write_run_files()

  checks <- check_analysis_inputs(
    files$dataset, files$loa,
    output_folder = file.path(files$out, "nope")
  )

  expect_false(checks$ready)
  expect_match(checks$folder_problem, "does not exist")
})


# -----------------------------------------------------------------------------
# Running
# -----------------------------------------------------------------------------

test_that("a run produces results and writes exactly one workbook", {
  skip_if_no_xlsx()
  files <- write_run_files()

  run <- run_analysis_locally(files$dataset, files$loa, files$out, verbose = FALSE)

  expect_s3_class(run, "analysis_run")
  expect_true(file.exists(run$output_path))
  expect_equal(length(list.files(files$out)), 1L)
  expect_match(basename(run$output_path), "^analysiskit_export_25_26_\\d{8}-\\d{6}\\.xlsx$")

  # Named after the dataset it came from, and traceable from the readme sheet.
  expect_true("readme" %in% readxl::excel_sheets(run$output_path))

  wide <- run$results$combined_results
  expect_gt(nrow(wide), 0L)
  expect_true("stat_Overall" %in% names(wide))
  expect_true(any(startsWith(names(wide), "stat_Interview_Location_")))
  expect_setequal(
    unique(wide$analysis_type),
    c("prop_select_one", "prop_select_multiple", "mean")
  )

  # The pipeline's own messages are kept rather than lost to the console.
  expect_true(length(run$log) > 0)
  expect_match(run$log, "ANALYSIS DONE", all = FALSE)
  expect_null(run$save_error)
  expect_s3_class(run$elapsed, "difftime")

  # The dataset itself is not carried in the result: a 100 MB export would
  # otherwise be duplicated in every saved run object.
  expect_false("data" %in% names(run$dataset))
  expect_equal(run$dataset$filename, "export_25_26.xlsx")
})

test_that("output_folder = NULL runs the analysis and writes nothing", {
  skip_if_no_xlsx()
  files <- write_run_files()

  run <- run_analysis_locally(files$dataset, files$loa, NULL, verbose = FALSE)

  expect_null(run$output_path)
  expect_gt(nrow(run$results$combined_results), 0L)
  expect_equal(length(list.files(files$out)), 0L)
  expect_output(print(run), "nothing written")
})

test_that("a fatal workbook stops before any work and names every problem", {
  skip_if_no_xlsx()
  files <- write_run_files(run_loa_sheets(
    analysis = data.frame(
      analysis_type = "nonsense", analysis_var = "Q27",
      stringsAsFactors = FALSE
    )
  ))

  expect_error(
    run_analysis_locally(files$dataset, files$loa, files$out, verbose = FALSE),
    "must be fixed before running"
  )
  # Nothing is written by a run that never started.
  expect_equal(length(list.files(files$out)), 0L)
})

test_that("an unusable output folder is refused before the analysis runs", {
  skip_if_no_xlsx()
  files <- write_run_files()

  expect_error(
    run_analysis_locally(
      files$dataset, files$loa,
      output_folder = file.path(files$out, "nope"),
      verbose = FALSE
    ),
    "does not exist"
  )
})

test_that("a failed save keeps the results and warns rather than losing them", {
  skip_if_no_xlsx()
  files <- write_run_files()

  # The failure has to happen after a successful analysis, which is hard to
  # arrange for real: an unusable folder is refused up front, and a name
  # already taken gets a _1 suffix rather than failing. So the export is
  # mocked - the branch under test is run_analysis_locally()'s handling of a
  # save that fails, not any particular reason for it.
  local_mocked_bindings(
    ak_export_results = function(...) stop("the disk filled up", call. = FALSE)
  )

  expect_warning(
    run <- run_analysis_locally(files$dataset, files$loa, files$out, verbose = FALSE),
    "could not be saved"
  )

  expect_null(run$output_path)
  expect_match(run$save_error, "the disk filled up")
  # The whole point: a long analysis is not thrown away over a failed write.
  expect_gt(nrow(run$results$combined_results), 0L)
  expect_output(print(run), "save failed")
})

test_that("... overrides the workbook for run-time concerns", {
  skip_if_no_xlsx()
  files <- write_run_files()

  # The workbook asks for the Interview_Location disaggregation; the caller
  # asks for the ungrouped analysis only.
  run <- run_analysis_locally(
    files$dataset, files$loa, NULL,
    verbose = FALSE,
    group_variables = "Overall"
  )

  expect_false(any(startsWith(names(run$results$combined_results), "stat_Interview_Location_")))
  expect_true("stat_Overall" %in% names(run$results$combined_results))
})

test_that("a data frame and its file produce the same result", {
  skip_if_no_xlsx()
  files <- write_run_files()

  from_file <- run_analysis_locally(files$dataset, files$loa, NULL, verbose = FALSE)
  from_memory <- run_analysis_locally(run_dataset(), files$loa, NULL, verbose = FALSE)

  expect_equal(
    from_memory$results$combined_results,
    from_file$results$combined_results
  )
})

test_that("verbose = FALSE keeps the log but prints nothing", {
  skip_if_no_xlsx()
  files <- write_run_files()

  quiet <- capture.output(
    run <- run_analysis_locally(files$dataset, files$loa, NULL, verbose = FALSE)
  )

  expect_equal(quiet, character(0))
  expect_true(length(run$log) > 0)
})


# -----------------------------------------------------------------------------
# Getting started
# -----------------------------------------------------------------------------

test_that("the run log strips the pipeline's arrow and drops empty lines", {
  collected <- with_run_log(
    {
      message("--> something happened")
      message("   ")
      warning("something to watch")
      "value"
    },
    echo = FALSE
  )

  expect_equal(collected$value, "value")
  expect_equal(collected$log, c("something happened", "Warning: something to watch"))
})

test_that("the template ships with the package and refuses to clobber", {
  dir <- file.path(tempfile("tmpl"))
  path <- suppressMessages(copy_loa_template(dir))

  expect_true(file.exists(path))
  expect_error(copy_loa_template(dir), "already exists")
  expect_silent(suppressMessages(copy_loa_template(dir, overwrite = TRUE)))

  skip_if_not_installed("readxl")
  expect_true("analysis" %in% loa_normalise_sheet_name(readxl::excel_sheets(path)))
})

test_that("the schema document ships with the package", {
  schema <- system.file("extdata", "loa-schema.md", package = "analysiskit")
  expect_true(nzchar(schema) && file.exists(schema))
  expect_match(paste(readLines(schema, warn = FALSE), collapse = "\n"), "count_exclusive_combinations")
})

test_that("the required packages are all reported installed", {
  status <- check_analysis_packages()

  expect_true(all(c("package", "need", "installed", "version", "install") %in% names(status)))
  expect_true(all(status$installed[status$need == "required"]))
  # An absent package is reported with the command that installs it, and the
  # two GitHub-only ones must not be reported as CRAN installs.
  github <- status$package %in% c("analysistools", "cleaningtools")
  expect_true(all(status$install[github & !status$installed] == "" |
                    grepl("install_github", status$install[github & !status$installed])))
})

test_that("the pipeline and the formatter are both reachable from the namespace", {
  # ak_export_results() and run_analysis_spec() find them with exists(), which
  # in a package searches the namespace. If that ever stopped working, every
  # run would fail with "not available" instead of running.
  ns <- asNamespace("analysiskit")
  expect_true(exists("run_group_analysis_pipeline", envir = ns, mode = "function"))
  expect_true(exists("format_my_xlsx_variable_x_group", envir = ns, mode = "function"))
})
