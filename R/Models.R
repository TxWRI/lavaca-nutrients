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
  
  gam(formula = formula,
      data = data,
      select = TRUE,
      knots = list(yday = c(1, 366)),
      family = family,
      method = "REML",
      optimizer = "efs") 
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
    mutate(# flow anomalies
      ltfa = fa(inflow+1, Date, T_1 = "1 year",
                T_2 = "period", transform = "log"),
      stfa = fa(inflow+1, Date, T_1 = "1 day",
                T_2 = "1 month", transform = "log"),
      # smooth discounted flow
      ma = sdf(log1p(inflow)))
  return(below_tex)
}

