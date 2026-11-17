# Normalise a Sheet Name for Matching

Lower case, trimmed, with spaces and hyphens collapsed to underscores,
so `"Disaggregation Variables"` and `"disaggregation-variables"` both
resolve to `disaggregation_variables`. The sheets' former names,
`analysis` and `group_analysis`, resolve to their current ones (see
[`loa_sheet_aliases()`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_sheet_aliases.md)),
so a workbook made before the rename still reads.

## Usage

``` r
loa_normalise_sheet_name(x)
```

## Arguments

- x:

  Character vector of sheet names.

## Value

A character vector.
