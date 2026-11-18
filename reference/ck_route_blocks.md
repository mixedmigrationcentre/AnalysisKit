# The Question Blocks of the Route Analysis

The exact 4Mi question names behind each route block. One row of `slots`
per repeat of the block; `follow_ups` name the select_multiple questions
asked about each slot, and `respondent_follow_ups` the select_multiple
questions asked once per respondent about the route as a whole;
`respondent_full_sample` are those of them asked of everyone, which
`route_full_sample_base` reports out of the full sample. `sheet` is the
name of the results sheet the block is written to.

## Usage

``` r
ck_route_blocks()
```

## Value

A named list, one element per block, in the order the blocks are
written: `transit_country`, `places_stop`, `dangerous_location`.
