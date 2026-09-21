# Report Which Combination of Choices Each Respondent Selected

## Usage

``` r
ck_add_choice_combinations(
  dataset,
  combinations,
  mode = c("multiple", "single"),
  sm_separator = "/",
  sm_child_style = c("auto", "label", "dummy"),
  exclude_choices = NULL,
  ignore_case = TRUE,
  joiner = " + ",
  only_suffix = " only",
  other_label = "Other",
  other_multiple_label = "Other multiple selection",
  other_single_label = "Other single selection",
  residual_label = "",
  order = c("descending", "ascending"),
  suffix = NULL,
  verbose = TRUE
)
```

## Arguments

- dataset:

  A dataframe (label row already removed).

- combinations:

  A named list: names are select_multiple parents, values are the choice
  labels of interest. Name the choices to get short display labels
  (`c(Economic = "Economic reasons")`); leave them unnamed and the full
  ONA label is used.

- mode:

  `"multiple"` (default) or `"single"`. See above.

- sm_separator:

  Separator between parent and choice. Default `"/"`.

- sm_child_style:

  `"auto"` (default), `"label"`, `"dummy"`.

- exclude_choices:

  Optional choice labels whose pickers leave the base.

- ignore_case:

  Logical. Match labels case-insensitively. Default `TRUE`.

- joiner:

  Placed between the display labels of a multi-choice combination, and
  before `other_label`. Default `" + "`.

- only_suffix:

  Appended to a row meaning "and nothing else". Default `" only"`.

- other_label:

  Stands for the unlisted choices. Default `"Other"`.

- other_multiple_label:

  Row label for respondents who selected more than one choice, none of
  them listed.

- other_single_label:

  Row label for respondents whose single selection was not one of the
  listed choices.

- residual_label:

  Row label for the respondents this block does not report - those who
  selected exactly one choice when `mode = "multiple"`, or more than one
  when `mode = "single"`. `""` (default) keeps them in the denominator
  without giving them a row, which is what makes the two blocks add to
  100\\

  orderRow order. `"descending"` (default) puts the largest combinations
  first; `"ascending"` reverses the block.

  suffixAppended to the variable name to make the derived column name.
  `NULL` (default) uses `"_choice_combination"` or
  `"_exclusive_combination"` depending on `mode`.

  verboseLogical. Default `TRUE`.

A list with `dataset` (the derived columns added) and `map`
(`analysis_var`, `combination_column`, `mode`, `n_choices`,
`n_combinations`, `n_in_base`, `n_in_block`, `n_other_block`,
`n_no_selection`, `n_excluded_out` and `hidden_row`). For each question
in `combinations`, adds a derived categorical column saying which of the
*chosen* choices that respondent selected and whether they selected
anything else besides. Because the result is an ordinary categorical
column it then flows through the normal analysis - overall and across
every grouping variable - with no special casing downstream. The feature
comes in two halves, and a question can use either or both:

- `mode = "multiple"`:

  Reports the respondents who selected **more than one** choice. With
  `c(Economic = "Economic reasons", Conflict = "Armed conflict, ...")`
  that is five rows: *Economic + Conflict only* (those two and nothing
  else), *Economic + Conflict + Other* (those two plus at least one
  unlisted choice), *Economic + Other*, *Conflict + Other*, and *Other
  multiple selection* (more than one choice, none of them listed).

- `mode = "single"`:

  Reports the respondents who selected **exactly one** choice: *Economic
  only*, *Conflict only* and *Other single selection*.

**Denominator.** Both halves sit on the same base: respondents who
answered the question - the parent column is non-blank, or at least one
child is selected - *and* have at least one choice recorded. Anyone
never asked, anyone asked who left it blank, and anyone who picked a
choice named in `exclude_choices` is `NA` and drops out. Because the
base is shared, the rows of the two halves *taken together* add to 100\\
half on its own adds to the share of respondents it covers. The
respondents the other half reports are held in the base as
`residual_label` rather than dropped, which is what keeps `n_total` the
same in both.A respondent who answered but has nothing recorded at all
is outside the base entirely. That number is reported per question and
returned as `n_no_selection`, because it is otherwise invisible in the
output.Run this *before*
[`ck_sm_children_to_binary`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_sm_children_to_binary.md):
the pattern is taken from the raw selections, before the not-asked mask
is applied.
