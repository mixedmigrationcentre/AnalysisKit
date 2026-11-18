# Analyse One Route Block

Analyse One Route Block

## Usage

``` r
ck_route_block(
  data,
  def,
  block,
  group_vars,
  weight_column,
  sm_separator,
  top_n,
  label_row,
  top_countries = 0,
  full_sample = TRUE
)
```

## Arguments

- data:

  The dataset, label row removed and grouping variables renamed.

- def:

  The block definition from
  [`ck_route_blocks()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_route_blocks.md).

- block:

  The block name.

- group_vars:

  Disaggregation variables.

- weight_column:

  Weights column, or `NULL`.

- sm_separator:

  The select_multiple separator.

- top_n:

  Places per country that get a section of their own.

- label_row:

  The ONA label row, or `NULL`.

- top_countries:

  Countries that get a section of their own, most respondents first; `0`
  for all.

- full_sample:

  Logical. Report the country ranking and the `respondent_full_sample`
  questions out of every respondent (see
  [`run_route_analysis()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_route_analysis.md)).
  Default `TRUE`.

## Value

The block's rows of the
[`run_route_analysis()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_route_analysis.md)
result, or `NULL`.
