# Count How Many Choices Each Respondent Selected

Adds a derived categorical column per question recording how many
choices that respondent picked: none, exactly one, or more than one.
Because it is an ordinary categorical column it then flows through the
normal analysis - overall and across every grouping variable - with no
special casing downstream.

## Usage

``` r
ck_add_selection_counts(
  dataset,
  count_selections,
  sm_separator = "/",
  sm_child_style = c("auto", "label", "dummy"),
  exclude_choices = NULL,
  ignore_case = TRUE,
  mode = c("grouped", "exact"),
  labels = c("No choice selected", "Selected exactly 1 choice",
    "Selected more than 1 choice"),
  order = c("descending", "ascending"),
  suffix = "_selection_count",
  verbose = TRUE
)
```

## Arguments

- dataset:

  A dataframe (label row already removed).

- count_selections:

  Character vector of select_multiple parents.

- sm_separator:

  Separator between parent and choice. Default `"/"`.

- sm_child_style:

  `"auto"` (default), `"label"`, `"dummy"`.

- exclude_choices:

  Optional choice labels not to count towards the total, so that e.g.
  "Refused" does not read as "selected one choice".

- ignore_case:

  Logical. Match `exclude_choices` case-insensitively.

- mode:

  `"grouped"` (default) gives none / one / more than one. `"exact"`
  gives the exact number selected.

- labels:

  The three category labels for `mode = "grouped"`, always in the order
  *none, exactly one, more than one* whatever the display order.

- order:

  Row order. `"descending"` (default) puts the largest selection count
  first.

- suffix:

  Appended to the variable name to make the derived column name.

- verbose:

  Logical. Default `TRUE`.

## Value

A list with `dataset` and `map` (`analysis_var`, `count_column`,
`n_choices_counted`).

## Details

Run this *before*
[`ck_sm_children_to_binary`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_sm_children_to_binary.md):
the counts are taken from the raw selection pattern, so that "no choice
selected" is a real category rather than a group the not-asked mask has
already removed.

**Read the "no choice selected" figure carefully.** It counts
respondents with nothing recorded, which lumps together those never
asked the question (a relevance condition sent them past it) and those
asked who left it blank. If the question was asked of everyone the two
are the same thing; if it was conditional, this is "not answered", not
"declined to answer". A filled parent with no child selected is a
genuine inconsistency and is warned about.
