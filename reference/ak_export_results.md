# Write a Completed Run to a Folder

Called once, from the Run handler, and only after the analysis has
finished without error. Returns the path written so the interface can
name it.

## Usage

``` r
ak_export_results(
  results,
  spec,
  folder,
  dataset_name,
  when = Sys.time(),
  formatter = NULL,
  verbose = FALSE
)
```

## Arguments

- results:

  The list returned by
  [`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md).

- spec:

  The `analysis_spec` behind the run.

- folder:

  Destination folder, already chosen by the user.

- dataset_name:

  Original dataset filename, used for the output name.

- when:

  The run time.

- formatter:

  The export function. Injectable so the wiring can be tested without
  building a real workbook.

- verbose:

  Passed to the formatter.

## Value

The full path of the file written.
