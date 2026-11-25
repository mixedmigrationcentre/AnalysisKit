# Read One Sheet, Skipping Its Description Row

The template has a row describing each column directly under the header
of some sheets (see
[`loa_column_descriptions()`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_column_descriptions.md)).
It is not data, so when the first row under the header is that row, the
data is read from the row after it. Reading from there, rather than
dropping the row afterwards, keeps readxl's column types: a text row
would otherwise turn the numeric `level` column into text.

## Usage

``` r
loa_read_sheet(path, sheet, normalised, col_types)
```

## Arguments

- path:

  Workbook path.

- sheet:

  Sheet name as written in the workbook.

- normalised:

  The sheet's normalised name.

- col_types:

  Passed to
  [`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html).

## Value

A data frame with attribute `header_rows`: 1, or 2 when a description
row was skipped.
