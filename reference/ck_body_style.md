# Register a Body Cell Style

The one factory behind every data-area style on both layouts: the index
panel, the statistic cells, the category column and the count cells.
Only the fill, alignment, number format, emphasis and which borders are
thick actually differ between them.

## Usage

``` r
ck_body_style(
  sg,
  pal,
  font_name,
  fill,
  halign,
  numfmt = NULL,
  deco = NULL,
  sides = c("Top", "Bottom", "Left", "Right"),
  thick = character(0)
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

- fill:

  Cell fill colour.

- halign:

  Horizontal alignment.

- numfmt:

  Optional number format ("PERCENTAGE", "NUMBER", "3").

- deco:

  Optional `textDecoration` value.

- sides:

  Which sides are drawn.

- thick:

  Which of those sides are thick.

## Value

The cache key of the style.

## Details

`deco = NULL` omits `textDecoration` entirely rather than passing `""`,
which is the distinction the original index / category styles relied on.
