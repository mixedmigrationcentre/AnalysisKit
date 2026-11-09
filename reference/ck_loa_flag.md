# Read a Logical Flag Column from an LOA

A spreadsheet delivers TRUE/FALSE as a logical, as text, or as 1/0
depending on how the cell was typed. Anything not recognisably true
reads as `FALSE`, which is the documented meaning of a blank cell: no
silent imputation, and the same answer in both engines.

## Usage

``` r
ck_loa_flag(x)
```

## Arguments

- x:

  One LOA column.

## Value

A logical vector with no `NA`.
