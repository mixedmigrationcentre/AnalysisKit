# A stand-in for a pipeline result, enough for ak_export_results() to export.
# Shared by the export and route analysis tests.

fake_results <- function(spec = NULL, extra = character(0)) {
  wide <- data.frame(
    analysis_type = c("prop_select_one", "count_select_multiple"),
    analysis_var = c("Respondent_Gender", "Q78"),
    analysis_var_value = c("Female", "Selected exactly 1 choice"),
    stat_Overall = c(0.5, 0.4),
    n_Overall = c(20, 16),
    n_total_Overall = c(40, 40),
    stringsAsFactors = FALSE
  )
  for (nm in extra) {
    wide[[nm]] <- "Demographics"
  }

  list(
    combined_results = wide,
    column_map = data.frame(
      column = "stat_Overall",
      group_variable = "Overall",
      stringsAsFactors = FALSE
    )
  )
}
