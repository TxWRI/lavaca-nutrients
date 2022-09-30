
## simulate posterior distribution of the fitted GAM to obtain 95% pointwise 
## confidence intervals

sim_posterior <- function(model, nsim, newdata) {
  sims <- gratia:::simulate.gam(model, nsim = nsim, newdata = newdata)
  colnames(sims) <- paste0("sim", seq_len(nsim))
  sims <- setNames(stack(as.data.frame(sims)), c("simulated", "run"))
  sims <- transform(sims, Date = rep(newdata$Date, nsim), simulated = simulated) %>%
    as_tibble()
  return(sims)
  
}

predict_daily <- function(model, # target
                          data, # target
                          site_no, # quoted string
                          date, # quoted string
                          output_name, #unquoted
                          output_upper, #unquoted
                          output_lower #unquoted
                          ) {
  
  data <- data |> 
    filter(site_no == {{site_no}},
           Date >= as.Date(date))
  
  ## return gam prediction
  out <- gratia::add_fitted(data,
                            model,
                            value = ".fits",
                            type = "response") |> 
    select(Date, site_no, .fits)

  ## return intervals
  sims <- sim_posterior(model, nsim = 1000, newdata = data)

  sims_sum <- sims |>
    group_by(Date) |>
    summarise({{output_lower}} := quantile(simulated, probs = 0.025, type = 8, na.rm = TRUE),
              {{output_upper}} := quantile(simulated, probs = 0.975, type = 8, na.rm = TRUE))

  out <- out |>
    left_join(sims_sum, by = c("Date" = "Date")) |>
    rename({{output_name}} := .fits)
  
  return(list(daily = out,
              sims = sims))
}


predict_month_year <- function(model, # target
                            data, # target
                            site_no, # quoted string
                            date, # quoted string
                            sims, #target
                            output_name, #unquoted
                            output_upper, #unquoted
                            output_lower #unquoted
                            ) {
  
  data <- data |> 
    filter(site_no == {{site_no}},
           Date >= as.Date(date))
  
  ## return gam prediction
  out <- gratia::add_fitted(data,
                            model,
                            value = ".fits",
                            type = "response")
  
  monthly <- out |>
    group_by(month = floor_date(Date, "month")) |>
    summarise({{output_name}} := sum(.fits, na.rm = TRUE)) |>
    mutate(month = format(month, "%Y-%m"))

  ## return intervals
  sims <- sims$sims
  sims_month <- sims |>
    group_by(month = floor_date(Date, "month"), run) |>
    summarise(fits = sum(simulated, na.rm = TRUE)) |>
    summarise({{output_lower}} := quantile(fits, probs = 0.025, type = 8, na.rm = TRUE),
              {{output_upper}} := quantile(fits, probs = 0.975, type = 8, na.rm = TRUE)) |>
    mutate(month = format(month, "%Y-%m"))

  monthly <- monthly |>
    left_join(sims_month, by = c("month" = "month"))

  annually <- out |>
    group_by(year = year(Date)) |>
    summarise({{output_name}} := sum(.fits, na.rm = TRUE))

  sims_annual <- sims |>
    group_by(year = year(Date), run) |>
    summarise(fits = sum(simulated, na.rm = TRUE)) |>
    summarise({{output_lower}} := quantile(fits, probs = 0.025, type = 8, na.rm = TRUE),
              {{output_upper}} := quantile(fits, probs = 0.975, type = 8, na.rm = TRUE))

  annually <- annually |>
    left_join(sims_annual, by = c("year" = "year"))

  return(list(monthly,
              annually))
  
}



## Simulate lake outputs

predict_daily_lk <- function(model, # target
                          data, # target
                          site_no, # quoted string
                          date, # quoted string
                          output_name, #unquoted
                          output_upper, #unquoted
                          output_lower #unquoted
) {
  
  data <- data |>
    format_dam_data() |> 
    filter(site_no == {{site_no}},
           Date >= as.Date(date))

  ## return gam prediction
  out <- gratia::add_fitted(data,
                            model,
                            value = ".fits",
                            type = "response") |>
    select(Date, Flow, site_no, .fits)

  ## return intervals
  sims <- sim_posterior(model, nsim = 1000, newdata = data)

  sims_sum <- sims |>
    group_by(Date) |>
    summarise({{output_lower}} := quantile(simulated, probs = 0.025, type = 8, na.rm = TRUE),
              {{output_upper}} := quantile(simulated, probs = 0.975, type = 8, na.rm = TRUE))

  out <- out |>
    left_join(sims_sum, by = c("Date" = "Date")) |>
    rename({{output_name}} := .fits) |>
    ## calculate load from concentration and mean daily dam discharge
    mutate(Flow = as_units(Flow, "ft^3/s"),
           Flow = set_units(Flow, "L/s"),
           {{output_name}} := as_units({{output_name}}, "mg/L"),
           "{{output_name}}_Flux" := {{output_name}} * Flow,
           across(last_col(),
                  ~set_units(., "kg/day")),
           {{output_lower}} := as_units({{output_lower}}, "mg/L"),
           "{{output_lower}}_Flux" := {{output_lower}} * Flow,
           across(last_col(),
                  ~set_units(., "kg/day")),
           {{output_upper}} := as_units({{output_upper}}, "mg/L"),
           "{{output_upper}}_Flux" := {{output_upper}} * Flow,
           across(last_col(),
                  ~set_units(., "kg/day")),
           Flow = set_units(Flow, "ft^3/s")) |> 
    ## drop units
    mutate(
      Flow = drop_units(Flow),
      across(.cols = tidyselect::starts_with(c("NO3", "TP")),
             ~drop_units(.))
    )

  return(list(daily = out,
              sims = sims))
}


predict_month_year_lk <- function(model, # target
                               data, # target
                               site_no, # quoted string
                               date, # quoted string
                               sims, #target
                               output_name, #unquoted
                               output_upper, #unquoted
                               output_lower #unquoted
) {
  
  data <- data |>
    format_dam_data() |> 
    filter(site_no == {{site_no}},
           Date >= as.Date(date))
  
  ## return gam prediction
  out <- gratia::add_fitted(data,
                            model,
                            value = ".fits",
                            type = "response") |>
    select(Date, Flow, site_no, .fits) |> 
    ##convert to loads
    mutate(Flow = as_units(Flow, "ft^3/s"),
           Flow = set_units(Flow, "L/s"),
           .fits := as_units(.fits, "mg/L"),
           "{{output_name}}" := .fits * Flow,
           across(last_col(),
                  ~set_units(., "kg/day")),
           Flow = set_units(Flow, "ft^3/s"),
           across(.cols = tidyselect::starts_with(c("NO3", "TP")),
                  ~drop_units(.))) |> 
    select(-c(.fits))
  

  monthly <- out |>
    group_by(month = floor_date(Date, "month")) |>
    summarise(across(
      last_col(),
      ~sum(., na.rm = TRUE)
    )) |> 
    mutate(month = format(month, "%Y-%m"))

  ## return intervals
  sims <- sims$sims
  
  sims_month <- sims |> 
    left_join(out |> select(Date, Flow), by = c("Date" = "Date")) |> 
    mutate(Flow = set_units(Flow, "L/s"),
           simulated = as_units(simulated, "mg/L"),
           fits = simulated * Flow,
           fits = set_units(fits, "kg/day"),
           Flow = set_units(Flow, "ft^3/s"),
           fits = drop_units(fits)) |> 
      group_by(month = floor_date(Date, "month"), run) |>
      summarise(fits = sum(fits, na.rm = TRUE)) |>
      summarise({{output_lower}} := quantile(fits, probs = 0.025, type = 8, na.rm = TRUE),
                {{output_upper}} := quantile(fits, probs = 0.975, type = 8, na.rm = TRUE)) |>
      mutate(month = format(month, "%Y-%m"))
  

  monthly <- monthly |>
    left_join(sims_month, by = c("month" = "month"))
  

  annually <- out |>
    group_by(year = year(Date)) |>
    summarise(across(
      last_col(),
      ~sum(., na.rm = TRUE)
    )) 

  sims_annual <- sims |>
    left_join(out |> select(Date, Flow), by = c("Date" = "Date")) |> 
    mutate(Flow = set_units(Flow, "L/s"),
           simulated = as_units(simulated, "mg/L"),
           fits = simulated * Flow,
           fits = set_units(fits, "kg/day"),
           Flow = set_units(Flow, "ft^3/s"),
           fits = drop_units(fits)) |> 
    group_by(year = year(Date), run) |>
    summarise(fits = sum(fits, na.rm = TRUE)) |>
    summarise({{output_lower}} := quantile(fits, probs = 0.025, type = 8, na.rm = TRUE),
              {{output_upper}} := quantile(fits, probs = 0.975, type = 8, na.rm = TRUE))

  annually <- annually |>
    left_join(sims_annual, by = c("year" = "year"))

  return(list(monthly,
              annually))
  
}

