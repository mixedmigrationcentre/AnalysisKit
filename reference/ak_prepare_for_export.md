# Prepare the Wide Table for the Formatter

Two things about the pipeline's wide table need attention before it is
formatted, and both come from the separator rows.

## Usage

``` r
ak_prepare_for_export(wide, layout = c("blocks", "matrix"))
```

## Arguments

- wide:

  The `combined_results` table.

- layout:

  The formatter layout the table is headed for.

## Value

`wide`, ready to format.

## Details

[`ck_insert_count_separators()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_insert_count_separators.md)
adds a blank spacer and a heading above each derived block, marked in a
`row_type` column that it appends at the *end* of the table. Left alone:

- the formatter reads everything after the first `stat_` column as a
  statistic, so a trailing `row_type` is reported as an unrecognised
  column and dropped with a warning;

- the marker rows carry no `sector`, so splitting sheets by sector sends
  them all to a sheet of their own called "not specified".

The spacer and heading exist to separate a derived block from the choice
rows above it in the **matrix** layout, where everything is one
continuous table. The **blocks** layout already gives every question its
own titled table, so there the markers are redundant and are removed; in
the matrix layout they are kept and `row_type` is moved in among the
identifier columns, where the formatter expects identifiers to be.
