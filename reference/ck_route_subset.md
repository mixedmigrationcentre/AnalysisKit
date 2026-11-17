# Keep Some Rows of a Collapsed Route Table

Keep Some Rows of a Collapsed Route Table

## Usage

``` r
ck_route_subset(tab, keep)
```

## Arguments

- tab:

  A list with `id`, `unit` and `vars`, as for
  [`ck_route_analyse()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_route_analyse.md).

- keep:

  Logical, one element per row.

## Value

`tab` with only the kept rows.
