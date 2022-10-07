---
title: "Supporting Materials: GAM Model Assessment"
author: 
  - name: Michael Schramm
    affiliations:
      - name: Texas A\&M AgriLife Research
        department: Texas Water Resources Institute
    orcid: 0000-0003-1876-6592
    email: michael.schramm@ag.tamu.edu
abstract: |
  This document includes model summaries and diagnostics for each Nitrate-Nitrogen (NO~3~-N) and Total Phosphorus (TP) Generalized Additive Model (GAM) developed in the Lavaca River Watershed.
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



# Modeling Approach

Site-specific Generalized Additive Models (GAMs) were developed for Nitrate-Nitrogen (NO~3~-N) and Total Phosphorus (TP). Previous papers suggest that other regression based load estimators, namely Weighted Regressions on Time Discharge and Season (WRTDS) produce results similar to GAMs where flow and season are primary drivers in nutrient loads [@beckNumericalQualitativeContrasts2017]. However, the mgcv package used to implement GAMs are easily extended to additional predictor variables and therefore chosen to be applied here [@beckNumericalQualitativeContrasts2017; @robsonPredictionSedimentParticulate2015a; @kuhnertQuantifyingTotalSuspended2012]. 

A suite of potential flow-based predictor variables were developed based on [@zhangImprovingRiverineConstituent2017].

$$
Y = s(ddate) + s(yday) + s(log1p(Q)) + s(stfa) + s(ma)
$$

where $Y$ is the response variable that is a function of the sum of some smoothed predictor variables. For each of the stream sites the response variable is daily NO~3~-N or TP load in kg/day. 

 - $ddate$ is date converted to decimal format;
 - $yday$ is the day of the year as a numeral between 1 and 366;
 - $log1p(Q)$ is mean daily streamflow plus one, log transformed;
 - $stfa$ is a short-term flow anomaly, a unitless term that reflects the difference in the current discharge from flows in the previous month;
 - $ma$ is the exponentially smoothed flow which is used to incorporate the influence of past flows on current load or concentration estimates;

The model was slightly altered for the Lake Texana site where daily load measurements are not a function of natural flow processes, but of operation decisions. Here, we expect concentration and load discharged from the dam to vary as a function of tributary inputs and some unknown lake metabolism processes. At this location, daily concentrations were modeled as a function of total inflow to the lake. Each of the flow based covariates ($log1p(Q)$, $stfa$, and $ma$) were calculated based on total inflow from gaged tributaries. Mean daily discharge was also included as a covariate under the assumption that hydraulic dynamics can substantially vary near the outlet of the dam based on the amount of water being discharged and influence nutrient concentration. Even under high inflow conditions, discharge might be low if it has been dry, conversely discharge could be higher than inflows if lake levels are high. Total loads below Palmetto Bend Dam were estimated using nutrient concentration in Lake Texana and reported mean daily dam discharges.

Thin plate regression splines were used for $ddate$, $log1p(Q)$, $ltfa$, and $ma$. A cyclic cubic regression spline was used for $yday$ to ensure ends of the spline match (day 1 and day 366 should match). First-order penalties were applied to the smooths of flow-based variables which penalize departures from a flat function to help constrain extrapolations for high flow measurements. GAMs were fit using the `gam()` function in the "mgcv" package in R version 4.2.1. Basis dimensions used for smooths were adjusted after using the `gam.check()` function to ensure models were not oversmoothed. Model residuals were inspected for distributional assumptions using the "gratia" package.

Left-censored nutrient concentrations were not uncommon in this dataset. Several methods are available to account for censored data. We decided to transform left-censored data to one-half the detection limit based on the fact that higher concentrations and loadings are typically associated with high-flow events and low-flow/low-concentration events will account for a small proportion of total loadings [@mcdowellImplicationsLagTimes2021]. The "cenGAM" package in R provides the Tobit I family to accommodate censored data using the "gam" function in R. Censored Gamma models can be fit using a Bayesian framework with the "brms" package in R. Initial exploration using "cenGAM" and "brms" packages resulted in models that overestimated nutrient concentrations relative to "mgcv" [@bergbuschUnexpectedShiftPhytoplankton2021]. All models were fit using the Gamma family and log link function.

Hold-out data is often used to validate predictive ability of a model. Given the small-sample size, we used all the available data to fit models at each site and implemented repeated 5-fold cross validation to assess model performance. Cross-validation predictions were assessed using King-Glupta Efficiency (KGE), R^2^, and Percent Bias across all folds.

# Model Results

## Lavaca River at Edna, 08164000 


::: {.cell}

:::


### NO~3~-N



::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-no3_08164000}NO\textsubscript{3}-N GAM summary - Lavaca River at Edna, USGS-08164000.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.089 & 0.100 & 20.955 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 1.482 & 17 & 0.164 & 0.111\\

 & s(yday) &  &  &  & 0.000 & 8 & 0.000 & 0.672\\

 & s(log1p(Flow)) &  &  &  & 6.897 & 9 & 25.880 & 0.000 ***\\

 & s(ma) &  &  &  & 0.001 & 5 & 0.000 & 0.391\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 4.125 & 5 & 3.882 & 0.001 ***\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.864, Deviance explained 0.844}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 245.609, Scale est: 0.735, N: 74}\\
\end{tabular}
\end{widestuff}
:::

::: {#tbl-NO308164000-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N GAM at Lavaca River at Edna, USGS-08164000.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** | **Median (IQR)**  |
|:--------------------------|:-----------------:|
|KGE                        | 0.74 (0.47, 0.83) |
|R^2^                       | 0.69 (0.57, 0.76) |
|Percent Bias               |   -8 (-21, -1)    |
:::
:::



\clearpage



::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for NO~3~-N model at USGS-08164000](model_assessment_files/figure-pdf/unnamed-chunk-4-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in NO~3~-N model at USGS-08164000](model_assessment_files/figure-pdf/unnamed-chunk-5-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily discharge and (b) predicted daily fluxes (for both sampled and non-sampled days) and measured daily fluxes.](model_assessment_files/figure-pdf/unnamed-chunk-6-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of NO~3~-N model predictions and observed values at USGS-08164000](model_assessment_files/figure-pdf/unnamed-chunk-7-1.png)
:::
:::



\clearpage


### TP



::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-tp_308164000}TP GAM summary - Lavaca River at Edna, USGS-08164000.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.926 & 0.047 & 61.761 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 1.607 & 17 & 0.166 & 0.121\\

 & s(yday) &  &  &  & 1.154 & 8 & 0.290 & 0.117\\

 & s(log1p(Flow)) &  &  &  & 3.867 & 4 & 42.896 & 0.000 ***\\

 & s(ma) &  &  &  & 3.443 & 5 & 2.329 & 0.004 **\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 1.971 & 4 & 1.143 & 0.045 *\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.784, Deviance explained 0.905}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 306.623, Scale est: 0.180, N: 80}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP308164000-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of TP load GAM at Lavaca River at Edna, USGS-08164000.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |  **Median (IQR)**  |
|:--------------------------|:------------------:|
|KGE                        | 0.64 (0.55, 0.71)  |
|R^2^                       | 0.53 (0.46, 0.60)  |
|Percent Bias               | -4.8 (-14.6, -3.3) |
:::
:::


\clearpage


::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for TP model at USGS-08164000](model_assessment_files/figure-pdf/unnamed-chunk-10-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in TP model at USGS-08164000](model_assessment_files/figure-pdf/unnamed-chunk-11-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily discharge and (b) predicted daily fluxes (for both sampled and non-sampled days) and measured daily fluxes.](model_assessment_files/figure-pdf/unnamed-chunk-12-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of TP model predictions and observed values at USGS-08164000](model_assessment_files/figure-pdf/unnamed-chunk-13-1.png)
:::
:::




\clearpage

## Navidad River at Strane Pk nr Edna, 08164390

### NO~3~




::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-no3_08164390}NO\textsubscript{3}-N GAM summary - Navidad River at Strane Pk nr Edna, USGS-08164390.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.107 & 0.071 & 29.581 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.626 & 17 & 0.066 & 0.164\\

 & s(yday) &  &  &  & 2.506 & 4 & 8.140 & 0.000 ***\\

 & s(log1p(Flow)) &  &  &  & 4.797 & 5 & 70.663 & 0.000 ***\\

 & s(stfa) &  &  &  & 0.984 & 5 & 0.215 & 0.294\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 0.750 & 4 & 0.305 & 0.123\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.703, Deviance explained 0.933}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 184.656, Scale est: 0.299, N: 59}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO308164390-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N concentration GAM at Navidad River at Strane Pk nr Edna,, USGS-NO308164390.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** | **Median (IQR)**  |
|:--------------------------|:-----------------:|
|KGE                        | 0.36 (0.22, 0.40) |
|R^2^                       | 0.38 (0.30, 0.49) |
|Percent Bias               |  -22 (-26, -16)   |
:::
:::


\clearpage


::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for NO~3~ model at USGS-08164390.](model_assessment_files/figure-pdf/unnamed-chunk-16-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in NO~3~-N model at USGS-08164390.](model_assessment_files/figure-pdf/unnamed-chunk-17-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily discharge and (b) predicted daily fluxes (for both sampled and non-sampled days) and measured daily fluxes.](model_assessment_files/figure-pdf/unnamed-chunk-18-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of NO~3~ model predictions and observed values at USGS-08164390.](model_assessment_files/figure-pdf/unnamed-chunk-19-1.png)
:::
:::


\clearpage

### TP




::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-tp_08164390}TP GAM summary - Navidad River at Strane Pk nr Edna, USGS-08164390.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.681 & 0.037 & 71.651 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 6.178 & 17 & 2.595 & 0.000 ***\\

 & s(yday) &  &  &  & 0.000 & 4 & 0.000 & 0.369\\

 & s(log1p(Flow)) &  &  &  & 4.910 & 5 & 316.610 & 0.000 ***\\

 & s(stfa) &  &  &  & 0.000 & 5 & 0.000 & 0.971\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 0.000 & 5 & 0.000 & 0.937\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.975, Deviance explained 0.961}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 254.624, Scale est: 0.108, N: 77}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164390-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of TP load GAM at Navidad River at Strane Pk nr Edna, USGS-08164390.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |  **Median (IQR)**   |
|:--------------------------|:-------------------:|
|KGE                        |  0.75 (0.59, 0.78)  |
|R^2^                       |  0.93 (0.84, 0.94)  |
|Percent Bias               | -10.2 (-18.2, -9.5) |
:::
:::


\clearpage


::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for TP model at USGS-08164390.](model_assessment_files/figure-pdf/unnamed-chunk-22-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in TP model at USGS-08164390.](model_assessment_files/figure-pdf/unnamed-chunk-23-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily discharge and (b) predicted daily fluxes (for both sampled and non-sampled days) and measured daily fluxes.](model_assessment_files/figure-pdf/unnamed-chunk-24-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of TP model predictions and observed values at USGS-08164390.](model_assessment_files/figure-pdf/unnamed-chunk-25-1.png)
:::
:::


\clearpage


## Sandy Creek nr Ganado, USGS-08164450

### NO~3~




::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-no3_08164450}NO\textsubscript{3}-N GAM summary - Sandy Creek nr Ganado, USGS-08164450.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.358 & 0.074 & 31.863 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.000 & 17 & 0.000 & 0.548\\

 & s(yday) &  &  &  & 1.951 & 4 & 2.492 & 0.004 **\\

 & s(log1p(Flow)) &  &  &  & 4.800 & 5 & 34.561 & 0.000 ***\\

 & s(stfa) &  &  &  & 2.457 & 5 & 0.986 & 0.086 +\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 3.842 & 5 & 3.507 & 0.001 **\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.793, Deviance explained 0.910}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 195.796, Scale est: 0.307, N: 56}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO308164450-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N concentration GAM at Sandy Creek nr Ganado, USGS-08164450.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** | **Median (IQR)**  |
|:--------------------------|:-----------------:|
|KGE                        | 0.44 (0.37, 0.47) |
|R^2^                       | 0.28 (0.26, 0.33) |
|Percent Bias               |   -16 (-20, -7)   |
:::
:::


\clearpage


::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for NO~3~ model at USGS-08164450.](model_assessment_files/figure-pdf/unnamed-chunk-28-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in NO~3~-N model at USGS-08164450.](model_assessment_files/figure-pdf/unnamed-chunk-29-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily discharge and (b) predicted daily fluxes (for both sampled and non-sampled days) and measured daily fluxes.](model_assessment_files/figure-pdf/unnamed-chunk-30-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of NO~3~ model predictions and observed values at USGS-08164450.](model_assessment_files/figure-pdf/unnamed-chunk-31-1.png)
:::
:::


\clearpage


### TP



::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-tp_08164450}TP GAM summary - Sandy Creek nr Ganado, USGS-08164450.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.633 & 0.073 & 35.934 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.487 & 17 & 0.038 & 0.251\\

 & s(yday) &  &  &  & 0.003 & 4 & 0.001 & 0.393\\

 & s(log1p(Flow)) &  &  &  & 8.200 & 9 & 57.412 & 0.000 ***\\

 & s(stfa) &  &  &  & 0.000 & 5 & 0.000 & 0.501\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 0.000 & 4 & 0.000 & 0.530\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.930, Deviance explained 0.887}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 269.592, Scale est: 0.403, N: 75}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164450-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of TP load GAM at Sandy Creek nr Ganado, USGS-08164450.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |  **Median (IQR)**  |
|:--------------------------|:------------------:|
|KGE                        | 0.69 (0.61, 0.73)  |
|R^2^                       | 0.80 (0.72, 0.87)  |
|Percent Bias               | -9.2 (-13.6, -7.6) |
:::
:::


\clearpage


::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for TP model at USGS-08164450.](model_assessment_files/figure-pdf/unnamed-chunk-34-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in TP model at USGS-08164450.](model_assessment_files/figure-pdf/unnamed-chunk-35-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily discharge and (b) predicted daily fluxes (for both sampled and non-sampled days) and measured daily fluxes.](model_assessment_files/figure-pdf/unnamed-chunk-36-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of TP model predictions and observed values at USGS-08164450.](model_assessment_files/figure-pdf/unnamed-chunk-37-1.png)
:::
:::


\clearpage


## E Mustang Creek nr Louise, USGS-08164504

### NO~3~




::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-no3_08164504}NO\textsubscript{3}-N GAM summary - E Mustang Creek nr Louise, USGS-08164504.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 0.404 & 0.231 & 1.751 &  &  &  & 0.086 +\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.000 & 5 & 0.000 & 0.350\\

 & s(yday) &  &  &  & 1.970 & 8 & 0.998 & 0.014 *\\

 & s(log1p(Flow)) &  &  &  & 3.731 & 4 & 46.681 & 0.000 ***\\

 & s(ma) &  &  &  & 0.000 & 5 & 0.000 & 0.933\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 0.001 & 4 & 0.000 & 0.498\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.567, Deviance explained 0.699}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 79.012, Scale est: 3.254, N: 61}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO308164504-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N load GAM at E Mustang Creek nr Louise, USGS-08164504.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |  **Median (IQR)**  |
|:--------------------------|:------------------:|
|KGE                        | 0.04 (-0.20, 0.07) |
|R^2^                       | 0.25 (0.10, 0.32)  |
|Percent Bias               |   -36 (-42, -28)   |
:::
:::


\clearpage


::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for NO~3~ model at USGS-08164504](model_assessment_files/figure-pdf/unnamed-chunk-40-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in NO~3~-N model at USGS-08164504](model_assessment_files/figure-pdf/unnamed-chunk-41-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily discharge and (b) predicted daily fluxes (for both sampled and non-sampled days) and measured daily fluxes.](model_assessment_files/figure-pdf/unnamed-chunk-42-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of NO~3~ model predictions and observed values at USGS-08164504](model_assessment_files/figure-pdf/unnamed-chunk-43-1.png)
:::
:::



\clearpage

### TP




::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-tp_08164504}TP GAM summary - E Mustang Creek nr Louise, USGS-08164504.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & -0.124 & 0.139 & -0.890 &  &  &  & 0.376\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 1.189 & 17 & 0.199 & 0.062 +\\

 & s(yday) &  &  &  & 1.178 & 8 & 0.303 & 0.122\\

 & s(log1p(Flow)) &  &  &  & 3.850 & 4 & 107.443 & 0.000 ***\\

 & s(ma) &  &  &  & 0.000 & 5 & 0.000 & 0.583\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 0.008 & 4 & 0.002 & 0.400\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.862, Deviance explained 0.749}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 77.488, Scale est: 1.532, N: 79}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164504-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of TP load GAM at E Mustang Creek nr Louise, USGS-08164504.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** | **Median (IQR)**  |
|:--------------------------|:-----------------:|
|KGE                        | 0.52 (0.48, 0.61) |
|R^2^                       | 0.78 (0.67, 0.82) |
|Percent Bias               |  -13 (-18, -12)   |
:::
:::



\clearpage


::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for TP model at USGS-08164504](model_assessment_files/figure-pdf/unnamed-chunk-46-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in TP model at USGS-08164504](model_assessment_files/figure-pdf/unnamed-chunk-47-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily discharge and (b) predicted daily fluxes (for both sampled and non-sampled days) and measured daily fluxes.](model_assessment_files/figure-pdf/unnamed-chunk-48-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of TP model predictions and observed values at USGS-08164504](model_assessment_files/figure-pdf/unnamed-chunk-49-1.png)
:::
:::


\clearpage

## W Mustang Creek nr Ganado, USGS-08164503

### NO~3~




::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-no3_08164503}NO\textsubscript{3}-N GAM summary - W Mustang Creek nr Ganado, USGS-08164503.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.575 & 0.088 & 29.196 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 1.143 & 17 & 0.204 & 0.052 +\\

 & s(yday) &  &  &  & 2.551 & 4 & 9.288 & 0.000 ***\\

 & s(log1p(Flow)) &  &  &  & 5.798 & 6 & 69.920 & 0.000 ***\\

 & s(ma) &  &  &  & 0.481 & 5 & 0.124 & 0.238\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 0.670 & 5 & 0.150 & 0.312\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.774, Deviance explained 0.879}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 242.088, Scale est: 0.490, N: 63}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO08164503-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N load GAM at W Mustang Creek nr Ganado, USGS-08164503.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** | **Median (IQR)**  |
|:--------------------------|:-----------------:|
|KGE                        | 0.36 (0.24, 0.49) |
|R^2^                       | 0.57 (0.44, 0.64) |
|Percent Bias               |  -32 (-40, -26)   |
:::
:::


\clearpage


::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for NO~3~ model at USGS-08164503](model_assessment_files/figure-pdf/unnamed-chunk-52-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in NO~3~-N model at USGS-08164503](model_assessment_files/figure-pdf/unnamed-chunk-53-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily discharge and (b) predicted daily fluxes (for both sampled and non-sampled days) and measured daily fluxes.](model_assessment_files/figure-pdf/unnamed-chunk-54-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of NO~3~ model predictions and observed values at USGS-08164503](model_assessment_files/figure-pdf/unnamed-chunk-55-1.png)
:::
:::



\clearpage

### TP




::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-tp_08164503}TP GAM summary - W Mustang Creek nr Ganado, USGS-08164503.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.641 & 0.060 & 43.895 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 2.181 & 17 & 0.468 & 0.019 *\\

 & s(yday) &  &  &  & 0.000 & 4 & 0.000 & 0.547\\

 & s(log1p(Flow)) &  &  &  & 8.118 & 9 & 81.410 & 0.000 ***\\

 & s(stfa) &  &  &  & 0.015 & 5 & 0.003 & 0.437\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 0.000 & 5 & 0.000 & 0.831\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.923, Deviance explained 0.880}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 291.984, Scale est: 0.293, N: 81}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164503-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of TP load GAM at W Mustang Creek nr Ganado, USGS-08164503.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |  **Median (IQR)**  |
|:--------------------------|:------------------:|
|KGE                        | 0.78 (0.73, 0.80)  |
|R^2^                       | 0.88 (0.87, 0.90)  |
|Percent Bias               | -7.0 (-12.1, -6.1) |
:::
:::


\clearpage


::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for TP model at USGS-08164503](model_assessment_files/figure-pdf/unnamed-chunk-58-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in TP model at USGS-08164503](model_assessment_files/figure-pdf/unnamed-chunk-59-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily discharge and (b) predicted daily fluxes (for both sampled and non-sampled days) and measured daily fluxes.](model_assessment_files/figure-pdf/unnamed-chunk-60-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of TP model predictions and observed values at USGS-08164503](model_assessment_files/figure-pdf/unnamed-chunk-61-1.png)
:::
:::


\clearpage


## Palmetto Bend Dam


### NO~3~




::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-no3_texana}NO\textsubscript{3}-N GAM summary - Navidad River at Palmetto Bend Dam.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & -1.384 & 0.113 & -12.212 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.000 & 8 & 0.000 & 0.605\\

 & s(yday) &  &  &  & 2.523 & 8 & 3.871 & 0.000 ***\\

 & s(log1p(Inflow)) &  &  &  & 0.000 & 4 & 0.000 & 0.714\\

 & s(log1p(Flow)) &  &  &  & 0.000 & 4 & 0.000 & 0.581\\

 & s(stfa) &  &  &  & 0.002 & 4 & 0.000 & 0.431\\

\multirow[t]{-6}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 2.884 & 5 & 2.769 & 0.002 **\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.466, Deviance explained 0.513}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -8.419, Scale est: 0.0355, N: 62}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO3PalmettoBend-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N load GAM at Palmetto Bend Dam.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** | **Median (IQR)**  |
|:--------------------------|:-----------------:|
|KGE                        | 0.30 (0.23, 0.51) |
|R^2^                       | 0.89 (0.87, 0.91) |
|Percent Bias               |  -38 (-43, -24)   |
:::
:::


\clearpage


::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for NO~3~ model below Palmetto Bend Dam.](model_assessment_files/figure-pdf/unnamed-chunk-64-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in NO~3~-N model below Palmetto Bend Dam.](model_assessment_files/figure-pdf/unnamed-chunk-65-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily inflows and (b) predicted daily concentration (for both sampled and non-sampled days) and measured daily concentration.](model_assessment_files/figure-pdf/unnamed-chunk-66-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of NO~3~ model predictions and observed values below Palmetto Bend Dam.](model_assessment_files/figure-pdf/unnamed-chunk-67-1.png)
:::
:::


\clearpage

### TP




::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-tp_texana}TP GAM summary - Navidad River at Palmetto Bend Dam.}
\centering
\begin{tabular}[t]{llllllrll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & -1.624 & 0.037 & -44.377 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 3.214 & 8 & 1.862 & 0.001 ***\\

 & s(yday) &  &  &  & 1.309 & 8 & 0.374 & 0.088 +\\

 & s(log1p(Inflow)) &  &  &  & 0.003 & 9 & 0.000 & 0.360\\

 & s(log1p(Flow)) &  &  &  & 1.104 & 4 & 0.561 & 0.098 +\\

 & s(stfa) &  &  &  & 0.000 & 5 & 0.000 & 0.470\\

\multirow[t]{-6}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 2.262 & 5 & 1.669 & 0.006 **\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.321, Deviance explained 0.388}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -99.963, Scale est: 0.00403, N: 81}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TPPalmettoBend-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of TP GAM at Palmetto Bend Dam.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |    **Median (IQR)**     |
|:--------------------------|:-----------------------:|
|KGE                        |    0.65 (0.62, 0.69)    |
|R^2^                       |  0.966 (0.950, 0.969)   |
|Percent Bias               | -18.20 (-20.60, -15.07) |
:::
:::


\clearpage


::: {.cell}
::: {.cell-output-display}
![Diagnostic plot for TP model below Palmetto Bend Dam.](model_assessment_files/figure-pdf/unnamed-chunk-70-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Partial effects of covariates in TP model below Palmetto Bend Dam.](model_assessment_files/figure-pdf/unnamed-chunk-71-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Comparisons of (a) in-sample and out-of-sample mean daily inflows and (b) predicted daily concentration (for both sampled and non-sampled days) and measured daily concentration.](model_assessment_files/figure-pdf/unnamed-chunk-72-1.png)
:::
:::

::: {.cell}
::: {.cell-output-display}
![Time series plot of TP model predictions and observed values below Palmetto Bend Dam.](model_assessment_files/figure-pdf/unnamed-chunk-73-1.png)
:::
:::



\clearpage






## References