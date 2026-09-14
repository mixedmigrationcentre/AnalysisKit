# The package roster and the dependency bootstrap.
#
# What is worth pinning: that the roster is the single source of truth, that the
# two GitHub-only packages carry an org/repo spec rather than a bare name, and
# that a missing OPTIONAL package never turns into a hard failure. That last one
# is the whole design premise - every run that leaves `level` empty needs none
# of the three - and it is easy to break by adding a stop() in the wrong place.

test_that("the roster names every package, with a purpose and a need", {
  roster <- ak_package_roster()

  expect_true(all(c("package", "need", "repo", "purpose") %in% names(roster)))
  expect_gt(nrow(roster), 0L)
  expect_true(all(roster$need %in% c("required", "optional")))
  expect_true(all(nzchar(roster$purpose)))
  expect_false(any(duplicated(roster$package)))

  # The five the package cannot run without.
  expect_setequal(
    roster$package[roster$need == "required"],
    c("dplyr", "tidyr", "stringr", "readxl", "openxlsx")
  )
})

test_that("check_analysis_packages reads from the roster, not a second list", {
  roster <- ak_package_roster()
  status <- check_analysis_packages()

  # Same packages, same order - so the two can never drift apart on whether
  # srvyr is optional.
  expect_identical(status$package, roster$package)
  expect_identical(status$need, roster$need)
  expect_identical(status$purpose, roster$purpose)
})

test_that("the GitHub-only packages install by org/repo, not by name", {
  roster <- ak_package_roster()
  specs <- ak_install_specs(roster)

  github <- c("analysistools", "cleaningtools")
  # A bare "analysistools" would send an installer to CRAN, where it is not.
  expect_equal(
    specs[match(github, roster$package)],
    c("impact-initiatives/analysistools", "impact-initiatives/cleaningtools")
  )

  # Everything else installs by plain name.
  cran <- setdiff(roster$package, github)
  expect_equal(specs[match(cran, roster$package)], cran)
})

test_that("the install hints match the spec each package needs", {
  # Both cases are forced rather than hoped for. Reading them off whatever is
  # absent on this machine means the test skips entirely once everything is
  # installed - which is exactly when a wrong hint would go unnoticed.
  local_mocked_bindings(
    ak_package_roster = function() {
      rbind(
        data.frame(
          package = "absent.from.cran", need = "optional",
          repo = NA_character_, purpose = "a CRAN package that is not here",
          stringsAsFactors = FALSE
        ),
        data.frame(
          package = "absent.from.github", need = "optional",
          repo = "an-org/absent.from.github",
          purpose = "a GitHub-only package that is not here",
          stringsAsFactors = FALSE
        ),
        data.frame(
          package = "stats", need = "required", repo = NA_character_,
          purpose = "present everywhere", stringsAsFactors = FALSE
        )
      )
    }
  )

  status <- check_analysis_packages()
  hint <- stats::setNames(status$install, status$package)

  # A GitHub-only package must not be sent to CRAN, where it is not.
  expect_match(hint[["absent.from.github"]], "install_github")
  expect_match(hint[["absent.from.github"]], "an-org/absent.from.github", fixed = TRUE)

  expect_match(hint[["absent.from.cran"]], "^install\\.packages")
  expect_false(grepl("install_github", hint[["absent.from.cran"]]))

  # Nothing to say about something already installed.
  expect_identical(hint[["stats"]], "")
})

test_that("a missing optional package is reported, never fatal", {
  # The design premise: srvyr, analysistools and cleaningtools are reached by
  # one feature each, so their absence must not stop anything.
  #
  # ak_install_missing() is mocked out rather than left to run: it is the only
  # part that touches the network, and what is under test here is the judgement
  # made afterwards, not the installing.
  local_mocked_bindings(
    ak_install_missing = function(...) invisible(FALSE),
    ak_package_roster = function() {
      data.frame(
        package = "a.package.that.does.not.exist",
        need = "optional",
        repo = NA_character_,
        purpose = "a test",
        stringsAsFactors = FALSE
      )
    }
  )

  # No error, and it says so rather than staying silent.
  expect_no_error(suppressWarnings(suppressMessages(load_packages())))
  expect_message(
    suppressWarnings(load_packages()),
    "Still missing"
  )
})

test_that("a missing required package warns loudly", {
  local_mocked_bindings(
    ak_install_missing = function(...) invisible(FALSE),
    ak_package_roster = function() {
      data.frame(
        package = "another.package.that.does.not.exist",
        need = "required",
        repo = NA_character_,
        purpose = "a test",
        stringsAsFactors = FALSE
      )
    }
  )

  expect_warning(
    suppressMessages(load_packages()),
    "required, so runs will fail"
  )
})

test_that("load_packages does nothing and says so when all is present", {
  local_mocked_bindings(
    ak_package_roster = function() {
      data.frame(
        package = "stats", need = "required", repo = NA_character_,
        purpose = "a test", stringsAsFactors = FALSE
      )
    }
  )

  expect_message(load_packages(), "already installed")
  expect_message(load_packages(), "Ready")
})

test_that("optional = FALSE narrows to the required packages", {
  # Nothing is installed by this: every required package is already present in
  # any session that can run the suite at all.
  expect_message(load_packages(optional = FALSE), "already installed")
})

test_that("the example script ships, parses, and calls only real functions", {
  path <- system.file("examples", "run_analysis.R", package = "analysiskit")
  skip_if(!nzchar(path) || !file.exists(path), "not testing an installed package")

  code <- parse(path)
  expect_gt(length(code), 0L)

  # Every analysiskit function the guide tells someone to call must exist,
  # or the guide sends them to an error.
  exports <- getNamespaceExports("analysiskit")
  used <- unique(unlist(lapply(code, all.names)))
  named <- intersect(used, exports)

  # One per step, in the order the script runs them.
  expect_true(all(c(
    "load_packages",           # 1. packages
    "setup_project_folders",   # 2. project folders
    "read_analysis_dataset",   # 3. read the files
    "read_loa_workbook",       #    "
    "check_analysis_inputs",   # 4. check the List of Analysis
    "run_analysis_spec",       # 5. run the analysis pipeline
    "ak_export_results"        # 6. create the output
  ) %in% named))

  # The "run once" caveat on setup_project_folders() is the one instruction a
  # reader most needs to see, so it is pinned rather than left to drift.
  text <- readLines(path, warn = FALSE)
  expect_match(paste(text, collapse = "\n"), "ONLY NEED TO RUN THIS ONCE")
})

test_that("the example script keeps its six steps, in order", {
  path <- system.file("examples", "run_analysis.R", package = "analysiskit")
  skip_if(!nzchar(path) || !file.exists(path), "not testing an installed package")

  text <- paste(readLines(path, warn = FALSE), collapse = "\n")

  steps <- c(
    "1. packages", "2. project folders", "3. read the files",
    "4. check the List of Analysis", "5. run the analysis pipeline",
    "6. create the output"
  )
  at <- vapply(
    steps,
    function(s) {
      hit <- regexpr(s, text, fixed = TRUE)
      if (hit < 0) NA_integer_ else as.integer(hit)
    },
    integer(1)
  )

  expect_false(any(is.na(at)))       # every step is there
  expect_identical(at, sort(at))     # and in this order
})

test_that("the example script stays short enough to read at a glance", {
  path <- system.file("examples", "run_analysis.R", package = "analysiskit")
  skip_if(!nzchar(path) || !file.exists(path), "not testing an installed package")

  # A requirement, not an accident. An earlier version spelled out every stage
  # and ran to 380 lines, which was too much to take in - the whole point of
  # this file is that it reads straight down in one screenful. Pinned so it
  # cannot creep back.
  expect_lt(length(parse(path)), 20L)
  expect_lt(length(readLines(path, warn = FALSE)), 130L)
})


test_that("the install step is handed the right specs, once", {
  seen <- NULL
  local_mocked_bindings(
    ak_install_missing = function(specs, upgrade = FALSE) {
      seen <<- specs
      invisible(TRUE)
    },
    ak_package_roster = function() {
      rbind(
        data.frame(
          package = "stats", need = "required", repo = NA_character_,
          purpose = "installed already, so must not be offered for install",
          stringsAsFactors = FALSE
        ),
        # A name that cannot resolve, so it is missing on every machine. An
        # earlier version of this test used cleaningtools, which made the
        # result depend on whether the person running the suite happened to
        # have it: it passed where cleaningtools was absent and failed where it
        # was installed, because then nothing was missing and the install step
        # was never reached.
        data.frame(
          package = "absent.by.construction", need = "optional",
          repo = "an-org/absent.by.construction",
          purpose = "always missing, and GitHub-only",
          stringsAsFactors = FALSE
        )
      )
    }
  )

  suppressWarnings(suppressMessages(load_packages()))

  # Only what is missing, and by org/repo rather than by bare name.
  expect_equal(seen, "an-org/absent.by.construction")
})

test_that("nothing is installed when nothing is missing", {
  called <- FALSE
  local_mocked_bindings(
    ak_install_missing = function(...) {
      called <<- TRUE
      invisible(TRUE)
    },
    ak_package_roster = function() {
      data.frame(
        package = "stats", need = "required", repo = NA_character_,
        purpose = "a test", stringsAsFactors = FALSE
      )
    }
  )

  suppressMessages(load_packages())
  expect_false(called)
})


test_that("run_analysis_spec explains itself when handed the reader's list", {
  skip_if_not_installed("writexl")

  # check_analysis_inputs() and run_analysis_locally() both accept either shape,
  # so passing the list here is an easy mistake. It used to fail deep inside
  # apply_rename_map() with "missing value where TRUE/FALSE needed", which named
  # neither the argument nor the cause.
  dataset <- fixture_dataset()
  spec <- build_analysis_spec(fixture_workbook(), dataset)

  as_read <- list(
    data = dataset, extension = "XLSX",
    filename = "export.xlsx", size = 1
  )

  expect_error(
    run_analysis_spec(as_read, spec, pipeline = function(...) NULL),
    "pass its data frame instead"
  )
  expect_error(
    run_analysis_spec("not a dataset at all", spec, pipeline = function(...) NULL),
    "must be a data frame"
  )

  # The data frame itself still goes straight through.
  expect_null(
    run_analysis_spec(dataset, spec, pipeline = function(...) NULL)
  )
})
