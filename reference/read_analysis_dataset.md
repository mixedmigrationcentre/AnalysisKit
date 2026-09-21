# Read a Dataset from a Path

Reads a `.csv` or `.xlsx` research dataset and reports what it found.
The file is read as it is: **row 1 of an ONA export is the label row and
is left in place**, because that is what
[`build_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/build_analysis_spec.md)
and
[`run_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_spec.md)
expect. The label row is set aside by the pipeline itself, under the
`skip_label_row` setting.

## Usage

``` r
read_analysis_dataset(path)
```

## Arguments

- path:

  Path to a `.csv` or `.xlsx` file. Only the first sheet of an `.xlsx`
  is read.

## Value

A list with `data`, `extension`, `filename` and `size`.

## Details

CSV blanks and the strings `NA`, `N/A` and `NULL` are read as missing.
Column names are preserved exactly (`check.names = FALSE`), because the
select_multiple child columns carry choice labels that R would otherwise
mangle.

## See also

[`dataset_overview()`](https://mixedmigrationcentre.github.io/analysiskit/reference/dataset_overview.md)
and
[`dataset_columns()`](https://mixedmigrationcentre.github.io/analysiskit/reference/dataset_columns.md)
to inspect the result,
[`read_loa_workbook()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md)
for the other half of a run.

## Examples

``` r
path <- tempfile(fileext = ".csv")
utils::write.csv(
  data.frame(Q27 = c("What is your gender?", "Female", "Male")),
  path,
  row.names = FALSE
)

dataset <- read_analysis_dataset(path)
dataset_overview(dataset)
#>          Measure                Value
#> 1      File name file186c45cc07bd.csv
#> 2      File type                  CSV
#> 3      File size             45 bytes
#> 4           Rows                    3
#> 5        Columns                    1
#> 6 Duplicate rows                    0
```
