# Check a count_combinations Specification

Validates the whole specification before any work is done, so a mistyped
choice label is the first thing the user sees rather than a wrong table.
Checks the structure, that every question really is a select_multiple,
that every choice label resolves to a child column, and that no focus
choice is also in `exclude_choices` (which would be contradictory: one
argument asks to report on a choice, the other to drop everyone who
picked it).

## Usage

``` r
ck_check_choice_combinations(
  combinations,
  dataset,
  loa = NULL,
  sm_separator = "/",
  ignore_case = TRUE,
  exclude_choices = NULL,
  max_choices = 6,
  mode = c("multiple", "single"),
  arg_name = "count_combinations"
)
```

## Arguments

- combinations:

  The `count_combinations` specification.

- dataset:

  The dataset (used for the child columns).

- loa:

  The list of analyses (used for declared types).

- sm_separator:

  Separator between parent and choice. Default `"/"`.

- ignore_case:

  Logical. Match labels case-insensitively.

- exclude_choices:

  The run's `exclude_choices`, if any.

- max_choices:

  Refuse more than this many focus choices per question, so a long list
  cannot silently produce hundreds of rows. Default `6` (121 combination
  rows).

- mode:

  `"multiple"` (the `count_combinations` block, whose row count grows as
  2^(k+1) - k - 1) or `"single"` (the `count_exclusive_combinations`
  block, which is k + 1 rows). Only decides how many rows the
  `max_choices` message says the request would produce.

- arg_name:

  The pipeline argument being checked, used in the error text.

## Value

The normalised specification, invisibly: a named list of named character
vectors, names being the display labels. Errors otherwise.
