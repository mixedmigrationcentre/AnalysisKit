# Format XLSX Variable by Group Using MMC Branding

Writes an analysis table to an Excel workbook in a variable-by-group
layout styled with the MMC palette: a navy (`#003D58`) band for the
merged disaggregation-group headers, a teal (`#00A2A5`) band for the
column headers, a light blue index panel on the left for the question /
option columns, and alternating white / pale blue shading per block of
statistics.

## Usage

``` r
format_my_xlsx_variable_x_group(
  table_group_x_variable,
  file_path = NULL,
  table_name = "variable_x_group_table",
  value_columns = c("stat", "stat_low", "stat_upp"),
  total_columns = NULL,
  readme_sheet_name = "readme",
  table_sheet_name = "variable_x_group_table",
  overwrite = FALSE,
  layout = c("matrix", "blocks"),
  insert_empty_rows = FALSE,
  empty_rows_col = "analysis_var",
  sort_within_groups = TRUE,
  split_by = "group_variable",
  max_sheets = 60,
  split_by_group_variable = NULL,
  column_map = NULL,
  repeat_overall = TRUE,
  order_groups_by_n = TRUE,
  order_groups_per_question = TRUE,
  drop_empty_groups = TRUE,
  short_group_labels = TRUE,
  colour_scale = TRUE,
  max_colour_scale_rules = 250,
  round_digits = NULL,
  percent_digits = 0,
  hidden_columns = 1:3,
  index_width = 7,
  stat_width = 13,
  total_width = 5,
  palette = NULL,
  font_name = "Arial Narrow",
  readme_text = NULL,
  verbose = TRUE
)
```

## Arguments

- table_group_x_variable:

  A data frame, a named list containing `table_name`, or the list
  returned by
  [`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md)
  (which supplies both `combined_results` and `column_map`).

- file_path:

  Output path. `NULL` (default) returns the workbook.

- table_name:

  Name of the element holding the table when a list is supplied.
  `"combined_results"` is picked up automatically.

- value_columns:

  Statistic column prefixes.

- total_columns:

  Count column prefixes (e.g. `c("n", "n_total")`), formatted as whole
  numbers.

- readme_sheet_name:

  Name of the readme sheet.

- table_sheet_name:

  Name of the table sheet; used only when a sheet name cannot be
  derived.

- overwrite:

  Logical, overwrite an existing file.

- layout:

  `"matrix"` (default) writes the wide variable-by-group table: one row
  per question option, one block of columns per disaggregation group.
  `"blocks"` writes one small table per question - the question on top,
  the disaggregation variable band under it, then a header row naming
  each group with its sample size, then the answer categories - with the
  percentages on the left of the sheet and the matching counts on the
  right.

- insert_empty_rows:

  Logical. Insert a blank row between question groups.

- empty_rows_col:

  Column used for grouping when inserting empty rows.

- sort_within_groups:

  Logical, sort rows inside each group by the first `stat_` column,
  descending.

- split_by:

  How results are spread across sheets. Any combination of `"none"`,
  `"group_variable"` (one sheet per disaggregation variable, needs
  `column_map`) and any column name (one sheet per value of that
  column - use for `sector`, `indicator`, `analysis_type` or any LOA
  column carried through by `extra_columns`).
  `c("sector", "group_variable")` writes one sheet per sector and
  grouping variable. `"analysis_var"` and `"analysis_var_value"` are
  accepted as aliases of the renamed `question` and `option` columns.

- max_sheets:

  Refuse to build more sheets than this, so a typo in `split_by` cannot
  produce hundreds of sheets.

- split_by_group_variable:

  Deprecated logical kept for backwards compatibility. `TRUE` maps to
  `split_by = "group_variable"`, `FALSE` to `"none"`. Ignored when
  `split_by` is given explicitly.

- column_map:

  Optional data frame with `group_variable` and `column`, as returned by
  [`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md).

- repeat_overall:

  Logical. Repeat the Overall block on every sheet.

- order_groups_by_n:

  Logical, default `TRUE`. Order the group columns within each grouping
  variable by sample size, largest first, instead of the alphabetical
  order they come out of the pipeline in - so
  `Female (n=740), Male (n=1152)` is written
  `Male (n=1152), Female (n=740)`, and `No, Refused, Yes` becomes
  `Yes, No, Refused`. Only blocks belonging to the same grouping
  variable move, so the merged variable band above them still spans a
  contiguous stretch and `Overall` stays put. Needs a count column: pass
  `total_columns` (e.g. `c("n", "n_total")`) or there is nothing to sort
  by and the order is left alone. `FALSE` restores the alphabetical
  order.

  This sets the sheet-wide order, from each group's sample size across
  the whole table. In `layout = "blocks"` it is then refined per
  question unless `order_groups_per_question` is turned off.

- order_groups_per_question:

  Logical, default `TRUE`, `layout = "blocks"` only. Give every question
  its own group order, largest first by that question's own denominator,
  rather than having them all follow the sheet-wide order. Questions
  with different coverage then show their groups in different orders,
  which is the point.

  The permutation stays inside each grouping variable's run, so the
  merged variable band above the columns, the alternating block shading
  and the column widths are all unaffected - only which block sits in
  which column changes, and every header carries its own name and
  `(n=)`.

  The cost: reading straight down a column no longer follows one group.
  The third column may be `Male` on one question and `Female` on the
  next. Set this to `FALSE` if you need the columns to line up down the
  sheet; `layout = "matrix"` always does, since there every question is
  a row under one shared header.

- drop_empty_groups:

  Logical, default `TRUE`. Leave out any group whose sample size is zero
  on that sheet, in both the percentage panel and the count panel. A
  grouping variable's levels are fixed across the whole table, so a
  country with no interviews for the questions on a sheet would
  otherwise get a full block of empty (or `#NUM!`) columns. Judged per
  sheet rather than per question, so the group columns stay aligned down
  the sheet; the Overall block is never dropped. Anything dropped is
  listed in a readme note, since silently omitting a country from a
  table is easy to misread.

- short_group_labels:

  Logical. In `layout = "blocks"`, drop the disaggregation variable
  prefix from each group label, so `Respondent_Gender_Female (n=11422)`
  reads `Female (n=11422)` under the `Respondent_Gender` band. `Overall`
  is never touched.

- colour_scale:

  Logical. Apply the per-question colour scale to the first statistic
  column.

- max_colour_scale_rules:

  Skip the colour scale when it would need more rules than this on a
  sheet (hundreds of rules make the workbook slow to open in Excel).

- round_digits:

  Optional integer. Round numeric statistic columns before writing.
  Shortens the XML noticeably on very large tables.

- percent_digits:

  Decimal places shown on proportions. `0` (the default) displays
  `0.668039538714992` as `67%`. This is a display format, so the cell
  keeps its full precision and the figures still add up correctly. Means
  and medians are unaffected; they keep two decimals.

- hidden_columns:

  Identifier columns to hide on every table sheet. Defaults to the first
  three (machine names and analysis type), which are kept in the file
  but collapsed out of the way. `NULL` shows everything.

- index_width:

  Width of the visible identifier columns.

- stat_width:

  Width of the statistic columns.

- total_width:

  Width of the count columns named in `total_columns`. Kept narrow so
  the statistics of neighbouring disaggregations sit side by side.

- palette:

  Optional named vector of colour overrides. See
  [`mmc_colours()`](https://mixedmigrationcentre.github.io/analysiskit/reference/mmc_colours.md).

- font_name:

  Font used throughout.

- readme_text:

  Optional character vector of extra readme lines.

- verbose:

  Logical, print progress messages.

## Value

An `openxlsx` workbook if `file_path` is NULL, otherwise the file is
written and the path returned invisibly.

## Details

Built for the wide outputs of
[`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md),
which can run to thousands of columns when many countries or towns are
used as grouping variables. With `column_map` from the pipeline, each
grouping variable is written to its own sheet, repeating the index panel
and, optionally, the Overall block.
