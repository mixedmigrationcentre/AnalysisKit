# Read Every Setting a Workbook Supplies

The `settings` sheet and the `route_analysis` sheet, parsed with
[`loa_parse_settings()`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_parse_settings.md)
and merged into one list. Each key has one sheet, so the two never
overlap.

## Usage

``` r
loa_read_settings(sheets)
```

## Arguments

- sheets:

  The workbook's named list of sheets.

## Value

A list with `settings` and `problems`, as
[`loa_parse_settings()`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_parse_settings.md).
