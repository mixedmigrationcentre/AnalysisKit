# Combine the Derived-Column Maps into One

The selection counts, the choice combinations and the exclusive choice
combinations are all derived categorical columns that ride through the
LOA as plain proportions and are renamed afterwards. Everything
downstream - the LOA append, the rename, the block positioning, the
separator rows - works off this single table so no feature needs its own
branch.

## Usage

``` r
ck_derived_map(count_map = NULL, combination_map = NULL, exclusive_map = NULL)
```

## Arguments

- count_map:

  The `map` from
  [`ck_add_selection_counts`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_add_selection_counts.md).

- combination_map:

  The `map` from
  [`ck_add_choice_combinations`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_add_choice_combinations.md)
  run with `mode = "multiple"`.

- exclusive_map:

  The `map` from
  [`ck_add_choice_combinations`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_add_choice_combinations.md)
  run with `mode = "single"`.

## Value

A dataframe of `analysis_var`, `derived_column` and `analysis_type`.
