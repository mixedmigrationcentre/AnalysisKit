# Read a saved workbook's cells together with how each is stored (number or
# text). Copied from the Analysis Kit App's R/compare_workbooks.R, where it is
# development tooling; test-performance-guards.R needs it to prove that the
# batched write keeps numbers numeric.


ak_shared_strings <- function(shared) {
  if (length(shared) == 0) {
    return(character(0))
  }

  text <- gsub("<[^>]*>", "", as.character(shared))
  text <- gsub("&lt;", "<", text, fixed = TRUE)
  text <- gsub("&gt;", ">", text, fixed = TRUE)
  text <- gsub("&quot;", "\"", text, fixed = TRUE)
  text <- gsub("&apos;", "'", text, fixed = TRUE)
  # Last, or an escaped entity would be unescaped twice.
  gsub("&amp;", "&", text, fixed = TRUE)
}

ak_snapshot_workbook <- function(path) {
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    stop("Comparing workbooks requires the 'openxlsx' package.", call. = FALSE)
  }
  if (!file.exists(path)) {
    stop(paste0("No workbook at ", path, "."), call. = FALSE)
  }

  wb <- openxlsx::loadWorkbook(path)
  strings <- ak_shared_strings(wb$sharedStrings)

  snapshot <- lapply(seq_along(wb$sheet_names), function(i) {
    cells <- wb$worksheets[[i]]$sheet_data

    keep <- !is.na(cells$v)
    rows <- as.integer(cells$rows)[keep]
    cols <- as.integer(cells$cols)[keep]
    kind <- cells$t[keep]
    value <- as.character(cells$v)[keep]

    # t == 1 is a shared string; anything else stores its value inline, and
    # numbers are much the commonest of those.
    is_text <- !is.na(kind) & kind == 1
    if (any(is_text)) {
      value[is_text] <- strings[as.integer(value[is_text]) + 1L]
    }

    type <- ifelse(is.na(kind), "number", ifelse(kind == 1, "text", paste0("t", kind)))
    type[!is.na(kind) & kind == 0] <- "number"

    data.frame(
      row = rows, col = cols, type = type, value = value,
      stringsAsFactors = FALSE
    )
  })

  stats::setNames(snapshot, wb$sheet_names)
}
