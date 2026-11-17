# Label One Section of a Route Block

Drops choices nobody in the unit selected and orders the rest by
percentage, largest first.

## Usage

``` r
ck_route_section(res, level, country, location, unit_n)
```

## Arguments

- res:

  Rows of
  [`ck_route_analyse()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_route_analyse.md)
  for one unit.

- level:

  `overall`, `country` or `location`.

- country, location:

  The unit.

- unit_n:

  Respondents in the unit.

## Value

The section's rows.
