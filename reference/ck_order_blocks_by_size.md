# Order Group Blocks by Sample Size Within Each Grouping Variable

Group values come out of the pipeline alphabetically, which puts
`Female` before `Male` and `No, Refused, Yes` in that order regardless
of how many respondents are behind each. Sorting them largest first puts
the substantial columns where they will be read.

## Usage

``` r
ck_order_blocks_by_size(blocks, block_group, size)
```

## Arguments

- blocks:

  The statistic blocks.

- block_group:

  Grouping variable of each block.

- size:

  Sample size of each block, from
  [`ck_block_sample_sizes()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ck_block_sample_sizes.md).

## Value

An integer permutation of `seq_along(blocks)`.

## Details

Only blocks *within* the same grouping variable move, so the merged
variable band above them still spans a contiguous stretch and
`Overall` - a run of one

- stays where it is. The order is decided once for the whole workbook
  from each block's overall sample size, not per question: the block
  layout writes one header per question, and re-sorting each of them
  independently would leave the columns unaligned down the sheet.
