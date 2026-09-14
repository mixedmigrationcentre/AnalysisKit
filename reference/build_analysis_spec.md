# Build an Analysis Specification from a List of Analysis Workbook

The single internal representation of a requested run. Everything
downstream reads this; nothing re-reads the workbook.

## Usage

``` r
build_analysis_spec(workbook, dataset = NULL)
```

## Arguments

- workbook:

  The list returned by
  [`read_loa_workbook`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md),
  or a bare named list of sheets.

- dataset:

  Optional dataset, with the ONA label row still on top.

## Value

An object of class `analysis_spec`: a list with `loa`,
`group_variables`, `rename_map`, `count_selections`,
`count_combinations`, `exclude_choices`, `settings` and `problems`.

## Details

Variable names are resolved here: the workbook is written in raw dataset
codes throughout, and the spec comes back in post-rename names, matching
the dataset
[`run_analysis_spec`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_spec.md)
will hand to the pipeline.

This never stops. Inspect `problems` (or call
[`loa_has_errors`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_has_errors.md))
before running.
