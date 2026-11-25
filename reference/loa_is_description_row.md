# Is This the Description Row

The row directly under the header is the description row when every
non-blank cell in it is the description of its own column, and at least
one cell is filled. A row where any cell holds something else is data,
so a description row that has been typed over is read, and checked, like
any other row rather than silently dropped.

## Usage

``` r
loa_is_description_row(sheet, row)
```

## Arguments

- sheet:

  The sheet's (normalised) name.

- row:

  A one-row data frame read as text, named by the header.

## Value

`TRUE` or `FALSE`.
