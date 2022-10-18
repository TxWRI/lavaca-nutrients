cross_validate <- function(model,
                           data,
                           constituent,
                           strata = Flow) {
  
  formula <- model$formula
  family <- model$family
  
  # create splits via leave one out cv
  set.seed(seed = 1972) 
  data <- vfold_cv(data, v = 5, repeats = 10, strata = {{ strata }}, pool = 0.50)
  
  out <- data |>
    # mutate from tidymodels splits to dataframes
    # tidymodels doesn't handle gams very well natively
    mutate(train = map(splits, 
                       ~as.data.frame(.x)),
           assessment = map(splits, ~as.data.frame(.x, data = "assessment")
                            ))  |>
    ## fit the GAM model using specified formula and family
    mutate(model = map(train, ~model_gam(formula = formula,
                                         data = .x,
                                         family = family
                                         )
                       )) |>
    ## predict against assessment data
    mutate(preds = map2(assessment, model,
                        ~predict(.y, newdata = .x,
                                 type = "response"))) |>
    dplyr::group_by(id) |>
    tidyr::unnest(c(assessment,preds)) 
  
  
  # convert c to flux
  out <- out |>
      mutate(preds = as_units(preds, "mg/L"),
             Flow = as_units(Flow, "ft^3/s"),
             Flow = set_units(Flow, "L/s"),
             preds = preds*Flow,
             preds = set_units(preds, "kg/day"),
             Flow = set_units(Flow, "ft^3/s"),
             Flow = drop_units(Flow),
             preds = drop_units(preds))

    out <- out |>
      dplyr::select(id, {{ constituent }}, preds) |>
      tidyr::nest(data = c( {{ constituent }}, preds)) |>
      dplyr::mutate(
        NSE = map(data,
                ~NSE(sim = (as.numeric(pull(.x, preds))),
                     obs = as.numeric(pull(.x, {{constituent}}))
                     )),
        r2 = map(data,
               ~{
                 r <- rPearson(sim = (as.numeric(pull(.x, preds))),
                               obs = as.numeric(pull(.x, {{constituent}}))
                               )
                 r^2
                 }),
        pbias = map(data,
                  ~pbias(sim = (as.numeric(pull(.x, preds))),
                         obs = as.numeric(pull(.x, {{constituent}}))
                         ))
      ) |>
      unnest(c(NSE, r2, pbias))
    out
  }