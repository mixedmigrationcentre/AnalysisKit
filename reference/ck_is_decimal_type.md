# Which Rows Hold a Decimal Rather Than a Percentage

`stat` is a proportion for the proportion and combination analyses, so
those rows take the percentage format. `mean`, `median` and `ratio` are
numbers in the question's own units and take the plain number format - a
ratio of 2.4 children per household displayed as a percentage reads as
240%.

## Usage

``` r
ck_is_decimal_type(analysis_type)
```

## Arguments

- analysis_type:

  The `analysis_type` column, any case.

## Value

A logical vector, `TRUE` where the row is a plain number.

## Details

The rule lives here because it is applied in two places, the matrix
layout and the blocks layout, and an analysis type added to one and not
the other is formatted inconsistently depending on which layout was
asked for.
