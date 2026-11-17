# Parse and Type-Check a Settings Sheet

Returns only the settings that were actually supplied, so every unset
argument keeps the pipeline's own default. Reads either the `settings`
sheet or the `route_analysis` sheet; each accepts only its own keys (the
`sheet` column of
[`loa_settings_schema()`](https://mixedmigrationcentre.github.io/analysiskit/reference/loa_settings_schema.md)).

## Usage

``` r
loa_parse_settings(sheet, sheet_name = "settings")
```

## Arguments

- sheet:

  The sheet's data frame, or `NULL`.

- sheet_name:

  `"settings"` or `"route_analysis"`.

## Value

A list with `settings` (named list, pipeline argument names) and
`problems`.
