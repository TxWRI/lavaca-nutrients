library(targets)
library(tidyverse)
library(janitor)
library(units)
library(mgcv)
library(gratia)
library(cenGAM)
library(mgcViz)

tar_make()
#

df <- tar_read(model_data)


df |>  select(-c(NH3, NO3, TKN, censored_NH3, censored_NO3, censored_TKN)) |>  filter(!is.na(TP)) -> df_phos
df |>  select(-c(NH3, TP, TKN, censored_NH3, censored_TP, censored_TKN)) |>  filter(!is.na(NO3)) -> df_nitrate


## how many censored values per site

df_phos |>
  mutate(censored = case_when(
    is.na(censored_TP) ~ 0,
    !is.na(censored_TP) ~ 1
  )) |>
  group_by(site_no) |>
  summarise(prop_cens = sum(censored)/n())

df_nitrate |>
  mutate(censored = case_when(
    is.na(censored_NO3) ~ 0,
    !is.na(censored_NO3) ~ 1
  )) |>
  group_by(site_no) |>
  summarise(prop_cens = sum(censored)/n())

## notes
## fitting to daily flux seems to be biased low compared to national sparrow models

df_nitrate |>
  mutate(Flow = as_units(Flow, "ft^3/s"),
         Flow = set_units(Flow, "L/s"),
         NO3 = as_units(NO3, "mg/L"),
         NO3_flux = NO3 * Flow,
         NO3_flux = set_units(NO3_flux, "kg/day"),
         NO3_flux = drop_units(NO3_flux),
         Flow = set_units(Flow, "ft^3/s"),
         Flow = drop_units(Flow),
         NO3 = drop_units(NO3)) -> df_nitrate

df_nitrate |>
  filter(site_no == "08164000") -> df_nitrate_08164000



library("brms")
library("bayesplot")
df_nitrate_08164000 |> 
  mutate(censored_NO3 = as.numeric(
    case_when(
      censored_NO3 == "<" ~ -1,
      is.na(censored_NO3) ~ 0
    )
  )) -> df_nitrate_08164000


get_prior(NO3 | cens(censored_NO3) ~ 
            s(lrunoff, bs = "tp", k = 5) +
            s(bfp, bs = "tp", k = 5) +
            t2(yday, year, bs = c("cc","tp")),
          data = df_nitrate_08164000,
          family = Gamma(link = "log"))

nonlinear.prior <- prior(normal(0, 10), class=b) +
  prior(exponential(0.5), class=sds) +
  prior(normal(0, 1), class=Intercept) +
  prior(gamma(1, 1), class=shape)

m1 <- brm(NO3 | cens(censored_NO3) ~
            s(year,bs = "tp") +
            s(lrunoff, bs = "tp", m = 1) +
            s(bfp, bs = "tp", m = 1) +
            s(yday, bs = "cc", m = 1),
          data = df_nitrate_08164000, 
          family = Gamma(link = "log"),
          prior = nonlinear.prior,
          warmup = 1000, iter = 3000, chains = 4, cores = 1, thin = 1,
          control = list(adapt_delta = 0.99, max_treedepth = 50))

## model never covers censored values, why??? set prior on Gamma parameters and intercept???

m2 <- brm(NO3 | cens(censored_NO3) ~ 
            s(lrunoff, bs = "tp", m = 1) +
            s(bfp, bs = "tp", m = 1) +
            t2(yday, year, bs = c("cc","tp")),
          data = df_nitrate_08164000, 
          family = Gamma(link = "log"),
          prior = nonlinear.prior,
          warmup = 1000, iter = 3000, chains = 4, cores = 1, thin = 1,
          control = list(adapt_delta = 0.99, max_treedepth = 50))


get_prior(NO3 | cens(censored_NO3) ~ 
            t2(lrunoff, bfp, bs = "tp", m = 1) +
            t2(yday, year, bs = c("cc","tp"), m = 1),
          data = df_nitrate_08164000, 
          family = Gamma(link = "log"))

nonlinear.prior <-
  prior(exponential(0.5), class=sds) +
  prior(normal(0, 1), class=Intercept) +
  prior(gamma(1, 1), class=shape)

m3 <- brm(NO3 | cens(censored_NO3) ~ 
            t2(lrunoff, bfp, bs = "tp", m = 1) +
            t2(yday, year, bs = c("cc","tp"), m = 1),
          data = df_nitrate_08164000, 
          family = Gamma(link = "log"),
          prior = nonlinear.prior,
          warmup = 1000, iter = 3000, chains = 4, cores = 1, thin = 1,
          control = list(adapt_delta = 0.99, max_treedepth = 50))


summary(m1, waic = FALSE)

summary(m2, waic = FALSE)

summary(m3, waic = FALSE)



ms1 <- conditional_smooths(m1)
ms2 <- conditional_smooths(m2)
ms3 <- conditional_smooths(m3)


plot(ms1)
plot(ms2)
plot(ms3)


WAIC(m1, m2, m3)
LOO(m1, m2, m3)

p1 <- posterior_predict(m1)
p2 <- posterior_predict(m2)
p3 <- posterior_predict(m3)
p4 <- posterior_predict(m4)
p5 <- posterior_predict(m5)

pp_check(m1)
pp_check(m2)
pp_check(m3)

### I think we can include site specific smooths and include site as predictor. Would need to use area normalized runoff.

df |>  select(-c(NH3, TP, TKN, censored_NH3, censored_TP, censored_TKN)) -> newd

newd |> filter(site_no == "08164000") -> newd


pred1 <- posterior_predict(m1, newdata = newd)

newd2_temp <- transform(newd,
                   mean = colMeans(pred1),
                   median = apply(pred1, 2L, quantile, probs = 0.5),
                   lower    = apply(pred1, 2L, quantile, probs = 0.025),
                   upper    = apply(pred1, 2L, quantile, probs = 0.975))

newd2_temp |> 
  mutate(censored_NO3 = case_when(
    censored_NO3 == "<" ~ "Censored",
    is.na(censored_NO3) ~ "Not Censored"
  )) -> newd2_temp

ggplot(newd2_temp) +
  geom_line(aes(Date, mean)) +
  geom_ribbon(aes(Date, ymin = lower, ymax = upper), alpha = 0.2) +
  geom_point(aes(Date, NO3, color = censored_NO3)) +
  facet_wrap(~site_no) + scale_y_log10()

ggplot(newd2_temp) +
  geom_point(aes(mean, NO3, color = censored_NO3)) +
  geom_abline(slope = 1) +
  scale_y_log10() + scale_x_log10() +
  labs(x = "Fitted Values", y = "Observed Values")


ggplot(newd2_temp) +
  geom_point(aes(log(Flow),log(NO3), color = censored_NO3))

ggplot(newd2_temp) +
  geom_point(aes(bfp, log(NO3), color = censored_NO3))

ggplot(newd2_temp |> filter(!is.na(NO3))) +
  geom_point(aes(bfp, log(Flow), color = log(NO3)))

ggplot(newd2_temp |> filter(!is.na(NO3))) +
  geom_point(aes(bfp, log(Flow), color = censored_NO3))
