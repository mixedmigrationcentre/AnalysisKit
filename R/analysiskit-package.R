#' analysiskit: the Analysis Kit workflow as a package
#'
#' Turns a research dataset and a List of Analysis (LoA) workbook into a
#' validated, MMC-branded results workbook, without an interface.
#'
#' @section The one function most runs need:
#'
#' [run_analysis_locally()] does the whole workflow: read both files, check
#' them against each other, run every requested analysis across every
#' disaggregation, and write the results workbook to a folder.
#'
#' ```r
#' run <- run_analysis_locally(
#'   dataset       = "data/mmr_analysis_data_25_26.xlsx",
#'   loa           = "resources/loa_template.xlsx",
#'   output_folder = "output"
#' )
#' ```
#'
#' @section Doing it a step at a time:
#'
#' Every stage is its own function, so a run can be inspected, altered or
#' repeated at any point:
#'
#' \describe{
#'   \item{[read_analysis_dataset()]}{read and profile a `.csv` / `.xlsx`
#'     dataset.}
#'   \item{[read_loa_workbook()]}{read every recognised sheet of the LoA
#'     workbook, interpreting nothing.}
#'   \item{[check_analysis_inputs()]}{validate the workbook against the
#'     dataset. Reports errors, warnings and variable coverage, and never
#'     stops.}
#'   \item{[build_analysis_spec()]}{turn the workbook into the single internal
#'     description of a run.}
#'   \item{[run_analysis_spec()]}{run a specification.}
#'   \item{[run_group_analysis_pipeline()]}{the analysis engine itself, callable
#'     directly with plain R arguments and no workbook at all.}
#'   \item{[ak_export_results()]}{write a completed run to a folder.}
#' }
#'
#' @section Which functions run an analysis:
#'
#' Anything that executes an analysis is named `run_*`:
#' [run_analysis_locally()], [run_analysis_spec()] and
#' [run_group_analysis_pipeline()]. Everything else reads, validates, reshapes
#' or writes.
#'
#' @section The LoA workbook:
#'
#' The schema is documented in full in the copy that ships with the package:
#'
#' ```r
#' file.edit(system.file("extdata", "loa-schema.md",
#'                       package = "analysiskit"))
#' copy_loa_template("resources")   # a workbook to start from
#' ```
#'
#' @keywords internal
"_PACKAGE"
