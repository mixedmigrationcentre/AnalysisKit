# analysiskit

Turns a 4Mi dataset and a **List of Analysis** workbook into an
MMC-styled results workbook. This package is the analysis itself; the
[Analysis Kit App](https://abu-analysiskit.share.connect.posit.cloud/)
is a point-and-click interface on top of it.

## Install

``` r

install.packages("pak")
pak::pkg_install("mixedmigrationcentre/analysiskit")
```

## Use

``` r

library(analysiskit)

# 1. Get the List of Analysis template and fill it in
copy_loa_template("resources")

# 2. Check the dataset and the workbook against each other
check_analysis_inputs(
  dataset = "data/my_4mi_export.xlsx",
  loa     = "resources/loa_template.xlsx"
)

# 3. Run, and save the results workbook
run_analysis_locally(
  dataset       = "data/my_4mi_export.xlsx",
  loa           = "resources/loa_template.xlsx",
  output_folder = "output"
)
```

Step 2 lists anything that must be fixed before a run. Step 3 refuses to
start until it is clean, and writes
`analysiskit_<dataset>_<date-time>.xlsx` to the output folder.

## The List of Analysis

Write raw question codes (`Q27`, `Q78`) everywhere in the workbook. The
template’s `readme` sheet explains each sheet, and the full reference is
[`inst/extdata/loa-schema.md`](https://mixedmigrationcentre.github.io/analysiskit/inst/extdata/loa-schema.md).

| `analysis_type` | What you get |
|----|----|
| `prop_select_one` | % of respondents giving each answer |
| `prop_select_multiple` | % of respondents selecting each option |
| `mean` / `median` | average / median of a numeric question |
| `ratio` | sum of `analysis_var_numerator` / sum of `analysis_var_denominator` |

Leave `level` empty unless a row needs a confidence interval. Rows with
a level use the much slower survey engine; the figures are the same
either way.

## For developers

Every step is also available on its own:
[`read_analysis_dataset()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_analysis_dataset.md),
[`read_loa_workbook()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md),
[`build_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/build_analysis_spec.md),
[`run_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_spec.md),
[`ak_export_results()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ak_export_results.md).
See
[`?run_analysis_locally`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_locally.md)
and the help pages it links to.

Changes to the analysis are made here, in this package. The app picks
them up when the package is reinstalled.
