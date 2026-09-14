# Register a Style and Return its Key

Memoises
[`openxlsx::createStyle()`](https://rdrr.io/pkg/openxlsx/man/createStyle.html)
so identical styles are built once and share a single style object at
save time.

## Usage

``` r
ck_style(sg, ...)
```

## Arguments

- sg:

  A style grid from
  [`ck_new_style_grid()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_new_style_grid.md).

- ...:

  Arguments passed to
  [`openxlsx::createStyle()`](https://rdrr.io/pkg/openxlsx/man/createStyle.html).

## Value

The cache key of the style.
