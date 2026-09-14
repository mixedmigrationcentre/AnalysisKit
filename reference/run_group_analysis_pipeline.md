# Run a Grouped Analysis Pipeline on an ONA Export

Runs an analysis plan (LOA / DAP) over one or more grouping variables
and returns a single wide table where each grouping variable contributes
a block of columns. Differences from the Kobo/XLSForm version:

## Usage

``` r
run_group_analysis_pipeline(
  dataset,
  loa,
  group_variables = c("Overall"),
  skip_label_row = TRUE,
  label_row = NULL,
  weight_column = NULL,
  strata_column = NULL,
  value_columns = c("stat", "n", "n_total"),
  extra_columns = NULL,
  exclude_choices = NULL,
  exclude_ignore_case = TRUE,
  count_selections = NULL,
  count_selections_mode = c("grouped", "exact"),
  count_selections_labels = c("No choice selected", "Selected exactly 1 choice",
    "Selected more than 1 choice"),
  count_selections_order = c("descending", "ascending"),
  count_selections_heading = "Select multiple count",
  count_selections_spacer = TRUE,
  count_selections_title_suffix = "",
  count_combinations = NULL,
  count_combinations_ignore_case = TRUE,
  count_combinations_none_label = "None of these",
  count_combinations_joiner = " + ",
  count_combinations_order = c("descending", "ascending"),
  count_combinations_heading = "Choice combination",
  count_combinations_spacer = TRUE,
  count_combinations_title_suffix = "",
  count_exclusive_combinations = NULL,
  count_exclusive_combinations_heading = "Exclusive choice combination",
  count_exclusive_combinations_suffix = " only",
  count_exclusive_combinations_none_label = "Other choices only",
  max_combination_choices = 6,
  fallback_level = 0.95,
  engine = c("auto", "fast", "survey"),
  min_group_n = NULL,
  slim_design = TRUE,
  keep_missing_groups = TRUE,
  sm_separator = "/",
  prepare_sm = TRUE,
  sm_child_style = c("auto", "label", "dummy"),
  blank_to_na = TRUE,
  label_choices = TRUE,
  add_analysis_type_label = TRUE,
  analysis_type_labels = NULL,
  recreate_sm_parents = FALSE,
  drop_empty_prop_rows = TRUE,
  summary_value_label = NA_character_,
  missing_group_label = "Missing",
  use_group_prefix = TRUE,
  lonely_psu = "adjust",
  verbose = TRUE
)
```

## Arguments

- dataset:

  The ONA export dataframe. Row 1 is the label row by default.

- loa:

  The list of analyses / DAP. Must contain `analysis_type` and
  `analysis_var`; `group_var` optional. `analysis_type` must be one of
  `"prop_select_one"`, `"prop_select_multiple"`, `"mean"`, `"median"`,
  `"ratio"`. Ratios also need `analysis_var_numerator` /
  `analysis_var_denominator`. The `level` column is optional and may be
  empty per row: empty means no confidence interval, a value (usually
  `0.95`) means an interval.

- group_variables:

  Grouping variables. `"Overall"` is the ungrouped analysis. Default
  `c("Overall")`.

- skip_label_row:

  Logical. Remove row 1 and use it as the label row. Default `TRUE`.

- label_row:

  Optional one-row dataframe of labels; takes precedence over the
  extracted row.

- weight_column:

  Optional weights column. Default `NULL`.

- strata_column:

  Optional strata column. Default `NULL`.

- value_columns:

  Statistic columns to spread. Default `c("stat", "n", "n_total")`. Add
  `"n_w"` / `"n_w_total"` when weighting, or `"stat_low"` / `"stat_upp"`
  for CIs.

- extra_columns:

  Optional LOA/DAP columns to carry into the output.

- exclude_choices:

  Optional choice labels to exclude from the denominator, e.g.
  `c("Don't know", "Refused")`. See
  [`ck_exclude_choices`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_exclude_choices.md) -
  this changes the denominator, it does not merely hide rows. Grouping
  variables are not affected.

- exclude_ignore_case:

  Logical. Default `TRUE`.

- count_selections:

  Optional **select_multiple** parents for which to report how many
  choices each respondent picked, as extra rows with
  `analysis_type = "count_select_multiple"`. Passing a single select is
  an error. Note "no choice selected" counts respondents with nothing
  recorded, including any never asked the question.

- count_selections_mode:

  `"grouped"` (default) or `"exact"`.

- count_selections_labels:

  The three labels for `"grouped"`, always in the order *none, exactly
  one, more than one*.

- count_selections_order:

  `"descending"` (default) or `"ascending"`.

- count_selections_heading:

  Heading row above each count block, so the rows cannot be read as
  three more choices. `""` inserts none.

- count_selections_spacer:

  Logical. Blank row above the heading. Default `TRUE`. With the heading
  this adds a `row_type` column.

- count_selections_title_suffix:

  Optionally appended to the question label on count rows. Default `""`.

- count_combinations:

  Optional named list asking, for one or more **select_multiple**
  questions, which *combination* of a chosen set of choices each
  respondent selected. Names are the parent variables, values are the
  choice labels of interest; name the choices to get short row labels.
  For example
  `list(Q78 = c(Economic = "Economic reasons", Conflict = "Armed conflict, generalised violence, and insecurity"))`
  gives four rows - *Economic + Conflict*, *Economic* (and not Conflict,
  whatever else was selected), *Conflict*, *None of these* - reported
  overall and across every grouping variable with
  `analysis_type = "combination_select_multiple"`. Choices other than
  the listed ones are ignored, so the rows are mutually exclusive and
  add to 100\\ Only respondents who answered the question are in the
  denominator. See
  [`ck_add_choice_combinations`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_add_choice_combinations.md).

- count_combinations_ignore_case:

  Logical. Match the choice labels case-insensitively. Default `TRUE`.

- count_combinations_none_label:

  Row label for respondents who selected none of the listed choices.
  Default `"None of these"`.

- count_combinations_joiner:

  Placed between the display labels of a multi-choice combination.
  Default `" + "`.

- count_combinations_order:

  `"descending"` (default) puts the largest combinations first;
  `"ascending"` reverses it.

- count_combinations_heading:

  Heading row above each combination block. `""` inserts none.

- count_combinations_spacer:

  Logical. Blank row above the heading. Default `TRUE`.

- count_combinations_title_suffix:

  Optionally appended to the question label on combination rows. Default
  `""`.

- count_exclusive_combinations:

  Optional named list, same shape as `count_combinations`, asking the
  *strict* version of the same question: *Economic only* means "selected
  Economic and nothing else at all", not "selected Economic, whatever
  else". For the same two choices that is *Economic + Conflict only*,
  *Economic only*, *Conflict only*, *None of these*. Reported with
  `analysis_type = "exclusive_combination_select_multiple"`, so a
  question can carry both this block and the `count_combinations` one.

  **These rows sit on a different base.** A respondent who selected
  Economic alongside a choice outside the list belongs to none of the
  four categories and is dropped, so the denominator here is smaller
  than on every other table in the workbook. The number dropped per
  question is returned in `exclusive_combinations$n_mixed_dropped` -
  footnote it wherever these percentages are published. The settings
  shared with `count_combinations` (`_ignore_case`, `_none_label`,
  `_joiner`, `_order`, `_spacer`, `_title_suffix`) apply to both blocks.

- count_exclusive_combinations_heading:

  Heading row above each exclusive combination block. `""` inserts none.

- count_exclusive_combinations_suffix:

  Appended to each row label of the exclusive block, so the strict
  reading is visible in the table itself. Default `" only"`; the
  `none_label` row is left alone.

- count_exclusive_combinations_none_label:

  Row label for respondents who selected none of the listed choices in
  the *exclusive* block. Kept separate from
  `count_combinations_none_label` so the two blocks do not both show a
  row called "None of these", which would be easy to confuse when they
  sit under the same question. Default `"Other choices only"` -
  accurate, because a respondent in this row selected nothing from the
  list, so everything they did select is outside it.

  Note the two rows hold the *same people*: not selecting a listed
  choice means never being dropped as a mixed response. Their `n` will
  match across the two blocks while their percentages differ, because
  the exclusive block divides by a smaller base. That is expected, not
  an error.

- max_combination_choices:

  Refuse more than this many choices per question, so a long list cannot
  silently produce hundreds of rows. Default `6`.

- fallback_level:

  Placeholder level for LOA rows with an empty `level` cell. Default
  `0.95`; the resulting interval is blanked in the output.

- engine:

  `"auto"` (default) sends rows that asked for an interval to
  `analysistools`/survey and everything else to
  [`ck_fast_analysis`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_fast_analysis.md).
  `"fast"` forces the fast engine (no intervals; neither analysistools
  nor srvyr needed). `"survey"` forces the old behaviour.

- min_group_n:

  Optional minimum interviews a group level must have.

- slim_design:

  Logical. Hand the design only the columns the analysis touches.
  Default `TRUE`.

- keep_missing_groups:

  Logical. Report respondents missing on the grouping variable as their
  own group. Default `TRUE`.

- sm_separator:

  Select_multiple separator. Default `"/"`.

- prepare_sm:

  Logical. Convert select_multiple children to 0/1 with an NA mask for
  rows never asked. Default `TRUE`.

- sm_child_style:

  `"auto"` (default), `"label"` or `"dummy"`.

- blank_to_na:

  Logical. Treat "" as `NA`. Default `TRUE`.

- label_choices:

  Logical. Relabel select_multiple choice values. Default `TRUE`.

- add_analysis_type_label:

  Logical. Add `label_analysis_type`.

- analysis_type_labels:

  Optional override dataframe.

- recreate_sm_parents:

  Logical. Rebuild select_multiple parents from their children first.
  Default `FALSE`; note it cannot distinguish "not asked" from "nothing
  selected".

- drop_empty_prop_rows:

  Logical. Drop the `NA`-valued placeholder row proportions produce.
  Default `TRUE`.

- summary_value_label:

  Value written into `analysis_var_value` for mean / median / ratio
  rows. Default `NA`.

- missing_group_label:

  Column label for respondents missing on the grouping variable. Default
  `"Missing"`.

- use_group_prefix:

  Logical. Prefix output columns with the grouping variable name.
  Default `TRUE`; `FALSE` gives the older `stat_<value>` naming, which
  collides if two grouping variables share a value.

- lonely_psu:

  How survey treats strata with a single observation. Default
  `"adjust"`; `NULL` leaves the option alone.

- verbose:

  Logical. Default `TRUE`.

## Value

A list with `combined_results` (the wide table), `results_long`,
`column_map`, `label_lookup`, `loa_used`, `excluded_choices`,
`dropped_groups`, `selection_counts`, `choice_combinations` and
`exclusive_combinations`.

## Details

- **Labels come from the dataset, not the tool.** Row 1 of an ONA export
  is the label row. It is set aside before the analysis runs (so it
  never contaminates the statistics) and used to relabel the question
  names in the output. No `tool_survey` / `tool_choices` needed.

- **Only questions are relabelled.** ONA exports store choice labels, so
  `analysis_var_value` is already human readable (except select_multiple
  children, where the child column label is used).

- **Weights and strata are optional.**

- **One estimation pass.** The LOA is stacked across grouping variables
  and estimated once, so rows align by construction and no uuid
  bookkeeping or horizontal joins are needed.

- **`sm_separator` defaults to `"/"`**, the ONA style.
