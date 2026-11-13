# Put the "Not Asked / No Response" Row Last

The wide table lists a question's choices in the order they first appear
in the long results, and the survey engine sorts choices alphabetically,
so the row added by
[`ck_full_sample_base`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_full_sample_base.md)
could land anywhere among them. This moves it to the end of its question
without disturbing any other row.

## Usage

``` r
ck_no_response_last(results_long, vars, label)
```

## Arguments

- results_long:

  Long results.

- vars:

  The select_one and select_multiple variables that were filled.

- label:

  The row label used for them.

## Value

`results_long`, reordered.
