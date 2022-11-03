library(targets)

estuary_gam_data <- function(model_data,
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
  data
}
model_comp <- AIC(tar_read(tp_lavaca_13563_temporal),
      tar_read(tp_lavaca_13563_flow),
      tar_read(tp_lavaca_13563_full))

row.names(model_comp) <- c("Temporal Model", "Flow Model", "Flow and Load Model")

m2 <- tar_read(tp_lavaca_13563_full)
summary(m2)
draw(m2)
appraise(m2)



est_data <- tar_read(estuary_model_data)
est_data <- est_data |> 
  filter(parameter_code == "00665", station_id == "13563") |> 
  mutate(ddate = decimal_date(end_date))

est_loads <- tar_read(estuary_tp_loads)
predict_data <- est_loads|> 
  select(end_date = Date,
         Discharge = Discharge,
         TP_resid = TP_resid) |> 
  mutate(ddate = decimal_date(end_date),
         day = yday(end_date)) 


fitted <- fitted_values(m2, data = tar_read(tp_lavaca_prediction_data))  
  
ggplot(est_data) +
  geom_point(aes(end_date, log(value))) +
  geom_line(data = fitted, aes(end_date, fitted),
            alpha = 0.5)

df <- data_slice(m2,
                 TP_resid = quantile(TP_resid, probs = c(0.25, 0.5, 0.75)),
                 ddate = evenly(ddate, 50))

fitted_values(m2, data = df) |> 
  mutate(TP_resid = as.factor(TP_resid)) |> 
  ggplot() +
  geom_line(aes(ddate, fitted, color = TP_resid, group = TP_resid))

df <- data_slice(m2, 
           flw_res = quantile(flw_res, probs = c(0.25, 0.5, 0.75)),
           TP_resid = quantile(TP_resid, probs = c(0.25, 0.5, 0.75)),
           ddate = evenly(ddate, 50))

fitted_values(m2, data = df) |> 
  mutate(TP_resid = as.factor(TP_resid),
         flw_res = as.factor(flw_res)) |> 
  ggplot() +
  geom_line(aes(ddate, fitted, color = flw_res, group = flw_res)) +
  facet_wrap(~TP_resid)

df <- data_slice(m2, 
                 TP_resid = quantile(TP_resid, probs = c(0.25, 0.5, 0.75)),
                 ddate = evenly(ddate, 50),
                 day = c(15, 75, 225, 320))

fitted_values(m2, data = df) |> 
  mutate(TP_resid = as.factor(TP_resid),
         day = as.factor(day)) |> 
  ggplot() +
  geom_line(aes(ddate, fitted, color = day)) +
  facet_wrap(~TP_resid)



## hold everything equal but load
df <- data_slice(m2,
                 TP_resid = evenly(TP_resid, n = 100))


fitted_values(m2, data = df) |>  
  ggplot() +
  geom_line(aes(TP_resid, fitted))



df <- data_slice(m2,
                 ddate = c(2000, 2005, 2010, 2015, 2020),
                 day = evenly(day,365))
fitted_values(m2, data = df) |> 
  ggplot() +
  geom_line(aes(day, fitted, color = ddate, group = ddate)) +
  geom_ribbon(aes(day, ymin = lower, ymax = upper, fill = ddate, group = ddate), alpha = 0.15) +
  scale_color_viridis_c() +
  scale_fill_viridis_c()


df <- data_slice(m2,
                 ddate = evenly(ddate, 1000),
                 TP_resid = quantile(TP_resid, c(0.25, .50, 0.75)))
fitted_values(m2, data = df) |> 
  ggplot() +
  geom_line(aes(ddate, fitted, color = TP_resid, group = TP_resid)) +
  geom_ribbon(aes(ddate, ymin = lower, ymax = upper), alpha = 0.15)


### need to just plot partial effect of load and flow https://gavinsimpson.github.io/gratia/articles/data-slices.html#using-smooth_estimates
## can I sub in the actual values for plotting???


df <- data_slice(m2,
                 ddate = evenly(ddate, 1000))
sm <- smooth_estimates(m2, smooth = "s(ddate)", data = df) |>
  add_confint()
sm
ggplot(sm) +
  geom_line(aes(ddate, est)) +
  geom_ribbon(aes(ddate, ymin = lower_ci, ymax = upper_ci), alpha = 0.25)


## x% change in load results in approximately x% increase in concentration all else equal.
df <- data_slice(m2,
                 TP_resid = evenly(TP_resid, 100))
fitted_values(m2, data = df) |> 
  ggplot() +
  geom_line(aes(TP_resid, fitted)) +
  geom_ribbon(aes(TP_resid, ymin = lower, ymax = upper), alpha = 0.15)
