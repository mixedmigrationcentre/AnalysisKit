# Run an Analysis Locally, From Two Files to a Results Workbook

The whole Analysis Kit workflow as one call: read the dataset and the
List of Analysis, check them against each other, run every analysis the
workbook asks for across every disaggregation it declares, and write the
results to an MMC-branded Excel workbook.

## Usage

``` r
run_analysis_locally(dataset, loa, output_folder = NULL, verbose = TRUE, ...)

# S3 method for class 'analysis_run'
print(x, ...)
```

## Arguments

- dataset:

  A dataset path (`.csv` / `.xlsx`), the list from
  [`read_analysis_dataset()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_analysis_dataset.md),
  or a data frame with the ONA label row still on top.

- loa:

  A List of Analysis path, or the list from
  [`read_loa_workbook()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md).
  A `.csv` carries no sheets and is read as the `analysis` table alone,
  so a configured run needs `.xlsx`.

- output_folder:

  Folder to write the results workbook into. It must already exist and
  be writable, and both are checked before the analysis starts. `NULL`
  runs the analysis and writes nothing.

- verbose:

  Logical. Print the pipeline's progress as it arrives. The log is kept
  in the result either way.

- ...:

  Ignored.

- x:

  An `analysis_run` object.

## Value

An object of class `analysis_run`: a list with `results` (the full
pipeline result), `spec`, `dataset`, `coverage`, `problems`,
`output_path`, `log`, `elapsed` and `save_error`. Print it for a
summary.

## What it will not do

The run **stops before doing any work** when the List of Analysis has a
fatal problem, and the error names every one of them. That is
deliberate: the alternative is a workbook full of plausible numbers
attributed to the wrong disaggregation. Call
[`check_analysis_inputs()`](https://mixedmigrationcentre.github.io/analysiskit/reference/check_analysis_inputs.md)
first to see the problems without triggering the run.

Warnings do not stop a run - they mean less output, not wrong output -
and they arrive in `$log`, which is worth reading rather than skipping.
A grouping variable absent from the dataset, a `Don't know` label that
matched nothing, a town set aside for having four interviews: all of
them are warnings, and all of them change what is in the file.

## The output file

Named `analysiskit_<dataset stem>_<YYYYmmdd-HHMMSS>.xlsx`, and an
existing file is never overwritten - a second run in the same second
gets a `_1` suffix. The workbook's readme sheet records the dataset, the
List of Analysis, the disaggregations and every setting that was
applied, so a file found six months later can be traced back to what
produced it.

Pass `output_folder = NULL` to run without writing anything. The results
are returned either way.

## See also

[`check_analysis_inputs()`](https://mixedmigrationcentre.github.io/analysiskit/reference/check_analysis_inputs.md)
to look before you leap,
[`run_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_spec.md)
to run an already-built specification,
[`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md)
to bypass the workbook entirely.

## Examples

``` r
if (FALSE) { # \dontrun{
# The usual case
run <- run_analysis_locally(
  dataset       = "data/mmr_analysis_data_25_26.xlsx",
  loa           = "resources/loa_template.xlsx",
  output_folder = "output"
)

run                      # summary, including the saved path
run$output_path          # the workbook that was written
run$log                  # what the pipeline reported
run$results$combined_results[1:5, 1:6]

# Check first, run second
checks <- check_analysis_inputs("data/export.xlsx", "resources/loa.xlsx")
if (checks$ready) {
  run <- run_analysis_locally(checks$dataset, "resources/loa.xlsx", "output")
}

# Analyse without writing anything
run <- run_analysis_locally("data/export.xlsx", "resources/loa.xlsx")

# The same List of Analysis over a folder of exports
runs <- lapply(
  list.files("data", pattern = "[.]xlsx$", full.names = TRUE),
  run_analysis_locally,
  loa = "resources/loa.xlsx",
  output_folder = "output"
)
} # }
```
