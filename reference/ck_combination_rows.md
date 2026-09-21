# The Rows One Choice-Combination Block Produces

Builds the row labels for a question, together with the selection
pattern each row stands for, so that assigning respondents is a single
[`match()`](https://rdrr.io/r/base/match.html) rather than a per-row
test. A pattern is a bit key over the chosen choices plus a flag for
"selected at least one choice outside the chosen set".

## Usage

``` r
ck_combination_rows(
  display,
  mode = c("multiple", "single"),
  joiner = " + ",
  only_suffix = " only",
  other_label = "Other",
  other_multiple_label = "Other multiple selection",
  other_single_label = "Other single selection",
  residual_level = NULL,
  order = c("descending", "ascending")
)
```

## Arguments

- display:

  Short display labels of the chosen choices, in the order they were
  given.

- mode:

  `"multiple"` or `"single"`.

- joiner:

  Placed between display labels, and before `other_label`.

- only_suffix:

  Appended to a row that means "and nothing else".

- other_label:

  Stands for the unlisted choices in a multiple-selection row.

- other_multiple_label:

  Row label for more than one selection, none of them chosen.

- other_single_label:

  Row label for exactly one selection that is not a chosen one.

- residual_level:

  Optional extra level for the respondents this block does not report
  but still counts in its denominator. Placed last (first when
  ascending).

- order:

  `"descending"` (default) or `"ascending"`.

## Value

A dataframe of `key`, `other` and `label`, in display order. The
residual row, when present, has `key = NA` and takes part in no
matching.

## Details

**mode = "multiple"** - respondents who selected more than one choice.
For each subset of the chosen choices, largest first:

- two or more chosen choices and nothing else: *A + B only*

- one or more chosen choices plus something unlisted: *A + Other*

- nothing chosen: *Other multiple selection*

A single chosen choice and nothing else is one selection, so it has no
row here - it belongs to the `"single"` block.

**mode = "single"** - respondents who selected exactly one choice: *A
only* for each chosen choice, then *Other single selection* for the
respondent whose single choice was not a chosen one.
