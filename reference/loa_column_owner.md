# Which Grouping Variable the Pipeline Will Attribute a Column To

Reproduces the ownership rule in
[`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md):
`Overall` first, then each grouping variable in turn, matching the fixed
substring `_<group>_`, first match wins. Reproduced rather than
approximated, so this check cannot drift from the behaviour it is
guarding.

## Usage

``` r
loa_column_owner(column, group_variables)
```

## Arguments

- column:

  A statistic column name, e.g. `stat_Region_of_origin_esa`.

- group_variables:

  Grouping variables in the order the pipeline sees them, excluding
  `Overall`.

## Value

The owning grouping variable, or `NA` when nothing matches.
