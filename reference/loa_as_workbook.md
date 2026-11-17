# Take a Workbook or a Bare List of Sheets, With Current Sheet Names

Accepts the list from
[`read_loa_workbook()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md)
or a bare named list of sheets, and renames any sheet still under a
former name (see
[`loa_sheet_aliases()`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_sheet_aliases.md)),
so every check reads the same names. When two sheets read as one
(`analysis` and `analysis_variables`, say), the first is kept and both
are recorded in `duplicate_sheets` for
[`validate_loa()`](https://mixedmigrationcentre.github.io/analysiskit/reference/validate_loa.md)
to report.

## Usage

``` r
loa_as_workbook(workbook)
```

## Arguments

- workbook:

  The list from
  [`read_loa_workbook()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md),
  or a bare named list of sheets.

## Value

A list with at least `sheets`.
