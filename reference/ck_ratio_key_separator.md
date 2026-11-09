# The analysis_var Separator Used for a Ratio

`analysistools::create_analysis()` reports a ratio's `analysis_var` as
`"numerator %/% denominator"`, and
[`ck_fast_analysis`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_fast_analysis.md)
reproduces it so the two engines agree. The string lives here rather
than at each use site so that verifying it against a new analysistools
version is a one-line job.

## Usage

``` r
ck_ratio_key_separator()
```

## Value

A single string.
