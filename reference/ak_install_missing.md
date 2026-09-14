# Install a Set of Packages, Best Effort

Split out from
[`load_packages()`](https://mixedmigrationcentre.github.io/analysiskit/reference/load_packages.md)
for two reasons: it is the only part that touches the network, which
keeps it out of the unit tests; and it is the only part that can fail in
ways worth reporting individually.

## Usage

``` r
ak_install_missing(specs, upgrade = FALSE)
```

## Arguments

- specs:

  Install specs from
  [`ak_install_specs()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ak_install_specs.md)
  — a CRAN name, or an `org/repo` for the GitHub-only packages.

- upgrade:

  Logical. Let pak upgrade what is already installed.

## Value

`TRUE` if an installer was available and ran, `FALSE` if not, invisibly.

## Details

Never stops. Whether a failure matters is
[`load_packages()`](https://mixedmigrationcentre.github.io/analysiskit/reference/load_packages.md)'s
judgement to make, from what is missing afterwards and whether any of it
was required.
