# =============================================================================
# Reading and profiling the primary dataset
# =============================================================================
#
# read_uploaded_dataset() is the Analysis Kit reader, unchanged: it takes the
# data frame a Shiny fileInput produces (name / datapath / size). Running
# locally there is no upload, only a path, so read_analysis_dataset() builds
# that shape and delegates. One reader, two ways in - rather than two readers
# that can drift apart on how a CSV's blanks are treated.
# =============================================================================


#' Read a Dataset from a Path
#'
#' Reads a `.csv` or `.xlsx` research dataset and reports what it found. The
#' file is read as it is: **row 1 of an ONA export is the label row and is
#' left in place**, because that is what [build_analysis_spec()] and
#' [run_analysis_spec()] expect. The label row is set aside by the pipeline
#' itself, under the `skip_label_row` setting.
#'
#' CSV blanks and the strings `NA`, `N/A` and `NULL` are read as missing.
#' Column names are preserved exactly (`check.names = FALSE`), because the
#' select_multiple child columns carry choice labels that R would otherwise
#' mangle.
#'
#' @section Reading only what the List of Analysis uses:
#'
#' A 4Mi export is often more than a thousand columns wide, and a List of
#' Analysis names a few dozen of them. Give the List of Analysis as `loa` and
#' only the columns it refers to are read: every analysis variable with its
#' select_multiple children, the ratio variables, the grouping variables, and
#' the weight and strata columns. The analysis reads no other column, so the
#' results are the same; what changes is the time and memory the read takes.
#'
#' A dataset read this way is for running that List of Analysis. It reports how
#' many columns the file has in `columns_in_file`, and it does not count
#' duplicate rows, because rows that agree on a few columns are not duplicates.
#' Read the file without `loa` to profile the whole export.
#'
#' @param path Path to a `.csv` or `.xlsx` file. Only the first sheet of an
#'   `.xlsx` is read.
#' @param loa Optional. A List of Analysis path, or the list from
#'   [read_loa_workbook()]. When given, only the columns it refers to are read.
#' @return A list with `data`, `extension`, `filename`, `size`,
#'   `duplicate_rows` and `columns_in_file`.
#' @seealso [dataset_overview()] and [dataset_columns()] to inspect the result,
#'   [read_loa_workbook()] for the other half of a run.
#' @export
#' @examples
#' path <- tempfile(fileext = ".csv")
#' utils::write.csv(
#'   data.frame(Q27 = c("What is your gender?", "Female", "Male")),
#'   path,
#'   row.names = FALSE
#' )
#'
#' dataset <- read_analysis_dataset(path)
#' dataset_overview(dataset)
read_analysis_dataset <- function(path, loa = NULL) {
  if (is.null(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    stop("Please give the path to one dataset file.", call. = FALSE)
  }
  if (!file.exists(path)) {
    stop(paste0("The dataset '", path, "' does not exist."), call. = FALSE)
  }

  columns <- NULL
  if (!is.null(loa)) {
    workbook <- as_loa_workbook(loa)
    columns <- function(header) loa_dataset_columns(workbook, header)
  }

  read_uploaded_dataset(
    data.frame(
      name = basename(path),
      datapath = path,
      size = file.size(path),
      stringsAsFactors = FALSE
    ),
    columns = columns
  )
}


#' The Dataset Columns a List of Analysis Refers To
#'
#' Every column the analysis can read: the variables
#' [loa_variable_coverage()] finds in the workbook (analysis variables, ratio
#' numerators and denominators, grouping variables, the derived-count
#' questions, weight and strata), the select_multiple children of each, and
#' `uuid` when `recreate_sm_parents` is on.
#'
#' @param workbook The list from [read_loa_workbook()], or a bare named list of
#'   sheets.
#' @param header The dataset's column names, in file order.
#' @return A logical vector, one element per name in `header`.
#' @keywords internal
loa_dataset_columns <- function(workbook, header) {
  wb <- if (!is.null(workbook$sheets)) workbook else list(sheets = workbook)
  settings <- loa_parse_settings(wb$sheets$settings)$settings
  sm_separator <- settings$sm_separator %||% "/"

  probe <- as.data.frame(
    stats::setNames(rep(list(character(0)), length(header)), header),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  variables <- unique(loa_variable_coverage(wb, probe, sm_separator)$variable)
  if (isTRUE(settings$recreate_sm_parents)) {
    variables <- c(variables, "uuid")
  }
  variables <- variables[!is.na(variables) & nzchar(variables)]

  keep <- header %in% variables
  for (v in variables) {
    keep <- keep | startsWith(header, paste0(v, sm_separator))
  }
  keep
}


#' Read an Uploaded Dataset
#'
#' The reader itself. Takes the one-row data frame a file upload produces, so
#' that the application and a local script read a dataset identically. From a
#' path, use [read_analysis_dataset()].
#'
#' @param file_info A one-row data frame with `name`, `datapath` and `size`.
#' @param columns Optional function taking the file's column names and
#'   returning a logical vector: which columns to read. `NULL` reads them all.
#'   If it selects nothing, every column is read.
#' @return A list with `data`, `extension`, `filename`, `size`,
#'   `duplicate_rows` and `columns_in_file`.
#' @export
read_uploaded_dataset <- function(file_info, columns = NULL) {
  if (is.null(file_info) || nrow(file_info) != 1L) {
    stop("Please select one dataset to upload.", call. = FALSE)
  }

  extension <- tolower(tools::file_ext(file_info$name))

  if (!extension %in% c("csv", "xlsx")) {
    stop("Unsupported file type. Please upload a CSV or XLSX file.", call. = FALSE)
  }

  if (extension == "xlsx" && !requireNamespace("readxl", quietly = TRUE)) {
    stop(
      "Reading XLSX files requires the 'readxl' package. Install it with install.packages('readxl').",
      call. = FALSE
    )
  }

  # With a column filter the header is read first, under the same name repair
  # a full read applies, so the columns that are kept carry exactly the names
  # they would have had.
  keep <- NULL
  if (!is.null(columns)) {
    header <- switch(extension,
      csv = names(utils::read.csv(
        file_info$datapath,
        nrows = 1,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )),
      xlsx = names(suppressMessages(
        readxl::read_excel(file_info$datapath, sheet = 1, n_max = 0)
      ))
    )

    keep <- as.logical(columns(header))
    if (length(keep) != length(header) || anyNA(keep) || !any(keep) || all(keep)) {
      keep <- NULL
    }
  }

  data <- switch(extension,
    csv = utils::read.csv(
      file_info$datapath,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      na.strings = c("", "NA", "N/A", "NULL"),
      colClasses = if (is.null(keep)) NA else ifelse(keep, NA, "NULL")
    ),
    xlsx = as.data.frame(
      if (is.null(keep)) {
        readxl::read_excel(file_info$datapath, sheet = 1)
      } else {
        suppressMessages(readxl::read_excel(
          file_info$datapath,
          sheet = 1,
          col_types = ifelse(keep, "guess", "skip")
        ))
      },
      check.names = FALSE
    )
  )

  columns_in_file <- ncol(data)
  if (!is.null(keep)) {
    names(data) <- header[keep]
    columns_in_file <- length(header)
  }

  if (ncol(data) == 0L) {
    stop("The uploaded file does not contain any columns.", call. = FALSE)
  }

  list(
    data = data,
    extension = toupper(extension),
    filename = file_info$name,
    size = file_info$size,
    # Counted once, here, rather than inside dataset_overview(). duplicated()
    # on a data frame fingerprints every row against every column - 3.8 s on a
    # 10,000 x 745 export - and dataset_overview() is rendered through
    # renderTable(), so leaving it there paid that cost again on every
    # invalidation of the dataset reactive rather than once per upload.
    #
    # Not counted at all when columns were skipped: rows that agree on the few
    # columns an analysis reads are not duplicate interviews.
    duplicate_rows = if (is.null(keep)) sum(duplicated(data)) else NA_integer_,
    columns_in_file = columns_in_file
  )
}


#' Summarise a Dataset
#'
#' @param dataset The list returned by [read_analysis_dataset()].
#' @return A data frame with `Measure` and `Value`: file name, file type, file
#'   size, rows, columns and completely duplicated rows.
#' @export
dataset_overview <- function(dataset) {
  data <- dataset$data

  # Older callers (and any test building the list by hand) may not carry the
  # count, so it is still computed here when it is absent.
  duplicates <- dataset$duplicate_rows
  if (is.null(duplicates)) duplicates <- sum(duplicated(data))

  in_file <- dataset$columns_in_file %||% ncol(data)
  columns <- format(in_file, big.mark = ",")
  if (in_file != ncol(data)) {
    columns <- paste0(
      columns, " (", format(ncol(data), big.mark = ","),
      " read: those the List of Analysis uses)"
    )
  }

  data.frame(
    Measure = c(
      "File name",
      "File type",
      "File size",
      "Rows",
      "Columns",
      "Duplicate rows"
    ),
    Value = c(
      dataset$filename,
      dataset$extension,
      format(structure(dataset$size, class = "object_size"), units = "auto"),
      format(nrow(data), big.mark = ","),
      columns,
      if (is.na(duplicates)) {
        "not counted (only some columns were read)"
      } else {
        format(duplicates, big.mark = ",")
      }
    ),
    check.names = FALSE
  )
}


#' Profile Every Column of a Dataset
#'
#' Note that the counts include the ONA label row, which is still row 1 of the
#' data at this point: a column that is otherwise empty will show one value.
#'
#' @param dataset The list returned by [read_analysis_dataset()].
#' @return A data frame with `Column`, `Type`, `Missing` and `Unique`.
#' @export
dataset_columns <- function(dataset) {
  data <- dataset$data

  data.frame(
    Column = names(data),
    Type = vapply(data, function(column) class(column)[1L], character(1)),
    Missing = vapply(data, function(column) sum(is.na(column)), integer(1)),
    Unique = vapply(data, function(column) length(unique(column[!is.na(column)])), integer(1)),
    check.names = FALSE
  )
}
