# Write a Blocks Sheet's Cells in as Few Calls as Possible

[`openxlsx::writeData()`](https://rdrr.io/pkg/openxlsx/man/writeData.html)
costs roughly its column count per call, almost regardless of how many
rows it writes: on a 523-column sheet, sixty calls of eleven rows took
2.52 s where one call of the same 31,380 cells took 0.22 s. The blocks
layout made two calls per question, so the write was sixty times more
expensive than the cells justified.

## Usage

``` r
ck_write_question_cells(wb, sheet, headers, bodies, n_col, last_row)
```

## Arguments

- wb:

  An openxlsx workbook.

- sheet:

  Sheet name.

- headers:

  A list of `list(row, values)`, one per question: the three header rows
  as a character matrix.

- bodies:

  A list of `list(row, values)`, one per question: the data rows as a
  list of one vector per sheet column.

- n_col:

  Number of columns on the sheet.

- last_row:

  The last row the sheet uses.

## Value

Invisibly the number of `writeData()` calls made.

## Details

Here the data area of the whole sheet is written once, and only the
three header rows of each question are written separately. The order is
not interchangeable: `writeData()` clears every cell of the rectangle it
covers, `NA` included, so the body pass leaves the header rows blank and
the header pass fills them afterwards. Writing them the other way round
would blank every header.

A column is only batched when every question contributes the same kind
of vector to it. If one question put text where another put numbers,
stacking them would coerce the numbers to text and Excel would stop
treating them as numbers - so a mixed column sends the whole sheet back
to the per-question path, which is slower and exactly correct.
