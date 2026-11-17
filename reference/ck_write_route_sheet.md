# Write a Route Analysis Sheet

Writes the rows it is given to one sheet, top to bottom: a band per
block (the formatter passes one block per sheet), then its sections in
order - overall, each country (most respondents first) and, under each
country, its top places. Each section lists its tables; each table is
followed directly by its disaggregations, one per grouping variable,
with the groups side by side (percentages first, then counts).

## Usage

``` r
ck_write_route_sheet(wb, sheet, route, pal, font_name, pct_fmt = "0%")
```

## Arguments

- wb:

  An `openxlsx` workbook.

- sheet:

  Sheet name.

- route:

  The data frame from
  [`run_route_analysis()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_route_analysis.md).

- pal:

  The MMC palette.

- font_name:

  Font used throughout.

- pct_fmt:

  Excel number format for percentages.

## Value

`NULL`, invisibly. Called for its effect on `wb`.
