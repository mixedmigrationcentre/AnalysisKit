# Check a Dataset and a List of Analysis Against Each Other

Everything
[`run_analysis_locally()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_locally.md)
checks before it commits to a run, with nothing run. Use it to see what
a workbook would do to a dataset - and what it would refuse to do -
without waiting for an analysis.

## Usage

``` r
check_analysis_inputs(dataset, loa, output_folder = NULL)

# S3 method for class 'analysis_readiness'
print(x, ...)
```

## Arguments

- dataset:

  A dataset path, the list from
  [`read_analysis_dataset()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_analysis_dataset.md),
  or a plain data frame with the ONA label row still on top.

- loa:

  A List of Analysis path, or the list from
  [`read_loa_workbook()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md).

- output_folder:

  Optional folder the results would be written to. When given it is
  checked for existence and write access now, so a long run is never
  lost to a read-only destination.

- x:

  An `analysis_readiness` object.

- ...:

  Ignored.

## Value

An object of class `analysis_readiness`: a list with `ready`,
`problems`, `counts`, `coverage`, `sheets`, `spec`, `dataset` and
`folder_problem`. Print it for a summary.

## Details

**This never stops.** A workbook with fatal problems comes back
described rather than thrown, so every problem is visible at once
instead of one per attempt. `$ready` is the answer to "would a run go
ahead".

The severity rule, inherited from
[`validate_loa()`](https://mixedmigrationcentre.github.io/analysiskit/reference/validate_loa.md):
**fatal** when the run would produce wrong or misleading output,
**warning** when it would only produce less output. So a grouping
variable that is missing from the dataset warns - one fewer column
block - while two `new_name` values where one contains the other is
fatal, because the column map would then attribute columns to the wrong
disaggregation.

## See also

[`validate_loa()`](https://mixedmigrationcentre.github.io/analysiskit/reference/validate_loa.md)
for the checks themselves,
[`loa_variable_coverage()`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_variable_coverage.md)
for the per-reference variable table.

## Examples

``` r
if (FALSE) { # \dontrun{
checks <- check_analysis_inputs(
  dataset = "data/mmr_analysis_data_25_26.xlsx",
  loa     = "resources/loa_template.xlsx"
)

checks                              # the summary
ak_problems_display(checks$problems) # every problem, errors first
subset(checks$coverage, !present)    # variables the dataset does not have
} # }
```
