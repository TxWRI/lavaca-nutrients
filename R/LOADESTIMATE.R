
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
                          output_lower, #unquoted
                          fn_data = FALSE
                          ) {
  
  
  if (!isTRUE(fn_data)) {
    data <- data |>
      filter(site_no == {{site_no}},
             Date >= as.Date(date))    
  } else {
    data <- data |>
      filter(site_no == {{site_no}},
             Date >= as.Date(date))   
  }
  
  ## return gam prediction
  out <- gratia::add_fitted(data,
                            model,
                            value = ".fits",
                            type = "response") |> 
    select(Date, site_no, .fits)
  
  ## if fn, need to take mean by date
  if(isTRUE(fn_data)) {
    out <- out |>
      group_by(site_no, Date) |> 
      summarise(.fits := mean(.fits, na.rm = TRUE))
  }
  
  ## return intervals
  sims <- sim_posterior(model, nsim = 1000, newdata = data)
  
  if(isTRUE(fn_data)) {
    sims <- sims |>
      group_by(Date, run) |>
      #summarise({{output_name}} := mean(simulated, na.rm = TRUE))
      summarise(simulated = mean(simulated, na.rm = TRUE))
  }
  
  daily_ci <- sims |>
    group_by(Date) |>
    summarise({{output_lower}} := quantile(simulated, probs = 0.025, type = 8, na.rm = TRUE),
              {{output_upper}} := quantile(simulated, probs = 0.975, type = 8, na.rm = TRUE))
  
  daily <- out |>
    left_join(daily_ci, by = c("Date" = "Date")) |>
    rename({{output_name}} := .fits)
  
  
  monthly_ci <- sims |>
    group_by(month = floor_date(Date, "month"), run) |>
    summarise(simulated = sum(simulated, na.rm = TRUE)) |>
    summarise({{output_lower}} := quantile(simulated, probs = 0.025, type = 8, na.rm = TRUE),
              {{output_upper}} := quantile(simulated, probs = 0.975, type = 8, na.rm = TRUE))
  
  monthly <- out |>
    group_by(month = floor_date(Date, "month")) |>
    summarise(.fits = sum(.fits, na.rm = TRUE)) |>
    left_join(monthly_ci, by = c("month" = "month")) |>
    rename({{output_name}} := .fits)
  
  annually_ci <- sims |>
    group_by(year = year(Date), run) |>
    summarise(simulated = sum(simulated, na.rm = TRUE)) |>
    summarise({{output_lower}} := quantile(simulated, probs = 0.025, type = 8, na.rm = TRUE),
              {{output_upper}} := quantile(simulated, probs = 0.975, type = 8, na.rm = TRUE))
  
  annually <- out |>
    group_by(year = year(Date)) |>
    summarise(.fits = sum(.fits, na.rm = TRUE)) |>
    left_join(annually_ci, by = c("year" = "year")) |>
    rename({{output_name}} := .fits)
  
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
  
  ## return gam prediction
  out <- gratia::add_fitted(data,
                            model,
                            value = ".fits",
                            type = "response") |>
    select(Date, Flow, log1p_Flow, site_no, .fits) |> 
    rename({{output_name}} := .fits) |>
    ## calculate load from concentration and mean daily dam discharge
    mutate(Flow = as_units(Flow, "ft^3/s"),
           Flow = set_units(Flow, "L/s"),
           {{output_name}} := as_units({{output_name}}, "mg/L"),
           {{output_name}} := {{output_name}} * Flow,
           across(last_col(),
                  ~set_units(., "kg/day"))) |> 
    mutate(
      Flow = drop_units(Flow),
      across(.cols = tidyselect::starts_with(c("NO3", "TP")),
             ~drop_units(.))
    )
  
  
  ## if fn, need to take mean by date
  if(isTRUE(fn_data)) {
    out <- out |>
      group_by(site_no, Date) |> 
      summarise({{output_name}} := mean({{output_name}}, na.rm = TRUE))
  }
  ## return intervals
  sims <- sim_posterior(model, nsim = 1000, newdata = data)
  
  sims$Flow <- rep(data$Flow, 1000)
  
  sims <- sims |>
    mutate(Flow = as_units(Flow, "ft^3/s"),
           Flow = set_units(Flow, "L/s"),
           simulated = as_units(simulated, "mg/L"),
           simulated_flux = Flow * simulated,
           simulated_flux = set_units(simulated_flux, "kg/day"),
           simulated_flux = drop_units(simulated_flux)) 
  
  if(isTRUE(fn_data)) {
    sims <- sims |> 
      group_by(Date, run) |> 
      summarise(simulated_flux = mean(simulated_flux, na.rm = TRUE))
  }
  daily_ci <- sims|>
    group_by(Date) |>
    summarise({{output_lower}} := quantile(simulated_flux, probs = 0.025, type = 8, na.rm = TRUE),
              {{output_upper}} := quantile(simulated_flux, probs = 0.975, type = 8, na.rm = TRUE))
  
  daily <- out |>
    left_join(daily_ci, by = c("Date" = "Date"))
  
  monthly_ci <- sims |>
    group_by(month = floor_date(Date, "month"), run) |>
    summarise(simulated_flux = sum(simulated_flux, na.rm = TRUE)) |>
    summarise({{output_lower}} := quantile(simulated_flux, probs = 0.025, type = 8, na.rm = TRUE),
              {{output_upper}} := quantile(simulated_flux, probs = 0.975, type = 8, na.rm = TRUE))
  
  monthly <- out |>
    group_by(month = floor_date(Date, "month")) |>
    summarise({{output_name}} := sum({{output_name}}, na.rm = TRUE)) |>
    left_join(monthly_ci, by = c("month" = "month")) 
  
  annually_ci <- sims |>
    group_by(year = year(Date), run) |>
    summarise(simulated_flux = sum(simulated_flux, na.rm = TRUE)) |>
    summarise({{output_lower}} := quantile(simulated_flux, probs = 0.025, type = 8, na.rm = TRUE),
              {{output_upper}} := quantile(simulated_flux, probs = 0.975, type = 8, na.rm = TRUE))
  
  annually <- out |>
    group_by(year = year(Date)) |>
    summarise({{output_name}} := sum({{output_name}}, na.rm = TRUE)) |>
    left_join(annually_ci, by = c("year" = "year"))
  
  return(list(sims = sims,
              daily = out,
              monthly = monthly,
              annually = annually))
}









