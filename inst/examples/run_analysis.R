# =============================================================================
# analysiskit - generate an analysis
# =============================================================================
#
#   dataset (.xlsx)  +  List of Analysis (.xlsx)  ->  results workbook
#
# Six steps, top to bottom. After the first run you only need 3 to 6.
#
# Open your own copy:
#   file.edit(system.file("examples", "run_analysis.R",
#                         package = "analysiskit"))
# =============================================================================

library(analysiskit)


# --- 1. packages -------------------------------------------------------- once
# Installs anything missing, including the optional survey engine
# (srvyr + analysistools), which does not come with the package.

load_packages()


# --- 2. project folders ------------------------------------------------- once
#
# ### YOU ONLY NEED TO RUN THIS ONCE, per project folder. ###
#
# Creates data/, resources/ and output/. Safe to run again - an existing folder
# is left alone, never emptied - but there is no reason to.

setup_project_folders()

# A List of Analysis workbook to fill in. Also once.
copy_loa_template("resources")


# --- 3. read the files -------------------------------------------------------
# Edit these two paths.

dataset <- read_analysis_dataset("data/mmr_analysis_data_25_26.xlsx")
loa     <- read_loa_workbook("resources/loa_template.xlsx")

dataset_overview(dataset)   # rows, columns, size, duplicate rows


# --- 4. check the List of Analysis -------------------------------------------
# Runs every check and NEVER stops, so you see all the problems at once.
# Milliseconds - always do this before a long run.

checks <- check_analysis_inputs(dataset, loa, output_folder = "output")
checks                                 # ends in "ready to run : yes" or "no"

ak_problems_display(checks$problems)   # every problem, must-fix first

# MUST FIX = the run would produce wrong or misleading output.
# WARNING  = the run would only produce less output.


# --- 5. run the analysis pipeline --------------------------------------------
# checks$spec is the workbook, already read and validated, so there is nothing
# to build here. This stops without doing any work if anything is must-fix.
#
# Note the $data: this step wants the data frame itself, not the list that
# read_analysis_dataset() returned.

results <- run_analysis_spec(dataset$data, checks$spec, verbose = TRUE)


# --- 6. create the output ----------------------------------------------------

path <- ak_export_results(
  results      = results,
  spec         = checks$spec,
  folder       = "output",
  dataset_name = dataset$filename
)

path                                     # the workbook that was written
results$combined_results[1:5, 1:6]       # a corner of the wide table


# =============================================================================
# Worth knowing
# =============================================================================
#
# ONE CALL INSTEAD OF 4-6, if you would rather not see the stages. It also
#   keeps a run log, times the run, recovers the results if only the save
#   fails, and prints the caveat below:
#     run <- run_analysis_locally(dataset, loa, output_folder = "output")
#
# ROW 1 IS THE LABEL ROW. An ONA export puts question text there and the
#   pipeline sets it aside. If your dataset has no label row, set
#   `skip_label_row` to FALSE in the workbook's settings sheet, or you lose
#   your first respondent.
#
# LEAVE `level` EMPTY unless you want a confidence interval. Empty uses the
#   fast engine - same point estimates, far faster on a big disaggregation,
#   and needs neither srvyr nor analysistools.
#
# exclude_choices CHANGES THE DENOMINATOR. Someone who picked "Don't know"
#   leaves the base for that question entirely.
#
# THE TWO COMBINATION BLOCKS SPLIT ONE BASE. count_combinations reports the
#   respondents who selected more than one choice, count_exclusive_combinations
#   those who selected exactly one, both over everyone who answered and selected
#   at least one choice - so the two blocks together add to 100%, and each on its
#   own adds to the share of the sample it covers. Anyone who answered with no
#   choice recorded is outside both:
#     ak_exclusive_base_note(results$choice_combinations)
#   Footnote it wherever those percentages are published.
#
# The full workbook specification - every sheet, every setting, every rule:
#   file.show(system.file("extdata", "loa-schema.md",
#                         package = "analysiskit"))
# =============================================================================
