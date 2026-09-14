# Accept a Dataset in Any of the Three Useful Shapes

A path, the list
[`read_analysis_dataset()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_analysis_dataset.md)
returns, or a bare data frame. The last is what makes an in-memory
dataset - one already cleaned in the session - usable without writing it
out to a file first.

## Usage

``` r
as_analysis_dataset(dataset, name = NULL)
```

## Arguments

- dataset:

  A path, a dataset list, or a data frame.

- name:

  Name to record when a bare data frame is given.

## Value

A dataset list with `data`, `extension`, `filename` and `size`.
