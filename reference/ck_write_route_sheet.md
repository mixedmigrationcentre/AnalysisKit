# Write a Route Analysis Sheet

One block per sheet, laid out as MMC's route tables:

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

  The rows of
  [`run_route_analysis()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_route_analysis.md)
  for one block.

- pal:

  The MMC palette.

- font_name:

  Font used throughout.

- pct_fmt:

  Excel number format for percentages.

## Value

`NULL`, invisibly. Called for its effect on `wb`.

## Details

1.  The country ranking: every country, as a share of respondents,
    overall and by each disaggregation.

2.  For each follow-up question, a wide table: `Overall`, then each
    country (most respondents first) followed by its top places, as
    columns; then, two rows below, the same question overall and by each
    disaggregation.

Every table is a percentage panel and, one column to the right, the same
table in counts.
