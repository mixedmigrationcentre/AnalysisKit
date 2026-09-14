# Insert a Spacer and a Heading Above Each Derived Block

Without a break, the derived rows sit flush against the question's own
choice rows and read as a few more choices - which they are not, and
which would invite someone to add them into a total. A `row_type` column
marks every row `"data"`, `"spacer"` or `"heading"` so the export step
can style or skip them without guessing from blank cells.

## Usage

``` r
ck_insert_count_separators(
  wide_table,
  count_map,
  heading = "Select multiple count",
  spacer = TRUE,
  derived_types = c("count_select_multiple", "combination_select_multiple",
    "exclusive_combination_select_multiple")
)
```

## Arguments

- wide_table:

  The wide results table, already ordered by
  [`ck_order_count_blocks`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_order_count_blocks.md).

- count_map:

  The derived map from
  [`ck_derived_map`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_derived_map.md)
  (or the `map` from
  [`ck_add_selection_counts`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_add_selection_counts.md),
  for compatibility).

- heading:

  Heading text. A single value applies to every derived block; a vector
  named by `analysis_type` sets one per block type. `""` inserts no
  heading row.

- spacer:

  Logical. Insert the blank row. Named by `analysis_type` to set one per
  block type. Default `TRUE`.

- derived_types:

  The `analysis_type` values that mark a derived block.

## Value

`wide_table` with the separator rows inserted and a `row_type` column
added.

## Details

Called *after* the column map is built, so `row_type` is never read as a
statistic column.
