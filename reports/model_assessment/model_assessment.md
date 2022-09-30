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

The model was slightly altered for the Lake Texana site where daily load measurements are not a function of natural flow processes, but of operation decisions. Here, we expect concentration to vary as a function of tributary inputs and some unknown lake metabolism processes. At this location, daily concentrations were modeled as a function of total inflow to the lake. Each of the flow based covariates ($log1p(Q)$, $stfa$, and $ma$) were calculated based on total inflow from gaged tributaries. Total loads below Palmetto Bend Dam are then estimated using nutrient concentration in Lake Texana and reported mean daily dam discharges.

Thin plate regression splines were used for $ddate$, $log1p(Q)$, $ltfa$, and $ma$. A cyclic cubic regression spline was used for $yday$ to ensure ends of the spline match (day 1 and day 366 should match). First-order penalties were applied to the smooths of flow-based variables which penalize departures from a flat function to help constrain extrapolations for high flow measurements. GAMs were fit using the `gam()` function in the "mgcv" package in R version 4.2.1. Basis dimensions used for smooths were adjusted after using the `gam.check()` function to ensure models were not oversmoothed. Model residuals were inspected for distributional assumptions using the "gratia" package.

Left-censored nutrient concentrations were not uncommon in this dataset. Several methods are available to account for censored data. We decided to transform left-censored data to one-half the detection limit based on the fact that higher concentrations and loadings are typically associated with high-flow events and low-flow/low-concentration events will account for a small proportion of total loadings [@mcdowellImplicationsLagTimes2021]. The "cenGAM" package in R provides the Tobit I family to accommodate censored data using the "gam" function in R. Censored Gamma models can be fit using a Bayesian framework with the "brms" package in R. Initial exploration using "cenGAM" and "brms" packages resulted in models that overestimated nutrient concentrations relative to "mgcv" [@bergbuschUnexpectedShiftPhytoplankton2021]. All models were fit using the Gamma family and log link function.

Hold-out data is often used to validate predictive ability of a model. Given the small-sample size, we used all the available data to fit models at each site and implemented repeated 10-fold cross validation to assess model performance. Cross-validation predictions were assessed using King-Glupta Efficiency (KGE), R^2^, and Percent Bias across all folds.

# Model Results

## Lavaca River at Edna, 08164000 


::: {.cell}

:::


### NO~3~-N



::: {.cell}
::: {.cell-output-display}
\begin{widestuff}

\caption{\label{tab:tbl-no3_08164000}NO\textsubscript{3}-N GAM summary - Lavaca River at Edna, USGS-08164000.}
\centering
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.089 & 0.100 & 20.955 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 1.482 & 17.000 & 0.164 & 0.111\\

 & s(yday) &  &  &  & 0.000 & 8.000 & 0.000 & 0.672\\

 & s(log1p(Flow)) &  &  &  & 6.897 & 9.000 & 25.879 & 0.000 ***\\

 & s(ma) &  &  &  & 0.001 & 5.000 & 0.000 & 0.391\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 4.125 & 5.000 & 3.882 & 0.001 ***\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.864, Deviance explained 0.844}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 245.609, Scale est: 0.735, N: 74}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO308164000-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of NO~3~-N GAM at Lavaca River at Edna, USGS-08164000.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |  **Median (IQR)**  |
|:--------------------------|:------------------:|
|KGE                        | 0.74 (0.58, 0.80)  |
|R^2^                       | 0.74 (0.66, 0.76)  |
|Percent Bias               | -8.7 (-15.9, -7.8) |
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
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.926 & 0.047 & 61.775 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 1.615 & 17.000 & 0.166 & 0.121\\

 & s(yday) &  &  &  & 1.203 & 8.000 & 0.302 & 0.117\\

 & s(log1p(Flow)) &  &  &  & 3.868 & 4.000 & 43.061 & 0.000 ***\\

 & s(ma) &  &  &  & 3.392 & 5.000 & 2.294 & 0.004 **\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 1.992 & 4.000 & 1.145 & 0.046 *\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.784, Deviance explained 0.905}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 306.645, Scale est: 0.179, N: 80}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP308164000-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of TP load GAM at Lavaca River at Edna, USGS-08164000.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** | **Median (IQR)**  |
|:--------------------------|:-----------------:|
|KGE                        | 0.59 (0.52, 0.70) |
|R^2^                       | 0.51 (0.40, 0.56) |
|Percent Bias               |   -8 (-14, -6)    |
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
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.106 & 0.070 & 29.903 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.671 & 17.000 & 0.072 & 0.163\\

 & s(yday) &  &  &  & 2.512 & 4.000 & 8.240 & 0.000 ***\\

 & s(log1p(Flow)) &  &  &  & 4.809 & 5.000 & 99.021 & 0.000 ***\\

 & s(ltfa) &  &  &  & 0.002 & 5.000 & 0.000 & 0.611\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 1.524 & 4.000 & 0.875 & 0.073 +\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.700, Deviance explained 0.933}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 184.491, Scale est: 0.293, N: 59}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO308164390-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of NO~3~-N concentration GAM at Navidad River at Strane Pk nr Edna,, USGS-NO308164390.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**   |
|:--------------------------|:--------------------:|
|KGE                        |  0.35 (0.27, 0.36)   |
|R^2^                       |  0.45 (0.39, 0.49)   |
|Percent Bias               | -23.2 (-29.8, -22.3) |
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
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.679 & 0.036 & 73.819 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 5.634 & 17.000 & 2.168 & 0.000 ***\\

 & s(yday) &  &  &  & 0.695 & 4.000 & 0.241 & 0.250\\

 & s(log1p(Flow)) &  &  &  & 4.912 & 5.000 & 334.375 & 0.000 ***\\

 & s(ltfa) &  &  &  & 0.851 & 5.000 & 0.767 & 0.018 *\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 0.000 & 5.000 & 0.000 & 0.568\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.975, Deviance explained 0.963}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 253.920, Scale est: 0.101, N: 77}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164390-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of TP load GAM at Navidad River at Strane Pk nr Edna, USGS-08164390.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**   |
|:--------------------------|:--------------------:|
|KGE                        | 0.783 (0.767, 0.797) |
|R^2^                       | 0.941 (0.932, 0.949) |
|Percent Bias               | -8.00 (-9.30, -7.73) |
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
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.358 & 0.074 & 31.864 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.000 & 17.000 & 0.000 & 0.548\\

 & s(yday) &  &  &  & 1.951 & 4.000 & 2.492 & 0.004 **\\

 & s(log1p(Flow)) &  &  &  & 4.800 & 5.000 & 34.560 & 0.000 ***\\

 & s(stfa) &  &  &  & 2.457 & 5.000 & 0.986 & 0.086 +\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 3.842 & 5.000 & 3.508 & 0.001 **\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.793, Deviance explained 0.910}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 195.798, Scale est: 0.307, N: 56}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO308164450-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of NO~3~-N concentration GAM at Sandy Creek nr Ganado, USGS-08164450.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** | **Median (IQR)**  |
|:--------------------------|:-----------------:|
|KGE                        | 0.44 (0.39, 0.49) |
|R^2^                       | 0.35 (0.33, 0.41) |
|Percent Bias               |  -16 (-21, -14)   |
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
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.631 & 0.073 & 36.086 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.582 & 17.000 & 0.049 & 0.230\\

 & s(yday) &  &  &  & 0.017 & 4.000 & 0.004 & 0.380\\

 & s(log1p(Flow)) &  &  &  & 8.206 & 9.000 & 58.072 & 0.000 ***\\

 & s(ltfa) &  &  &  & 0.191 & 5.000 & 0.043 & 0.302\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 0.000 & 4.000 & 0.000 & 0.534\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.927, Deviance explained 0.888}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 269.508, Scale est: 0.399, N: 75}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164450-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of TP load GAM at Sandy Creek nr Ganado, USGS-08164450.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |  **Median (IQR)**   |
|:--------------------------|:-------------------:|
|KGE                        |  0.64 (0.61, 0.69)  |
|R^2^                       |  0.78 (0.69, 0.80)  |
|Percent Bias               | -11.1 (-13.8, -8.8) |
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
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 0.405 & 0.231 & 1.752 &  &  &  & 0.085 +\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.000 & 5.000 & 0.000 & 0.350\\

 & s(yday) &  &  &  & 1.971 & 8.000 & 0.999 & 0.014 *\\

 & s(log1p(Flow)) &  &  &  & 3.731 & 4.000 & 46.682 & 0.000 ***\\

 & s(ma) &  &  &  & 0.000 & 5.000 & 0.000 & 0.933\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 0.001 & 4.000 & 0.000 & 0.498\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.568, Deviance explained 0.699}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 79.014, Scale est: 3.253, N: 61}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO308164504-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of NO~3~-N load GAM at E Mustang Creek nr Louise, USGS-08164504.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** | **Median (IQR)**  |
|:--------------------------|:-----------------:|
|KGE                        | 0.22 (0.19, 0.27) |
|R^2^                       | 0.34 (0.26, 0.43) |
|Percent Bias               |  -30 (-34, -17)   |
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
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & -0.124 & 0.139 & -0.889 &  &  &  & 0.377\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 1.189 & 17.000 & 0.199 & 0.062 +\\

 & s(yday) &  &  &  & 1.178 & 8.000 & 0.303 & 0.122\\

 & s(log1p(Flow)) &  &  &  & 3.850 & 4.000 & 107.446 & 0.000 ***\\

 & s(ma) &  &  &  & 0.000 & 5.000 & 0.000 & 0.583\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 0.008 & 4.000 & 0.002 & 0.400\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.862, Deviance explained 0.748}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 77.497, Scale est: 1.531, N: 79}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164504-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of TP load GAM at E Mustang Creek nr Louise, USGS-08164504.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**   |
|:--------------------------|:--------------------:|
|KGE                        |  0.49 (0.45, 0.56)   |
|R^2^                       |  0.71 (0.66, 0.78)   |
|Percent Bias               | -14.6 (-16.6, -10.8) |
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
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.575 & 0.088 & 29.194 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 1.143 & 17.000 & 0.204 & 0.052 +\\

 & s(yday) &  &  &  & 2.551 & 4.000 & 9.286 & 0.000 ***\\

 & s(log1p(Flow)) &  &  &  & 5.798 & 6.000 & 69.907 & 0.000 ***\\

 & s(ma) &  &  &  & 0.481 & 5.000 & 0.124 & 0.238\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 0.669 & 5.000 & 0.150 & 0.313\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.774, Deviance explained 0.879}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 242.096, Scale est: 0.490, N: 63}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO08164503-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of NO~3~-N load GAM at W Mustang Creek nr Ganado, USGS-08164503.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** | **Median (IQR)**  |
|:--------------------------|:-----------------:|
|KGE                        | 0.61 (0.35, 0.70) |
|R^2^                       | 0.60 (0.52, 0.62) |
|Percent Bias               |   -14 (-32, -8)   |
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
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & 2.641 & 0.060 & 43.895 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 2.181 & 17.000 & 0.468 & 0.019 *\\

 & s(yday) &  &  &  & 0.000 & 4.000 & 0.000 & 0.547\\

 & s(log1p(Flow)) &  &  &  & 8.118 & 9.000 & 81.409 & 0.000 ***\\

 & s(stfa) &  &  &  & 0.015 & 5.000 & 0.003 & 0.437\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 0.000 & 5.000 & 0.000 & 0.831\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.923, Deviance explained 0.880}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 291.985, Scale est: 0.293, N: 81}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164503-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of TP load GAM at W Mustang Creek nr Ganado, USGS-08164503.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**   |
|:--------------------------|:--------------------:|
|KGE                        |  0.77 (0.75, 0.79)   |
|R^2^                       |  0.89 (0.88, 0.89)   |
|Percent Bias               | -7.65 (-8.97, -6.70) |
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
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & -1.445 & 0.079 & -18.313 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.000 & 8.000 & 0.000 & 0.567\\

 & s(yday) &  &  &  & 2.572 & 8.000 & 4.185 & 0.000 ***\\

 & s(log1p(inflow)) &  &  &  & 0.474 & 4.000 & 0.160 & 0.217\\

 & s(ltfa) &  &  &  & 2.794 & 4.000 & 4.078 & 0.001 ***\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 2.137 & 5.000 & 1.000 & 0.048 *\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.539, Deviance explained 0.497}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -24.859, Scale est: 0.386, N: 62}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO3PalmettoBend-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of NO~3~-N load GAM at Palmetto Bend Dam.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**   |
|:--------------------------|:--------------------:|
|KGE                        | 0.435 (0.421, 0.452) |
|R^2^                       |  0.33 (0.29, 0.34)   |
|Percent Bias               |  -5.8 (-6.6, -4.8)   |
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
\begin{tabular}[t]{lllllllll}
\toprule
Component & Term & Estimate & Std.Error & t-value & edf & ref.df & F-value & p-value\textsuperscript{1}\\
\midrule
A. parametric coefficients & (Intercept) & -1.642 & 0.034 & -48.597 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 2.223 & 9.000 & 1.293 & 0.003 **\\

 & s(yday) &  &  &  & 0.214 & 8.000 & 0.030 & 0.323\\

 & s(log1p(inflow)) &  &  &  & 0.000 & 9.000 & 0.000 & 0.425\\

 & s(ltfa) &  &  &  & 3.271 & 5.000 & 2.981 & 0.001 **\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 2.284 & 5.000 & 1.335 & 0.023 *\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.364, Deviance explained 0.315}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -88.355, Scale est: 0.0925, N: 81}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TPPalmettoBend-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 10-fold cross-validation of TP GAM at Palmetto Bend Dam.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**   |
|:--------------------------|:--------------------:|
|KGE                        | 0.267 (0.260, 0.292) |
|R^2^                       | 0.201 (0.186, 0.231) |
|Percent Bias               | -1.45 (-1.88, -1.00) |
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