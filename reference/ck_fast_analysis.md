# Point Estimates Without the Survey Package

A drop-in replacement for `analysistools::create_analysis()` returning
the same long results table but point estimates and counts only - no
confidence intervals. The design affects nothing but the variance, so
the estimates are identical to the survey package's to floating-point
precision while being roughly 200x faster on a large disaggregation. Use
it whenever the LOA `level` cell is empty, which is what
`engine = "auto"` does.

## Usage

``` r
ck_fast_analysis(
  dataset,
  loa,
  weight_column = NULL,
  sm_separator = "/",
  keep_missing_groups = TRUE,
  survey_shape = FALSE,
  verbose = TRUE
)
```

## Arguments

- dataset:

  The prepared analysis dataset (label row removed, select_multiple
  children 0/1, mean/median variables numeric).

- loa:

  A stacked LOA from
  [`ck_stack_loa`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_stack_loa.md).

- weight_column:

  Optional weights column. `NULL` makes `stat` a plain proportion or
  mean.

- sm_separator:

  Select_multiple separator. Default `"/"`.

- keep_missing_groups:

  Logical. Report respondents missing on the grouping variable as their
  own group. Default `TRUE`, matching srvyr; `survey::svyby` drops them.

- survey_shape:

  Logical. Lay the rows out exactly as
  `analysistools::create_analysis()` would, so a row moved off the
  survey engine produces the same workbook it always did. The numbers
  are the same either way; what changes is which rows exist and their
  order: groups are sorted in the C locale with the missing group last,
  rows run group by group, a select_one category nobody in a group chose
  has no row (rather than a zero), and a select_multiple group with
  nobody in the denominator keeps an empty row (rather than none).
  Applies to proportions and means. Default `FALSE`.

- verbose:

  Logical. Default `TRUE`.

## Value

A long results table with `analysis_type`, `analysis_var`,
`analysis_var_value`, `group_var`, `group_var_value`, `stat`, `n`,
`n_total`, `n_w`, `n_w_total` and `analysis_key`.
