# One Block of Long Results

The single shape every branch of
[`ck_fast_analysis`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_fast_analysis.md)
returns. Scalars recycle, so a branch passes whichever of its arguments
vary.

## Usage

``` r
ck_res_df(type, avar, avalue, gvar, gvalue, stat, n, n_total, n_w, n_w_total)
```

## Arguments

- type, avar, avalue, gvar, gvalue:

  Key columns.

- stat, n, n_total, n_w, n_w_total:

  Statistic columns.

## Value

A dataframe with the ten long-format columns.
