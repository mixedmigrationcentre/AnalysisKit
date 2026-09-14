# Write the Branded Readme Sheet

An MMC-branded cover sheet holding the sample composition across every
disaggregation variable, a directory of the sheets in the workbook, the
colour key and the reading notes.

## Usage

``` r
ck_write_readme_sheet(
  wb,
  sheet,
  pal,
  font_name,
  composition = NULL,
  sheet_table,
  split_by = "none",
  hidden_columns = integer(0),
  hidden_names = character(0),
  dropped_groups = character(0),
  readme_text = NULL,
  pct_fmt = ck_percent_format(0)
)
```

## Arguments

- wb:

  An openxlsx workbook.

- sheet:

  Readme sheet name (already added to the workbook).

- pal:

  Resolved MMC palette.

- font_name:

  Font used throughout.

- composition:

  Output of
  [`ck_sample_composition()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_sample_composition.md),
  or `NULL`.

- sheet_table:

  Data frame with `sheet` and `content`.

- split_by:

  The resolved `split_by` specification.

- hidden_columns:

  Identifier columns hidden on the table sheets.

- hidden_names:

  Names of those columns, used in the notes.

- dropped_groups:

  Group labels left out for having no respondents.

- readme_text:

  Optional character vector of extra lines.

- pct_fmt:

  Excel number format for proportions, from
  [`ck_percent_format()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_percent_format.md).
  Used both for the sample-composition percentages and for the
  number-format note, so the note cannot drift from the sheets.

## Value

Invisibly `NULL`.

## Details

This sheet is small and written once, so it uses `addStyle()` directly
rather than the style collector.
