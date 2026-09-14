# Write One Question-Block Sheet

Each question becomes a small table: the question label on top, the
disaggregation variable band under it, then a header row naming every
group with its sample size, then one row per answer category.
Percentages sit on the left panel and the matching counts on the right,
separated by a spacer column, so a figure and its count can be read
without scrolling.

## Usage

``` r
ck_write_block_sheet(
  wb,
  sheet,
  dat,
  blocks,
  block_group,
  value_columns,
  total_columns,
  pal,
  font_name,
  order_per_question = TRUE,
  colour_scale = TRUE,
  max_colour_scale_rules = 250,
  category_width = 46,
  group_width = 14,
  pct_fmt = ck_percent_format(0)
)
```

## Arguments

- wb:

  An openxlsx workbook.

- sheet:

  Sheet name (the sheet is created here).

- dat:

  The rows for this sheet.

- blocks:

  Blocks to show, in column order.

- block_group:

  Grouping variable of each block.

- value_columns:

  Statistic column prefixes; the first is the one shown.

- total_columns:

  Count column prefixes.

- pal:

  Resolved MMC palette.

- font_name:

  Font used throughout.

- order_per_question:

  Logical. Order each question's groups by its own denominator, largest
  first, instead of following the sheet-wide order.

- colour_scale:

  Logical, shade the percentage block of each question.

- max_colour_scale_rules:

  Rule ceiling for the colour scale.

- category_width:

  Width of the category columns.

- group_width:

  Width of the group value columns.

- pct_fmt:

  Excel number format for proportion rows, from
  [`ck_percent_format()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_percent_format.md).

## Value

Invisibly the number of style objects written.
