# GT tables ----

# Returns GT table with GAM summary,
# just kidding! it returns a kableExtra object because
# gt captions with markdown or latex formatting don't render
# properly in quarto yet.

gam_gt <- function(model, caption, label) {
  
  options(knitr.kable.NA = '')
  ## return parametric terms as tibble
  models <- list("Estimate" = model,
                 "Std.Error" = model,
                 "t-value" = model,
                 "p-value" = model)
  
  a <- modelsummary(models, estimate =c("Estimate" = "estimate",
                                        "Std.Error" = "std.error",
                                        "t-value" = "statistic",
                                        "p-value" = "{p.value} {stars}"),
                    output = "data.frame",
                    coef_omit = "s\\(.",
                    gof_omit = "AIC|BIC|R2|RMSE",
                    shape = component + term ~ model,
                    statistic = NULL,
                    group_map = c("conditional" = "A. parametric coefficients",
                                  "smooth_terms" = "B. smooth terms")) |> 
    filter(part != "gof") |> 
    select(!c(part, statistic)) |> 
    dplyr::rename(c("Component" = "group",
                    "Term" = "term")) 
  
  ref.df <- data.frame(summary(model)$s.table)$Ref.df
  
  ## return smooth terms as tibble
  models <- list("edf" = model,
                 #"ref.df" = model,
                 "F-value" = model,
                 "p-value" = model)
  
  b <- modelsummary(models, estimate =c("edf" = "df",
                                        #"Ref.df" = "ref.df",
                                        "F-value" = "statistic",
                                        "p-value" = "{p.value} {stars}"),
                    output = "data.frame",
                    coef_omit = "\\(Intercept\\)",
                    gof_omit = "AIC|BIC|R2|RMSE",
                    shape = component + term ~ model,
                    statistic = NULL,
                    group_map = c("conditional" = "A. parametric coefficients",
                                  "smooth_terms" = "B. smooth terms")) |>
    filter(part != "gof") |>
    select(!c(part, statistic)) |>
    dplyr::rename(c("Component" = "group",
                    "Term" = "term")) |> 
    mutate(ref.df = ref.df) |> 
    mutate(Term = case_when(
      Term == "s(log1p_Flow)" ~ "s(log1p(Flow))",
      Term == "s(log1p_inflow)" ~ "s(log1p(Inflow))",
      Term != "s(log1p_Flow)" ~ Term
    ))
  
  ## get gof metrics
  data_g <- glance_gam(model)
  
  
  out_tab <- bind_rows(a,b) |>
    select(Component, Term, Estimate, Std.Error, `t-value`, edf, ref.df, `F-value`, `p-value`) |>
    group_by(Component)
  
  names(out_tab)[9] <- paste0(names(out_tab)[9],
                              footnote_marker_number(1,"latex"))
  
  kbl(out_tab, format = "latex", booktabs = TRUE, escape = FALSE,
      table.envir = "widestuff", ## wraps the adjust width environment provided at the top of the quarto file
      caption = caption, ## have to set caption here, not in  quarto to keep formatting
      label = label ## label too, or else quarto strips formatting and rewraps table env and screws everything up
  ) |>
    collapse_rows(columns = 1,
                  latex_hline = "major",
                  valign = "top") |>
    add_footnote("Signif. codes: 0 <= '***' < 0.001 < '**' < 0.01 < '*' < 0.05 < '+' < 0.1",
                 notation = "number") |>
    add_footnote(sprintf("Adjusted R-squared: %s, Deviance explained %s",
                         format(data_g$adj.r.squared, digits = 3, format = "f", nsmall = 3),
                         format(data_g$deviance, digits = 3, format = "f", nsmall = 3)),
                 notation = "none") |>
    add_footnote(sprintf("%s : %s, Scale est: %s, N: %d",
                         data_g$method,
                         format(data_g$sp.crit, format = "f", digits = 3, nsmall = 3),
                         format(data_g$scale.est, digits = 3, nsmall = 3),
                         data_g$nobs),
                 notation = "none")
}





### misc functions to create gt compatible summary tables used in reports


glance_gam <- function(model) {
  df <- sum(model$edf)
  if(length(df) < 1) df <- NA_real_
  df.res <- df.residual(model)
  if(length(df.res) < 1) df.res <- NA_real_
  logLik <- as.numeric(logLik(model))
  if(length(logLik) < 1) logLik <- NA_real_
  aic <- AIC(model)
  if(length(aic) < 1) aic <- NA_real_
  bic <- BIC(model)
  if(length(bic) < 1) bic <- NA_real_
  dev <- summary(model)$dev.expl
  if(length(dev) < 1) dev <- NA_real_
  adj.r.squared <- summary(model)$r.sq
  if(length(adj.r.squared) < 1) adj.r.squared <- NA_real_
  scale.est <- summary(model)$scale
  if(length(scale.est) < 1) scale.est <- NA_real_
  sp.criterion <- as.numeric(summary(model)$sp.criterion)
  if(length(sp.criterion) < 1) sp.criterion <- NA_real_
  
  data.frame(
    df = df,
    df.residual = df.res,
    logLik = logLik,
    AIC = aic,
    BIC = bic,
    adj.r.squared = adj.r.squared,
    deviance = dev,
    nobs = length(model$y),
    method = as.character(summary(model)$method),
    sp.crit = sp.criterion,
    scale.est = scale.est,
    stringsAsFactors = FALSE
  )
}
