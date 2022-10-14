prediction_bias <- function(model,
                            df,
                            site,
                            date,
                            constituent,
                            p2_x_labs = c("Predicted Flux", "Observed Flux"),
                            p2_y_title = "NO~3~-N Flux (kg/day)") {
  
  df <- df |> 
    filter(site_no == {{site}},
           Date >= as.Date(date))
  
  df <- gratia::add_fitted(df,
                           model = model,
                           value = ".fits",
                           type = "response") |> 
    mutate(.fits = as_units(.fits, "mg/L"),
           Flow = as_units(Flow, "ft^3/s"),
           Flow = set_units(Flow, "L/s"),
           .fits = .fits*Flow,
           .fits = set_units(.fits, "kg/day"),
           Flow = set_units(Flow, "ft^3/s"),
           Flow = drop_units(Flow),
           .fits = drop_units(.fits)) |> 
    mutate(x_lab = case_when(
      !is.na({{ constituent }}) ~ "In-sample",
      is.na( {{ constituent }}) ~ "Out-of-sample"))
  
  p1 <- ggplot(df) +
    geom_boxplot(aes(x = x_lab,
                     y = Flow)) +
    scale_y_log10() +
    labs(x = "", y = "Mean Daily Discharge [cfs]") +
    theme_TWRI_print()

  p2 <- df |>
    pivot_longer(cols = c(.fits, {{ constituent }})) |>
    ggplot(aes(name, value)) +
    geom_boxplot() +
    scale_y_log10() +
    scale_x_discrete(labels = p2_x_labs) +
    labs(x = "", y = p2_y_title) +
    theme_TWRI_print() +
    theme(axis.title.y = ggtext::element_markdown())
  
  p1 + p2 + plot_annotation(tag_levels = "a")
  
}


prediction_bias_dam <- function(model,
                                df,
                                site = "lktexana_g",
                                date,
                                constituent,
                                p2_x_labs = c("Predicted Concentration", "Observed Concentration"),
                                p2_y_title = "NO<sub>3</sub>-N Concentration (mg/mL)") {
  gaged_inflow <- df |> 
    filter(site_no != "lktexana_g") |> 
    filter(site_no != "usgs08164000") |> 
    select(c(Date, site_no, Flow)) |> 
    pivot_wider(names_from = site_no,
                values_from = Flow) |> 
    mutate(inflow = usgs08164390 + usgs08164450 + usgs08164503 + usgs08164504)
  
  below_tex <- df |> 
    filter(site_no == "lktexana_g") |> 
    # select(-c("NH3", "TKN", "censored_TKN")) |> 
    mutate(inflow = gaged_inflow$inflow) |> 
    mutate(
      log1p_inflow = log1p(inflow),
      # flow anomalies
      ltfa = fa(inflow+1, Date, T_1 = "1 year",
                T_2 = "period", transform = "log"),
      stfa = fa(inflow+1, Date, T_1 = "1 day",
                T_2 = "1 month", transform = "log"),
      # smooth discounted flow
      ma = sdf(log1p(inflow)))
  
  df <- below_tex |> 
    filter(site_no == site,
           Date >= as.Date(date))
  
  df <- gratia::add_fitted(df,
                           model = model,
                           value = ".fits",
                           type = "response") |> 
    mutate(x_lab = case_when(
      !is.na({{ constituent }}) ~ "In-sample",
      is.na( {{ constituent }}) ~ "Out-of-sample"))
  
  p1 <- ggplot(df) +
    geom_boxplot(aes(x = x_lab,
                     y = inflow)) +
    scale_y_log10(labels = scales::comma) +
    labs(x = "", y = "Mean Daily Inflow [cfs]") +
    theme_TWRI_print()
  p2 <- df |>
    pivot_longer(cols = c(.fits, {{ constituent }})) |>
    ggplot(aes(name, value)) +
    geom_boxplot() +
    scale_y_log10(labels = scales::comma) +
    scale_x_discrete(labels = p2_x_labs) +
    labs(x = "", y = p2_y_title) +
    theme_TWRI_print() +
    theme(axis.title.y = ggtext::element_markdown())
  
  p1 + p2 + plot_annotation(tag_levels = "a")
  
}