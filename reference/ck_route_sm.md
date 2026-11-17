# Code One Select_Multiple Question as 0/1/NA

Code One Select_Multiple Question as 0/1/NA

## Usage

``` r
ck_route_sm(data, parent, sm_separator)
```

## Arguments

- data:

  The dataset, label row removed.

- parent:

  The parent question.

- sm_separator:

  The select_multiple separator.

## Value

A numeric matrix, one column per choice (named by the choice), `NA` in
rows that were not asked; `NULL` when the question has no children.
