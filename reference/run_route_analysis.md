# Run the Route Analysis

Pools the repeated country and place questions of 4Mi - transit
countries (Q47-Q54, with Q72 and QN8), places stopped (Q56-Q70) and most
dangerous locations (Q98-Q117) - and analyses them across all slots.
Turned on per block by the `transit_country`, `places_stop` and
`dangerous_location` settings;
[`run_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_spec.md)
calls this when any of them is `TRUE`.

## Usage

``` r
run_route_analysis(
  dataset,
  spec,
  blocks = ck_route_enabled(spec$settings),
  verbose = TRUE
)
```

## Arguments

- dataset:

  The dataset, with the ONA label row still on top (as for
  [`run_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_spec.md)).

- spec:

  An `analysis_spec` from
  [`build_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/build_analysis_spec.md).

- blocks:

  The blocks to run. Defaults to those the settings turn on.

- verbose:

  Logical. Print progress. Default `TRUE`.

## Value

A data frame, one row per cell, with `block`, `block_title`, `section`
(writing order), `level` (`overall`, `country`, `location`), `country`,
`location`, `unit_n`, `variable`, `variable_label`, `group_var` (`NA`
for the undisaggregated table), `group_var_value`, `choice`, `stat`,
`n`, `n_total`, `n_w` and `n_w_total`. `NULL` when no block is enabled
or none could run.

## Details

For each block the result has an overall section, then one section per
country for the `route_top_countries` countries with the most
respondents (default 10; 0 for all) and, for stops and dangerous
locations, one per place within the country (the `route_top_locations`
places with the most respondents, default 4). The overall section, which
also ranks every country, is disaggregated by the gender variable
(`route_gender_var`, default `Q27`) and by every grouping variable of
the `disaggregation_variables` sheet; the country and place sections are
not.

Percentages are of respondents. A respondent counts once per country or
place however many slots name it, and a choice counts as selected there
if it was selected in any of those slots. Weights come from
`weight_column`.
