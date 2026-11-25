# Build inst/extdata/loa_template.xlsx
#
# The template is written by ak_write_loa(), the same function the app uses to
# save a setup, so the two always share one layout: the readme by sheet, the
# description rows and the drop-down lists. Change the example rows here, and
# the descriptions in R/loa_layout.R; never edit the .xlsx by hand.
#
# Run from the package root:
#   "/c/Program Files/R/R-4.6.1/bin/Rscript.exe" dev/build_loa_template.R

pkgload::load_all(quiet = TRUE)

sheets <- list(
  analysis_variables = data.frame(
    analysis_type = c(
      "prop_select_one",
      "prop_select_multiple",
      "prop_select_one",
      "mean",
      "median"
    ),
    analysis_var = c("Q27", "Q78", "Q31", "Q29", "Q29"),
    section = c(
      "Demographics",
      "Drivers",
      "Demographics",
      "Demographics",
      "Demographics"
    ),
    sample_base = NA,
    na_label = NA_character_,
    stringsAsFactors = FALSE
  ),

  disaggregation_variables = data.frame(
    raw_data_name = c("Q27", "Q30", "Region", "Region_of_origin", "Q41_2"),
    new_name = c(
      "Respondent gender",
      "Travelling with children",
      "Region of interview",
      "Region of origin",
      "Country living in before journey"
    ),
    include = TRUE,
    stringsAsFactors = FALSE
  ),

  route_analysis = data.frame(
    setting = c(
      "transit_country",
      "places_stop",
      "dangerous_location",
      "route_full_sample_base",
      "route_gender_var",
      "route_top_countries",
      "route_top_locations"
    ),
    value = c("FALSE", "FALSE", "FALSE", "TRUE", "Q27", "10", "4"),
    stringsAsFactors = FALSE
  ),

  settings = data.frame(
    setting = c(
      "sm_separator",
      "value_columns",
      "extra_columns",
      "skip_label_row",
      "engine",
      "weight_column",
      "strata_column",
      "min_group_n",
      "use_group_prefix",
      "missing_group_label",
      "count_selections_mode",
      "count_selections_order",
      "count_selections_heading",
      "count_selections_label_none",
      "count_selections_label_one",
      "count_selections_label_many",
      "count_combinations_order",
      "count_combinations_other_multiple_label",
      "count_combinations_joiner",
      "count_combinations_heading",
      "max_combination_choices",
      "count_exclusive_combinations_heading",
      "count_exclusive_combinations_only_suffix",
      "count_exclusive_combinations_other_label",
      "include_dataset"
    ),
    value = c(
      "/",
      "stat,n,n_total",
      "section",
      "TRUE",
      "auto",
      NA,
      NA,
      NA,
      "TRUE",
      "Missing",
      "grouped",
      "descending",
      "Select multiple count",
      "No choice selected",
      "Selected exactly 1 choice",
      "Selected more than 1 choice",
      "descending",
      "Other multiple selection",
      "\" + \"",
      "Choice combinations (of those who selected more than one choice)",
      "6",
      "Single choices (of those who selected only one choice)",
      "\" only\"",
      "Other single selection",
      "FALSE"
    ),
    stringsAsFactors = FALSE
  )
)

out <- file.path("inst", "extdata", "loa_template.xlsx")
ak_write_loa(sheets, out)

# The template must read back cleanly: no problem other than the example
# codes not being checked against a dataset.
check <- validate_loa(read_loa_workbook(out))
if (nrow(check) > 0) {
  print(check)
  stop(
    "The template does not validate. Fix the example rows above.",
    call. = FALSE
  )
}
message("Wrote ", out, " (", file.size(out), " bytes).")
