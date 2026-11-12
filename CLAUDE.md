# analysiskit

R package that runs Mixed Migration Centre 4Mi analyses locally: a dataset plus
a List of Analysis (LoA) workbook in, an MMC-branded Excel results workbook out.
The engine, LoA reader and exporter are the same code the Analysis Kit Shiny app
uses, so keep function signatures and outputs compatible with the app.
Sister package: `cleaningkit` (Desktop\Projects\Cleaning kit\cleaningkit) produces
the cleaned data this package analyses.

## Environment

- Windows. `Rscript` is **not on PATH**; call it as
  `"/c/Program Files/R/R-4.6.1/bin/Rscript.exe"` from Bash.

## Dev loop

- Full cycle: `Rscript dev/setup.R` (attachment updates DESCRIPTION, step 1b
  moves optional deps back to Suggests, then `devtools::document()` and
  `devtools::check()`). Always use this rather than calling
  `attachment::att_amend_desc()` alone.
- Quick: `Rscript -e "devtools::document()"` and
  `Rscript -e "devtools::test(filter = 'read_loa')"` (filter = test file stem).
- Tests: testthat 3e in `tests/testthat/`. `helper-loa.R` builds LoA fixtures;
  `helper-snapshot.R` reads saved workbooks cell by cell (value + storage type)
  to compare Excel output. Add or update a test with any behaviour change.

## Dependencies

- Imports stay minimal: dplyr, openxlsx, readxl, stringr, tidyr + base.
- `srvyr`, `survey`, `analysistools`, `cleaningtools`, `pak` are **Suggests**
  and must stay there. They are only reached by the survey engine (an
  `analysis` row with `level` set) and `recreate_sm_parents`. Guard every use
  with `requireNamespace()`. `analysistools`/`cleaningtools` are GitHub-only.

## Generated files: do not edit by hand

A PreToolUse hook blocks these; edit the source instead.

| Generated | Source | Rebuild |
|---|---|---|
| `man/*.Rd`, `NAMESPACE` | roxygen `#'` comments in `R/` | `devtools::document()` |
| `docs/` | everything (pkgdown) | `pkgdown::build_site()`; CI also builds it |

## The LoA contract

`inst/extdata/loa-schema.md` is the specification of the LoA workbook (sheets,
columns, settings). Any change to what `read_loa_workbook()` /
`build_analysis_spec()` accept must update that document and
`inst/extdata/loa_template.xlsx` in the same change.

## Conventions

- Formatting: a PostToolUse hook runs `air format` on each `.R` file Claude
  edits. Don't fight it.
- Pipes: base `|>` only; no magrittr.
- Errors with `stop(..., call. = FALSE)`, written as full sentences that say
  what to fix.
- Naming: functions that execute an analysis are `run_*`; exported utilities
  are `ak_*`; internal helpers are `ck_*` and tagged `@keywords internal`.
- Always call other packages with `pkg::fn()`.

## Data

Survey data is personal data about people on the move. Never commit real
datasets or results workbooks; scratch outputs go in `Claude outputs/`
(git-ignored). `inst/examples/run_analysis.R` is the reference workflow.
