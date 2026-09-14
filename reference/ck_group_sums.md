# Group-Wise Sums of Several Numeric Vectors at Once

The same arithmetic as calling
[`ck_gsum`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_gsum.md)
once per vector, but a single
[`rowsum()`](https://rdrr.io/r/base/rowsum.html) pass over a matrix
instead of one per statistic. Each analysis needs two to four group-wise
sums over the same grouping, so this is where the repetition was.

## Usage

``` r
ck_group_sums(x, g, levels_g)
```

## Arguments

- x:

  A numeric matrix (or vector) whose rows align with `g`. Column names
  become the column names of the result.

- g:

  Group vector (character).

- levels_g:

  Group levels to report, in order.

## Value

A numeric matrix: one row per level of `levels_g`, one column per column
of `x`. Levels with no rows are zero.
