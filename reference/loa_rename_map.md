# Build the Rename Map from the `disaggregation_variables` Sheet

Build the Rename Map from the `disaggregation_variables` Sheet

## Usage

``` r
loa_rename_map(sheet, dataset = NULL, sm_separator = "/")
```

## Arguments

- sheet:

  The `disaggregation_variables` data frame, or `NULL`.

- dataset:

  Optional dataset, used to drop rows whose `raw_data_name` is absent.

- sm_separator:

  Select_multiple separator.

## Value

A named character vector: names are `raw_data_name`, values are
`new_name`. Empty when there is nothing to rename.
