# Which Rows Carry a Level Nobody Will See

A row's `level` asks for a confidence interval, and the interval only
reaches the output through `stat_low` / `stat_upp` in `value_columns`.
Where neither is asked for, the survey engine would compute an interval
and discard it, so under `engine = "auto"` the row is tabulated instead.

## Usage

``` r
ck_level_is_redundant(analysis_type, supplied, value_columns, engine = "auto")
```

## Arguments

- analysis_type:

  Character vector of analysis types.

- supplied:

  Logical vector: was a level supplied for the row.

- value_columns:

  The statistic columns the run reports.

- engine:

  `"auto"`, `"fast"` or `"survey"`.

## Value

A logical vector, `TRUE` for each row to tabulate in the survey engine's
layout.

## Details

Medians and ratios stay on the survey engine whatever `value_columns`
says: the survey median interpolates where the fast one reports an
observed value, and the two engines describe a ratio's counts
differently, so moving either could change a number in the workbook.
