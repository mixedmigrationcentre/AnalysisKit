# Move Each Derived Block Under Its Own Question

The selection counts and choice combinations are appended to the LOA, so
left alone they land in a lump at the bottom. Only the derived rows
move; every other row keeps the order the DAP put it in, so a DAP that
deliberately analyses the same variable at two separate points is not
silently reshuffled. A derived block whose question is not otherwise in
the DAP stays at the end.

## Usage

``` r
ck_order_count_blocks(
  wide_table,
  count_map,
  derived_types = c("count_select_multiple", "combination_select_multiple",
    "exclusive_combination_select_multiple")
)
```

## Arguments

- wide_table:

  The wide results table.

- count_map:

  The derived map from
  [`ck_derived_map`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_derived_map.md)
  (or the `map` from
  [`ck_add_selection_counts`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_add_selection_counts.md),
  for compatibility).

- derived_types:

  The `analysis_type` values that mark a derived block, in the order the
  blocks should appear.

## Value

`wide_table` with the derived blocks repositioned.

## Details

Where a question has both, the order of `derived_types` decides which
block comes first: counts, then combinations.
