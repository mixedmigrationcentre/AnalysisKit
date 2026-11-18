# Changelog

## analysiskit 2026.11.1

### New features

- **Route analysis.** Three new settings in a new List of Analysis
  `route_analysis` sheet, all `FALSE` by default, pool 4Mi’s repeated
  country and place questions and analyse them across every slot rather
  than slot by slot:

  - `transit_country`: transit countries (Q47–Q54), with Q72 and QN8.
  - `places_stop`: places stopped (Q56–Q70) and why.
  - `dangerous_location`: most dangerous locations (Q98–Q117), with
    incidents and perpetrators (experienced incidents only).

  Each block that is turned on gets a sheet of its own in the results
  workbook: `Transit Countries`, `Places Stop` and
  `Dangerous Locations`. A sheet opens with the ranking of every
  country, then has one wide table per follow-up question: `Overall`,
  then each country with the most respondents first
  (`route_top_countries`, default 10; 0 for all), each followed by its
  top places (`route_top_locations`, default 4), as columns, with the
  same table in counts alongside. Beneath each, the question is
  disaggregated by gender (`route_gender_var`, default `Q27`) and by
  every `disaggregation_variables` variable. Percentages are of
  respondents: a respondent counts once per country or place, however
  many slots name it. The question names are fixed, so no
  `analysis_variables` rows are needed; the slots are reshaped in memory
  and never saved. The new
  [`run_route_analysis()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_route_analysis.md)
  runs the same analysis from a script.

- **`include_dataset`.** A new setting that adds the dataset the
  analysis was run on to the results workbook, as a `dataset` sheet. Off
  by default; the dataset is personal data, so a workbook with this
  sheet must be handled as such.

- **`full_sample_base` and `full_sample_label`.** New columns of the
  `analysis_variables` sheet that keep respondents who were not asked a
  question (for example, skipped by skip logic) in the denominator, so
  that question is out of the full sample or group. Set per row: `TRUE`
  turns it on for that question, blank or `FALSE` leaves it out of those
  who answered. The not-asked share is reported as its own row,
  `full_sample_label`, or `Not asked / no response` when that is blank.
  Proportions only. A `description` column, ignored by the reader,
  explains both in its header in the template.

### Performance

- Under `engine = "auto"`, rows with a `level` whose confidence interval
  is not reported in `value_columns` now run on the fast engine, laid
  out exactly as the survey engine would have laid them out. Medians and
  ratios with a `level` stay on the survey engine.
- A dataset read from a file with a List of Analysis now reads only the
  columns the analysis uses.

### Breaking changes

- Two List of Analysis sheets are renamed: `analysis` is now
  `analysis_variables`, and `group_analysis` is now
  `disaggregation_variables`. Workbooks using the former names still
  read as before; one carrying both names for the same sheet is an
  error. Messages and the sheet summary use the new names, and the
  reader’s `sheets` list is keyed by them.
- The template no longer ships an `exclude_choices` sheet. The feature
  is unchanged: add the sheet when a run needs it.

### Minor changes

- The LoA template (`inst/extdata/loa_template.xlsx`) and the LoA
  specification (`inst/extdata/loa-schema.md`) document every new
  setting.

## analysiskit 2026.09.1

- First release: the Analysis Kit workflow as a package. Reads a dataset
  and a List of Analysis workbook, validates them against each other,
  runs the analysis across every disaggregation and writes an
  MMC-branded Excel workbook.
