# Write All Queued Styles to a Worksheet

One `addStyle()` call per distinct style, with `stack = FALSE`, which is
what keeps `saveWorkbook()` fast.

## Usage

``` r
ck_flush_styles(sg, wb, sheet)
```

## Arguments

- sg:

  A style grid from
  [`ck_new_style_grid()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_new_style_grid.md).

- wb:

  An `openxlsx` workbook.

- sheet:

  Sheet name.

## Value

Invisibly the number of style objects written.
