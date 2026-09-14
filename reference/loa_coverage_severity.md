# How Bad Is a Missing Variable, by Where It Was Named

Ordinarily an absent variable costs a row of output, not correctness, so
it warns. The two exceptions are the derived analyses: the pipeline's
own validators *stop* when a `count_selections` or `count_combinations`
question is not a usable select_multiple, so a warning followed by a
hard abort would be worse than saying so up front.

## Usage

``` r
loa_coverage_severity(role)
```

## Arguments

- role:

  The `role` column of
  [`loa_variable_coverage`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_variable_coverage.md).

## Value

`"error"` or `"warning"`, one per element.
