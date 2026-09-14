# Derive a Select Multiple Parent Label from its Child Column Labels

`"Why did you leave?/Conflict"` and `"Why did you leave?/Economic"` give
`"Why did you leave?"`.

## Usage

``` r
ck_parent_label_from_children(parent, label_lookup, sm_separator = "/")
```

## Arguments

- parent:

  The select_multiple parent variable name.

- label_lookup:

  A named vector from
  [`ck_build_label_lookup`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_build_label_lookup.md).

- sm_separator:

  Select_multiple separator. Default `"/"`.

## Value

The derived parent label, or `NA`.
