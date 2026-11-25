# analysiskit (development version)

## List of Analysis template

* **A clearer template.** `loa_template.xlsx` has been rebuilt:

  * The `readme` sheet is organised by sheet, in the order the sheets
    appear, with what to put in each column. The yellow placeholder shading
    and the `exclude_choices` notes are gone.
  * Row 2 of `analysis_variables`, `disaggregation_variables` and `settings`
    describes each column, in italics. The reader recognises it and skips it,
    so it can be left in place or deleted; problems still name the row as
    seen in Excel.
  * `settings` has a `description` column saying what each setting does.
  * Drop-down lists for `analysis_type`, `sample_base` and
    `disaggregation_variables/include`, covering the first 1,000 rows.

* **Renamed columns.** In `analysis_variables`, `full_sample_base` is now
  `sample_base`, `full_sample_label` is now `na_label`, and the template's
  `sector` column is now `section` (with `extra_columns = section`). Workbooks
  that use the former names still read exactly as before; a sheet with both
  the former and the current name of a column is a fatal error. The results
  workbook is split into one sheet per `section` (or `sector`, in an older
  workbook).

* **`ak_write_loa()`** writes a List of Analysis workbook in the template's
  layout, and is what builds the template (`dev/build_loa_template.R`).
  `loa_column_descriptions()` and `loa_setting_descriptions()` return the
  help text it writes.

# analysiskit 2026.11.1

## New features

* **Route analysis.** Three new settings in a new List of Analysis `route_analysis`
  sheet, all `FALSE` by default, pool 4Mi's repeated country and place
  questions and analyse them across every slot rather than slot by slot:

  * `transit_country`: transit countries (Q47–Q54), with Q72 and QN8.
  * `places_stop`: places stopped (Q56–Q70) and why.
  * `dangerous_location`: most dangerous locations (Q98–Q117), with incidents
    and perpetrators (experienced incidents only).

  Each block that is turned on gets a sheet of its own in the results
  workbook: `Transit Countries`, `Places Stop` and `Dangerous Locations`. A
  sheet opens with the ranking of every country, then has one wide table per
  follow-up question: `Overall`, then each country with the most respondents
  first (`route_top_countries`, default 10; 0 for all), each followed by its
  top places (`route_top_locations`, default 4), as columns, with the same
  table in counts alongside. Beneath each, the question is disaggregated by
  gender (`route_gender_var`, default `Q27`) and by every `disaggregation_variables`
  variable. Percentages are of respondents: a respondent counts
  once per country or place, however many slots name it. The question names
  are fixed, so no `analysis_variables` rows are needed; the slots are reshaped in
  memory and never saved. The new `run_route_analysis()` runs the same
  analysis from a script.

  `route_full_sample_base` (default `TRUE`) puts the questions every
  respondent is asked out of the full sample: the country ranking of each
  block (None and Refused still not listed) and Q72, whose blanks become a
  `Not asked / no response` row. QN8, the reasons for stopping, the
  incidents and the perpetrators stay out of those asked.

* **`include_dataset`.** A new setting that adds the dataset the analysis was
  run on to the results workbook, as a `dataset` sheet. Off by default; the
  dataset is personal data, so a workbook with this sheet must be handled as
  such.

* **`full_sample_base` and `full_sample_label`.** New columns of the
  `analysis_variables` sheet that keep respondents who were not asked a
  question (for example, skipped by skip logic) in the denominator, so that
  question is out of the full sample or group. Set per row: `TRUE` turns it
  on for that question, blank or `FALSE` leaves it out of those who answered.
  The not-asked share is reported as its own row, `full_sample_label`, or
  `Not asked / no response` when that is blank. Proportions only. A
  `description` column, ignored by the reader, explains both in its header
  in the template.

## Performance

* Under `engine = "auto"`, rows with a `level` whose confidence interval is
  not reported in `value_columns` now run on the fast engine, laid out exactly
  as the survey engine would have laid them out. Medians and ratios with a
  `level` stay on the survey engine.
* A dataset read from a file with a List of Analysis now reads only the
  columns the analysis uses.

## Breaking changes

* Two List of Analysis sheets are renamed: `analysis` is now
  `analysis_variables`, and `group_analysis` is now
  `disaggregation_variables`. Workbooks using the former names still read
  as before; one carrying both names for the same sheet is an error. Messages
  and the sheet summary use the new names, and the reader's `sheets` list is
  keyed by them.
* The template no longer ships an `exclude_choices` sheet. The feature is
  unchanged: add the sheet when a run needs it.

## Minor changes

* The LoA template (`inst/extdata/loa_template.xlsx`) and the LoA
  specification (`inst/extdata/loa-schema.md`) document every new setting.

# analysiskit 2026.09.1

* First release: the Analysis Kit workflow as a package. Reads a dataset and a
  List of Analysis workbook, validates them against each other, runs the
  analysis across every disaggregation and writes an MMC-branded Excel
  workbook.
