# Read a List of Analysis Workbook

Reads every recognised sheet and interprets nothing. Unrecognised sheet
names are recorded rather than rejected here, so that
[`validate_loa`](https://mixedmigrationcentre.github.io/analysiskit/reference/validate_loa.md)
remains the single place that decides what is a problem.

## Usage

``` r
read_loa_workbook(path, filename = NULL)
```

## Arguments

- path:

  Path to a `.xlsx` or `.csv` file.

- filename:

  Optional original filename, for messages. Defaults to
  `basename(path)`.

## Value

A list with `sheets` (named list of data frames), `format`, `filename`,
`sheet_names` (as written in the workbook), `unknown_sheets` and
`ignored_sheets`.

## Details

Configuration sheets are read as text so their types are decided by this
file rather than by whatever readxl guessed from the first few rows. The
`analysis` sheet keeps its guessed types, so a numeric `level` column
stays numeric.

A `.csv` upload carries no sheets: it is read as the `analysis` table
alone, and `format` is `"CSV"` so the caller can say so.
