# Write a List of Analysis Workbook

Writes the sheets as a styled List of Analysis workbook: a `readme`
sheet with one section per sheet, in sheet order; a navy header; an
italic row of column descriptions under the header of
`analysis_variables`, `disaggregation_variables` and `settings` (skipped
by
[`read_loa_workbook()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md));
a `description` column in `settings` and `route_analysis`; and drop-down
lists for `analysis_type`, `sample_base` and `include`.

## Usage

``` r
ak_write_loa(sheets, path, dropdown_rows = 1000L)
```

## Arguments

- sheets:

  A named list of data frames, named by sheet (`analysis_variables`,
  `disaggregation_variables`, `settings`, ...). Former column names
  (`full_sample_base`, `full_sample_label`) are written under their
  current names. Empty optional sheets are left out.

- path:

  Where to write the `.xlsx`.

- dropdown_rows:

  Number of data rows the drop-down lists cover.

## Value

`path`, invisibly.

## Details

A drop-down list is one rule over a range of cells, so its size in the
file does not depend on how many rows it covers.

## Examples

``` r
sheets <- list(
  analysis_variables = data.frame(
    analysis_type = "prop_select_one",
    analysis_var = "Q27",
    section = "Demographics"
  ),
  settings = data.frame(setting = "sm_separator", value = "/")
)
ak_write_loa(sheets, tempfile(fileext = ".xlsx"))
```
