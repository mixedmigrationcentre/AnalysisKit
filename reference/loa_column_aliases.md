# Former Column Names and the Names They Now Read As

`full_sample_base` became `sample_base` and `full_sample_label` became
`na_label`. A workbook that still uses the former names reads exactly as
before.

## Usage

``` r
loa_column_aliases()
```

## Value

A named list, one element per sheet: a named character vector whose
names are the former column names and values the current ones.
