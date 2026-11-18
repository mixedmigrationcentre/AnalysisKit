# Rank the Countries or Places Respondents Named

The share of respondents in a unit who named each value in at least one
slot. Counted directly rather than through one-hot columns, which on a
full 4Mi round would mean a column for every place in every country.

## Usage

``` r
ck_route_rank(id, unit, value, variable, w, groups, base_id = NULL)
```

## Arguments

- id:

  The respondent of each slot.

- unit:

  The unit each slot is ranked within (`"Overall"`, or the country).

- value:

  The country or place the slot names; `NA` is left out of both
  numerator and denominator.

- variable:

  The variable name to report.

- w:

  Respondent weights.

- groups:

  Named list of respondent-level disaggregation values.

- base_id:

  The respondents of the denominator, for a ranking with a single unit
  (`"Overall"`); `NULL` (the default) for those who named at least one
  value. The full sample passes every respondent, so those who named
  nothing, or only None or Refused, stay in the base.

## Value

Rows in the shape of
[`ck_route_analyse()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_route_analyse.md).
