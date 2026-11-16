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
  dataset = NULL,
  include_dataset = spec$settings$include_dataset %||% FALSE,
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

- dataset:

  The data frame the analysis was run on. Written to a sheet of its own
  when `include_dataset` is `TRUE`, and otherwise unused.

- include_dataset:

  Logical. Add the dataset to the workbook as a sheet named `dataset`.
  Defaults to the List of Analysis's `settings/include_dataset`, and to
  `FALSE` when that is not set.

- formatter:

  The export function. Injectable so the wiring can be tested without
  building a real workbook.

- verbose:

  Passed to the formatter.

## Value

The full path of the file written.
