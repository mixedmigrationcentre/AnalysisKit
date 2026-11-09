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
#' @param path Path to a `.csv` or `.xlsx` file. Only the first sheet of an
#'   `.xlsx` is read.
#' @return A list with `data`, `extension`, `filename` and `size`.
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
read_analysis_dataset <- function(path) {
  if (is.null(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    stop("Please give the path to one dataset file.", call. = FALSE)
  }
  if (!file.exists(path)) {
    stop(paste0("The dataset '", path, "' does not exist."), call. = FALSE)
  }

  read_uploaded_dataset(data.frame(
    name = basename(path),
    datapath = path,
    size = file.size(path),
    stringsAsFactors = FALSE
  ))
}


#' Read an Uploaded Dataset
#'
#' The reader itself. Takes the one-row data frame a file upload produces, so
#' that the application and a local script read a dataset identically. From a
#' path, use [read_analysis_dataset()].
#'
#' @param file_info A one-row data frame with `name`, `datapath` and `size`.
#' @return A list with `data`, `extension`, `filename` and `size`.
#' @export
read_uploaded_dataset <- function(file_info) {
  if (is.null(file_info) || nrow(file_info) != 1L) {
    stop("Please select one dataset to upload.", call. = FALSE)
  }

  extension <- tolower(tools::file_ext(file_info$name))

  if (!extension %in% c("csv", "xlsx")) {
    stop("Unsupported file type. Please upload a CSV or XLSX file.", call. = FALSE)
  }

  data <- switch(extension,
    csv = utils::read.csv(
      file_info$datapath,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      na.strings = c("", "NA", "N/A", "NULL")
    ),
    xlsx = {
      if (!requireNamespace("readxl", quietly = TRUE)) {
        stop(
          "Reading XLSX files requires the 'readxl' package. Install it with install.packages('readxl').",
          call. = FALSE
        )
      }

      as.data.frame(
        readxl::read_excel(file_info$datapath, sheet = 1),
        check.names = FALSE
      )
    }
  )

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
    duplicate_rows = sum(duplicated(data))
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
      format(ncol(data), big.mark = ","),
      format(duplicates, big.mark = ",")
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
