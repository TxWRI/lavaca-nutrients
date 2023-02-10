---
title: "Supporting Materials: Load Estimates"
author: 
  - name: Michael Schramm
    affiliations:
      - name: Texas A\&M AgriLife Research
        department: Texas Water Resources Institute
    orcid: 0000-0003-1876-6592
    email: michael.schramm@ag.tamu.edu
abstract: |
  This document includes figures and tables summarizing total loading estimates for the Lavaca River watershed.
thanks: |
  This project was funded by a Texas Coastal Management Program grant approved by the Texas Land Commissioner, providing financial assistance under the Coastal Zone Management Act of 1972, as amended, awarded by the National Oceanic and Atmospheric Administration (NOAA), Office for Coastal Management, pursuant to NOAA Award No. NA21NOS4190136. The views expressed herein are those of the author(s) and do not necessarily reflect the views of NOAA, the U.S. Department of Commerce, or any of their subagencies.
format: 
  pdf:
    keep-md: true
    keep-tex: true
    documentclass: article
    mainfont: MINIONPRO-REGULAR.OTF
    sansfont: MORISTONPERSONAL-REGULAR.OTF
    number-sections: true
    fig-pos: 'h'
    execute:
      eval: true
      echo: false
      warning: false
      error: false
      message: false
    include-in-header:
      text: |
        \usepackage{flafter, amsmath, booktabs, caption, longtable, changepage, multirow}
        \newenvironment{widestuff}{\begin{table}[h]\begin{adjustwidth}{-4.5cm}{-4.5cm}\centering}{\end{adjustwidth}\end{table}}
knitr: 
  opts_chunk: 
    dev: ragg_png
    dpi: 200
    # flextable options
    ft.align: "center"
    ft.latex.float: "none"
    #ft.tabcolsep: 0
    tab.lp: "tbl-"
bibliography: reference.yml
csl: https://raw.githubusercontent.com/TxWRI/csl/main/twri-technical-report.csl
---


::: {.cell}

:::



# Load estimation and summarization

Daily Nitrate-Nitrogen (NO~3~-N) and Total Phosphorus (TP) loads at stream sites were predicted using fitted GAM models. Standard deviations and credible intervals from GAM models can be obtained by drawing samples from the multivariate normal posterior distribution of the fitted GAM [@woodCONFIDENCEINTERVALSGENERALIZED2006; @marraCoveragePropertiesConfidence2012; @mcdowellImplicationsLagTimes2021]. Uncertainty in loads were reported as 95% credible intervals developed by drawing 1000 realizations of parameter estimates from the multivariate normal posterior distribution of the model parameters. We re-estimated the load for each realization and report the 2.5% and 97.5% quantiles. Monthly and annual loads were calculated by summing for each respective time period. 

Daily flow variability is responsible for the majority of daily load variability. WRTDS utilizes a flow- normalization procedure that removes the influence of flow variability by treating daily flow as a random sample of all possible discharges on a given day [@hirschWeightedRegressionsTime2010]. The flow-normalized estimates are not true estimates of load, but are indicative of potential changes in load that are not attributable to variability in daily flow. These flow-normalized estimates are most suitable for assessing changes in long-term trends. We implemented a similar procedure by setting flow-based covariates on each day of the year equal to each of the historical values for that day of the year between 2000 and 2021. The flow-normalized estimate is simply the mean of the model predictions for each day considering all of the flow values. Flow-normalized estimates and credible intervals were aggregated to annual reporting periods following procedures used for predicted actual loading.


# Total Load Estimates

## Lavaca River at Edna, USGS-08164000


::: {.cell}
::: {.cell-output-display}
![Aggregated (a) monthly and (b) annual NO~3~-N loads at Lavaca River at Edna, USGS-08164000.](load_estimates_files/figure-pdf/no3_aggregate-08164000-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Aggregated (a) monthly and (b) annual TP loads at Lavaca River at Edna, USGS-08164000.](load_estimates_files/figure-pdf/tp_aggregate-08164000-1.png)
:::
:::


\clearpage

## Navidad River at Palmetto Bend Dam, Lake Texana


::: {.cell}
::: {.cell-output-display}
![Aggregated (a) monthly and (b) annual NO~3~-N loads at Palmetto Bend Dam at Lake Texana.](load_estimates_files/figure-pdf/no3_aggregate-texana-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Aggregated (a) monthly and (b) annual TP loads at Palmetto Bend Dam at Lake Texana.](load_estimates_files/figure-pdf/tp_aggregate-texana-1.png)
:::
:::


\clearpage

## Total Export

### NO~3~-N


::: {.cell}
::: {.cell-output-display}
![Modelled monthly and annual total NO~3~-N input to Lavaca Bay](load_estimates_files/figure-pdf/no3_total_export-1.png)
:::
:::


\clearpage

### TP


::: {.cell}
::: {.cell-output-display}
![Modelled monthly and annual total TP input to Lavaca Bay](load_estimates_files/figure-pdf/tp_total_export-1.png)
:::
:::



\clearpage

# References
