# Write One Variable-by-Group Sheet

Writes the index panel plus a set of statistic blocks to a single
worksheet and applies the MMC styling through a style collector, so the
number of openxlsx style objects stays constant regardless of the number
of blocks.

## Usage

``` r
ck_write_group_sheet(
  wb,
  sheet,
  dat,
  n_index,
  blocks,
  value_columns,
  pal,
  font_name,
  colour_scale = TRUE,
  max_colour_scale_rules = 250,
  hidden_columns = 1:3,
  index_width = 7,
  stat_width = 13,
  total_width = 5,
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

- n_index:

  Number of identifier columns on the left.

- blocks:

  List of block descriptions.

- value_columns:

  Statistic column prefixes.

- pal:

  Resolved MMC palette.

- font_name:

  Font used throughout.

- colour_scale:

  Logical, apply the per-question colour scale.

- max_colour_scale_rules:

  Rule ceiling for the colour scale.

- hidden_columns:

  Identifier columns to hide.

- index_width, stat_width, total_width:

  Column widths.

- pct_fmt:

  Excel number format for proportion rows, from
  [`ck_percent_format()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_percent_format.md).

## Value

Invisibly the number of style objects written.
