# Can the Analysis Be Run

Both files in, no fatal check, and somewhere to put the result. The
destination is part of the gate because a run that cannot be saved
wastes the wait.

## Usage

``` r
ak_can_run(states)
```

## Arguments

- states:

  A vector from
  [`ak_step_states()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ak_step_states.md).

## Value

`TRUE` when the run should go ahead.
