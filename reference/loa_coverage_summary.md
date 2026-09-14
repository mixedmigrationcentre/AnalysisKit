# Summarise Variable Coverage, One Row per Variable

The display form: each variable once, with every place it is used and
whether the dataset has it.

## Usage

``` r
loa_coverage_summary(coverage)
```

## Arguments

- coverage:

  The output of
  [`loa_variable_coverage`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_variable_coverage.md).

## Value

A data frame with `Variable`, `Used as`, `References` and `Status`.
