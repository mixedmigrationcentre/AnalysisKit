# Export Settings for a Completed Run

Derived from the run rather than hard-coded, so the split stays correct
when the workbook asks for different `value_columns`. With the defaults
this reproduces the settings behind `4Mi_results_QN6.xlsx`: the blocks
layout, one sheet per sector, `stat` as the statistic and `n` /
`n_total` as the counts.

## Usage

``` r
ak_export_settings(results, spec)
```

## Arguments

- results:

  The list returned by
  [`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md).

- spec:

  The `analysis_spec` behind the run.

## Value

A named list of arguments for
[`format_my_xlsx_variable_x_group()`](https://mixedmigrationcentre.github.io/analysiskit/reference/format_my_xlsx_variable_x_group.md).

## Details

`length(c(value_columns, total_columns))` must equal the number of
columns the pipeline wrote per group block, or the formatter cuts the
blocks in the wrong places. Splitting one list guarantees that by
construction.
