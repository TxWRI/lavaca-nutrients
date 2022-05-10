# Download Lavaca-Navidad WQP data ----

#' @title Download WQP data from water quality portal
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
      startDate = "2000-01-01",
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
  texana <- read_table("data/TWDB/Gaged/lktexanag", col_types = "nnnn_") |> 
    pivot_longer(cols = lktexana_g, names_to = "site_no", values_to = "Flow") |> 
    mutate(Date = lubridate::ymd(paste0(year,"-", month,"-", day)),
           agency_cd = "TWDB") |> 
    select(-c(year, month, day))
  
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
      site_no == "8164000" ~ "08164000",
      site_no == "8164390" ~ "08164390",
      site_no == "8164450" ~ "08164450",
      site_no == "8164503" ~ "08164503",
      site_no == "8164504" ~ "08164504",
      site_no == "lktexana_g" ~ "lktexana_g"
    )) |> 
    mutate(area = case_when(
      site_no == "08164000" ~ 817, #sq miles
      site_no == "08164390" ~ 579,
      site_no == "08164450" ~ 289,
      site_no == "08164503" ~ 178,
      site_no == "08164504" ~ 53.9,
      site_no == "lktexana_g" ~ 1370
    )) |> 
    nest() |>
    ## calculate base and quickflow
    mutate(data = map(data, ~{
      .x |> 
        bind_cols(EcoHydRology::BaseflowSeparation(.x$Flow))
    })) |>
    ## calculate the flow and time based covariates
    mutate(data = map(data, ~{
      .x |> 
        mutate(
          ## first row returns negative, fixes that
          qft = case_when(
            qft < 0 ~ Flow - bt,
            qft >= 0 ~ qft
          ),
          ## add a very small amount to permit log transformation
          bt = bt + 1E-6,
          qft = qft + 1E-6,
          Flow = Flow + 1E-6,
          ## runoff
          runoff = Flow/area,
          lrunoff = log(runoff),
          ## day of year
          yday = lubridate::yday(Date),
          ## decimal date
          ddate = lubridate::decimal_date(Date),
          ## year
          year = lubridate::year(Date),
          ## log base e flow
          logq = log(Flow),
          ## discharge rate of change
          dT = as.numeric(difftime(lead(Date), lag(Date), units = "days")),
          lagQ = lag(logq),
          leadQ = lead(logq),
          dQ = lagQ - leadQ,
          dQdT = dQ/dT,
          ## baseflow proportion of total flow
          bfp = bt/Flow
        )
    })) |> 
    unnest(cols = c(data)) -> q_df
  
  ## create field to join wq data to discharge data
  wq_df |> 
    clean_names() |> 
    filter(station_id != "15377") |> 
    mutate(site_no = case_when(
      station_id == "12524" ~ "08164000",
      station_id == "13654" ~ "08164450",
      station_id == "13655" ~ "08164503",
      station_id == "15374" ~ "lktexana_g",
      station_id == "15380" ~ "08164390",
      station_id == "15382" ~ "08164504"
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
    select(-c(greater_than_less_than_NA, value_NA)) -> q_df
}


