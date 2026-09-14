# Validate a List of Analysis Workbook

Every check the schema defines, in one place. Never stops: it returns
the problems so the app can show all of them at once instead of one per
run.

## Usage

``` r
validate_loa(workbook, dataset = NULL)
```

## Arguments

- workbook:

  The list returned by
  [`read_loa_workbook`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md),
  or a bare named list of sheets.

- dataset:

  Optional dataset, with the ONA label row still on top. When supplied,
  variable-existence and column-ownership checks are run.

## Value

A data frame with `sheet`, `row`, `severity` and `message`.

## Details

The severity rule, applied throughout: **fatal** when the run would
produce wrong or misleading output; **warning** when it would only
produce less output.
