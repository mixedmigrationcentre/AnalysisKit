# Rename Former Columns to Their Current Names

A sheet that carries both the former and the current name of one column
is left as it is, and the pair is returned in `clashes` for
[`validate_loa()`](https://mixedmigrationcentre.github.io/analysiskit/reference/validate_loa.md)
to report: the reader cannot tell which one is meant.

## Usage

``` r
loa_apply_column_aliases(df, sheet)
```

## Arguments

- df:

  A sheet's data frame, or `NULL`.

- sheet:

  The sheet's (normalised) name.

## Value

A list with `df` and `clashes` (character: "former / current").
