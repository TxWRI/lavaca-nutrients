

predict_daily <- function(model, # target
                          data, # target
                          site_no, # quoted string
                          date, # quoted string
                          output_name, #unquoted
                          output_upper, #unquoted
                          output_lower, #unquoted
                          fn_data = FALSE
                          ) {
  
  # data <- data |>
  #   filter(site_no == {{site_no}},
  #          Date >= as.Date(date)) 
  
  data <- data |>
    filter(site_no == {{site_no}}) 
  
  ## if actual predictions of load
  if (!isTRUE(fn_data)) {
    
    
    ## return gam prediction
    out <- gratia::add_fitted(data,
                              model,
                              value = ".fits",
                              type = "response") |>
      select(Date, Flow, log1p_Flow, site_no, .fits) |> 
      rename({{output_name}} := .fits)
    
    ## fitted values of the response drawn from the posterior distribution of 
    ## the fitted model using Gaussian approximation to the posterior.
    sims <- fitted_samples(model, newdata = data, n = 1000,
                           seed = 1972, scale = "response",
                           freq = TRUE)
    
    sims$Date <- rep(data$Date, 1000)
    sims$Flow <- rep(data$Flow, 1000)
    
    ## return credible intervals for daily predictions
    daily_ci <- sims |>
      mutate(Flow = as_units(Flow, "ft^3/s")) |> 
      mutate(Flow = set_units(Flow, "L/s")) |> 
      mutate(fitted = as_units(fitted, "mg/L")) |> 
      mutate(fitted = fitted * Flow) |> 
      mutate(fitted = set_units(fitted, "kg/day")) |> 
      mutate(Flow = set_units(Flow, "ft^3/s")) |> 
      mutate(fitted = drop_units(fitted)) |> 
      group_by(row) |>
      summarise(lower.ci = quantile(fitted, probs = 0.05, type = 8, na.rm = TRUE),
                upper.ci = quantile(fitted, probs = 0.95, type = 8, na.rm = TRUE))
    
    ## convert concentration to flux
    daily <- out |>
      mutate({{output_upper}} := daily_ci$upper.ci,
             {{output_lower}} := daily_ci$lower.ci) |> 
      filter(Date >= as.Date(date)) |>
      mutate(Flow = as_units(Flow, "ft^3/s")) |> 
      mutate(Flow = set_units(Flow, "L/s")) |> 
      mutate({{output_name}} := as_units({{output_name}}, "mg/L")) |> 
      mutate({{output_name}} := Flow * {{output_name}}) |> 
      mutate({{output_name}} := set_units({{output_name}}, "kg/day")) |> 
      mutate(Flow = set_units(Flow, "ft^3/s")) |> 
      mutate(Flow = drop_units(Flow)) |> 
      mutate({{output_name}} := drop_units({{output_name}}))
    
  } else {
    ## if making flow normalized predictions
    message("FN predictions!")
    
    ## return gam prediction
    out <- gratia::add_fitted(data,
                              model,
                              value = ".fits",
                              type = "response") |>
      select(Date, Flow, log1p_Flow, site_no, .fits) |> 
      rename({{output_name}} := .fits)
    
    ## fitted values of the response drawn from the posterior distribution of 
    ## the fitted model using Gaussian approximation to the posterior.
    sims <- fitted_samples(model, newdata = data, n = 1000,
                           seed = 1972, scale = "response",
                           freq = TRUE)
    
    sims$Date <- rep(data$Date, 1000)
    sims$Flow <- rep(data$Flow, 1000)
    
    ## return credible intervals for fn concentration
    ## grouped by date/row to combine with fn fits
    sims <- sims |> 
      group_by(Date, row) |> 
      summarise(lower.ci = quantile(fitted, probs = 0.05, type = 8, na.rm = TRUE),
                upper.ci = quantile(fitted, probs = 0.95, type = 8, na.rm = TRUE))
    
    out <- out |> 
      mutate({{output_upper}} := sims$upper.ci,
             {{output_lower}} := sims$lower.ci)
    
    ## calculate daily loads
    daily <- out |> 
      ungroup() |> 
      filter(Date >= as.Date(date)) |>
      mutate(Flow = as_units(Flow, "ft^3/s")) |> 
      mutate(Flow = set_units(Flow, "L/s")) |> 
      mutate({{output_name}} := as_units({{output_name}}, "mg/L"),
             {{output_upper}} := as_units({{output_upper}}, "mg/L"),
             {{output_lower}} := as_units({{output_lower}}, "mg/L")) |> 
      mutate({{output_name}} := Flow * {{output_name}},
             {{output_upper}} := Flow * {{output_upper}},
             {{output_lower}} := Flow * {{output_lower}}) |> 
      mutate({{output_name}} := set_units({{output_name}}, "kg/day"),
             {{output_upper}} := set_units({{output_upper}}, "kg/day"),
             {{output_lower}} := set_units({{output_lower}}, "kg/day")) |> 
      mutate(Flow = set_units(Flow, "ft^3/s")) |> 
      group_by(Date, site_no) |> 
      summarise({{output_name}} := mean({{output_name}}, na.rm = TRUE),
                {{output_upper}} := mean({{output_upper}}, na.rm = TRUE),
                {{output_lower}} := mean({{output_lower}}, na.rm = TRUE)) |> 
      mutate({{output_name}} := drop_units({{output_name}}),
             {{output_upper}} := drop_units({{output_upper}}),
             {{output_lower}} := drop_units({{output_lower}}))
  }
  
  ## sum to month
  monthly <- daily |> 
    mutate(month = floor_date(Date, "month")) |> 
    mutate(month = as.character(month, format = "%Y-%m")) |> 
    group_by(month, site_no) |> 
    summarise({{output_name}} := sum({{output_name}}, na.rm = TRUE),
              {{output_upper}} := sum({{output_upper}}, na.rm = TRUE),
              {{output_lower}} := sum({{output_lower}}, na.rm = TRUE))
  
  ## sum to year
  annually <- daily |> 
    group_by(year = year(Date), site_no) |> 
    summarise({{output_name}} := sum({{output_name}}, na.rm = TRUE),
              {{output_upper}} := sum({{output_upper}}, na.rm = TRUE),
              {{output_lower}} := sum({{output_lower}}, na.rm = TRUE))
  
    

  return(list(sims = sims,
              daily = daily,
              monthly = monthly,
              annually = annually))
  

}









## Simulate lake outputs

predict_daily_lk <- function(model, # target
                          data, # target
                          site_no, # quoted string
                          date, # quoted string
                          output_name, #unquoted
                          output_upper, #unquoted
                          output_lower, #unquoted
                          fn_data = FALSE
) {
  
  if (!isTRUE(fn_data)) {
    data <- data |>
      format_dam_data() |>
      filter(site_no == {{site_no}},
             Date >= as.Date(date))
  } else {
    data <- data |>
      filter(site_no == {{site_no}},
             Date >= as.Date(date))
  }
  
  ## if actual predictions of load
  if (!isTRUE(fn_data)) {
    
    
    ## return gam prediction
    out <- gratia::add_fitted(data,
                              model,
                              value = ".fits",
                              type = "response") |>
      select(Date, Flow, log1p_Flow, site_no, .fits) |> 
      rename({{output_name}} := .fits)
    
    ## fitted values of the response drawn from the posterior distribution of 
    ## the fitted model using Gaussian approximation to the posterior.
    sims <- fitted_samples(model, newdata = data, n = 1000,
                           seed = 1972, scale = "response",
                           freq = TRUE)
    
    sims$Date <- rep(data$Date, 1000)
    sims$Flow <- rep(data$Flow, 1000)
    
    ## return credible intervals for daily predictions
    daily_ci <- sims |>
      mutate(Flow = as_units(Flow, "ft^3/s")) |> 
      mutate(Flow = set_units(Flow, "L/s")) |> 
      mutate(fitted = as_units(fitted, "mg/L")) |> 
      mutate(fitted = fitted * Flow) |> 
      mutate(fitted = set_units(fitted, "kg/day")) |> 
      mutate(Flow = set_units(Flow, "ft^3/s")) |> 
      mutate(fitted = drop_units(fitted)) |> 
      group_by(row) |>
      summarise(lower.ci = quantile(fitted, probs = 0.025, type = 8, na.rm = TRUE),
                upper.ci = quantile(fitted, probs = 0.975, type = 8, na.rm = TRUE))
    
    ## convert concentration to flux
    daily <- out |>
      mutate({{output_upper}} := daily_ci$upper.ci,
             {{output_lower}} := daily_ci$lower.ci) |> 
      mutate(Flow = as_units(Flow, "ft^3/s")) |> 
      mutate(Flow = set_units(Flow, "L/s")) |> 
      mutate({{output_name}} := as_units({{output_name}}, "mg/L")) |> 
      mutate({{output_name}} := Flow * {{output_name}}) |> 
      mutate({{output_name}} := set_units({{output_name}}, "kg/day")) |> 
      mutate(Flow = set_units(Flow, "ft^3/s")) |> 
      mutate(Flow = drop_units(Flow)) |> 
      mutate({{output_name}} := drop_units({{output_name}}))
    
  } else {
    ## if making flow normalized predictions
    message("FN predictions!")
    
    ## return gam prediction
    out <- gratia::add_fitted(data,
                              model,
                              value = ".fits",
                              type = "response") |>
      select(Date, Flow, log1p_Flow, site_no, .fits) |> 
      rename({{output_name}} := .fits)
    
    ## fitted values of the response drawn from the posterior distribution of 
    ## the fitted model using Gaussian approximation to the posterior.
    sims <- fitted_samples(model, newdata = data, n = 1000,
                           seed = 1972, scale = "response",
                           freq = TRUE)
    
    sims$Date <- rep(data$Date, 1000)
    sims$Flow <- rep(data$Flow, 1000)
    
    ## return credible intervals for fn concentration
    ## grouped by date/row to combine with fn fits
    sims <- sims |> 
      group_by(Date, row) |> 
      summarise(lower.ci = quantile(fitted, probs = 0.025, type = 8, na.rm = TRUE),
                upper.ci = quantile(fitted, probs = 0.975, type = 8, na.rm = TRUE))
    
    out <- out |> 
      mutate({{output_upper}} := sims$upper.ci,
             {{output_lower}} := sims$lower.ci)
    
    ## calculate daily loads
    daily <- out |> 
      ungroup() |> 
      mutate(Flow = as_units(Flow, "ft^3/s")) |> 
      mutate(Flow = set_units(Flow, "L/s")) |> 
      mutate({{output_name}} := as_units({{output_name}}, "mg/L"),
             {{output_upper}} := as_units({{output_upper}}, "mg/L"),
             {{output_lower}} := as_units({{output_lower}}, "mg/L")) |> 
      mutate({{output_name}} := Flow * {{output_name}},
             {{output_upper}} := Flow * {{output_upper}},
             {{output_lower}} := Flow * {{output_lower}}) |> 
      mutate({{output_name}} := set_units({{output_name}}, "kg/day"),
             {{output_upper}} := set_units({{output_upper}}, "kg/day"),
             {{output_lower}} := set_units({{output_lower}}, "kg/day")) |> 
      mutate(Flow = set_units(Flow, "ft^3/s")) |> 
      group_by(Date, site_no) |> 
      summarise({{output_name}} := mean({{output_name}}, na.rm = TRUE),
                {{output_upper}} := mean({{output_upper}}, na.rm = TRUE),
                {{output_lower}} := mean({{output_lower}}, na.rm = TRUE)) |> 
      mutate({{output_name}} := drop_units({{output_name}}),
             {{output_upper}} := drop_units({{output_upper}}),
             {{output_lower}} := drop_units({{output_lower}}))
  }
  
  ## sum to month
  monthly <- daily |> 
    mutate(month = floor_date(Date, "month")) |> 
    mutate(month = as.character(month, format = "%Y-%m")) |> 
    group_by(month, site_no) |> 
    summarise({{output_name}} := sum({{output_name}}, na.rm = TRUE),
              {{output_upper}} := sum({{output_upper}}, na.rm = TRUE),
              {{output_lower}} := sum({{output_lower}}, na.rm = TRUE))
  
  ## sum to year
  annually <- daily |> 
    group_by(year = year(Date),
             site_no) |> 
    summarise({{output_name}} := sum({{output_name}}, na.rm = TRUE),
              {{output_upper}} := sum({{output_upper}}, na.rm = TRUE),
              {{output_lower}} := sum({{output_lower}}, na.rm = TRUE))
  
  
  
  return(list(sims = sims,
              daily = daily,
              monthly = monthly,
              annually = annually))
  
}









