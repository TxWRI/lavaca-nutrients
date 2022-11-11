estuary_prediction_data <- function(adjusted_flow,
                                 loads,
                                 date) {
  df <- adjusted_flow |> 
    left_join(loads, by = c("Date" = "Date")) |> 
    rename(end_date = Date) |> 
    filter(end_date >= as.Date(date)) |> 
    mutate(ddate = decimal_date(end_date),
           day = yday(end_date))
  
  df
    
}