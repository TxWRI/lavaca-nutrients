

## write loads to csv file
loads_to_csv <- function(daily_data, #list of daily data
                         df = "daily",
                         output = "data/Output/daily_loads/daily_loads.csv") {
  
  daily_data |> 
    map(pluck, df) |> 
    bind_rows() |> 
    mutate(site_no = case_when(
      site_no == "lktexana_g" ~ "usgs08164525",
      site_no != "lktexana_g" ~ site_no
    )) |> 
    write_csv_arrow(file = output)
  
  output
  
}