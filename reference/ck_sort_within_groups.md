# Sort Rows Within Each Group, Largest First

Sorts rows inside each run of `col` by the first `stat_` column,
descending. Because the permutation only ever moves rows within a run of
identical `col` values, the run boundaries are unchanged - which is why
[`add_empty_rows_between_groups()`](https://mixedmigrationcentre.github.io/analysiskit/reference/add_empty_rows_between_groups.md)
can sort first and then walk the runs.

## Usage

``` r
ck_sort_within_groups(df, col)
```

## Arguments

- df:

  The data frame.

- col:

  The column that identifies groups.

## Value

`df` with the rows of each group reordered.
