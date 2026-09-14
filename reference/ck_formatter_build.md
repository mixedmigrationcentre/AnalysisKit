# Which Build of the Formatter Is Loaded

Two files in this project define
[`format_my_xlsx_variable_x_group()`](https://mixedmigrationcentre.github.io/analysiskit/reference/format_my_xlsx_variable_x_group.md),
so [`source()`](https://rdrr.io/r/base/source.html) order decides which
definition survives - silently, and with no error, because the
signatures overlap. This is printed on every run so the answer is never
in doubt.

## Usage

``` r
ck_formatter_build()
```

## Value

A one-line build description.
