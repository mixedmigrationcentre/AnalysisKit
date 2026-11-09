# Compose the Question Label for a Ratio

A ratio's `analysis_var` is the composite key built by
[`ck_loa_var_key`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_loa_var_key.md),
which is never a column of the export, so the ordinary label lookup
misses it and the output would show raw question codes where every other
row shows label text.

## Usage

``` r
ck_ratio_label(
  analysis_var,
  label_lookup,
  sm_separator = "/",
  joiner = " per "
)
```

## Arguments

- analysis_var:

  One `analysis_var` value.

- label_lookup:

  A named vector from
  [`ck_build_label_lookup`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_build_label_lookup.md).

- sm_separator:

  Separator between parent and choice. Default `"/"`.

- joiner:

  Text placed between the two labels. Default `" per "`.

## Value

A single label, or `NA_character_` when either half is unlabelled or the
value is not a ratio key.

## Details

Both halves must resolve, or the raw key is kept: "How many children are
travelling with you? per Q11" reads worse than "Q12 \\ least says
plainly that nothing was labelled.
