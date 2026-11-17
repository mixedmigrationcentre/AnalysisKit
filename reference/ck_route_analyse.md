# Run the Fast Engine Over One Collapsed Route Table

Builds the derived dataset - select_multiple children named
`<variable>/<choice>`, the unit, and one unit-by-group column per
disaggregation variable - and analyses every variable for the unit and
for each unit-by-group cell in one call to
[`ck_fast_analysis()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_fast_analysis.md).

## Usage

``` r
ck_route_analyse(tab, w, groups, sm_separator = "/")
```

## Arguments

- tab:

  A list with `id`, `unit` and `vars` (named list of 0/1/NA matrices,
  one row per element of `id`).

- w:

  Respondent weights.

- groups:

  Named list of respondent-level disaggregation values.

- sm_separator:

  Unused in the derived data, which always uses `/`; kept so the
  signature mirrors the engine's.

## Value

Long results with `unit`, `variable`, `group_var`, `group_var_value`,
`choice` and the statistic columns.
