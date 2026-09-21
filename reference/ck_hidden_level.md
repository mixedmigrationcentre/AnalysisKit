# The Row Label That Marks a Hidden Residual Category

The two combination blocks sit on one shared denominator, so each
derived column has to keep the respondents the other block reports -
otherwise its percentages would be of its own sub-base and the two
blocks would not add to 100\\ into `n_total` and then dropped from the
output before the pivot.

## Usage

``` r
ck_hidden_level()
```

## Value

A single string.

## Details

A control character is used so the sentinel cannot collide with a real
choice label, however the labels were written.
