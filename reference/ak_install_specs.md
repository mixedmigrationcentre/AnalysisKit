# What to Hand an Installer for Each Package

A CRAN package installs by name; the two GitHub-only ones install by
`org/repo`, which is the spec both pak and remotes understand.

## Usage

``` r
ak_install_specs(roster)
```

## Arguments

- roster:

  Rows of
  [`ak_package_roster()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ak_package_roster.md).

## Value

A character vector of install specs, one per row.
