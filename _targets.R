library(targets)

source("R/Data.R")
source("R/Models.R")
source("R/CV.R")
source("R/gt_functions.R")
source("R/FIGURES.R")
source("R/LOADESTIMATE.R")
source("R/write_files.R")
options(tidyverse.quiet = TRUE)
targets::tar_option_set(packages = c("adc", 
                                     "arrow", 
                                     "dataRetrieval", 
                                     "dplyr", 
                                     "flextable", 
                                     "fs", 
                                     "furrr", 
                                     "ggplot2", 
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
                                     "patchwork", 
                                     "purrr", 
                                     "ragg",
                                     "quarto", 
                                     "readr", 
                                     "rsample",
                                     "scico",
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
                family = Gamma(link = "log")
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
                           family = Gamma(link = "log"))
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
                            family = Gamma(link = "log"))
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
                           family = Gamma(link = "log"))
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
                            family = Gamma(link = "log"))
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
                           family = Gamma(link = "log"))
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
                            family = Gamma(link = "log"))
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
                           family = Gamma(link = "log"))
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
  
  
  # create loading output file (csv)
  tar_target(write_daily, 
             loads_to_csv(list("lav" = tar_read(daily_tp_08164000), 
                               "tex" = tar_read(daily_tp_texana)),
                          df = "daily",
                          output = "data/Output/daily_loads/tp_daily_loads.csv"),
             format = "file"),
  
  # loading estimates pdf
  tar_quarto(loading_estimates, "reports/load_estimates/load_estimates.qmd")
  #
  
)
