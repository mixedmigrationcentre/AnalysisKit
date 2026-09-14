# Stack One LOA per Grouping Variable into a Single LOA

`create_analysis()` accepts an LOA whose rows carry different
`group_var` values, so the whole cross-tab set is estimated in one call
instead of looping and joining blocks afterwards - which is what makes
the rows align by construction.

## Usage

``` r
ck_stack_loa(
  loa,
  dataset,
  group_variables = c("Overall"),
  sm_separator = "/",
  overall_label = "Overall",
  fallback_level = 0.95,
  verbose = TRUE
)
```

## Arguments

- loa:

  The list of analyses.

- dataset:

  The analysis dataset.

- group_variables:

  Grouping variables; `overall_label` means the ungrouped analysis.

- sm_separator:

  Select_multiple separator. Default `"/"`.

- overall_label:

  Label for the ungrouped analysis. Default `"Overall"`.

- fallback_level:

  Placeholder level for rows with an empty `level` cell. Default `0.95`.
  See
  [`ck_level_info`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_level_info.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The stacked LOA, containing only the columns `create_analysis()`
understands, with a `"level_supplied"` attribute.
