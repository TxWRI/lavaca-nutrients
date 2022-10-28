## GAM models for stream sites

model_gam <- function(formula,
                      data,
                      family) {
  
  gam(formula = formula,
      data = data,
      select = TRUE,
      knots = list(yday = c(1, 366)),
      family = family,
      method = "REML",
      optimizer = "efs"
      )
}


## GAM models for below lk texana

gam_b_texana <- function(formula,
                         data,
                         family) {
  
  data <- format_dam_data(data)
  
  model_gam(formula, data, family)
  
  # gam(formula = formula,
  #     data = data,
  #     select = TRUE,
  #     knots = list(yday = c(1, 366)),
  #     family = family,
  #     method = "REML",
  #     optimizer = "efs") 
}


format_dam_data <- function(data) {
  gaged_inflow <- data |> 
    filter(site_no != "lktexana_g") |> 
    filter(site_no != "usgs08164000") |> 
    select(c(Date, site_no, Flow)) |> 
    pivot_wider(names_from = site_no,
                values_from = Flow) |> 
    mutate(inflow = usgs08164390 + usgs08164450 + usgs08164503 + usgs08164504)
  
  below_tex <- data |> 
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
  return(below_tex)
}


# Estuary models -------------

fn_estuary_tp_loads <- function(lavaca_loads,
                                navidad_loads,
                                flow) {
  loads <- lavaca_loads$daily |> 
    bind_rows(navidad_loads$daily) |> 
    select(Date, TP_Estimate) |> 
    group_by(Date) |> 
    summarise(TP = sum(TP_Estimate)) |> 
    filter(Date >= as.Date("2000-01-02")) |> 
    left_join(flow, by = c("Date" = "Date"))
  
  tp_flow <- gam(log(TP) ~ log1p(Discharge),
                 data = loads,
                 family = gaussian())
  
  loads$TP_resid <- residuals(tp_flow)
  
  loads
  
}



fn_estuary_no3_loads <- function(lavaca_loads,
                                navidad_loads,
                                flow) {
  loads <- lavaca_loads$daily |> 
    bind_rows(navidad_loads$daily) |> 
    select(Date, NO3_Estimate) |> 
    group_by(Date) |> 
    summarise(NO3 = sum(NO3_Estimate)) |> 
    filter(Date >= as.Date("2005-01-02")) |> 
    left_join(flow, by = c("Date" = "Date"))
  
  no3_flow <- gam(log(NO3) ~ log1p(Discharge),
                 data = loads,
                 family = gaussian())
  
  loads$NO3_resid <- residuals(no3_flow)
  
  loads
  
}


estuary_gam <- function(formula,
                        model_data,
                        loads,
                        response_parameter,
                        predictor_parameter = TP_resid,
                        date,
                        station) {
  data <- model_data |> 
    mutate(ddate = decimal_date(end_date),
           day = yday(end_date)) |> 
    filter(parameter_code == {{response_parameter}}) |> 
    filter(station_id == {{station}}) |> 
    filter(end_date >= as.Date(date)) |> 
    left_join(loads |> select(Date, {{predictor_parameter}}), 
              by = c("end_date" = "Date"))
  
  estuary_gam_model(formula = formula,
                    data = data)
}

estuary_gam_model <- function(formula, data) {
  gam(formula,
      data = data,
      knots = list(day = c(1,366)),
      method = "REML",
      select = TRUE,
      family = Gamma(link = "log"))
}
