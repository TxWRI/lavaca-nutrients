library(sf)
library(tidyverse)
library(dataRetrieval)


## create geopacakge outputs to put in arcgis dashboard


generate_geopackage <- function() {

  ## usgs sites spatial locations
  df_sites <- download_usgs_sites()
  
  df_sites <- st_as_sf(df_sites, coords = c("dec_long_va", "dec_lat_va"),
                       crs = 4326)  
  
  ## read rivers spatial data
  rivers <- read_sf("data/Spatial/lavaca.gpkg",
                    layer = "rivers")
  
  ## read lake texana polygon
  waterbody <- read_sf("data/Spatial/lavaca.gpkg",
                       layer = "waterbody")
  
  ## read watershed polygons
  lavaca_ws <- read_sf("data/Spatial/lavaca.gpkg",
                       layer = "lavaca_ws")
  
  navidad_ws <- read_sf("data/Spatial/lavaca.gpkg",
                        layer = "navidad_ws")
  ds_ws <- read_sf("data/Spatial/lavaca.gpkg",
                   layer = "ds_ws")
  
  ## read daily loading data
  no3_daily_loads <- read_csv("data/Output/daily_loads/no3_daily_loads.csv")
  tp_daily_loads <- read_csv("data/Output/daily_loads/tp_daily_loads.csv")
  
  ## join to spatial locations
  loading <- df_sites |> 
    mutate(site_no = paste0(stringr::str_to_lower(agency_cd), site_no)) |>
    left_join(tp_daily_loads |> select(Date, site_no, Flow, TP_Estimate, TP_Upper, TP_Lower), 
              by = c("site_no" = "site_no")) |>
    left_join(no3_daily_loads |> select(Date, site_no, NO3_Estimate, NO3_Upper, NO3_Lower), 
              by = c("Date" = "Date", "site_no" = "site_no")) |> 
    select(site_no, station_nm, Date, Flow, NO3_Estimate, NO3_Upper, NO3_Lower, TP_Estimate, TP_Upper, TP_Lower)
  
  ## write data
  dsn <- "data/Output/spatial/loading.gpkg"
  st_write(df_sites, dsn = dsn, layer = "sites")
  st_write(loading, dsn = dsn, layer = "sites")
  st_write(lavaca_ws, dsn = dsn, layer = "lavaca_watershed")
  st_write(navidad_ws, dsn = dsn, layer = "navidad_watershed")
  st_write(ds_ws, dsn = dsn, layer = "downstream_watersheds")
  st_write(rivers, dsn = dsn, layer = "rivers")
  return(NULL)
}