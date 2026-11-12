# Read an Uploaded Dataset

The reader itself. Takes the one-row data frame a file upload produces,
so that the application and a local script read a dataset identically.
From a path, use
[`read_analysis_dataset()`](https://mixedmigrationcentre.github.io/analysiskit/reference/read_analysis_dataset.md).

## Usage

``` r
read_uploaded_dataset(file_info, columns = NULL)
```

## Arguments

- file_info:

  A one-row data frame with `name`, `datapath` and `size`.

- columns:

  Optional function taking the file's column names and returning a
  logical vector: which columns to read. `NULL` reads them all. If it
  selects nothing, every column is read.

## Value

A list with `data`, `extension`, `filename`, `size`, `duplicate_rows`
and `columns_in_file`.
