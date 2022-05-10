library(targets)
library(tidyverse)
library(janitor)
library(loadflex)
library(rloadest)

## see example data
data(lamprey_nitrate)
intdat <- lamprey_nitrate[c("DATE","DISCHARGE","NO3")]

# Calibration data: Restrict to points separated by sufficient time
regdat <- subset(lamprey_nitrate, REGR)[c("DATE","DISCHARGE","NO3")]

# Estimation data: Packers Falls discharge
data(lamprey_discharge)
estdat <- subset(lamprey_discharge, DATE < as.POSIXct("2012-10-01 00:00:00", tz="EST5EDT"))
estdat <- estdat[seq(1, nrow(estdat), by=96/4),] # pare to 4 obs/day for speed

tar_make()
#

df <- tar_read(qdata)
df_wq <- tar_read(wqpdata) |> 
  clean_names()

#calculate flow covariates first
df |> 
  filter(site_no == "8164000") |>  ## lavaca gage,
  # mutate(Flow = case_when(
  #   Flow == 0 ~ Flow + 0.001,
  #   Flow != 0 ~ Flow
  # )) |>
  ## calculate baseflow and quickflow components
  bind_cols(EcoHydRology::BaseflowSeparation(df[df$site_no=="8164000",]$Flow)) |>
  ## first row returns negative, fixes that
  mutate(qft = case_when(
    qft < 0 ~ Flow - bt,
    qft >= 0 ~ qft
  )) |> 
  ## add a very small amount to permit log transformation
  mutate(bt = bt + 1E-6,
         qft = qft + 1E-6,
         Flow = Flow + 1E-6) |>
  mutate(yday = lubridate::yday(Date),
         ddate = lubridate::decimal_date(Date),
         year = lubridate::year(Date),
         logq = log(Flow),
         dT = as.numeric(difftime(lead(Date), lag(Date), units = "days")),
         lagQ = lag(logq),
         leadQ = lead(logq),
         dQ = lagQ - leadQ, #,
         dQdT = dQ/dT,
         bfp = bt/Flow) -> df

df |> 
  left_join(
    df_wq |> 
      filter(station_id == "12524") |> 
      select(c(parameter_code, greater_than_less_than, value, end_date)) |> 
      group_by(parameter_code, greater_than_less_than, end_date) |> 
      summarise(value = max(value, na.rm = TRUE), .groups = "drop"),
    by = c("Date" = "end_date")
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
  select(-c(greater_than_less_than_NA, value_NA)) -> df_model


df_model |>  select(-c(NH3, NO3, TKN, censored_NH3, censored_NO3, censored_TKN)) |>  filter(!is.na(TP)) -> df_phos


meta <- metadata(constituent = "TP", flow = "Flow", dates = "Date", 
                 conc.units = "mg L^-1", flow.units = "cfs", load.units = "kg", 
                 load.rate.units = "kg d^-1",
                 site.name = "Lavaca River nr Edna", consti.name = "TP")

tp_rloadest <- loadReg2(loadReg(TP ~ model(9), data = df_phos,
                                flow = "Flow", 
                                dates = "Date", 
                                flow.units = "cfs", 
                                conc.units = "mg/L",
                                load.units = "kg",
                                time.step = "day",
                                station = "Lavaca nr Edna"))
summary(getFittedModel(tp_rloadest))
preds_lr <- predictSolute(tp_rloadest, "conc", df_phos, se.pred=TRUE, date=TRUE)

estimateRho(tp_rloadest, "conc", newdata=df_phos, irreg=TRUE)$rho
residDurbinWatson(tp_rloadest, "conc", newdata=df_phos, irreg=TRUE)


df_phos |> 
  left_join(preds_lr, by = c("Date" = "date")) |> 
  ggplot() +
  geom_point(aes(TP, conc))
