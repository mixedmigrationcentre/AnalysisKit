# The `settings` Sheet Allow-List

One row per accepted key. `arg` is the
[`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md)
argument it sets; `type` decides the coercion; `values` restricts an
enum. A key absent from this table is a fatal error.

## Usage

``` r
loa_settings_schema()
```

## Value

A data frame with `setting`, `arg`, `type` and `values`.

## Details

Defaults deliberately live in the pipeline, not here: a blank or absent
setting is simply not passed, so there is one definition of every
default.
