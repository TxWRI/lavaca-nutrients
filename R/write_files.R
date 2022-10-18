

## write loads to csv file
loads_to_csv <- function(daily_data, #list of daily data
                         df = "daily",
                         output = "data/Output/daily_loads/daily_loads.csv") {
  
  daily_data |> 
    map(pluck, df) |> 
    bind_rows() |> 
    write_csv_arrow(file = output)
  
  output
  
}