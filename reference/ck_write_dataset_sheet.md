# Write the Analysed Dataset to a Sheet of its Own

The data is written as it is, with a styled, frozen header row and a
filter. The body is left unstyled on purpose: a style per cell would
make a large dataset slow to write and the file much bigger. Written so
the figures on the result sheets can be traced back to the respondents
behind them.

## Usage

``` r
ck_write_dataset_sheet(wb, sheet, dataset, pal, font_name)
```

## Arguments

- wb:

  An `openxlsx` workbook.

- sheet:

  Sheet name, already legal and unique.

- dataset:

  A data frame.

- pal:

  A resolved MMC palette.

- font_name:

  Font used throughout.

## Value

`NULL`, invisibly. Called for its effect on `wb`.
