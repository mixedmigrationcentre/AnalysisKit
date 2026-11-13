# Count Proportions Out of the Full Sample

By default a respondent with no answer to a question - typically because
skip logic never asked it - is outside the denominator of that question,
so a question asked of 600 of 1,000 respondents reports `n_total = 600`.
This puts those respondents back in the base:

## Usage

``` r
ck_full_sample_base(
  dataset,
  loa,
  group_variables = NULL,
  label = "Not asked / no response",
  sm_separator = "/",
  verbose = TRUE
)
```

## Arguments

- dataset:

  The analysis dataset.

- loa:

  The list of analyses, used to find the variables to act on.

- group_variables:

  Grouping variables; these are never filled.

- label:

  Row label for select_one respondents with no answer. Default
  `"Not asked / no response"`.

- sm_separator:

  Separator between parent and choice. Default `"/"`.

- verbose:

  Logical. Default `TRUE`.

## Value

A list with `dataset`, `filled` (one row per variable: `analysis_var`,
`analysis_type`, `n_filled`) and `select_one_vars` (the select_one
variables that were filled).

## Details

- select_one:

  A blank answer becomes `label` (by default *Not asked / no response*),
  so it is reported as its own row and the question's rows add up to the
  whole sample.

- select_multiple:

  A blank child (the question was not asked) becomes `0` (not selected),
  so every choice is a share of the full sample.

Means, medians and ratios are left alone: a blank number cannot be
averaged without inventing a value for it.

Run it after
[`ck_sm_children_to_binary`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_sm_children_to_binary.md)
and before
[`ck_exclude_choices`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_exclude_choices.md),
so that a choice excluded on purpose still leaves the denominator. A
variable that is also a grouping variable is skipped, so the "Missing"
group of a disaggregation is not renamed.
