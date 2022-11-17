Texas Coastal Nutrient Input Repository (Phase 1 - Lavaca Bay)
================

[![License: CC BY
4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

This repository contains code and data for the Texas Coastal Nutrient
Input Repository project. This project develops estimates of actual and
flow-normalized daily nitrate (NO<sup>3</sup>-N) and total phosphorus
(TP) watershed loads. Reports and publications are forthcoming.

Data analysis and models were developed in R using the
[renv](https://rstudio.github.io/renv/) and
[targets](https://docs.ropensci.org/targets/) R packages to facilitate
reproducibility. To reproduce this analysis clone the repository to your
local machine, ensure both renv and targets are installed and open the
project. The analysis can be reproduced using:

``` r
renv::restore()
targets::tar_make()
```

## Data Download

Metadata and download links for nutrient loading data (csv files) are
located here: <https://txwri.github.io/lavaca-nutrients/>

## Funding

This project was funded by a Texas Coastal Management Program grant
approved by the Texas Land Commissioner, providing financial assistance
under the Coastal Zone Management Act of 1972, as amended, awarded by
the National Oceanic and Atmospheric Administration (NOAA), Office for
Coastal Management, pursuant to NOAA Award No. NA21NOS4190136. The views
expressed herein are those of the author(s) and do not necessarily
reflect the views of NOAA, the U.S. Department of Commerce, or any of
their subagencies.
