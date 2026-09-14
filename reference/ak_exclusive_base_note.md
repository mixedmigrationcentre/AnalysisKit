# The Exclusive-Combination Base, Spelled Out

`count_exclusive_combinations` rows sit on a smaller denominator than
every other table in the output: a respondent who selected a listed
choice *together with* an unlisted one belongs to none of the categories
and leaves the base. That is the intended meaning of "only", but it is
invisible in the finished workbook - the percentages simply look like
every other percentage.

## Usage

``` r
ak_exclusive_base_note(exclusive_map)
```

## Arguments

- exclusive_map:

  The `exclusive_combinations` element of a pipeline result:
  `analysis_var`, `n_in_base` and `n_mixed_dropped`.

## Value

A character vector of sentences, or `character(0)` when no respondent
was dropped.

## Details

So the number is reported per question, as a share of everyone who
answered.
[`run_analysis_locally()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_locally.md)
prints it after a run for the same reason.
