# Rows Above the First Data Row of a Sheet

The header, plus the description row when the sheet was read with one,
so a problem can name the row the user sees in Excel.

## Usage

``` r
loa_header_rows(workbook, sheet)
```

## Arguments

- workbook:

  The list from
  [`read_loa_workbook()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md),
  or a bare list of sheets.

- sheet:

  The sheet's (normalised) name.

## Value

An integer: 1 or 2.
