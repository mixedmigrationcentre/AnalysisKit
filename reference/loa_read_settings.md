# Read Every Setting a Workbook Supplies

The `settings` sheet and the `route_analysis` sheet, parsed with
[`loa_parse_settings()`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_parse_settings.md)
and merged into one list. Each key has one sheet, so the two never
overlap.

## Usage

``` r
loa_read_settings(sheets, header_rows = NULL)
```

## Arguments

- sheets:

  The workbook's named list of sheets.

- header_rows:

  Optional named integer vector: rows above the first data row of each
  sheet (see
  [`loa_header_rows()`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_header_rows.md)),
  so problems name the row seen in Excel.

## Value

A list with `settings` and `problems`, as
[`loa_parse_settings()`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_parse_settings.md).
