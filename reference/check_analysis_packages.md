# What the Package Needs, and What Is Installed

`need = "required"` means every run uses it and it is installed with the
package. `need = "optional"` means one feature needs it, and that
feature is the survey engine: an analysis row with a `level` set asks
for a confidence interval, which routes that row through srvyr and
analysistools. Leave every `level` cell empty and the fast tabulation
engine handles the whole run, needing neither - and, on a large
disaggregation, taking seconds rather than minutes.

## Usage

``` r
check_analysis_packages()
```

## Value

A data frame with `package`, `need`, `installed`, `version`, `install`
and `purpose`.

## Details

Nothing is installed here. The two optional GitHub packages are not on
CRAN, so the `install` column gives the command to run.
[`load_packages()`](https://mixedmigrationcentre.github.io/analysiskit/reference/load_packages.md)
does the installing.

The roster itself lives in
[`ak_package_roster()`](https://mixedmigrationcentre.github.io/analysiskit/reference/ak_package_roster.md),
so this function and
[`load_packages()`](https://mixedmigrationcentre.github.io/analysiskit/reference/load_packages.md)
cannot disagree about what is optional or where the GitHub packages come
from.

## See also

[`load_packages()`](https://mixedmigrationcentre.github.io/analysiskit/reference/load_packages.md)
to install what is missing.

## Examples

``` r
check_analysis_packages()
#>         package     need installed version
#> 1         dplyr required      TRUE   1.2.1
#> 2         tidyr required      TRUE   1.3.2
#> 3       stringr required      TRUE   1.6.0
#> 4        readxl required      TRUE 1.5.0.1
#> 5      openxlsx required      TRUE   4.2.9
#> 6         srvyr optional     FALSE    <NA>
#> 7 analysistools optional     FALSE    <NA>
#> 8 cleaningtools optional     FALSE    <NA>
#> 9       writexl optional     FALSE    <NA>
#>                                                       install
#> 1                                                            
#> 2                                                            
#> 3                                                            
#> 4                                                            
#> 5                                                            
#> 6                                   install.packages('srvyr')
#> 7 remotes::install_github('impact-initiatives/analysistools')
#> 8 remotes::install_github('impact-initiatives/cleaningtools')
#> 9                                 install.packages('writexl')
#>                                                                       purpose
#> 1                                                       the analysis pipeline
#> 2                                       reshaping results into the wide table
#> 3                                                  question and choice labels
#> 4                       reading .xlsx datasets and List of Analysis workbooks
#> 5                                                writing the results workbook
#> 6   the survey engine, used only when an analysis row sets a confidence level
#> 7   the survey engine, used only when an analysis row sets a confidence level
#> 8 rebuilding select_multiple parent columns, when recreate_sm_parents is TRUE
#> 9                                                         the test suite only
```
