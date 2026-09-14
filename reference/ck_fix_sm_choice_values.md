# Repair Truncated Select Multiple Choice Values

Depending on the `analysistools` version, the reported
`analysis_var_value` may be derived by *splitting* the child column name
on the separator rather than by removing the parent prefix, which
truncates a label that contains the separator
(`"QN9/Interception at sea/pull-back..."` becomes
`"Interception at sea"`). A value is replaced only when exactly one
child suffix starts with it, so a correct value is never altered and an
ambiguous one is left alone with a warning.

## Usage

``` r
ck_fix_sm_choice_values(
  results_table,
  dataset,
  sm_separator = "/",
  verbose = TRUE
)
```

## Arguments

- results_table:

  A long results table.

- dataset:

  The analysis dataset, for the real child column names.

- sm_separator:

  Separator between parent and choice. Default `"/"`.

- verbose:

  Logical. Default `TRUE`.

## Value

`results_table` with select_multiple choice values repaired.

## Details

Only reachable via the survey engine -
[`ck_fast_analysis`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_fast_analysis.md)
takes the suffix by prefix removal and never truncates.
