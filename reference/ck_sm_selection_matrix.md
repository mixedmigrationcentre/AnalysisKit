# Who Selected Which Choice

The single place that decides whether a select_multiple cell counts as a
selection, so "selected" can never mean two things in one run. Two
export styles are detected per column:

## Usage

``` r
ck_sm_selection_matrix(
  dataset,
  parent,
  sm_separator = "/",
  sm_child_style = c("auto", "label", "dummy"),
  exclude_choices = NULL,
  ignore_case = TRUE,
  cache = NULL
)
```

## Arguments

- dataset:

  A dataframe.

- parent:

  The select_multiple parent variable name.

- sm_separator:

  Separator between parent and choice. Default `"/"`.

- sm_child_style:

  `"auto"` (default), `"label"` or `"dummy"`.

- exclude_choices:

  Optional choice labels to leave out entirely.

- ignore_case:

  Logical. Match `exclude_choices` case-insensitively.

- cache:

  Optional environment memoising the result per parent. One run of the
  pipeline asks for the same matrix up to four times - the selection
  counts, the two combination blocks and the conversion to 0/1 - and
  each pass re-reads and re-trims every child column of the export. The
  cache is only valid while those child columns are unchanged, which the
  pipeline guarantees by building all four before
  [`ck_sm_children_to_binary`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_sm_children_to_binary.md)
  rewrites them. Pass `NULL` (the default) anywhere that guarantee does
  not hold.

## Value

`NULL` if the parent has no children, otherwise a list with `selected`
(logical matrix), `columns`, `suffixes` and `styles`.

## Details

- `"label"`:

  MMC 4Mi ONA style - the cell holds the choice label when selected and
  is blank otherwise, so any non-blank value is a selection. This is the
  only safe rule for these exports: real choice labels include "None",
  "No" and "Refused", and treating those strings as negatives would zero
  out genuine answers.

- `"dummy"`:

  The cell holds 0/1 or TRUE/FALSE, so only 1 / TRUE is a selection.

Detection is conservative: a column is a dummy only when *every*
non-blank value in it is one of 0, 1, TRUE, FALSE. No masking is
applied.
