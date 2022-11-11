# Download Lavaca-Navidad WQP data ----

#' @title Reads SWQMIS data files
#'
#' @return list of tibbles
download_WQP_data <- function(dir = "data/SWQM") {
  ## read data
  files <- fs::dir_ls(dir)
  files <- files[1:28]
  readr::read_delim(files, 
                    delim = "|", escape_double = FALSE, col_types = cols(Segment = col_character(), 
                                                                         `Station ID` = col_character(), `End Date` = col_date(format = "%m/%d/%Y"), 
                                                                         `End Time` = col_skip(), `End Depth` = col_skip(), 
                                                                         `Start Date` = col_skip(), `Start Time` = col_skip(), 
                                                                         `Start Depth` = col_skip(), `Composite Category` = col_skip(), 
                                                                         `Composite Type` = col_skip(), Comments = col_skip()), 
                    trim_ws = TRUE)
  
  
}



# Download discharge data ----

#' @title Download Mean Daily Discharge
#'
#' @return tibbles
download_Q_data <- function(usgs_dir = "data/USGS",
                            twdb_dir = "data/TWDB") {
  ## download or read USGS data
  if(!file.exists(paste0(usgs_dir, "/usgs_flows.csv"))) {
    q <- dataRetrieval::readNWISdv(
      siteNumbers = c("08164000", # Lavaca River at Edna
                      "08164504", # E Mustang Creek nr Louise
                      "08164503", # W Mustang Creek nr Ganado
                      "08164450", # Sandy Creek nr Ganado
                      "08164390"), # Navidad River at Strane Pk nr Edna
      parameterCd = "00060", #discharge
      startDate = "1995-01-01",
      endDate = "2020-12-31"
    )
    q <- dataRetrieval::renameNWISColumns(q)
    
    arrow::write_csv_arrow(q, paste0(usgs_dir,"/usgs_flows.csv"))
    
  } else {
    q <- arrow::read_csv_arrow(paste0(usgs_dir,"/usgs_flows.csv"))
  }
  q <- q |> 
    mutate(site_no = as.character(site_no))
  ## agency_cd, site_no, Date, Flow, Flow_cd
  
  ## read TWDB data
  
  # texana is gaged flow and can be used as is.
  # need to convert from acre-feet per day to cubic feet per second!
  texana <- read_table("data/TWDB/Gaged/lktexanag", col_types = "nnnn_") |> 
    pivot_longer(cols = lktexana_g, names_to = "site_no", values_to = "Flow") |> 
    mutate(Date = lubridate::ymd(paste0(year,"-", month,"-", day)),
           agency_cd = "TWDB") |> 
    select(-c(year, month, day)) |> 
    #convert to cubic feet per second
    mutate(Flow = (Flow * (43560/86400)))
  
  q |> 
    bind_rows(texana)
  
}


# Clean data ----

clean_data <- function(wq_df, q_df) {
  
  ## clean flow data
  q_df |> 
    group_by(site_no) |> 
    ## add zero to front of gage numbers
    mutate(site_no = case_when(
      site_no == "8164000" ~ "usgs08164000",
      site_no == "8164390" ~ "usgs08164390",
      site_no == "8164450" ~ "usgs08164450",
      site_no == "8164503" ~ "usgs08164503",
      site_no == "8164504" ~ "usgs08164504",
      site_no == "lktexana_g" ~ "lktexana_g"
    )) |> 
    complete(Date = seq(min(Date), max(Date), by = 'day')) |> 
    filter(Date >= as.Date("2000-01-01")) |> 
    select(Date, site_no, Flow)-> q_df
  
  
  fill_gaps_df <- q_df |> 
    pivot_wider(names_from = site_no, values_from = Flow)
  
  ##use imputeTS to fill short gaps
  imp <- imputeTS::na_interpolation(fill_gaps_df$usgs08164390, maxgap = 5)
  fill_gaps_df$usgs08164390 <- imp
  imp <- imputeTS::na_interpolation(fill_gaps_df$usgs08164450, maxgap = 5)
  fill_gaps_df$usgs08164450 <- imp
  imp <- imputeTS::na_interpolation(fill_gaps_df$usgs08164503, maxgap = 5)
  fill_gaps_df$usgs08164503 <- imp
  
  ## interpolate large gap using log model between nearby sites
  m1 <- gam(log1p(usgs08164450) ~ s(log1p(usgs08164000)) +
              s(log1p(usgs08164390)) +
              s(log1p(usgs08164503)) + 
              s(log1p(usgs08164504)),
            data = fill_gaps_df,
            family = scat(link = "identity"))
  out <- expm1(predict(m1, newdata = fill_gaps_df,
                       type = "response"))
  
  fill_gaps_df$usgs08164450[is.na(fill_gaps_df$usgs08164450)] <- out[is.na(fill_gaps_df$usgs08164450)]
  
  q_df <- pivot_longer(fill_gaps_df,
                     !Date,
                     names_to = "site_no", 
                     values_to = "Flow")
  
  ## create flow and time variables:
  
  q_df <- q_df |> 
    group_by(site_no) |> 
    ## antecedant flow variables
    mutate(Flow = Flow,
           Flow_p1 = Flow + 1,
           log1p_Flow = log(Flow_p1),
           # flow anomalies
           ltfa = fa(Flow_p1, Date, T_1 = "1 year",
                     T_2 = "period", transform = "log10"),
           stfa = fa(Flow_p1, Date, T_1 = "1 day",
                     T_2 = "1 month", transform = "log10"),
           # rate of change
           dqdt = rate_of_change(Flow, Date), 
           # smooth discounted flow
           ma = sdf(log1p(Flow))) |> 
    ## time variables
    mutate(
      ## day of year
      yday = lubridate::yday(Date),
      ## decimal date
      ddate = lubridate::decimal_date(Date),
      ## year
      year = lubridate::year(Date)
    )
  
  ## create field to join wq data to discharge data
  wq_df |> 
    clean_names() |> 
    filter(station_id != "15374") |> 
    mutate(site_no = case_when(
      station_id == "12524" ~ "usgs08164000",
      station_id == "13654" ~ "usgs08164450",
      station_id == "13655" ~ "usgs08164503",
      station_id == "15377" ~ "lktexana_g",
      station_id == "15380" ~ "usgs08164390",
      station_id == "15382" ~ "usgs08164504"
    )) -> wq_df
  
  ## join discharge and wq data
  q_df |> 
    left_join(
      wq_df |>
        select(c(station_id, site_no, parameter_code, greater_than_less_than, value, end_date)) |> 
        group_by(station_id, site_no, parameter_code, greater_than_less_than, end_date) |> 
        summarise(value = max(value, na.rm = TRUE), .groups = "drop"),
      by = c("Date" = "end_date", "site_no" = "site_no")
    ) |> 
    pivot_wider(names_from = parameter_code,
                values_from = c(greater_than_less_than, value),
                values_fill = NA) |>
    rename(censored_TP = greater_than_less_than_00665,
           censored_NO3 = greater_than_less_than_00620,
           censored_NH3 = greater_than_less_than_00610,
           censored_TKN = greater_than_less_than_00625,
           TP = value_00665,
           NO3 = value_00620,
           NH3 = value_00610,
           TKN = value_00625) |> 
    select(-c(greater_than_less_than_NA, value_NA)) |> 
    ## convert censored data for cenGAM
    select(-c(censored_NH3, censored_TKN, NH3, TKN)) |>
    ## save original values
    mutate(original_NO3 = NO3,
           original_TP = TP) |> 
    ## multiply censored values by 0.5
    dplyr::mutate(trans_TP = case_when(
      !is.na(censored_TP) ~ TP * 0.5, #when censored, transform value to .5 detection limit
      is.na(censored_TP) ~ TP
    )) |>
    dplyr::mutate(trans_NO3 = case_when(
      !is.na(censored_NO3) ~ NO3 * 0.5, #when censored, transform value to .5 detection limit
      is.na(censored_NO3) ~ NO3
    )) |>
    ## calculate daily flux
    mutate(Flow = Flow + 0.001,
           Flow = as_units(Flow, "ft^3/s"),
           Flow = set_units(Flow, "L/s"),
           ## NO3 flux calculation
           NO3 = as_units(NO3, "mg/L"),
           NO3_flux = NO3 * Flow,
           NO3_flux = set_units(NO3_flux, "kg/day"),
           NO3_flux = drop_units(NO3_flux),
           ## TP flux calculation
           TP = as_units(TP, "mg/L"),
           TP_flux = TP * Flow,
           TP_flux = set_units(TP_flux, "kg/day"),
           TP_flux = drop_units(TP_flux),
           ## remove units from vectors to run models
           Flow = set_units(Flow, "ft^3/s"),
           Flow = drop_units(Flow),
           NO3 = drop_units(NO3),
           TP = drop_units(TP)) -> q_df
  

}



### create flow-normalized dataset

fn_data <-   function(model_data) {
  
  grouped <- model_data |> 
    dplyr::select(site_no, Flow, log1p_Flow, stfa, ltfa, ma, yday) |> 
    group_by(site_no, yday) #|> 
  
  
  
  model_data |> 
    dplyr::select(site_no, yday, ddate, Date) |> 
    left_join(grouped)
  
}


fn_lk_data <-   function(model_data) {
  
  inflow <- model_data |>
    filter(site_no != "usgs08164000") |> 
    select(c(Date, site_no, Flow, yday)) |> 
    pivot_wider(names_from = site_no,
                values_from = Flow) |> 
    mutate(inflow = usgs08164390 + usgs08164450 + usgs08164503 + usgs08164504) |> 
    select(Date, Flow = lktexana_g, inflow, yday) |> 
    mutate(
      log1p_inflow = log1p(inflow),
      # flow anomalies
      ltfa = fa(inflow+1, Date, T_1 = "1 year",
                T_2 = "period", transform = "log"),
      stfa = fa(inflow+1, Date, T_1 = "1 day",
                T_2 = "1 month", transform = "log"),
      # smooth discounted flow
      ma = sdf(log1p(inflow))) |>
    dplyr::select(Flow, inflow, log1p_inflow, stfa, ltfa, ma, yday) |>
    group_by(yday) |> 
    mutate(log1p_Flow = log1p(Flow))
  
  
  model_data |>
    filter(site_no == "lktexana_g") |>
    ungroup()  |> 
    dplyr::select(site_no, yday, ddate, Date) |> 
    left_join(inflow)
}




## Read Lavaca Bay Inflow Data

load_lb_inflow <- function() {
  ## need to load TWDB data
  files <- fs::dir_ls("data/TWDB/Modeled/")
  
  files |> 
    map_df(~{read_table(.x,
                        col_names = c("year", "month", "day", "afd"), 
                        col_types = "nnnn",
                        skip = 1) |> 
        bind_rows()}) |> 
    mutate(Date = lubridate::ymd(paste0(year,"-", month,"-", day))) |> 
    group_by(Date) |> 
    summarize(Discharge = sum(afd)) |> 
    mutate(Discharge = (Discharge * (43560/86400)))
}


## develop seasonally adjusted lavaca bay inflow

adjust_lbay_inflow <- function(flow) {
  flow_out <- flow |> 
    mutate(day = yday(Date))
  
  m_flow <- gam(log1p(Discharge) ~ s(day, bs = "cc"),
                data = flow_out,
                method = "REML")
  flow$flw_res <- residuals(m_flow)
  
  return(flow)
}


## return estuary wq data

load_est_wq_data <- function() {
  df <- readr::read_delim("data/SWQM-LavacaBay/SWQM-LavacaBay.txt", 
                          delim = "|", escape_double = FALSE, col_types = cols(Segment = col_character(), 
                                                                               `Station ID` = col_character(), `End Date` = col_date(format = "%m/%d/%Y"), 
                                                                               `End Time` = col_skip(), `End Depth` = col_skip(), 
                                                                               `Start Date` = col_skip(), `Start Time` = col_skip(), 
                                                                               `Start Depth` = col_skip(), `Composite Category` = col_skip(), 
                                                                               `Composite Type` = col_skip(), Comments = col_skip()), 
                          trim_ws = TRUE) |> 
    janitor::clean_names()
  df
}


## create estuary model data
create_est_model_data <- function(wq_data,
                                  flow) {
  wq_data <- wq_data |> 
    left_join(flow, by = c("end_date" = 'Date')) 
  wq_data
  
}