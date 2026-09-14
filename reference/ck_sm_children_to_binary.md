# Convert Select Multiple Child Columns to 0/1 Dummies

`analysistools` estimates a select_multiple proportion as the weighted
mean of each child dummy, so the children must be numeric 0/1 with `NA`
for respondents never asked the question. Selection detection is
[`ck_sm_selection_matrix`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_sm_selection_matrix.md).

## Usage

``` r
ck_sm_children_to_binary(
  dataset,
  parents,
  sm_separator = "/",
  sm_child_style = c("auto", "label", "dummy"),
  verbose = TRUE
)
```

## Arguments

- dataset:

  A dataframe.

- parents:

  Character vector of select_multiple parent variables.

- sm_separator:

  Separator between parent and choice. Default `"/"`.

- sm_child_style:

  `"auto"` (default), `"label"` or `"dummy"`.

- verbose:

  Logical. Default `TRUE`.

## Value

The dataframe with the child columns as numeric 0/1/NA.

## Details

Who was asked is taken from the concatenated parent column when present
(non-blank parent = asked), unioned with "selected at least one child"
so a blank parent cell cannot delete a real selection - and because in a
dummy-style export a never-asked row can be filled with zeros. When the
parent column is absent every row is treated as asked, which inflates
`n_total`; a warning is issued.

A respondent who was asked but selected nothing has a blank parent and
blank children and is therefore excluded from the denominator. For the
4Mi tools that is correct: "None", "Don't know" and "Refused" are
explicit choices, so a genuinely answered question is never entirely
blank.
