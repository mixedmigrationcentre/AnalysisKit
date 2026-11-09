# Turn Blank Strings into NA

ONA uses empty strings for skipped questions. Left as they are, ""
becomes a legitimate response category and inflates every denominator.

## Usage

``` r
ck_blank_to_na(dataset, columns = NULL)
```

## Arguments

- dataset:

  A dataframe.

- columns:

  Optional character vector of columns to clean. `NULL` (the default)
  cleans every character column, which is what a caller outside the
  pipeline should want. The pipeline passes the columns the run actually
  reads: a 4Mi export is hundreds of columns wide, most of them never
  named by the List of Analysis, and walking all of them cost 1.76 s on
  a 10,000 x 745 export without changing a single output cell.

## Value

The dataframe with "" replaced by `NA` in the character columns it
covered.
