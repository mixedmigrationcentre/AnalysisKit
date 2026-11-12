# Which Estimation Engine Each Analysis Will Use

The `level` cell of the `analysis` sheet is the largest performance
decision in the application, and it is made in the workbook rather than
in the code. A row with a level goes to
`analysistools::create_analysis()`, which builds a survey design and
re-subsets it once per level of the grouping variable; a row without one
goes to the fast tabulation engine, whose cost does not grow with the
disaggregation at all. The gap is a factor of 136 at a 200-level
grouping variable.

## Usage

``` r
loa_engine_split(spec)
```

## Arguments

- spec:

  An `analysis_spec` from
  [`build_analysis_spec`](https://mixedmigrationcentre.github.io/analysiskit/reference/build_analysis_spec.md).

## Value

A list with `engine`, `analyses`, `survey`, `fast`, `group_variables`
and `survey_estimations` - the last being the number of
analysis-by-grouping-variable estimations the survey engine will
perform.

## Details

A level only buys `stat_low` and `stat_upp`. Under `engine = "auto"`, a
proportion or mean whose level would produce an interval that
`value_columns` does not report is counted as fast, because that is
where the pipeline sends it. Medians and ratios with a level are always
counted as survey.

This reports the split before the run, so nobody discovers it from a
progress bar that has stopped moving.
