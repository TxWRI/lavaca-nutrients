library(targets)


m1 <- tar_read(tp_lavaca_13563_time)
summary(m1)
draw(m1)
appraise(m1)


m2 <- tar_read(tp_lavaca_13563)
summary(m2)
draw(m2)
appraise(m2)


library(ggeffects)


m2_df_load <- ggemmeans(m2, terms = c("TP_resid"))

ggplot(m2_df_load, aes(x, predicted)) +
  geom_line()

plot(m2_df_load)


m2_df_load_time <- ggemmeans(m2, terms = c("ddate"))
plot(m2_df_load_time)



est_data <- tar_read(estuary_model_data)
est_data <- est_data |> 
  filter(parameter_code == "00665", station_id == "13563") |> 
  mutate(ddate = decimal_date(end_date))

plot(m2_df_load_time) +
  geom_point(data = est_data, aes(ddate, value))
