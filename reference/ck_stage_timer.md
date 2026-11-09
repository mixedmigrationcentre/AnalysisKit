# A Stage Timer for the Pipeline

Returns a function that reports the seconds elapsed since the last call,
through the same [`message()`](https://rdrr.io/r/base/message.html)
channel the rest of the pipeline uses - so the timings reach the app's
run log and the console without any new plumbing. Without them, every
statement about where a run spends its time is an extrapolation from
somewhere else's dataset.

## Usage

``` r
ck_stage_timer(verbose = TRUE)
```

## Arguments

- verbose:

  Logical. `FALSE` makes the timer a no-op.

## Value

A function of one argument, the name of the stage just finished.
