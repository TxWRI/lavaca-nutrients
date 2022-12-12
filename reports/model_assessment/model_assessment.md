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

Hold-out data is often used to validate predictive ability of a model. Given the small-sample size, we used all the available data to fit models at each site and implemented repeated 5-fold cross validation to assess model performance. Cross-validation predictions were assessed using Nash-Sutcliffe Efficiency (NSE), R^2^, and Percent Bias across all folds.

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
A. parametric coefficients & (Intercept) & -1.950 & 0.146 & -13.335 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 1.977 & 17 & 0.299 & 0.036 *\\

 & s(yday) &  &  &  & 0.001 & 4 & 0.000 & 0.442\\

 & s(log1p(Flow)) &  &  &  & 2.320 & 9 & 0.724 & 0.019 *\\

 & s(ma) &  &  &  & 0.000 & 9 & 0.000 & 0.917\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ltfa) &  &  &  & 0.000 & 9 & 0.000 & 0.445\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.107, Deviance explained 0.255}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -58.587, Scale est: 1.582, N: 74}\\
\end{tabular}
\end{widestuff}
:::

::: {#tbl-NO308164000-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N GAM at Lavaca River at Edna, USGS-08164000.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**   |
|:--------------------------|:--------------------:|
|NSE                        |  0.56 (0.25, 0.83)   |
|R^2^                       |  0.76 (0.53, 0.92)   |
|Percent Bias               | 1.25 (-26.40, 23.18) |
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
A. parametric coefficients & (Intercept) & -1.611 & 0.045 & -35.811 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 3.262 & 17 & 0.408 & 0.045 *\\

 & s(yday) &  &  &  & 1.266 & 8 & 0.352 & 0.094 +\\

 & s(log1p(Flow)) &  &  &  & 0.953 & 4 & 0.405 & 0.133\\

 & s(ma) &  &  &  & 0.000 & 5 & 0.000 & 0.510\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 2.585 & 4 & 2.857 & 0.003 **\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.274, Deviance explained 0.250}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -70.944, Scale est: 0.162, N: 80}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP308164000-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of TP load GAM at Lavaca River at Edna, USGS-08164000.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**   |
|:--------------------------|:--------------------:|
|NSE                        |  0.80 (0.71, 0.86)   |
|R^2^                       |  0.94 (0.83, 0.98)   |
|Percent Bias               | -8.70 (-20.65, 7.45) |
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
A. parametric coefficients & (Intercept) & -2.037 & 0.102 & -20.057 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 1.685 & 17 & 0.781 & 0.001 ***\\

 & s(yday) &  &  &  & 2.486 & 4 & 5.143 & 0.000 ***\\

 & s(log1p(Flow)) &  &  &  & 4.072 & 5 & 11.579 & 0.000 ***\\

 & s(ma) &  &  &  & 2.227 & 4 & 3.098 & 0.001 **\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ltfa) &  &  &  & 0.001 & 9 & 0.000 & 0.387\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.717, Deviance explained 0.767}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -46.034, Scale est: 0.00733, N: 59}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO308164390-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N concentration GAM at Navidad River at Strane Pk nr Edna,, USGS-NO308164390.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**    |
|:--------------------------|:---------------------:|
|NSE                        |   0.54 (0.23, 0.78)   |
|R^2^                       |   0.83 (0.74, 0.97)   |
|Percent Bias               | -3.55 (-26.55, 36.45) |
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
A. parametric coefficients & (Intercept) & -1.597 & 0.038 & -42.298 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 7.120 & 17 & 3.465 & 0.000 ***\\

 & s(yday) &  &  &  & 0.456 & 4 & 0.147 & 0.270\\

 & s(log1p(Flow)) &  &  &  & 2.630 & 5 & 2.428 & 0.002 **\\

 & s(stfa) &  &  &  & 0.000 & 5 & 0.000 & 0.690\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 0.000 & 5 & 0.000 & 0.759\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.550, Deviance explained 0.486}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -76.491, Scale est: 0.110, N: 77}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164390-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of TP load GAM at Navidad River at Strane Pk nr Edna, USGS-08164390.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**   |
|:--------------------------|:--------------------:|
|NSE                        |  0.93 (0.90, 0.95)   |
|R^2^                       |  0.98 (0.92, 0.99)   |
|Percent Bias               | -9.35 (-15.17, 2.90) |
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
A. parametric coefficients & (Intercept) & -1.946 & 0.080 & -24.212 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.000 & 17 & 0.000 & 0.916\\

 & s(yday) &  &  &  & 2.005 & 4 & 2.720 & 0.003 **\\

 & s(log1p(Flow)) &  &  &  & 2.391 & 5 & 1.043 & 0.071 +\\

 & s(ma) &  &  &  & 4.107 & 5 & 4.440 & 0.000 ***\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ltfa) &  &  &  & 0.605 & 5 & 0.138 & 0.302\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.274, Deviance explained 0.518}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -51.543, Scale est: 0.362, N: 56}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO308164450-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N concentration GAM at Sandy Creek nr Ganado, USGS-08164450.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**    |
|:--------------------------|:---------------------:|
|NSE                        |   0.40 (0.03, 0.57)   |
|R^2^                       |   0.67 (0.46, 0.90)   |
|Percent Bias               | -0.35 (-31.05, 21.47) |
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
A. parametric coefficients & (Intercept) & -1.729 & 0.067 & -25.973 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 9.316 & 17 & 4.295 & 0.000 ***\\

 & s(yday) &  &  &  & 0.000 & 4 & 0.000 & 0.730\\

 & s(log1p(Flow)) &  &  &  & 6.939 & 9 & 2.967 & 0.000 ***\\

 & s(stfa) &  &  &  & 2.097 & 5 & 0.757 & 0.090 +\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 2.171 & 4 & 3.529 & 0.000 ***\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.757, Deviance explained 0.824}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -34.024, Scale est: 0.00944, N: 75}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164450-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of TP load GAM at Sandy Creek nr Ganado, USGS-08164450.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**    |
|:--------------------------|:---------------------:|
|NSE                        |   0.62 (0.45, 0.86)   |
|R^2^                       |   0.87 (0.66, 0.97)   |
|Percent Bias               | -1.35 (-24.92, 13.50) |
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
A. parametric coefficients & (Intercept) & -0.481 & 0.159 & -3.028 &  &  &  & 0.004 **\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.000 & 17 & 0.000 & 0.788\\

 & s(yday) &  &  &  & 2.557 & 4 & 6.590 & 0.000 ***\\

 & s(log1p(Flow)) &  &  &  & 2.794 & 4 & 3.692 & 0.001 **\\

 & s(ma) &  &  &  & 0.000 & 5 & 0.000 & 0.684\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ltfa) &  &  &  & 0.000 & 9 & 0.000 & 0.892\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.348, Deviance explained 0.498}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : 43.673, Scale est: 1.542, N: 61}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO308164504-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N load GAM at E Mustang Creek nr Louise, USGS-08164504.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**    |
|:--------------------------|:---------------------:|
|NSE                        |  0.15 (-0.68, 0.60)   |
|R^2^                       |   0.86 (0.66, 0.97)   |
|Percent Bias               | -6.75 (-55.98, 68.28) |
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
A. parametric coefficients & (Intercept) & -1.001 & 0.081 & -12.331 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.044 & 17 & 0.003 & 0.343\\

 & s(yday) &  &  &  & 0.385 & 8 & 0.057 & 0.293\\

 & s(log1p(Flow)) &  &  &  & 1.642 & 4 & 1.416 & 0.005 **\\

 & s(ma) &  &  &  & 1.184 & 5 & 0.447 & 0.086 +\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(stfa) &  &  &  & 1.015 & 4 & 0.415 & 0.117\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.263, Deviance explained 0.246}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -2.438, Scale est: 0.521, N: 79}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164504-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of TP load GAM at E Mustang Creek nr Louise, USGS-08164504.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**    |
|:--------------------------|:---------------------:|
|NSE                        |   0.71 (0.57, 0.88)   |
|R^2^                       |   0.88 (0.77, 0.97)   |
|Percent Bias               | -0.10 (-29.03, 13.05) |
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
A. parametric coefficients & (Intercept) & -1.244 & 0.085 & -14.678 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 1.556 & 17 & 0.462 & 0.006 **\\

 & s(yday) &  &  &  & 2.672 & 4 & 13.475 & 0.000 ***\\

 & s(log1p(Flow)) &  &  &  & 5.453 & 6 & 11.500 & 0.000 ***\\

 & s(ma) &  &  &  & 0.118 & 5 & 0.024 & 0.346\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ltfa) &  &  &  & 2.270 & 9 & 0.928 & 0.007 **\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.510, Deviance explained 0.673}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -3.704, Scale est: 0.453, N: 63}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO08164503-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N load GAM at W Mustang Creek nr Ganado, USGS-08164503.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |    **Median (IQR)**    |
|:--------------------------|:----------------------:|
|NSE                        |   0.43 (-0.58, 0.65)   |
|R^2^                       |   0.90 (0.53, 0.98)    |
|Percent Bias               | -10.65 (-43.88, 74.47) |
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
A. parametric coefficients & (Intercept) & -1.150 & 0.063 & -18.148 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 2.054 & 17 & 0.411 & 0.025 *\\

 & s(yday) &  &  &  & 0.000 & 4 & 0.000 & 0.573\\

 & s(log1p(Flow)) &  &  &  & 0.000 & 9 & 0.000 & 0.648\\

 & s(stfa) &  &  &  & 0.235 & 5 & 0.050 & 0.342\\

\multirow[t]{-5}{*}{\raggedright\arraybackslash B. smooth terms} & s(ma) &  &  &  & 0.285 & 5 & 0.067 & 0.293\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.0843, Deviance explained 0.142}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -33.755, Scale est: 0.325, N: 81}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-TP08164503-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of TP load GAM at W Mustang Creek nr Ganado, USGS-08164503.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**    |
|:--------------------------|:---------------------:|
|NSE                        |   0.86 (0.72, 0.89)   |
|R^2^                       |   0.91 (0.75, 0.95)   |
|Percent Bias               | -5.75 (-15.43, 10.45) |
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
A. parametric coefficients & (Intercept) & -1.450 & 0.087 & -16.634 &  &  &  & 0.000 ***\\
\cmidrule{1-9}
 & s(ddate) &  &  &  & 0.000 & 9 & 0.000 & 0.779\\

 & s(yday) &  &  &  & 2.836 & 8 & 5.179 & 0.000 ***\\

 & s(log1p(Inflow)) &  &  &  & 0.000 & 4 & 0.000 & 0.467\\

 & s(log1p(Flow)) &  &  &  & 6.058 & 9 & 2.712 & 0.000 ***\\

 & s(ma) &  &  &  & 2.665 & 5 & 2.101 & 0.002 **\\

\multirow[t]{-6}{*}{\raggedright\arraybackslash B. smooth terms} & s(ltfa) &  &  &  & 4.781 & 9 & 3.193 & 0.000 ***\\
\bottomrule
\multicolumn{9}{l}{\textsuperscript{1} Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1}\\
\multicolumn{9}{l}{\textsuperscript{} Adjusted R-squared: 0.746, Deviance explained 0.812}\\
\multicolumn{9}{l}{\textsuperscript{} -REML : -15.004, Scale est: 0.017, N: 62}\\
\end{tabular}
\end{widestuff}
:::
:::

::: {#tbl-NO3PalmettoBend-CV .cell tbl-cap='Summary of goodness-of-fit metrics for 5-fold cross-validation of NO~3~-N load GAM at Palmetto Bend Dam.'}
::: {.cell-output-display}
|**Goodness of Fit Metric** |   **Median (IQR)**    |
|:--------------------------|:---------------------:|
|NSE                        |  0.47 (-0.17, 0.70)   |
|R^2^                       |   0.90 (0.76, 0.98)   |
|Percent Bias               | 15.75 (-22.45, 56.75) |
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
|**Goodness of Fit Metric** |   **Median (IQR)**   |
|:--------------------------|:--------------------:|
|NSE                        |  0.91 (0.87, 0.97)   |
|R^2^                       |  1.00 (0.93, 1.00)   |
|Percent Bias               | -3.75 (-16.17, 4.80) |
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