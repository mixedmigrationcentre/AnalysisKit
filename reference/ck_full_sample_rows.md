# Which Analysis Rows Use the Full-Sample Base, and With What Label

The `full_sample_base` and `full_sample_label` columns of the list of
analyses decide it row by row. A blank `full_sample_base` cell takes the
pipeline argument `full_sample_base` (`FALSE` unless a caller set it),
and a blank `full_sample_label` cell takes `full_sample_label`. Only
`prop_select_one` and `prop_select_multiple` rows are affected; a mean,
median or ratio is left as it is whatever the cell says.

## Usage

``` r
ck_full_sample_rows(
  loa,
  full_sample_base = FALSE,
  full_sample_label = "Not asked / no response"
)
```

## Arguments

- loa:

  The list of analyses.

- full_sample_base:

  Logical. The value for a row that leaves the cell blank (or every row,
  when the column is absent).

- full_sample_label:

  The label for a row that leaves the cell blank.

## Value

A list with `rows` (logical, one per `loa` row) and `label` (character,
one per `loa` row).
