# Pool 0/1/NA Columns Within a Key

Pool 0/1/NA Columns Within a Key

## Usage

``` r
ck_route_pool(x, key)
```

## Arguments

- x:

  A numeric 0/1/NA matrix, one row per slot.

- key:

  The unit each slot belongs to.

## Value

One row per distinct key, in order of first appearance: 1 if selected in
any slot, 0 if asked but never selected, `NA` if never asked.
