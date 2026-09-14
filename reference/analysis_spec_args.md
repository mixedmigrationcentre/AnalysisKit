# Assemble the Pipeline Call for a Specification

Split out from
[`run_analysis_spec`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_spec.md)
so the argument list can be inspected and tested without running an
analysis.

## Usage

``` r
analysis_spec_args(dataset, spec)
```

## Arguments

- dataset:

  The dataset, with the ONA label row still on top.

- spec:

  An `analysis_spec`.

## Value

A named list of arguments for
[`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md).
