# Every Dataset Variable the Workbook Names, and Whether It Is There

The check that runs the moment both files are in: each variable the
workbook refers to, where it is referred to, and whether the uploaded
dataset actually has it. Presence is judged by
[`loa_var_present`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_var_present.md),
so a select_multiple parent counts when its child columns are present
even though ONA did not export the concatenated parent column.

## Usage

``` r
loa_variable_coverage(workbook, dataset, sm_separator = NULL)
```

## Arguments

- workbook:

  The list from
  [`read_loa_workbook`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md),
  or a bare named list of sheets.

- dataset:

  The dataset, with the ONA label row still on top.

- sm_separator:

  Select_multiple separator. Read from the `settings` sheet when not
  given.

## Value

A data frame with `variable`, `role`, `sheet`, `row` and `present`, one
row per reference.

## Details

Names are matched as written in the workbook - raw dataset codes -
against the raw dataset, before any renaming.
