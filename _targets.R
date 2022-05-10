library(targets)
source("R/functions.R")
options(tidyverse.quiet = TRUE)
targets::tar_option_set(packages = c("arrow", "dataRetrieval", "dplyr", 
                                     "EcoHydRology", "fs", "ggplot2", "janitor",
                                     "lubridate", "purrr", "readr", "tidyr", 
                                     "units"))

list(
  tar_target(
    wqpdata, download_WQP_data()
  ),
  tar_target(
    qdata, download_Q_data()
  ),
  tar_target(
    model_data, clean_data(wqpdata, qdata)
  )
)
