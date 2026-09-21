# The Combination Base, Spelled Out

`count_combinations` and `count_exclusive_combinations` share one
denominator: everyone who answered the question and has at least one
choice recorded. A respondent who answered but has nothing recorded at
all - never asked, or asked and left blank - is outside that base, so
the two blocks describe slightly fewer people than the question's own
choice percentages do. That is invisible in the finished workbook, where
the percentages simply look like every other percentage.

## Usage

``` r
ak_exclusive_base_note(map)
```

## Arguments

- map:

  The `choice_combinations` or `exclusive_combinations` element of a
  pipeline result: `analysis_var`, `n_in_base` and `n_no_selection`.

## Value

A character vector of sentences, or `character(0)` when every respondent
who answered is in the base.

## Details

So the number is reported per question, as a share of everyone who
answered.
[`run_analysis_locally()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_locally.md)
prints it after a run for the same reason.
