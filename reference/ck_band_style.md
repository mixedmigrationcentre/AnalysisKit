# Register a Header Band Style

The three coloured header bands share everything except size, fill and
alignment.

## Usage

``` r
ck_band_style(
  sg,
  pal,
  font_name,
  size,
  fill,
  halign,
  wrap = FALSE,
  border_colour = pal[["grid"]]
)
```

## Arguments

- sg:

  A style grid from
  [`ck_new_style_grid()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_new_style_grid.md).

- pal:

  Resolved MMC palette.

- font_name:

  Font used throughout.

- size:

  Font size.

- fill:

  Band fill colour.

- halign:

  Horizontal alignment.

- wrap:

  Logical. Wrap the text.

- border_colour:

  Colour of the header gridlines.

## Value

The cache key of the style.
