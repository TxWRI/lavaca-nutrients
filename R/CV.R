cross_validate <- function(model,
                           data,
                           constituent) {
  
  formula <- model$formula
  #family <- model$family
  
  # create splits via leave one out cv
  data <- vfold_cv(data, v = 10, repeats = 10, strata = ddate, pool = 0.50)
  
  data |>
    # mutate from tidymodels splits to dataframes
    # tidymodels doesn't handle gams very well natively
    mutate(train = map(splits, 
                       ~as.data.frame(.x)),
           assessment = map(splits, ~as.data.frame(.x, data = "assessment")
                            ))  |>
    ## fit the GAM model using specified formula and family
    mutate(model = map(train, ~model_gam(formula = formula,
                                         data = .x,
                                         family = Gamma(link = "log")
                                         )
                       )) |>
    ## predict against assessment data
    mutate(preds = map2(assessment, model,
                        ~predict(.y, newdata = .x,
                                 type = "response"))) |>
    dplyr::group_by(id) |>
    tidyr::unnest(c(assessment,preds)) |>
    dplyr::select(id, {{ constituent }}, preds) |>
    tidyr::nest(data = c( {{ constituent }}, preds)) |>
    dplyr::mutate(
      kge = map(data,
                ~KGE(sim = (as.numeric(pull(.x, preds))),
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
    unnest(c(kge, r2, pbias))
  }