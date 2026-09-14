# Relabel Question Names in an Analysis Table

Adds `label_analysis_var` from the ONA label row. Only the *questions*
are relabelled: choice values are already labels in an ONA export. For
select_multiple, `analysis_var_value` holds the child suffix, so the
child column label is used where available and the repeated parent
prefix is stripped.

## Usage

``` r
ck_relabel_questions(
  results_table,
  label_lookup,
  sm_separator = "/",
  label_choices = TRUE
)
```

## Arguments

- results_table:

  A dataframe containing at least `analysis_var`.

- label_lookup:

  A named vector from
  [`ck_build_label_lookup`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_build_label_lookup.md).

- sm_separator:

  Separator between parent and choice. Default `"/"`.

- label_choices:

  Logical. Relabel select_multiple choice values. Default `TRUE`.

## Value

`results_table` with `label_analysis_var` added.
