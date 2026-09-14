# Report Which Combination of Choices Each Respondent Selected

For each question in `combinations`, adds a derived categorical column
recording which of the *chosen* choices that respondent selected,
ignoring everything else they selected. With k choices of interest every
respondent falls into exactly one of 2^k groups, so the categories are
mutually exclusive and exhaustive and the percentages add to 100\\

## Usage

``` r
ck_add_choice_combinations(
  dataset,
  combinations,
  sm_separator = "/",
  sm_child_style = c("auto", "label", "dummy"),
  exclude_choices = NULL,
  ignore_case = TRUE,
  none_label = "None of these",
  joiner = " + ",
  mode = c("any", "only"),
  only_suffix = " only",
  order = c("descending", "ascending"),
  suffix = "_choice_combination",
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

- sm_separator:

  Separator between parent and choice. Default `"/"`.

- sm_child_style:

  `"auto"` (default), `"label"`, `"dummy"`.

- exclude_choices:

  Optional choice labels whose pickers leave the base.

- ignore_case:

  Logical. Match labels case-insensitively. Default `TRUE`.

- none_label:

  Row label for respondents who selected none of the listed choices.
  Default `"None of these"`.

- joiner:

  Placed between the display labels of a multi-choice combination.
  Default `" + "`.

- mode:

  `"any"` (default) ignores the choices outside the listed ones.
  `"only"` requires that nothing outside them was selected, and drops
  respondents who mixed a listed choice with an unlisted one.

- only_suffix:

  Appended to each row label under `mode = "only"`, so the strict
  reading is visible in the table itself. Default `" only"`; the
  `none_label` row is left alone.

- order:

  Row order. `"descending"` (default) puts the largest combinations
  first, so the "both" row leads and `none_label` closes. `"ascending"`
  reverses it.

- suffix:

  Appended to the variable name to make the derived column name.

- verbose:

  Logical. Default `TRUE`.

## Value

A list with `dataset` (the derived columns added) and `map` (a dataframe
of `analysis_var`, `combination_column`, `n_choices`, `n_combinations`,
`n_in_base` and `n_mixed_dropped`).

## Details

For `c(Economic = "Economic reasons", Conflict = "Armed conflict, ...")`
that is four rows: *Economic + Conflict*, *Economic* (selected Economic
and not Conflict, whatever else they selected), *Conflict*, and *None of
these*.

Because the result is an ordinary categorical column it then flows
through the normal analysis - overall and across every grouping
variable - with no special casing downstream.

**Two readings of "combination".** `mode = "any"` (the default) ignores
every choice outside the listed ones, so *Economic* means "selected
Economic, did not select Conflict, and whatever else they selected does
not matter". `mode = "only"` is strict: *Economic only* means "selected
Economic and nothing else at all". The strict reading is not
exhaustive - a respondent who selected Economic alongside some choice
outside the list belongs to none of the categories - and those
respondents are dropped from the base. **The result is that
`mode = "only"` reports on a smaller and differently defined base than
every other table in the run**, so the number dropped is returned in the
map as `n_mixed_dropped` and should be footnoted wherever these
percentages are published.

**Denominator.** Only respondents who answered the question are counted:
the parent column is non-blank, or at least one child is selected.
Anyone who was never asked, or asked and left it blank, is `NA` and
drops out - so *None of these* means "answered, but picked none of the
listed choices", not "did not answer". When `exclude_choices` is in
play, respondents who picked an excluded choice also drop out, which
keeps this base identical to the one behind the question's own choice
percentages.

Run this *before*
[`ck_sm_children_to_binary`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_sm_children_to_binary.md):
the pattern is taken from the raw selections, before the not-asked mask
is applied.
