# Install and Load Everything This Package Needs

Installs whatever is missing and, optionally, attaches it. Uses pak,
which resolves the whole set in one pass and handles the two GitHub-only
packages from the same call.

## Usage

``` r
load_packages(optional = TRUE, attach = FALSE, upgrade = FALSE)
```

## Arguments

- optional:

  Logical. Also install the optional packages — the survey engine and
  `cleaningtools`. Default `TRUE`; `FALSE` does the required ones only,
  which is the quick offline-safe check.

- attach:

  Logical. Also [`library()`](https://rdrr.io/r/base/library.html) the
  required CRAN packages into your session. Default `FALSE`; see above.

- upgrade:

  Logical. Let pak upgrade packages that are already installed. Default
  `FALSE`, so a working library is not disturbed.

## Value

The status table from
[`check_analysis_packages()`](https://mixedmigrationcentre.github.io/analysiskit/reference/check_analysis_packages.md),
invisibly, taken *after* the install so it reflects what actually
happened.

## What it installs

The **required** packages come with the package itself, so on a normal
install there is nothing to do — this only matters if the folder was
copied rather than installed.

The **optional** ones are the point. `srvyr`, `analysistools` and
`cleaningtools` are in `Suggests` and are *not* installed with the
package, and two of them are not on CRAN at all. Run this once and the
survey engine works:

    load_packages()

**You do not need them for most runs.** An `analysis` row with a `level`
set asks for a confidence interval, which routes that row through
`srvyr` and `analysistools`. Leave every `level` cell empty and the fast
tabulation engine handles the whole run, needing none of the three — and
on a large disaggregation taking seconds rather than minutes. So if
`load_packages()` cannot reach GitHub, that is inconvenient rather than
fatal.

## Why it does not attach by default

Unlike a folder of scripts, this is a package: every internal call is
namespace-qualified
([`dplyr::bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html),
[`openxlsx::createStyle()`](https://rdrr.io/pkg/openxlsx/man/createStyle.html)),
so nothing needs to be on your search path for the analysis to run.
Attaching `dplyr` would also mask
[`stats::filter()`](https://rdrr.io/r/stats/filter.html) and
[`stats::lag()`](https://rdrr.io/r/stats/lag.html) in your session for
no gain. Pass `attach = TRUE` if you want them anyway, for your own
interactive work.

## See also

[`check_analysis_packages()`](https://mixedmigrationcentre.github.io/analysiskit/reference/check_analysis_packages.md)
to look without installing anything.

## Examples

``` r
if (FALSE) { # \dontrun{
# Everything, including the survey engine
load_packages()

# Required only - no network beyond CRAN, no GitHub
load_packages(optional = FALSE)

# ...and put dplyr and friends on the search path for your own use
load_packages(attach = TRUE)
} # }
```
