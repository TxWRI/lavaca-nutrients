


df <- readr::read_delim("data/SWQM-LavacaBay/SWQM-LavacaBay.txt", 
                          delim = "|", escape_double = FALSE, col_types = cols(Segment = col_character(), 
                                                                               `Station ID` = col_character(), `End Date` = col_date(format = "%m/%d/%Y"), 
                                                                               `End Time` = col_skip(), `End Depth` = col_skip(), 
                                                                               `Start Date` = col_skip(), `Start Time` = col_skip(), 
                                                                               `Start Depth` = col_skip(), `Composite Category` = col_skip(), 
                                                                               `Composite Type` = col_skip(), Comments = col_skip()), 
                          trim_ws = TRUE) |> 
  janitor::clean_names()



### 13563 (above causeway) -> 13383 (causeway) -> 13384 Lower bay



## add flow residuals to the model and compare


## then add load residuals and compare



flow <-  targets::tar_read(lbay_inflow)

flow <- flow |> 
  mutate(day = yday(Date))


m_flow <- gam(log1p(Discharge) ~ s(day, bs = "cc"),
              data = flow)
summary(m_flow)
draw(m_flow)

flow$flw_res <- residuals(m_flow)

df <- df |> 
  left_join(flow, by = c("end_date" = 'Date')) 



load_lav_tp <- tar_read(daily_tp_08164000)
load_nav_tp <- tar_read(daily_tp_texana)


loads <- load_lav_tp$daily |> 
  bind_rows(load_nav_tp$daily) |> 
  select(Date, TP_Estimate) |> 
  group_by(Date) |> 
  summarise(TP = sum(TP_Estimate)) |> 
  filter(Date >= as.Date("2000-01-02")) |> 
  left_join(flow, by = c("Date" = "Date"))


tp_flow <- gam(log(TP) ~ log1p(Discharge),
               data = loads,
               family = gaussian())

loads$TP_resid <- residuals(tp_flow)


df |> 
  mutate(ddate = decimal_date(end_date),
         day = yday(end_date)) |> 
  filter(parameter_code == "00665") |> 
  filter(station_id == "13563") |> 
  filter(end_date >= as.Date("2000-01-02")) |> 
  left_join(loads |> select(Date, TP_resid), by = c("end_date" = "Date")) -> df_tp_13563

ggplot(df_tp_13563) +
  geom_point(aes(end_date, log(value)))
ggplot(df_tp_13563) +
  geom_point(aes(day, log(value)))

m1 <- gam(log(value) ~ s(ddate) + s(day, bs = "cc"),
         data = df_tp_13563)
summary(m1)

## used to calculate percent change
m1 <- gam(log(value) ~ 
            s(ddate, k = 10) +
            s(day, k = 6,  bs = "cc") +
            ti(ddate, day, k = c(10,6), bs = c("tp", "cc")),
          data = df_tp_13563,
          knots = list(day = c(1,366)),
          method = "REML",
          select = TRUE)

summary(m1)
appraise(m1)
draw(m1)

## does discharge acount for some of the 
m2.1 <- gam(log(value) ~ 
            s(flw_res) + # explanatory variable
            s(day, k = 5,  bs = "cc"),
          data = df_tp_13563,
          knots = list(day = c(1,366)),
          method = "REML",
          select = TRUE)
appraise(m2.1)

m2.2 <- gam(log(value) ~ 
              s(flw_res) + # explanatory variable
              s(day, k = 5,  bs = "cc") +
              s(ddate), # trend
            data = df_tp_13563,
            knots = list(day = c(1,366)),
            method = "REML",
            select = TRUE)
appraise(m2.2)

summary(m2.1)
draw(m2.1)
summary(m2.2)
draw(m2.2)
AIC(m2.1, m2.2)

m3 <- gam(log(value) ~ 
            s(flw_res) + # explanatory variable
            s(TP_resid) + #explanatory variable
            s(day, k = 5,  bs = "cc") +
            s(ddate), # trend
          data = df_tp_13563,
          knots = list(day = c(1,366)),
          method = "REML",
          select = TRUE)
summary(m3)
appraise(m3)
draw(m3)



## notes
## bugica dound sig increase in Chl and TKN at 13563
## TP at 13384 and 13383



df |> 
  mutate(ddate = decimal_date(end_date),
         day = yday(end_date)) |> 
  filter(parameter_code == "00665") |> 
  filter(station_id == "13383") |> 
  filter(end_date >= as.Date("2000-01-02")) |> 
  left_join(loads |> select(Date, TP_resid), by = c("end_date" = "Date")) -> df_tp_13383


ggplot(df_tp_13383) +
  geom_point(aes(end_date, log(value)))
ggplot(df_tp_13383) +
  geom_point(aes(day, log(value)))

df_tp_13383 |> arrange(end_date) |> pull(value) |> Kendall::MannKendall()



## used to calculate percent change
m1 <- gam(log(value) ~ 
            s(ddate, k = 10) +
            s(day, k = 6,  bs = "cc") +
            ti(ddate, day, k = c(10,6), bs = c("tp", "cc")),
          data = df_tp_13383,
          knots = list(day = c(1,366)),
          method = "REML",
          select = TRUE)

summary(m1)
appraise(m1)
draw(m1)


m3 <- gam(log(value) ~ 
            s(flw_res) + # explanatory variable
            s(TP_resid) + #explanatory variable
            s(day, k = 5,  bs = "cc") +
            s(ddate), # trend
          data = df_tp_13383,
          knots = list(day = c(1,366)),
          method = "REML",
          select = TRUE)
summary(m3)
appraise(m3)
draw(m3)



df |> 
  mutate(ddate = decimal_date(end_date),
         day = yday(end_date)) |> 
  filter(parameter_code == "00665") |> 
  filter(station_id == "13384") |> 
  filter(end_date >= as.Date("2000-01-02")) |> 
  left_join(loads |> select(Date, TP_resid), by = c("end_date" = "Date")) -> df_tp_13384

ggplot(df_tp_13384) +
  geom_point(aes(end_date, log(value)))
ggplot(df_tp_13384) +
  geom_point(aes(day, log(value)))

df_tp_13384 |> arrange(end_date) |> pull(value) |> Kendall::MannKendall()



## used to calculate percent change
m1 <- gam(log(value) ~ 
            s(ddate, k = 10) +
            s(day, k = 6,  bs = "cc") +
            ti(ddate, day, k = c(10,6), bs = c("tp", "cc")),
          data = df_tp_13384,
          knots = list(day = c(1,366)),
          method = "REML",
          select = TRUE)

summary(m1)
appraise(m1)
draw(m1)


m3 <- gam(log(value) ~ 
            s(flw_res) + # explanatory variable
            s(TP_resid) + #explanatory variable
            s(day, k = 5,  bs = "cc") +
            s(ddate), # trend
          data = df_tp_13384,
          knots = list(day = c(1,366)),
          method = "REML",
          select = TRUE)
summary(m3)
appraise(m3)
draw(m3)


## chl

df |> 
  mutate(ddate = decimal_date(end_date),
         day = yday(end_date)) |> 
  filter(parameter_code == "70953") |> 
  filter(station_id == "13384") |> 
  filter(end_date >= as.Date("2000-01-02")) |> 
  left_join(loads |> select(Date, TP_resid), by = c("end_date" = "Date")) -> df_ch_13384

ggplot(df_ch_13384) +
  geom_point(aes(end_date, log(value)))
ggplot(df_ch_13384) +
  geom_point(aes(day, log(value)))

m3 <- gam(log(value) ~ 
            s(flw_res) + # explanatory variable
            s(TP_resid) + #explanatory variable
            s(day, k = 5,  bs = "cc") +
            s(ddate), # trend
          data = df_ch_13384,
          knots = list(day = c(1,366)),
          method = "REML",
          select = TRUE)
summary(m3)
appraise(m3)
draw(m3)




df |> 
  mutate(ddate = decimal_date(end_date),
         day = yday(end_date)) |> 
  filter(parameter_code == "70953") |> 
  filter(station_id == "13563") |> 
  filter(end_date >= as.Date("2000-01-02")) |> 
  left_join(loads |> select(Date, TP_resid), by = c("end_date" = "Date")) -> df_ch_13563

ggplot(df_ch_13563) +
  geom_point(aes(end_date, log(value)))
ggplot(df_ch_13563) +
  geom_point(aes(day, log(value)))

m3 <- gam(log(value) ~ 
            s(flw_res) + # explanatory variable
            s(TP_resid) + #explanatory variable
            s(day, k = 5,  bs = "cc") +
            s(ddate), # trend
          data = df_ch_13563,
          knots = list(day = c(1,366)),
          method = "REML",
          select = TRUE)
summary(m3)
appraise(m3)
draw(m3)
