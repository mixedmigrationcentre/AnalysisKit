# Exclude Non-Substantive Choices from an Analysis

Removes choices such as "Don't know" and "Refused" so that percentages
are reported over respondents who gave a substantive answer. This is
deliberately a change to the *denominator*, not a filter on the output
rows: dropping the rows afterwards would leave the excluded respondents
in every other choice's denominator, which is the opposite of "of those
who answered".

## Usage

``` r
ck_exclude_choices(
  dataset,
  loa,
  exclude_choices = NULL,
  sm_separator = "/",
  ignore_case = TRUE,
  verbose = TRUE
)
```

## Arguments

- dataset:

  The analysis dataset. For select_multiple, run this *after*
  [`ck_sm_children_to_binary`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_sm_children_to_binary.md).

- loa:

  The list of analyses, used to find the variables to act on.

- exclude_choices:

  Character vector of choice labels, matched after trimming. `NULL`
  (default) does nothing.

- sm_separator:

  Separator between parent and choice. Default `"/"`.

- ignore_case:

  Logical. Match case-insensitively. Default `TRUE`.

- verbose:

  Logical. Default `TRUE`.

## Value

A list with `dataset` and `excluded` (the audit trail).

## Details

- select_one:

  The cell is set to `NA`, so the respondent leaves the denominator
  entirely.

- select_multiple:

  A respondent who selected an excluded choice has *all* children of
  that question set to `NA` and so leaves the denominator. The excluded
  child columns are then blanked so they produce no result row.

Grouping variables are left untouched - excluding a category from a
disaggregation changes which respondents appear in the table at all, so
filter the dataset yourself if that is what you want.
