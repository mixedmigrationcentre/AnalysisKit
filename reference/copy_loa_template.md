# Copy the List of Analysis Template

A workbook with every sheet the reader recognises, to fill in and
upload. The schema behind it is documented in
`inst/extdata/loa-schema.md`.

## Usage

``` r
copy_loa_template(dir = ".", filename = "loa_template.xlsx", overwrite = FALSE)
```

## Arguments

- dir:

  Folder to copy the template into. Created if it does not exist.

- filename:

  Name to give the copy.

- overwrite:

  Logical. Replace an existing file of that name.

## Value

The path written, invisibly.

## Examples

``` r
copy_loa_template(tempdir())
#> List of Analysis template written to /tmp/Rtmpbuohxs/loa_template.xlsx
```
