# Run a Pipeline from an Analysis Specification

The only place the workbook and the analysis pipeline meet.

## Usage

``` r
run_analysis_spec(dataset, spec, pipeline = NULL, ...)
```

## Arguments

- dataset:

  The dataset, with the ONA label row still on top.

- spec:

  An `analysis_spec` from
  [`build_analysis_spec`](https://mixedmigrationcentre.github.io/analysiskit/reference/build_analysis_spec.md).

- pipeline:

  The function to call. Injectable so the assembly can be tested without
  the analysis code loaded.

- ...:

  Further arguments passed to `pipeline`, overriding the spec. Used by
  the app for run-time concerns such as `verbose`.

## Value

Whatever `pipeline` returns.
