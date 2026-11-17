# The route analysis: pooling the repeated country and place questions.
# Expected figures are worked out by hand in helper-route.R.

run_route <- function(..., dataset = fixture_route_dataset(), spec = NULL) {
  if (is.null(spec)) {
    spec <- route_spec(...)
  }
  suppressMessages(run_route_analysis(dataset, spec, verbose = FALSE))
}

test_that("nothing runs when no block is turned on", {
  expect_null(run_route())
  expect_null(run_route(places_stop = FALSE))
})

test_that("countries are pooled across slots and counted per respondent", {
  res <- run_route(places_stop = TRUE)

  mali <- route_cell(res, "places_stop", "route_country", "Mali")
  niger <- route_cell(res, "places_stop", "route_country", "Niger")
  # r1, r2 and r3 named a stop; r4 did not, so is out of the denominator.
  expect_equal(mali$n, 2)
  expect_equal(mali$n_total, 3)
  expect_equal(niger$n, 2)
  # "None" names no place.
  expect_false("None" %in% res$choice)
})

test_that("a reason given at two stops in one country counts once there", {
  res <- run_route(places_stop = TRUE)

  # r1 gave Work at Gao and at Bamako; r2 gave only Rest/sleep in Mali.
  work <- route_cell(
    res,
    "places_stop",
    "stop_reason",
    "Work",
    country = "Mali"
  )
  rest <- route_cell(
    res,
    "places_stop",
    "stop_reason",
    "Rest/sleep",
    country = "Mali"
  )
  expect_equal(c(work$n, work$n_total), c(1, 2))
  expect_equal(c(rest$n, rest$n_total), c(2, 2))

  # Overall: Work from r1 and r3, Rest/sleep from r1 and r2.
  overall <- route_cell(res, "places_stop", "stop_reason", "Work")
  expect_equal(c(overall$n, overall$n_total), c(2, 3))
})

test_that("places are ranked within their country and cut to the top N", {
  res <- run_route(places_stop = TRUE)

  gao <- route_cell(
    res,
    "places_stop",
    "route_location",
    "Gao",
    country = "Mali"
  )
  bamako <- route_cell(
    res,
    "places_stop",
    "route_location",
    "Bamako",
    country = "Mali"
  )
  expect_equal(c(gao$n, bamako$n), c(2, 1))

  sections <- unique(res[, c(
    "section",
    "level",
    "country",
    "location",
    "unit_n"
  )])
  sections <- sections[order(sections$section), ]
  # Overall, then Mali (tied with Niger on n, so alphabetical), its places by
  # n, then Niger and its place.
  expect_equal(
    paste(sections$level, sections$country, sections$location),
    c(
      "overall NA NA",
      "country Mali NA",
      "location Mali Gao",
      "location Mali Bamako",
      "country Niger NA",
      "location Niger Agadez"
    )
  )
  expect_equal(sections$unit_n, c(3, 2, 2, 1, 2, 2))

  top1 <- run_route(places_stop = TRUE, route_top_locations = 1)
  expect_false("Bamako" %in% top1$location)
  expect_true("Gao" %in% top1$location)

  expect_error(
    run_route(places_stop = TRUE, route_top_locations = 0),
    "whole number of 1 or more"
  )
})

test_that("a place's reasons are pooled within that place only", {
  res <- run_route(places_stop = TRUE)
  gao_work <- route_cell(
    res,
    "places_stop",
    "stop_reason",
    "Work",
    country = "Mali",
    location = "Gao"
  )
  expect_equal(c(gao_work$n, gao_work$n_total), c(1, 2))
})

test_that("choice labels containing the separator survive", {
  res <- run_route(dangerous_location = TRUE)
  perp <- route_cell(
    res,
    "dangerous_location",
    "perpetrator",
    "Armed groups/militias"
  )
  # r2 was not asked about perpetrators.
  expect_equal(c(perp$n, perp$n_total), c(1, 1))
  inc <- route_cell(res, "dangerous_location", "incident", "Physical violence")
  expect_equal(c(inc$n, inc$n_total), c(1, 2))
})

test_that("respondent-level follow-ups keep their own denominator", {
  res <- run_route(transit_country = TRUE)

  # Asked of everyone, including r4 who named no transit country.
  cheapest <- route_cell(res, "transit_country", "Q72", "Cheapest")
  expect_equal(c(cheapest$n, cheapest$n_total), c(3, 4))
  expect_identical(
    cheapest$variable_label,
    "Why did you take this route? (label row)"
  )

  # Within Mali: r1 (Cheapest) and r2 (Safest).
  mali <- route_cell(
    res,
    "transit_country",
    "Q72",
    "Cheapest",
    country = "Mali"
  )
  expect_equal(c(mali$n, mali$n_total), c(1, 2))

  # Transit countries have no places.
  expect_false(any(res$level == "location"))
})

test_that("weights change the percentages but not the counts", {
  res <- run_route(places_stop = TRUE, weight_column = "weight")
  mali <- route_cell(res, "places_stop", "route_country", "Mali")
  # r1 (1) and r2 (3) of r1, r2, r3 (1 + 3 + 1).
  expect_equal(mali$stat, 4 / 5)
  expect_equal(mali$n, 2)
})

test_that("every table is disaggregated by gender and the grouping variables", {
  dataset <- fixture_route_dataset()
  dataset$Q31 <- c("Travelling with children", "Yes", "No", "Yes", "No")
  spec <- route_spec(
    places_stop = TRUE,
    group_variables = c("Overall", "Children"),
    rename_map = c(Q31 = "Children")
  )
  res <- run_route(spec = spec, dataset = dataset)

  expect_setequal(stats::na.omit(unique(res$group_var)), c("Q27", "Children"))

  female <- route_cell(
    res,
    "places_stop",
    "route_country",
    "Mali",
    group_var = "Q27",
    group_var_value = "Female"
  )
  # Female respondents with a stop: r1 and r3; r1 stopped in Mali.
  expect_equal(c(female$n, female$n_total), c(1, 2))

  # A gender variable that is not in the dataset is skipped with a warning.
  expect_warning(
    run_route_analysis(
      fixture_route_dataset(),
      route_spec(places_stop = TRUE, route_gender_var = "Q999"),
      verbose = FALSE
    ),
    "Q999"
  )
})

test_that("a block whose columns are missing is skipped with a warning", {
  dataset <- fixture_route_dataset()
  dataset$Q98 <- NULL
  expect_warning(
    res <- run_route_analysis(
      dataset,
      route_spec(dangerous_location = TRUE, places_stop = TRUE),
      verbose = FALSE
    ),
    "Q98"
  )
  expect_false("dangerous_location" %in% res$block)
  expect_true("places_stop" %in% res$block)
})


# -----------------------------------------------------------------------------
# Settings and wiring
# -----------------------------------------------------------------------------

route_workbook_dataset <- function() {
  route <- fixture_route_dataset()
  route$Q27 <- NULL
  cbind(fixture_dataset(n = 4), route)
}

spec_with_route <- function(...) {
  values <- c(...)
  sheets <- fixture_sheets()
  sheets$settings <- rbind(
    sheets$settings,
    data.frame(setting = names(values), value = unname(values))
  )
  build_analysis_spec(fixture_workbook(sheets), route_workbook_dataset())
}

test_that("route settings are typed and never reach the pipeline", {
  spec <- spec_with_route(
    places_stop = "TRUE",
    dangerous_location = "yes",
    transit_country = "FALSE",
    route_gender_var = "Q27",
    route_top_locations = "2"
  )
  expect_false(loa_has_errors(spec$problems))
  expect_identical(spec$settings$places_stop, TRUE)
  expect_identical(spec$settings$transit_country, FALSE)
  expect_equal(spec$settings$route_top_locations, 2)
  expect_equal(
    ck_route_enabled(spec$settings),
    c("places_stop", "dangerous_location")
  )
  expect_length(
    intersect(
      names(analysis_spec_args(route_workbook_dataset(), spec)),
      loa_route_settings()
    ),
    0
  )

  bad <- spec_with_route(places_stop = "perhaps")
  expect_true(loa_has_errors(bad$problems))
})

test_that("run_analysis_spec attaches the route analysis only when asked", {
  stub <- function(...) list(combined_results = data.frame())

  off <- build_analysis_spec(fixture_workbook(), route_workbook_dataset())
  expect_null(
    run_analysis_spec(
      route_workbook_dataset(),
      off,
      pipeline = stub
    )$route_analysis
  )

  on <- spec_with_route(places_stop = "TRUE")
  res <- suppressMessages(
    run_analysis_spec(
      route_workbook_dataset(),
      on,
      pipeline = stub,
      verbose = FALSE
    )
  )
  expect_true(is.data.frame(res$route_analysis))
  # Q27 is renamed by the disaggregation_variables sheet; the route analysis follows.
  expect_true("Respondent_Gender" %in% res$route_analysis$group_var)
})

test_that("the exporter hands the route analysis to the formatter", {
  spec <- spec_with_route(places_stop = "TRUE")
  route <- run_route(places_stop = TRUE)
  folder <- tempfile()
  dir.create(folder)

  capture <- function(results) {
    seen <- NULL
    ak_export_results(
      results,
      spec,
      folder,
      "d.xlsx",
      formatter = function(...) {
        seen <<- list(...)
        file.create(seen$file_path)
      }
    )
    seen
  }

  results <- fake_results()
  expect_false("route_sheet" %in% names(capture(results)))
  results$route_analysis <- route
  expect_identical(capture(results)$route_sheet, route)
})

export_route_run <- function(...) {
  folder <- tempfile()
  dir.create(folder)
  dataset <- route_workbook_dataset()
  spec <- spec_with_route(...)
  results <- suppressMessages(suppressWarnings(
    run_analysis_spec(dataset, spec, verbose = FALSE)
  ))
  suppressMessages(
    ak_export_results(results, spec, folder, "4mi.xlsx", dataset = dataset)
  )
}

test_that("each route block is written to a sheet of its own", {
  skip_if_not_installed("openxlsx")
  skip_if_not_installed("readxl")

  path <- export_route_run(
    places_stop = "TRUE",
    dangerous_location = "TRUE",
    transit_country = "TRUE"
  )
  sheets <- readxl::excel_sheets(path)
  route_sheets <- c("transit-countries", "places-stop", "dangerous-locations")
  expect_true(all(route_sheets %in% sheets))
  # In the blocks' order, after the result sheets.
  expect_equal(sheets[sheets %in% route_sheets], route_sheets)

  book <- ak_snapshot_workbook(path)
  text_of <- function(sheet) book[[sheet]]$value[book[[sheet]]$type == "text"]

  # Each sheet carries its own block and no other.
  expect_true("Transit countries" %in% text_of("transit-countries"))
  expect_false("Places stopped" %in% text_of("transit-countries"))
  expect_true("Places stopped" %in% text_of("places-stop"))
  expect_false("Most dangerous locations" %in% text_of("places-stop"))
  expect_true("Most dangerous locations" %in% text_of("dangerous-locations"))

  readme <- unlist(readxl::read_excel(path, "readme", col_names = FALSE))
  for (s in route_sheets) {
    expect_true(any(grepl(s, readme, fixed = TRUE)))
  }
})

# The cells of one sheet row, left to right, as text.
route_row <- function(sheet, row) {
  cells <- sheet[sheet$row == row, , drop = FALSE]
  cells$value[order(cells$col)]
}

test_that("a follow-up question is one wide table: Overall, countries, places", {
  skip_if_not_installed("openxlsx")
  skip_if_not_installed("readxl")

  stops <- ak_snapshot_workbook(export_route_run(places_stop = "TRUE"))[[
    "places-stop"
  ]]
  text <- stops$type == "text"

  # The header row of the reasons table: countries by n (Mali and Niger tie
  # on 2, so alphabetical), each followed by its places by n. The n is the
  # question's base in that column. Then the counts panel, the same again.
  head_row <- stops$row[text & stops$value == "Gao (n=2)"][1]
  header <- c(
    "Category",
    "Overall (n=3)",
    "Mali (n=2)",
    "Gao (n=2)",
    "Bamako (n=1)",
    "Niger (n=2)",
    "Agadez (n=2)"
  )
  expect_equal(route_row(stops, head_row), c(header, header))

  # The band row above it.
  expect_equal(
    route_row(stops, head_row - 1L),
    rep(c("Overall", "Country", "Locations", "Country", "Locations"), 2)
  )
  expect_equal(
    route_row(stops, head_row - 2L),
    c("% of respondents", "Number of respondents")
  )

  # Work: overall r1 and r3 of 3; in Mali r1 of 2; at Gao r1 of 2; at
  # Bamako r1 of 1; in Niger and at Agadez r3 of 2 (r1 rested there).
  work_row <- stops$row[
    text & stops$value == "Work" & stops$row > head_row & stops$col == 1
  ][1]
  values <- stops[stops$row == work_row & stops$col %in% 2:7, ]
  expect_equal(
    as.numeric(values$value[order(values$col)]),
    c(2 / 3, 1 / 2, 1 / 2, 1, 1 / 2, 1 / 2)
  )
  counts <- stops[stops$row == work_row & stops$col %in% 10:15, ]
  expect_equal(as.numeric(counts$value[order(counts$col)]), c(2, 1, 1, 1, 1, 1))

  # Below it, the same question overall and by gender, named as the
  # disaggregation_variables sheet renamed it.
  expect_true("Respondent Gender" %in% stops$value[text & stops$row > work_row])
  expect_true("Female (n=2)" %in% stops$value[text & stops$row > work_row])

  # The sheet opens with the ranking of every country.
  expect_true("Countries stopped in: all countries" %in% stops$value[text])
})

test_that("transit countries have one Countries band and no places", {
  skip_if_not_installed("openxlsx")
  skip_if_not_installed("readxl")

  transit <- ak_snapshot_workbook(export_route_run(transit_country = "TRUE"))[[
    "transit-countries"
  ]]
  text <- transit$type == "text"
  head_row <- transit$row[text & transit$value == "Mali (n=2)"][1]
  expect_equal(
    route_row(transit, head_row)[1:4],
    c("Category", "Overall (n=4)", "Mali (n=2)", "Niger (n=2)")
  )
  # Merged band: written once over both country columns.
  expect_equal(
    route_row(transit, head_row - 1L),
    rep(c("Overall", "Countries"), 2)
  )
  expect_false("Locations" %in% transit$value[text])
})

test_that("only the top countries get columns, and only overall is disaggregated", {
  res <- run_route(places_stop = TRUE, route_top_countries = 1)
  expect_equal(unique(stats::na.omit(res$country)), "Mali")
  # The ranking still lists every country.
  expect_setequal(
    res$choice[res$variable == "route_country" & is.na(res$group_var)],
    c("Mali", "Niger")
  )

  all_countries <- run_route(places_stop = TRUE, route_top_countries = 0)
  expect_setequal(
    unique(stats::na.omit(all_countries$country)),
    c("Mali", "Niger")
  )

  expect_true(all(is.na(all_countries$group_var[
    all_countries$level != "overall"
  ])))
  expect_true(any(
    !is.na(all_countries$group_var[all_countries$level == "overall"])
  ))

  expect_error(
    run_route(places_stop = TRUE, route_top_countries = -1),
    "route_top_countries"
  )
})

test_that("only the blocks turned on get a sheet", {
  skip_if_not_installed("openxlsx")
  skip_if_not_installed("readxl")

  sheets <- readxl::excel_sheets(export_route_run(dangerous_location = "TRUE"))
  expect_true("dangerous-locations" %in% sheets)
  expect_false(any(c("transit-countries", "places-stop") %in% sheets))
})

test_that("the dataset reader keeps the route columns when a block is on", {
  path <- tempfile(fileext = ".csv")
  dataset <- route_workbook_dataset()
  utils::write.csv(dataset, path, row.names = FALSE, na = "")
  on.exit(unlink(path), add = TRUE)

  sheets <- fixture_sheets()
  off <- read_analysis_dataset(path, loa = sheets)
  expect_false("Q56" %in% names(off$data))

  sheets$settings <- rbind(
    sheets$settings,
    data.frame(setting = "places_stop", value = "TRUE")
  )
  on <- read_analysis_dataset(path, loa = sheets)
  expect_true(all(
    c("Q56", "Q57", "Q58/Work", "Q58/Rest/sleep") %in% names(on$data)
  ))
  expect_false("Q98" %in% names(on$data))
})
