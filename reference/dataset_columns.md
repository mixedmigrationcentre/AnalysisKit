# Profile Every Column of a Dataset

Note that the counts include the ONA label row, which is still row 1 of
the data at this point: a column that is otherwise empty will show one
value.

## Usage

``` r
dataset_columns(dataset)
```

## Arguments

- dataset:

  The list returned by
  [`read_analysis_dataset()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_analysis_dataset.md).

## Value

A data frame with `Column`, `Type`, `Missing` and `Unique`.
