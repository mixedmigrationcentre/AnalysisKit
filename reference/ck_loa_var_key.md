# The analysis_var Value analysistools Will Report for Each LOA Row

For ratios, `create_analysis()` reports `analysis_var` as
`"numerator %/% denominator"`. This reproduces that so LOA metadata can
be joined back onto ratio rows too. The separator itself is
[`ck_ratio_key_separator`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_ratio_key_separator.md);
verify it against your installed analysistools version.

## Usage

``` r
ck_loa_var_key(loa)
```

## Arguments

- loa:

  The list of analyses.

## Value

A character vector, one element per LOA row.
