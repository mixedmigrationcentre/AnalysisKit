# Put Rerouted Rows Back Among the Survey Rows

Rows that carry a level used to come back from one `create_analysis()`
call, in LOA order. When some of them are tabulated instead, the two
sets are stacked and re-sorted into that order, so the wide table's rows
and columns appear exactly where they did.

## Usage

``` r
ck_merge_level_rows(rerouted, survey, stacked_loa)
```

## Arguments

- rerouted:

  Long results from
  [`ck_fast_analysis`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_fast_analysis.md),
  or `NULL`.

- survey:

  Long results from `create_analysis()`.

- stacked_loa:

  The stacked LOA both were estimated from.

## Value

One long results table.
