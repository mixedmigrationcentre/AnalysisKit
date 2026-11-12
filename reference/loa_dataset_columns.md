# The Dataset Columns a List of Analysis Refers To

Every column the analysis can read: the variables
[`loa_variable_coverage()`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_variable_coverage.md)
finds in the workbook (analysis variables, ratio numerators and
denominators, grouping variables, the derived-count questions, weight
and strata), the select_multiple children of each, and `uuid` when
`recreate_sm_parents` is on.

## Usage

``` r
loa_dataset_columns(workbook, header)
```

## Arguments

- workbook:

  The list from
  [`read_loa_workbook()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md),
  or a bare named list of sheets.

- header:

  The dataset's column names, in file order.

## Value

A logical vector, one element per name in `header`.
