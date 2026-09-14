# analysiskit: the Analysis Kit workflow as a package

Turns a research dataset and a List of Analysis (LoA) workbook into a
validated, MMC-branded results workbook, without an interface.

Turns a research dataset and a List of Analysis (LoA) workbook into a
validated, MMC-branded results workbook, without an interface.

## The one function most runs need

[`run_analysis_locally()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_locally.md)
does the whole workflow: read both files, check them against each other,
run every requested analysis across every disaggregation, and write the
results workbook to a folder.

    run <- run_analysis_locally(
      dataset       = "data/mmr_analysis_data_25_26.xlsx",
      loa           = "resources/loa_template.xlsx",
      output_folder = "output"
    )

[`run_analysis_locally()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_locally.md)
does the whole workflow: read both files, check them against each other,
run every requested analysis across every disaggregation, and write the
results workbook to a folder.

    run <- run_analysis_locally(
      dataset       = "data/mmr_analysis_data_25_26.xlsx",
      loa           = "resources/loa_template.xlsx",
      output_folder = "output"
    )

## Doing it a step at a time

Every stage is its own function, so a run can be inspected, altered or
repeated at any point:

- [`read_analysis_dataset()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_analysis_dataset.md):

  read and profile a `.csv` / `.xlsx` dataset.

- [`read_loa_workbook()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md):

  read every recognised sheet of the LoA workbook, interpreting nothing.

- [`check_analysis_inputs()`](https://mixedmigrationcentre.github.io/analysiskit/reference/check_analysis_inputs.md):

  validate the workbook against the dataset. Reports errors, warnings
  and variable coverage, and never stops.

- [`build_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/build_analysis_spec.md):

  turn the workbook into the single internal description of a run.

- [`run_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_spec.md):

  run a specification.

- [`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md):

  the analysis engine itself, callable directly with plain R arguments
  and no workbook at all.

- [`ak_export_results()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ak_export_results.md):

  write a completed run to a folder.

Every stage is its own function, so a run can be inspected, altered or
repeated at any point:

- [`read_analysis_dataset()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_analysis_dataset.md):

  read and profile a `.csv` / `.xlsx` dataset.

- [`read_loa_workbook()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_loa_workbook.md):

  read every recognised sheet of the LoA workbook, interpreting nothing.

- [`check_analysis_inputs()`](https://mixedmigrationcentre.github.io/analysiskit/reference/check_analysis_inputs.md):

  validate the workbook against the dataset. Reports errors, warnings
  and variable coverage, and never stops.

- [`build_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/build_analysis_spec.md):

  turn the workbook into the single internal description of a run.

- [`run_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_spec.md):

  run a specification.

- [`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md):

  the analysis engine itself, callable directly with plain R arguments
  and no workbook at all.

- [`ak_export_results()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ak_export_results.md):

  write a completed run to a folder.

## Which functions run an analysis

Anything that executes an analysis is named `run_*`:
[`run_analysis_locally()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_locally.md),
[`run_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_spec.md)
and
[`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md).
Everything else reads, validates, reshapes or writes.

Anything that executes an analysis is named `run_*`:
[`run_analysis_locally()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_locally.md),
[`run_analysis_spec()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_analysis_spec.md)
and
[`run_group_analysis_pipeline()`](https://mixedmigrationcentre.github.io/analysiskit/reference/run_group_analysis_pipeline.md).
Everything else reads, validates, reshapes or writes.

## The LoA workbook

The schema is documented in full in the copy that ships with the
package:

    file.edit(system.file("extdata", "loa-schema.md",
                          package = "analysiskit"))
    copy_loa_template("resources")   # a workbook to start from

The schema is documented in full in the copy that ships with the
package:

    file.edit(system.file("extdata", "loa-schema.md",
                          package = "analysiskitlocal"))
    copy_loa_template("resources")   # a workbook to start from

## See also

Useful links:

- <https://github.com/mixedmigrationcentre/analysiskit>

- <https://mixedmigrationcentre.github.io/analysiskit/>

- Report bugs at
  <https://github.com/mixedmigrationcentre/analysiskit/issues>

## Author

**Maintainer**: Abubakar Athman <abubakar.athman@mixedmigration.org>

Authors:

- Abubakar Athman <abubakar.athman@mixedmigration.org>

Other contributors:

- Mixed Migration Centre \[copyright holder, funder\]
