# Settings That Belong to the Export, Not the Pipeline

These keys are accepted in the `settings` sheet but are read by
[`ak_export_results()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ak_export_results.md)
rather than passed to
[`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md),
which has no argument of that name.

## Usage

``` r
loa_export_settings()
```

## Value

A character vector of setting names.
