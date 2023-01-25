library(targets)

source("R/Data.R")
source("R/Models.R")
source("R/CV.R")
source("R/TABLES.R")
source("R/FIGURES.R")
source("R/LOADESTIMATE.R")
source("R/prediction_gams.R")
source("R/write_files.R")
source("R/spatial_outputs.R")
options(tidyverse.quiet = TRUE)
targets::tar_option_set(packages = c("adc", 
                                     "arrow", 
                                     "dataRetrieval", 
                                     "dplyr", 
                                     "FedData",
                                     "flextable", 
                                     "fs", 
                                     "furrr", 
                                     "ggplot2", 
                                     "ggrepel",
                                     "ggspatial",
                                     "ggtext",
                                     "glue",
                                     "gratia", 
                                     "hydroGOF", 
                                     "imputeTS", 
                                     "janitor", 
                                     "lubridate", 
                                     "kableExtra",
                                     "mgcv",
                                     "modelsummary",
                                     "MuMIn",
                                     "patchwork", 
                                     "purrr", 
                                     "ragg",
                                     "quarto", 
                                     "readr", 
                                     "rcartocolor",
                                     "rsample",
                                     "scico",
                                     "sf",
                                     "tarchetypes",
                                     "tibble",
                                     "tidyr", 
                                     "tidyselect", 
                                     "twriTemplates",  
                                     "units", 
                                     "yardstick"))
library(tarchetypes)


list(
  ## read and format data ----
  tar_target(
    wqpdata, download_WQP_data()
    ),
  tar_target(
    qdata, download_Q_data()
    ),
  tar_target(
    model_data, clean_data(wqpdata, qdata)
    ),
  tar_target(flow_normalized_data,
             fn_data(model_data)
             ),
  tar_target(flow_normalized_lk_data,
             fn_lk_data(model_data)
  ),
  
  ## fit GAM models ----
  
  ### Lavaca River at Edna ----
  
  #### NO3-N
  tar_target(
    no3_08164000, {
      df <- model_data |> 
        filter(site_no == "usgs08164000") |> 
        filter(!is.na(NO3))
      
      model_gam(formula = trans_NO3 ~
                  s(ddate, bs = "tp", k = 18, m = 1) +
                  s(yday, k = 6, bs = "cc") +
                  s(log1p_Flow, k = 10, bs = "tp", m = 1) +
                  s(ma, k = 10, bs = "tp", m = 1) +
                  s(ltfa, k = 10, bs = "tp", m = 1),
                data = df,
                family = gaussian(link = "log")
                )
      }
    ),
  #### Cross-validate NO3-N GAMs to evaluate fit to new data ----
  tar_target(
    cv_no3_08164000, {

      df <- model_data |>
        filter(site_no == "usgs08164000") |>
        filter(!is.na(NO3))

      cross_validate(model = no3_08164000,
                     data = df,
                     constituent = NO3_flux)}
  ),

  #### TP GAM
  tar_target(
    tp_08164000, model_gam(formula = trans_TP ~
                             s(ddate, bs = "tp", k = 18, m = 1) +
                             s(yday, bs = "cc") +
                             s(log1p_Flow, k = 5, bs = "tp", m = 1) +
                             s(ma, k = 6, bs = "tp", m = 1) +
                             s(stfa, k = 5, bs = "tp", m = 1),
                           data = model_data |> filter(site_no == "usgs08164000"),
                           family = gaussian(link = "log"))
  ),

  #### TP CV
  tar_target(
    cv_tp_08164000, {

      df <- model_data |>
        filter(site_no == "usgs08164000") |>
        filter(!is.na(TP))

      cross_validate(model = tp_08164000,
                     data = df,
                     constituent = TP_flux)}
  ),



  ### E Mustang Creek nr Louise ----

  #### NO3
  tar_target(
    no3_08164504, model_gam(formula = trans_NO3 ~
                              s(ddate, bs = "tp", k = 18, m = 1) +
                              s(yday, k = 6, bs = "cc") +
                              s(log1p_Flow, k = 5, bs = "tp", m = 1) +
                              s(ma, k = 6, bs = "tp", m = 1) +
                              s(ltfa, k = 10, bs = "tp", m = 1),
                            data = model_data |> filter(site_no == "usgs08164504"),
                            family = gaussian(link = "log"))
  ),

  #### CV NO3 ----
  tar_target(
    cv_no3_08164504, {

      df <- model_data |>
        filter(site_no == "usgs08164504") |>
        filter(!is.na(NO3))

      cross_validate(model = no3_08164504,
                     data = df,
                     constituent = NO3_flux)}
  ),

  #### GAM TP
  tar_target(
    tp_08164504, model_gam(formula = trans_TP ~
                             s(ddate, bs = "tp", k = 18) +
                             s(yday, bs = "cc") +
                             s(log1p_Flow, k = 5, bs = "tp", m = 1) +
                             s(ma, k = 6, bs = "tp", m = 1) +
                             s(stfa, k = 5, bs = "tp", m = 1),
                           data = model_data |> filter(site_no == "usgs08164504"),
                           family = gaussian(link = "log"))
  ),

  #### CV TP ----
  tar_target(
    cv_tp_08164504, {

      df <- model_data |>
        filter(site_no == "usgs08164504") |>
        filter(!is.na(TP))

      cross_validate(model = tp_08164504,
                     data = df,
                     constituent = TP_flux)}
  ),

  ### W Mustang Creek nr Ganado ----

  #### NO3 ----
  tar_target(
    no3_08164503, model_gam(formula = trans_NO3 ~
                              s(ddate, bs = "tp", k = 18) +
                              s(yday, k = 6, bs = "cc") +
                              s(log1p_Flow, k = 7, bs = "tp", m = 1) +
                              s(ma, k = 6, bs = "tp", m = 1) +
                              s(ltfa, k = 10, bs = "tp", m = 1),
                            data = model_data |> filter(site_no == "usgs08164503"),
                            family = gaussian(link = "log"))
  ),

  #### CV NO3 ----
  tar_target(
    cv_no3_08164503, {

      df <- model_data |>
        filter(site_no == "usgs08164503") |>
        filter(!is.na(NO3))

      cross_validate(model = no3_08164503,
                     data = df,
                     constituent = NO3_flux)}
  ),

  #### TP ----
  tar_target(
    tp_08164503, model_gam(formula = trans_TP ~
                             s(ddate, bs = "tp", k = 18) +
                             s(yday, k = 6, bs = "cc") +
                             s(log1p_Flow, k = 10, bs = "tp", m = 1) +
                             s(stfa, k = 6, bs = "tp", m = 1) +
                             s(ma, k = 6, bs = "tp", m = 1),
                           data = model_data |> filter(site_no == "usgs08164503"),
                           family = gaussian(link = "log"))
  ),
  #### CV TP ----
  tar_target(
    cv_tp_08164503, {

      df <- model_data |>
        filter(site_no == "usgs08164503") |>
        filter(!is.na(TP))

      cross_validate(model = tp_08164503,
                     data = df,
                     constituent = TP_flux)}
  ),

  ### Sandy Creek nr Ganado ----

  #### NO3 -----
  tar_target(
    no3_08164450, model_gam(formula = trans_NO3 ~
                              s(ddate, bs = "tp", k = 18) +
                              s(yday, k = 6, bs = "cc") +
                              s(log1p_Flow, k = 6, bs = "tp", m = 1) +
                              s(ma, k = 6, bs = "tp", m = 1) +
                              s(ltfa, k = 6, bs = "tp", m = 1),
                            data = model_data |> filter(site_no == "usgs08164450"),
                            family = gaussian(link = "log"))
  ),
  #### CV NO3 ----
  tar_target(
    cv_no3_08164450, {

      df <- model_data |>
        filter(site_no == "usgs08164450") |>
        filter(!is.na(NO3))

      cross_validate(model = no3_08164450,
                     data = df,
                     constituent = NO3_flux)}
  ),

  #### TP -----
  tar_target(
    tp_08164450, model_gam(formula = trans_TP ~
                             s(ddate, bs = "tp", k = 18) +
                             s(yday, k = 6, bs = "cc") +
                             s(log1p_Flow, k = 10, bs = "tp", m = 1) +
                             s(stfa, k = 6, bs = "tp", m = 1) +
                             s(ma, k = 5, bs = "tp", m = ),
                           data = model_data |> filter(site_no == "usgs08164450"),
                           family = gaussian(link = "log"))
  ),
  #### CV TP ----
  tar_target(
    cv_tp_08164450, {

      df <- model_data |>
        filter(site_no == "usgs08164450") |>
        filter(!is.na(TP))

      cross_validate(model = tp_08164450,
                     data = df,
                     constituent = TP_flux)}
  ),

  ### Navidad River at Strane Pk nr Edna ----

  #### NO3
  tar_target(
    no3_08164390, model_gam(formula = trans_NO3 ~
                              s(ddate, bs = "tp", k = 18) +
                              s(yday, k = 6, bs = "cc") +
                              s(log1p_Flow, k = 6, bs = "tp",  m = 1) +
                              s(ma, k = 5, bs = "tp", m = 1) +
                              s(ltfa, k = 10, bs = "tp", m = 1),
                            data = model_data |> filter(site_no == "usgs08164390"),
                            family = gaussian(link = "log"))
  ),

  #### CV NO3 ----
  tar_target(
    cv_no3_08164390, {

      df <- model_data |>
        filter(site_no == "usgs08164390") |>
        filter(!is.na(NO3))

      cross_validate(model = no3_08164390,
                     data = df,
                     constituent = NO3_flux)}
  ),

  #### TP -----
  tar_target(
    tp_08164390, model_gam(formula = trans_TP ~
                             s(ddate, bs = "tp", k = 18) +
                             s(yday, k = 6, bs = "cc") +
                             s(log1p_Flow, k = 6, bs = "tp", m = 1) +
                             s(stfa, k = 6, bs = "tp") +
                             s(ma, k = 6, bs = "tp"),
                           data = model_data |> filter(site_no == "usgs08164390"),
                           family = gaussian(link = "log"))
  ),

  #### CV TP ----
  tar_target(
    cv_tp_08164390, {

      df <- model_data |>
        filter(site_no == "usgs08164390") |>
        filter(!is.na(TP))

      cross_validate(model = tp_08164390,
                     data = df,
                     constituent = TP_flux)}
  ),


  # for the lake outlet we model the concentration at the outlet as a function
  # of the total inflow, time, and related antecedent flow conditions.
  # total load is estimate as lake discharge x concentration.

  # note the family is gaussian with log link to better fit residuals

  ## goodness of fit metrics are evaluated by load for consistency with other models.


  ## below lk texana ----

  ### NO3 ----
  tar_target(
    no3_texana, gam_b_texana(
      formula = trans_NO3 ~
        s(ddate, k = 10, bs = "tp", m = 1) +
        s(yday, k = 10, bs = "cc") +
        s(log1p_inflow, k = 5, bs = "tp", m = 1) +
        s(log1p_Flow, k = 10, bs = "tp", m = 1) +
        s(ma, k = 6, bs = "tp", m = 1) +
        s(ltfa, k = 10, bs = "tp", m = 1),
      data = model_data,
      family = gaussian(link = "log")
    )
  ),

  ### CV NO3----
  tar_target(
    cv_no3_texana, {

      df <- format_dam_data(model_data) |>
        filter(!is.na(NO3))

      cross_validate(model = no3_texana,
                     data = df,
                     constituent = NO3_flux,
                     strata = log1p_Flow)}
  ),

  ### TP -----
  tar_target(
    tp_texana, gam_b_texana(
      formula = trans_TP ~
        s(ddate, bs = "tp", m = 1) +
        s(yday, k = 10, bs = "cc") +
        s(log1p_inflow, k = 10, bs = "tp", m = 1) +
        s(log1p_Flow, k = 5, bs = "tp", m = 1) +
        s(stfa, k = 6, bs = "tp", m = 1) +
        s(ma, k = 6, bs = "tp", m = 1),
      data = model_data,
      family = gaussian(link = "log")
    )
  ),

  ### CV TP----
  tar_target(
    cv_tp_texana, {

      df <- format_dam_data(model_data) |>
        filter(!is.na(TP))

      cross_validate(model = tp_texana,
                     data = df,
                     constituent = TP_flux,
                     strata = log1p_Flow)}
  ),

  ## print model outputs and appraisal ----
  ### model_summaries----
  tar_target(summary_no3_08164000,
             gam_gt(no3_08164000,
                    caption = "NO\\textsubscript{3}-N GAM summary - Lavaca River at Edna, USGS-08164000.",
                    label = "tbl-no3_08164000")),
  tar_target(summary_tp_08164000,
             gam_gt(tp_08164000,
                    caption = "TP GAM summary - Lavaca River at Edna, USGS-08164000.",
                    label = "tbl-tp_308164000")),
  tar_target(summary_no3_08164504,
             gam_gt(no3_08164504,
                    caption = "NO\\textsubscript{3}-N GAM summary - E Mustang Creek nr Louise, USGS-08164504.",
                    label = "tbl-no3_08164504")),
  tar_target(summary_tp_08164504,
             gam_gt(tp_08164504,
                    caption = "TP GAM summary - E Mustang Creek nr Louise, USGS-08164504.",
                    label = "tbl-tp_08164504")),
  tar_target(summary_no3_08164503,
             gam_gt(no3_08164503,
                    caption = "NO\\textsubscript{3}-N GAM summary - W Mustang Creek nr Ganado, USGS-08164503.",
                    label = "tbl-no3_08164503")),
  tar_target(summary_tp_08164503,
             gam_gt(tp_08164503,
                    caption = "TP GAM summary - W Mustang Creek nr Ganado, USGS-08164503.",
                    label = "tbl-tp_08164503")),
  tar_target(summary_no3_08164450,
             gam_gt(no3_08164450,
                    caption = "NO\\textsubscript{3}-N GAM summary - Sandy Creek nr Ganado, USGS-08164450.",
                    label = "tbl-no3_08164450")),
  tar_target(summary_tp_08164450,
             gam_gt(tp_08164450,
                    caption = "TP GAM summary - Sandy Creek nr Ganado, USGS-08164450.",
                    label = "tbl-tp_08164450")),
  tar_target(summary_no3_08164390,
             gam_gt(no3_08164390,
                    caption = "NO\\textsubscript{3}-N GAM summary - Navidad River at Strane Pk nr Edna, USGS-08164390.",
                    label = "tbl-no3_08164390")),
  tar_target(summary_tp_08164390,
             gam_gt(tp_08164390,
                    caption = "TP GAM summary - Navidad River at Strane Pk nr Edna, USGS-08164390.",
                    label = "tbl-tp_08164390")),
  tar_target(summary_no3_texana,
             gam_gt(no3_texana,
                    caption = "NO\\textsubscript{3}-N GAM summary - Navidad River at Palmetto Bend Dam.",
                    label = "tbl-no3_texana")),
  tar_target(summary_tp_texana,
             gam_gt(tp_texana,
                    caption = "TP GAM summary - Navidad River at Palmetto Bend Dam.",
                    label = "tbl-tp_texana")),

  ### bias plots
  tar_target(bias_plot_no3_08164000,
             prediction_bias(model = no3_08164000,
                             df = model_data,
                             site = "usgs08164000",
                             date = "2005-01-01",
                             constituent = NO3_flux,
                             p2_x_labs = c("Predicted Flux", "Observed Flux"),
                             p2_y_title = "NO<sub>3</sub>-N Flux (kg/day)")),
  tar_target(bias_plot_tp_08164000,
             prediction_bias(model = tp_08164000,
                             df = model_data,
                             site = "usgs08164000",
                             date = "2000-01-01",
                             constituent = TP_flux,
                             p2_x_labs = c("Predicted Flux", "Observed Flux"),
                             p2_y_title = "TP Flux (kg/day)")),
  tar_target(bias_plot_no3_08164504,
             prediction_bias(model = no3_08164504,
                             df = model_data,
                             site = "usgs08164504",
                             date = "2005-01-01",
                             constituent = NO3_flux,
                             p2_x_labs = c("Predicted Flux", "Observed Flux"),
                             p2_y_title = "NO<sub>3</sub>-N Flux (kg/day)")),
  tar_target(bias_plot_tp_08164504,
             prediction_bias(model = tp_08164504,
                             df = model_data,
                             site = "usgs08164504",
                             date = "2000-01-01",
                             constituent = TP_flux,
                             p2_x_labs = c("Predicted Flux", "Observed Flux"),
                             p2_y_title = "TP Flux (kg/day)")),
  tar_target(bias_plot_no3_08164503,
             prediction_bias(model = no3_08164503,
                             df = model_data,
                             site = "usgs08164503",
                             date = "2005-01-01",
                             constituent = NO3_flux,
                             p2_x_labs = c("Predicted Flux", "Observed Flux"),
                             p2_y_title = "NO<sub>3</sub>-N Flux (kg/day)")),
  tar_target(bias_plot_tp_08164503,
             prediction_bias(model = tp_08164503,
                             df = model_data,
                             site = "usgs08164503",
                             date = "2000-01-01",
                             constituent = TP_flux,
                             p2_x_labs = c("Predicted Flux", "Observed Flux"),
                             p2_y_title = "TP Flux (kg/day)")),
  tar_target(bias_plot_no3_08164450,
             prediction_bias(model = no3_08164450,
                             df = model_data,
                             site = "usgs08164450",
                             date = "2005-01-01",
                             constituent = NO3_flux,
                             p2_x_labs = c("Predicted Flux", "Observed Flux"),
                             p2_y_title = "NO<sub>3</sub>-N Flux (kg/day)")),
  tar_target(bias_plot_tp_08164450,
             prediction_bias(model = tp_08164450,
                             df = model_data,
                             site = "usgs08164450",
                             date = "2000-01-01",
                             constituent = TP_flux,
                             p2_x_labs = c("Predicted Flux", "Observed Flux"),
                             p2_y_title = "TP Flux (kg/day)")),
  tar_target(bias_plot_no3_08164390,
             prediction_bias(model = no3_08164390,
                             df = model_data,
                             site = "usgs08164390",
                             date = "2005-01-01",
                             constituent = NO3_flux,
                             p2_x_labs = c("Predicted Flux", "Observed Flux"),
                             p2_y_title = "NO<sub>3</sub>-N Flux (kg/day)")),
  tar_target(bias_plot_tp_08164390,
             prediction_bias(model = tp_08164390,
                             df = model_data,
                             site = "usgs08164390",
                             date = "2000-01-01",
                             constituent = TP_flux,
                             p2_x_labs = c("Predicted Flux", "Observed Flux"),
                             p2_y_title = "TP Flux (kg/day)")),
  tar_target(bias_plot_no3_texana,
             prediction_bias_dam(model = no3_texana,
                             df = model_data,
                             site = "lktexana_g",
                             date = "2005-01-01",
                             constituent = NO3,
                             p2_x_labs = c("Predicted\nConcentration", "Observed\nConcentration"),
                             p2_y_title = "NO<sub>3</sub>-N Concentration (mg/mL)")),
  tar_target(bias_plot_tp_texana,
             prediction_bias_dam(model = tp_texana,
                                 df = model_data,
                                 site = "lktexana_g",
                                 date = "2005-01-01",
                                 constituent = TP,
                                 p2_x_labs = c("Predicted\nConcentration", "Observed\nConcentration"),
                                 p2_y_title = "TP Concentration (mg/mL)")),

  ## assessment pdf
  tar_quarto(assess_gams, "reports/model_assessment/model_assessment.qmd"),


  ## Model Predictions

  ### NO3
  tar_target(daily_no3_08164000,
             predict_daily(
               model = no3_08164000, # target
               data = model_data, # target
               site_no = "usgs08164000", # quoted string
               date = "2005-01-01", # quoted string
               output_name = NO3_Estimate, #unquoted
               output_upper = NO3_Upper, #unquoted
               output_lower = NO3_Lower #unquoted
             )),

  ## flow-normalized NO3
  tar_target(daily_no3_08164000_fn,
             predict_daily(
               model = no3_08164000, # target
               data = flow_normalized_data, # target
               site_no = "usgs08164000", # quoted string
               date = "2005-01-01", # quoted string
               output_name = NO3_Estimate, #unquoted
               output_upper = NO3_Upper, #unquoted
               output_lower = NO3_Lower, #unquoted
               fn_data = TRUE
             )),

  ### TP
  tar_target(daily_tp_08164000,
             predict_daily(
               model = tp_08164000, # target
               data = model_data, # target
               site_no = "usgs08164000", # quoted string
               date = "2000-01-01", # quoted string
               output_name = TP_Estimate, #unquoted
               output_upper = TP_Upper, #unquoted
               output_lower = TP_Lower #unquoted
             )),
  ### flow-normalized TP
  tar_target(daily_tp_08164000_fn,
             predict_daily(
               model = tp_08164000, # target
               data = flow_normalized_data, # target
               site_no = "usgs08164000", # quoted string
               date = "2000-01-01", # quoted string
               output_name = TP_Estimate, #unquoted
               output_upper = TP_Upper, #unquoted
               output_lower = TP_Lower, #unquoted
               fn_data = TRUE
             )),

  ### NO3 Lake Texana
  tar_target(daily_no3_texana,
             predict_daily_lk(model = no3_texana, # target
                              data = model_data, # target
                              site_no = "lktexana_g", # quoted string
                              date = "2005-01-01", # quoted string
                              output_name = NO3_Estimate, #unquoted
                              output_upper = NO3_Upper, #unquoted
                              output_lower = NO3_Lower #unquoted
                              )),

  ### flow-normalized NO3 Lake Texana
  tar_target(daily_no3_texana_fn,
             predict_daily_lk(
               model = no3_texana, # target
               data = flow_normalized_lk_data, # target
               site_no = "lktexana_g", # quoted string
               date = "2005-01-01", # quoted string
               output_name = NO3_Estimate, #unquoted
               output_upper = NO3_Upper, #unquoted
               output_lower = NO3_Lower, #unquoted
               fn_data  = TRUE
             )),


  tar_target(daily_tp_texana,
             predict_daily_lk(model = tp_texana, # target
                              data = model_data, # target
                              site_no = "lktexana_g", # quoted string
                              date = "2000-01-01", # quoted string
                              output_name = TP_Estimate, #unquoted
                              output_upper = TP_Upper, #unquoted
                              output_lower = TP_Lower #unquoted
             )),
  tar_target(daily_tp_texana_fn,
             predict_daily_lk(model = tp_texana, # target
                              data = flow_normalized_lk_data, # target
                              site_no = "lktexana_g", # quoted string
                              date = "2000-01-01", # quoted string
                              output_name = TP_Estimate, #unquoted
                              output_upper = TP_Upper, #unquoted
                              output_lower = TP_Lower, #unquoted
                              fn_data = TRUE
             ))
  ,
  
  ### NO3 navidad
  tar_target(daily_no3_08164390,
             predict_daily(
               model = no3_08164390, # target
               data = model_data, # target
               site_no = "usgs08164390", # quoted string
               date = "2005-01-01", # quoted string
               output_name = NO3_Estimate, #unquoted
               output_upper = NO3_Upper, #unquoted
               output_lower = NO3_Lower #unquoted
             )),
  ## flow-normalized NO3
  tar_target(daily_no3_08164390_fn,
             predict_daily(
               model = no3_08164390, # target
               data = flow_normalized_data, # target
               site_no = "usgs08164390", # quoted string
               date = "2005-01-01", # quoted string
               output_name = NO3_Estimate, #unquoted
               output_upper = NO3_Upper, #unquoted
               output_lower = NO3_Lower, #unquoted
               fn_data = TRUE
             )),
  ### TP navidad
  tar_target(daily_tp_08164390,
             predict_daily(
               model = tp_08164390, # target
               data = model_data, # target
               site_no = "usgs08164390", # quoted string
               date = "2000-01-01", # quoted string
               output_name = TP_Estimate, #unquoted
               output_upper = TP_Upper, #unquoted
               output_lower = TP_Lower #unquoted
             )),
  ### flow-normalized TP
  tar_target(daily_tp_08164390_fn,
             predict_daily(
               model = tp_08164390, # target
               data = flow_normalized_data, # target
               site_no = "usgs08164390", # quoted string
               date = "2000-01-01", # quoted string
               output_name = TP_Estimate, #unquoted
               output_upper = TP_Upper, #unquoted
               output_lower = TP_Lower, #unquoted
               fn_data = TRUE
             )),
  
  ### NO3 sandy
  tar_target(daily_no3_08164450,
             predict_daily(
               model = no3_08164450, # target
               data = model_data, # target
               site_no = "usgs08164450", # quoted string
               date = "2005-01-01", # quoted string
               output_name = NO3_Estimate, #unquoted
               output_upper = NO3_Upper, #unquoted
               output_lower = NO3_Lower #unquoted
             )),
  ## flow-normalized NO3
  tar_target(daily_no3_08164450_fn,
             predict_daily(
               model = no3_08164450, # target
               data = flow_normalized_data, # target
               site_no = "usgs08164450", # quoted string
               date = "2005-01-01", # quoted string
               output_name = NO3_Estimate, #unquoted
               output_upper = NO3_Upper, #unquoted
               output_lower = NO3_Lower, #unquoted
               fn_data = TRUE
             )),
  ### TP sandy
  tar_target(daily_tp_08164450,
             predict_daily(
               model = tp_08164450, # target
               data = model_data, # target
               site_no = "usgs08164450", # quoted string
               date = "2000-01-01", # quoted string
               output_name = TP_Estimate, #unquoted
               output_upper = TP_Upper, #unquoted
               output_lower = TP_Lower #unquoted
             )),
  ### flow-normalized TP
  tar_target(daily_tp_08164450_fn,
             predict_daily(
               model = tp_08164450, # target
               data = flow_normalized_data, # target
               site_no = "usgs08164450", # quoted string
               date = "2000-01-01", # quoted string
               output_name = TP_Estimate, #unquoted
               output_upper = TP_Upper, #unquoted
               output_lower = TP_Lower, #unquoted
               fn_data = TRUE
             )),
  ### NO3 W Mustang
  tar_target(daily_no3_08164503,
             predict_daily(
               model = no3_08164503, # target
               data = model_data, # target
               site_no = "usgs08164503", # quoted string
               date = "2005-01-01", # quoted string
               output_name = NO3_Estimate, #unquoted
               output_upper = NO3_Upper, #unquoted
               output_lower = NO3_Lower #unquoted
             )),
  ## flow-normalized NO3
  tar_target(daily_no3_08164503_fn,
             predict_daily(
               model = no3_08164503, # target
               data = flow_normalized_data, # target
               site_no = "usgs08164503", # quoted string
               date = "2005-01-01", # quoted string
               output_name = NO3_Estimate, #unquoted
               output_upper = NO3_Upper, #unquoted
               output_lower = NO3_Lower, #unquoted
               fn_data = TRUE
             )),
  ### TP W Mustang
  tar_target(daily_tp_08164503,
             predict_daily(
               model = no3_08164503, # target
               data = model_data, # target
               site_no = "usgs08164503", # quoted string
               date = "2000-01-01", # quoted string
               output_name = TP_Estimate, #unquoted
               output_upper = TP_Upper, #unquoted
               output_lower = TP_Lower #unquoted
             )),
  ### flow-normalized TP
  tar_target(daily_tp_08164503_fn,
             predict_daily(
               model = tp_08164503, # target
               data = flow_normalized_data, # target
               site_no = "usgs08164503", # quoted string
               date = "2000-01-01", # quoted string
               output_name = TP_Estimate, #unquoted
               output_upper = TP_Upper, #unquoted
               output_lower = TP_Lower, #unquoted
               fn_data = TRUE
             )),
  ### NO3 E Mustang
  tar_target(daily_no3_08164504,
             predict_daily(
               model = no3_08164504, # target
               data = model_data, # target
               site_no = "usgs08164504", # quoted string
               date = "2005-01-01", # quoted string
               output_name = NO3_Estimate, #unquoted
               output_upper = NO3_Upper, #unquoted
               output_lower = NO3_Lower #unquoted
             )),
  ## flow-normalized NO3
  tar_target(daily_no3_08164504_fn,
             predict_daily(
               model = no3_08164504, # target
               data = flow_normalized_data, # target
               site_no = "usgs08164504", # quoted string
               date = "2005-01-01", # quoted string
               output_name = NO3_Estimate, #unquoted
               output_upper = NO3_Upper, #unquoted
               output_lower = NO3_Lower, #unquoted
               fn_data = TRUE
             )),
  ### TP E Mustang
  tar_target(daily_tp_08164504,
             predict_daily(
               model = tp_08164504, # target
               data = model_data, # target
               site_no = "usgs08164504", # quoted string
               date = "2000-01-01", # quoted string
               output_name = TP_Estimate, #unquoted
               output_upper = TP_Upper, #unquoted
               output_lower = TP_Lower #unquoted
             )),
  ### flow-normalized TP
  tar_target(daily_tp_08164504_fn,
             predict_daily(
               model = tp_08164504, # target
               data = flow_normalized_data, # target
               site_no = "usgs08164504", # quoted string
               date = "2000-01-01", # quoted string
               output_name = TP_Estimate, #unquoted
               output_upper = TP_Upper, #unquoted
               output_lower = TP_Lower, #unquoted
               fn_data = TRUE
             )),
  # create loading output files (csv)
  tar_target(write_daily_tp, 
             loads_to_csv(list("lavaca" = tar_read(daily_tp_08164000), 
                               "texana" = tar_read(daily_tp_texana),
                               "navidad" = tar_read(daily_tp_08164390),
                               "sandy" = tar_read(daily_tp_08164450),
                               "w_mustang" = tar_read(daily_tp_08164503),
                               "e_mustang" = tar_read(daily_tp_08164504)),
                          df = "daily",
                          output = "data/Output/daily_loads/tp_daily_loads.csv"),
             format = "file"),
  tar_target(write_daily_tp_fn, 
             loads_to_csv(list("lavaca" = tar_read(daily_tp_08164000_fn), 
                               "texana" = tar_read(daily_tp_texana_fn),
                               "navidad" = tar_read(daily_tp_08164390_fn),
                               "sandy" = tar_read(daily_tp_08164450_fn),
                               "w_mustang" = tar_read(daily_tp_08164503_fn),
                               "e_mustang" = tar_read(daily_tp_08164504_fn)),
                          df = "daily",
                          output = "data/Output/daily_loads/tp_daily_loads_flow_normalized.csv"),
             format = "file"),
  tar_target(write_monthly_tp, 
             loads_to_csv(list("lavaca" = tar_read(daily_tp_08164000), 
                               "texana" = tar_read(daily_tp_texana),
                               "navidad" = tar_read(daily_tp_08164390),
                               "sandy" = tar_read(daily_tp_08164450),
                               "w_mustang" = tar_read(daily_tp_08164503),
                               "e_mustang" = tar_read(daily_tp_08164504)),
                          df = "monthly",
                          output = "data/Output/monthly_loads/tp_monthly_loads.csv"),
             format = "file"),
  tar_target(write_monthly_tp_fn, 
             loads_to_csv(list("lavaca" = tar_read(daily_tp_08164000_fn), 
                               "texana" = tar_read(daily_tp_texana_fn),
                               "navidad" = tar_read(daily_tp_08164390_fn),
                               "sandy" = tar_read(daily_tp_08164450_fn),
                               "w_mustang" = tar_read(daily_tp_08164503_fn),
                               "e_mustang" = tar_read(daily_tp_08164504_fn)),
                          df = "monthly",
                          output = "data/Output/monthly_loads/tp_monthly_loads_flow_normalized.csv"),
             format = "file"),
  tar_target(write_annual_tp, 
             loads_to_csv(list("lavaca" = tar_read(daily_tp_08164000), 
                               "texana" = tar_read(daily_tp_texana),
                               "navidad" = tar_read(daily_tp_08164390),
                               "sandy" = tar_read(daily_tp_08164450),
                               "w_mustang" = tar_read(daily_tp_08164503),
                               "e_mustang" = tar_read(daily_tp_08164504)),
                          df = "annually",
                          output = "data/Output/annual_loads/tp_annual_loads.csv"),
             format = "file"),
  tar_target(write_annual_tp_fn, 
             loads_to_csv(list("lavaca" = tar_read(daily_tp_08164000_fn), 
                               "texana" = tar_read(daily_tp_texana_fn),
                               "navidad" = tar_read(daily_tp_08164390_fn),
                               "sandy" = tar_read(daily_tp_08164450_fn),
                               "w_mustang" = tar_read(daily_tp_08164503_fn),
                               "e_mustang" = tar_read(daily_tp_08164504_fn)),
                          df = "annually",
                          output = "data/Output/annual_loads/tp_annual_loads_flow_normalized.csv"),
             format = "file"),
  
  tar_target(write_daily_no3, 
             loads_to_csv(list("lavaca" = tar_read(daily_no3_08164000), 
                               "texana" = tar_read(daily_no3_texana),
                               "navidad" = tar_read(daily_no3_08164390),
                               "sandy" = tar_read(daily_no3_08164450),
                               "w_mustang" = tar_read(daily_no3_08164503),
                               "e_mustang" = tar_read(daily_no3_08164504)),
                          df = "daily",
                          output = "data/Output/daily_loads/no3_daily_loads.csv"),
             format = "file"),
  tar_target(write_daily_no3_fn, 
             loads_to_csv(list("lavaca" = tar_read(daily_no3_08164000_fn), 
                               "texana" = tar_read(daily_no3_texana_fn),
                               "navidad" = tar_read(daily_no3_08164390_fn),
                               "sandy" = tar_read(daily_no3_08164450_fn),
                               "w_mustang" = tar_read(daily_no3_08164503_fn),
                               "e_mustang" = tar_read(daily_no3_08164504_fn)),
                          df = "daily",
                          output = "data/Output/daily_loads/no3_daily_loads_flow_normalized.csv"),
             format = "file"),
  tar_target(write_monthly_no3, 
             loads_to_csv(list("lavaca" = tar_read(daily_no3_08164000), 
                               "texana" = tar_read(daily_no3_texana),
                               "navidad" = tar_read(daily_no3_08164390),
                               "sandy" = tar_read(daily_no3_08164450),
                               "w_mustang" = tar_read(daily_no3_08164503),
                               "e_mustang" = tar_read(daily_no3_08164504)),
                          df = "monthly",
                          output = "data/Output/monthly_loads/no3_monthly_loads.csv"),
             format = "file"),
  tar_target(write_monthly_no3_fn, 
             loads_to_csv(list("lavaca" = tar_read(daily_no3_08164000_fn), 
                               "texana" = tar_read(daily_no3_texana_fn),
                               "navidad" = tar_read(daily_no3_08164390_fn),
                               "sandy" = tar_read(daily_no3_08164450_fn),
                               "w_mustang" = tar_read(daily_no3_08164503_fn),
                               "e_mustang" = tar_read(daily_no3_08164504_fn)),
                          df = "monthly",
                          output = "data/Output/monthly_loads/no3_monthly_loads_flow_normalized.csv"),
             format = "file"),
  tar_target(write_annual_no3, 
             loads_to_csv(list("lavaca" = tar_read(daily_no3_08164000), 
                               "texana" = tar_read(daily_no3_texana),
                               "navidad" = tar_read(daily_no3_08164390),
                               "sandy" = tar_read(daily_no3_08164450),
                               "w_mustang" = tar_read(daily_no3_08164503),
                               "e_mustang" = tar_read(daily_no3_08164504)),
                          df = "annually",
                          output = "data/Output/annual_loads/no3_annual_loads.csv"),
             format = "file"),
  tar_target(write_annual_no3_flow_normalized, 
             loads_to_csv(list("lavaca" = tar_read(daily_no3_08164000_fn), 
                               "texana" = tar_read(daily_no3_texana_fn),
                               "navidad" = tar_read(daily_no3_08164390_fn),
                               "sandy" = tar_read(daily_no3_08164450_fn),
                               "w_mustang" = tar_read(daily_no3_08164503_fn),
                               "e_mustang" = tar_read(daily_no3_08164504_fn)),
                          df = "annually",
                          output = "data/Output/annual_loads/no3_annual_loads_flow_normalized.csv"),
             format = "file"),
  
  # loading estimates pdf
  tar_quarto(loading_estimates, "reports/load_estimates/load_estimates.qmd"),
  
  ##############################################################################
  # This section creates gams that evaluate Lavaca Bay trends! -----------------
  ##############################################################################
  ### Read lavaca bay inflow
  tar_target(lbay_inflow,
             load_lb_inflow()),
  
  ### lavaca bay seasonally adjusted flow
  tar_target(lbay_adj_flow,
             adjust_lbay_inflow(lbay_inflow)),
  
  ## estuary wq data
  tar_target(lbay_wq_data,
             load_est_wq_data()),
  
  ## estuary model data
  tar_target(estuary_model_data,
             create_est_model_data(lbay_wq_data,
                                   lbay_adj_flow)),
  
  ## calculate total loads and flow normalize
  tar_target(estuary_tp_loads,
              fn_estuary_tp_loads(daily_tp_08164000,
                                  daily_tp_texana,
                                  lbay_inflow)),
  tar_target(estuary_no3_loads,
             fn_estuary_no3_loads(daily_no3_08164000,
                                 daily_no3_texana,
                                 lbay_inflow)),
  
  ## fit gams

  ### TP
  #### temporal model
  tar_target(tp_lavaca_13563_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads,
                         response_parameter = "00665",
                         date = "2005-01-01",
                         station = "13563")),

  tar_target(tp_lavaca_13383_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads,
                         response_parameter = "00665",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),

  tar_target(tp_lavaca_13384_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads,
                         response_parameter = "00665",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),


  ### flow model
  tar_target(tp_lavaca_13563_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads,
                         response_parameter = "00665",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),

  tar_target(tp_lavaca_13383_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads,
                         response_parameter = "00665",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),

  tar_target(tp_lavaca_13384_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads,
                         response_parameter = "00665",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),

  ### full model
  tar_target(tp_lavaca_13563_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(TP_resid, k = 8) + #explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads,
                         response_parameter = "00665",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),

  tar_target(tp_lavaca_13383_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(TP_resid, k = 8) + #explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads,
                         response_parameter = "00665",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),

  tar_target(tp_lavaca_13384_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(TP_resid, k = 8) + #explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20),  # trend
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads,
                         response_parameter = "00665",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),


  ### NO3
  ### notes: we uses nitrate + nitrite as response value because very few nitrate
  ### measurements in lavaca bay
  #### temporal model
  tar_target(no3_lavaca_13563_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20),  # trend,
                         model_data = estuary_model_data,
                         loads = estuary_no3_loads,
                         response_parameter = "00630",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),

  tar_target(no3_lavaca_13383_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20),  # trend,
                         model_data = estuary_model_data,
                         loads = estuary_no3_loads,
                         response_parameter = "00630",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),

  tar_target(no3_lavaca_13384_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_no3_loads,
                         response_parameter = "00630",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),


  ### flow model
  tar_target(no3_lavaca_13563_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_no3_loads,
                         response_parameter = "00630",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),

  tar_target(no3_lavaca_13383_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend
                         model_data = estuary_model_data,
                         loads = estuary_no3_loads,
                         response_parameter = "00630",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),

  tar_target(no3_lavaca_13384_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_no3_loads,
                         response_parameter = "00630",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),

  ### full model
  tar_target(no3_lavaca_13563_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(NO3_resid, k = 8) + #explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_no3_loads,
                         response_parameter = "00630",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),

  tar_target(no3_lavaca_13383_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(NO3_resid, k = 8) + #explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_no3_loads,
                         response_parameter = "00630",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),

  tar_target(no3_lavaca_13384_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(NO3_resid, k = 8) + #explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_no3_loads,
                         response_parameter = "00630",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),

  
  ### chl-a
  ### measurements in lavaca bay
  #### temporal model
  tar_target(chla_lavaca_13563_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "70953",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),

  tar_target(chla_lavaca_13383_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "70953",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),

  tar_target(chla_lavaca_13384_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "70953",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),


  ### flow model
  tar_target(chla_lavaca_13563_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "70953",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),

  tar_target(chla_lavaca_13383_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "70953",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),

  tar_target(chla_lavaca_13384_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "70953",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),

  ### full model
  tar_target(chla_lavaca_13563_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(NO3_resid, k = 8) + #explanatory variable
                           s(TP_resid, k = 8) + #explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20),  # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "70953",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),

  tar_target(chla_lavaca_13383_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(NO3_resid, k = 8) + #explanatory variable
                           s(TP_resid, k = 8) + #explanatory variables
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20),  # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "70953",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),

  tar_target(chla_lavaca_13384_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(NO3_resid, k = 8) + #explanatory variable
                           s(TP_resid, k = 8) + #explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "70953",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),

  
  ### DO
  ### measurements in lavaca bay
  #### temporal model
  tar_target(do_lavaca_13563_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00300",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),
  
  tar_target(do_lavaca_13383_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00300",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),
  
  tar_target(do_lavaca_13384_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00300",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),
  
  
  ### flow model
  tar_target(do_lavaca_13563_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00300",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),
  
  tar_target(do_lavaca_13383_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00300",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),
  
  tar_target(do_lavaca_13384_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00300",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),
  
  ### full model
  tar_target(do_lavaca_13563_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(NO3_resid, k = 8) + #explanatory variable
                           s(TP_resid, k = 8) + #explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20),  # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00300",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),
  
  tar_target(do_lavaca_13383_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(NO3_resid, k = 8) + #explanatory variable
                           s(TP_resid, k = 8) + #explanatory variables
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20),  # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00300",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),
  
  tar_target(do_lavaca_13384_full,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(NO3_resid, k = 8) + #explanatory variable
                           s(TP_resid, k = 8) + #explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00300",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),
  

  ### TKN
  ### measurements in lavaca bay
  #### temporal model
  tar_target(tkn_lavaca_13563_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00625",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),
  
  tar_target(tkn_lavaca_13383_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00625",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),
  
  tar_target(tkn_lavaca_13384_temporal,
             estuary_gam(formula = value ~
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00625",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),
  
  ### flow model
  tar_target(tkn_lavaca_13563_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00625",
                         date = "2005-01-01",
                         station = "13563",
                         family = Gamma(link = "log"))),
  
  tar_target(tkn_lavaca_13383_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00625",
                         date = "2005-01-01",
                         station = "13383",
                         family = Gamma(link = "log"))),
  
  tar_target(tkn_lavaca_13384_flow,
             estuary_gam(formula = value ~
                           s(flw_res, k = 8) + # explanatory variable
                           s(day, k = 5,  bs = "cc") + # seasonal
                           s(ddate, k = 20), # trend,
                         model_data = estuary_model_data,
                         loads = estuary_tp_loads |>  left_join(estuary_no3_loads),
                         response_parameter = "00625",
                         date = "2005-01-01",
                         station = "13384",
                         family = Gamma(link = "log"))),
  
    
  
  ## data for predictions with gams
  tar_target(tp_lavaca_prediction_data,
             estuary_prediction_data(lbay_adj_flow,
                                     estuary_tp_loads,
                                     "2000-01-01")),
  
  tar_target(no3_lavaca_prediction_data,
             estuary_prediction_data(lbay_adj_flow,
                                     estuary_no3_loads,
                                     "2005-01-01")),
  
  ## Report Figures
  tar_target(report_map,
             study_area_map()),
  
  tar_target(fw_site_map,
             fw_study_area_map()),
  
  tar_target(est_site_map,
             est_study_area_map()),
  
  ## Report tables
  tar_target(tp_13563,
             est_model_fits(tp_lavaca_13563_temporal,
                            tp_lavaca_13563_flow, 
                            tp_lavaca_13563_full,
                            site = "TCEQ-13563",
                            param = "TP")),
  tar_target(tp_13383,
             est_model_fits(tp_lavaca_13383_temporal,
                            tp_lavaca_13383_flow, 
                            tp_lavaca_13383_full,
                            site = "TCEQ-13383",
                            param = "TP")),
  tar_target(tp_13384,
             est_model_fits(tp_lavaca_13384_temporal,
                            tp_lavaca_13384_flow, 
                            tp_lavaca_13384_full,
                            site = "TCEQ-13384",
                            param = "TP")),
  tar_target(no3_13563,
             est_model_fits(no3_lavaca_13563_temporal,
                            no3_lavaca_13563_flow, 
                            no3_lavaca_13563_full,
                            site = "TCEQ-13563",
                            param = "Nitrite+Nitrate")),
  tar_target(no3_13383,
             est_model_fits(no3_lavaca_13383_temporal,
                            no3_lavaca_13383_flow, 
                            no3_lavaca_13383_full,
                            site = "TCEQ-13383",
                            param = "Nitrite+Nitrate")),
  tar_target(no3_13384,
             est_model_fits(no3_lavaca_13384_temporal,
                            no3_lavaca_13384_flow, 
                            no3_lavaca_13384_full,
                            site = "TCEQ-13384",
                            param = "Nitrite+Nitrate")),
  tar_target(chla_13563,
             est_model_fits(chla_lavaca_13563_temporal,
                            chla_lavaca_13563_flow, 
                            chla_lavaca_13563_full,
                            site = "TCEQ-13563",
                            param = "Chlorophyll-a")),
  tar_target(chla_13383,
             est_model_fits(chla_lavaca_13383_temporal,
                            chla_lavaca_13383_flow, 
                            chla_lavaca_13383_full,
                            site = "TCEQ-13383",
                            param = "Chlorophyll-a")),
  tar_target(chla_13384,
             est_model_fits(chla_lavaca_13384_temporal,
                            chla_lavaca_13384_flow, 
                            chla_lavaca_13384_full,
                            site = "TCEQ-13384",
                            param = "Chlorophyll-a")),
  
  tar_target(do_13563,
             est_model_fits(do_lavaca_13563_temporal,
                            do_lavaca_13563_flow, 
                            do_lavaca_13563_full,
                            site = "TCEQ-13563",
                            param = "DO")),
  tar_target(do_13383,
             est_model_fits(do_lavaca_13383_temporal,
                            do_lavaca_13383_flow, 
                            do_lavaca_13383_full,
                            site = "TCEQ-13383",
                            param = "DO")),
  tar_target(do_13384,
             est_model_fits(do_lavaca_13384_temporal,
                            do_lavaca_13384_flow, 
                            do_lavaca_13384_full,
                            site = "TCEQ-13384",
                            param = "DO")),
  tar_target(tkn_13563,
             est_model_fits(tkn_lavaca_13563_temporal,
                            tkn_lavaca_13563_flow,
                            NULL,
                            site = "TCEQ-13563",
                            param = "TKN")),
  tar_target(tkn_13383,
             est_model_fits(tkn_lavaca_13383_temporal,
                            tkn_lavaca_13383_flow,
                            NULL,
                            site = "TCEQ-13383",
                            param = "TKN")),
  tar_target(tkn_13384,
             est_model_fits(tkn_lavaca_13384_temporal,
                            tkn_lavaca_13384_flow,
                            NULL,
                            site = "TCEQ-13384",
                            param = "TKN")),
  
  ## spatial outputfiles
  tar_target(arc_path,
             command = "data/Output/spatial/loading.gpkg",
             format = "file")
  # ,
  
  # tar_target(arc_outputs,
  #            generate_geopackage(arc_path = arc_path),
  #            format = "file")
  
)
