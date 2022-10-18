## estimate mean annual yields
library(units)


df <- list("lav" = tar_read(daily_tp_08164000), 
     "tex" = tar_read(daily_tp_texana))


df |> 
  map(pluck, "annually") |> 
  bind_rows() |> 
  group_by(year) |> 
  summarise(TP_Estimate = sum(TP_Estimate),
            TP_Upper = sum(TP_Upper),
            TP_Lower = sum(TP_Lower)) |> 
  ungroup() |> 
  summarise(TP_Estimate = mean(TP_Estimate),
            TP_Upper = mean(TP_Upper),
            TP_Lower = mean(TP_Lower)) |> 
  mutate(area = as_units(1370+817, "mi^2")) |> 
  mutate(area = set_units(area, "km^2")) |> 
  mutate(TP_Estimate = as_units(TP_Estimate, "kg/year"),
         TP_Upper = as_units(TP_Upper, "kg/year"),
         TP_Lower = as_units(TP_Lower, "kg/year")) |> 
  mutate(TP_Yield = TP_Estimate/area,
         TP_Yield_Upper = TP_Upper/area,
         TP_Yield_Lower = TP_Lower/area)

## Lk Texasna 1370 sq mile 
## Lavaca at Edna 817 sq miles



x <- as_units(0.079, "kg/hectare/yr")
x <- set_units(x, "kg/kilometer^2/yr")
