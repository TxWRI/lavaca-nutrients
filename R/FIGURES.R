prediction_bias <- function(model,
                            df,
                            site,
                            date,
                            constituent,
                            p2_x_labs = c("Predicted Flux", "Observed Flux"),
                            p2_y_title = "NO~3~-N Flux (kg/day)") {
  
  df <- df |> 
    filter(site_no == {{site}},
           Date >= as.Date(date))
  
  df <- gratia::add_fitted(df,
                           model = model,
                           value = ".fits",
                           type = "response") |> 
    mutate(.fits = as_units(.fits, "mg/L"),
           Flow = as_units(Flow, "ft^3/s"),
           Flow = set_units(Flow, "L/s"),
           .fits = .fits*Flow,
           .fits = set_units(.fits, "kg/day"),
           Flow = set_units(Flow, "ft^3/s"),
           Flow = drop_units(Flow),
           .fits = drop_units(.fits)) |> 
    mutate(x_lab = case_when(
      !is.na({{ constituent }}) ~ "In-sample",
      is.na( {{ constituent }}) ~ "Out-of-sample"))
  
  p1 <- ggplot(df) +
    geom_boxplot(aes(x = x_lab,
                     y = Flow)) +
    scale_y_log10() +
    labs(x = "", y = "Mean Daily Discharge [cfs]") +
    theme_TWRI_print()

  p2 <- df |>
    pivot_longer(cols = c(.fits, {{ constituent }})) |>
    ggplot(aes(name, value)) +
    geom_boxplot() +
    scale_y_log10() +
    scale_x_discrete(labels = p2_x_labs) +
    labs(x = "", y = p2_y_title) +
    theme_TWRI_print() +
    theme(axis.title.y = ggtext::element_markdown())
  
  p1 + p2 + plot_annotation(tag_levels = "a")
  
}


prediction_bias_dam <- function(model,
                                df,
                                site = "lktexana_g",
                                date,
                                constituent,
                                p2_x_labs = c("Predicted Concentration", "Observed Concentration"),
                                p2_y_title = "NO<sub>3</sub>-N Concentration (mg/mL)") {
  gaged_inflow <- df |> 
    filter(site_no != "lktexana_g") |> 
    filter(site_no != "usgs08164000") |> 
    select(c(Date, site_no, Flow)) |> 
    pivot_wider(names_from = site_no,
                values_from = Flow) |> 
    mutate(inflow = usgs08164390 + usgs08164450 + usgs08164503 + usgs08164504)
  
  below_tex <- df |> 
    filter(site_no == "lktexana_g") |> 
    # select(-c("NH3", "TKN", "censored_TKN")) |> 
    mutate(inflow = gaged_inflow$inflow) |> 
    mutate(
      log1p_inflow = log1p(inflow),
      # flow anomalies
      ltfa = fa(inflow+1, Date, T_1 = "1 year",
                T_2 = "period", transform = "log"),
      stfa = fa(inflow+1, Date, T_1 = "1 day",
                T_2 = "1 month", transform = "log"),
      # smooth discounted flow
      ma = sdf(log1p(inflow)))
  
  df <- below_tex |> 
    filter(site_no == site,
           Date >= as.Date(date))
  
  df <- gratia::add_fitted(df,
                           model = model,
                           value = ".fits",
                           type = "response") |> 
    mutate(x_lab = case_when(
      !is.na({{ constituent }}) ~ "In-sample",
      is.na( {{ constituent }}) ~ "Out-of-sample"))
  
  p1 <- ggplot(df) +
    geom_boxplot(aes(x = x_lab,
                     y = inflow)) +
    scale_y_log10(labels = scales::comma) +
    labs(x = "", y = "Mean Daily Inflow [cfs]") +
    theme_TWRI_print()
  p2 <- df |>
    pivot_longer(cols = c(.fits, {{ constituent }})) |>
    ggplot(aes(name, value)) +
    geom_boxplot() +
    scale_y_log10(labels = scales::comma) +
    scale_x_discrete(labels = p2_x_labs) +
    labs(x = "", y = p2_y_title) +
    theme_TWRI_print() +
    theme(axis.title.y = ggtext::element_markdown())
  
  p1 + p2 + plot_annotation(tag_levels = "a")
  
}

## Maps ------------


 
study_area_map <- function(){
  
  ## usgs sites
  df_sites <- download_usgs_sites() |> 
    filter(site_no == "08164000" | site_no == "08164525")
  
  df_sites <- st_as_sf(df_sites, coords = c("dec_long_va", "dec_lat_va"),
                       crs = 4326)  
  
  ## tceq sites
  tceq_sites <- download_tceq_sites()
  tceq_sites <- st_as_sf(tceq_sites, coords = c("LongitudeMeasure", "LatitudeMeasure"),
                         crs = 4326)
  
  tceq_sites$MonitoringLocationIdentifier <- stringr::str_replace_all(tceq_sites$MonitoringLocationIdentifier, "MAIN", "")
  
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
  
  ## read counties polygons
  counties <- read_sf("data/Spatial/lavaca.gpkg",
                      layer = "counties")
  
  ## combine watersheds into one sf
  ws <- bind_rows(lavaca_ws, navidad_ws, ds_ws)
  
  ## subset counties to just the ones near our porjec area
  counties_sub <- counties |> st_transform(crs = st_crs(lavaca_ws))
  
  counties_sub <- counties_sub[ws,]
  
  ws |> 
    mutate(label = c("Lavaca River\nWatershed", "Navidad River\nWatershed", "Garcitas Creek,\nPlacedo Creek\nand Cox Bay\nWatersheds")) -> ws
  
  ## read urbanized areas polygons
  urban <- read_sf("data/Spatial/lavaca.gpkg",
                   layer = "urban")
  
  
  ## download nhd data
  bounds <- st_as_sfc(st_bbox(counties_sub))
  bounds <- st_buffer(bounds, dist = 5000)
  
  nhd_stuff <- get_nhd(bounds,
                       "lavaca_plus",
                       force.redo = FALSE)
  
  ## subset flowlines to streams
  nhd_stuff$Flowline |>
    filter(ftype == 460) |>
    mutate(visibilityfilter = as.factor(visibilityfilter)) ->nhd_stuff$Flowline
  
  ## melt the waterbodies to remove subunit lines
  waterbody <- waterbody |> 
    summarise()
  
  nhd_stuff$Area <- nhd_stuff$Area |> 
    summarise()
  
  
  waterbody_labs <- tibble(lab = c("Lake\nTexana", "Lavaca Bay", "Matagorda Bay"),
                           x = c(-96.54, -96.6, -96.4),
                           y = c(28.95, 28.65, 28.55)) |> 
    st_as_sf(coords = c("x", "y"),
             crs = 4326)
  
  p1 <- ggplot() +
    ## watersheds
    geom_sf(data = ws, aes(fill = label, color = label), alpha = 0.3, size = 0.2, show.legend = FALSE) +
    ## colorado, wharton, dewit, calhoun county label
    geom_sf_text(data = counties_sub |> 
                   filter(CNTY_NM == "Colorado"|CNTY_NM == "Lavaca"| 
                            CNTY_NM == "Wharton"|CNTY_NM == "Calhoun"|
                            CNTY_NM == "De Witt"), 
                 aes(label = glue::glue("{CNTY_NM}\nCounty")), 
                 size = 2, family = "Atkinson Hyperlegible", 
                 alpha = 0.5, fontface = "bold") +
    ## Jackson county label
    geom_sf_text(data = counties_sub |> 
                   filter(CNTY_NM == "Jackson"), 
                 aes(label = glue::glue("{CNTY_NM}\nCounty")), 
                 size = 2, family = "Atkinson Hyperlegible", 
                 alpha = 0.5, fontface = "bold",
                 nudge_x = 10000) +
    ## victoria county label
    geom_sf_text(data = counties_sub |> 
                   filter(CNTY_NM == "Victoria"), 
                 aes(label = glue::glue("{CNTY_NM}\nCounty")), 
                 size = 2, family = "Atkinson Hyperlegible", 
                 alpha = 0.5, fontface = "bold",
                 nudge_x = -10000, nudge_y = -10000) +
    geom_sf(data = urban, fill = "azure4", size = 0.2, alpha = 0.5) +
    geom_sf(data = nhd_stuff$Area, color = alpha("steelblue",0.25), alpha = 0.25, fill = "steelblue", size = 0.15) +
    geom_sf(data = counties_sub, fill = "transparent", linetype = 3, size = 0.15, show.legend = FALSE) +
    geom_sf(data = nhd_stuff$Flowline, alpha = 0.25, size = 0.15, color = "steelblue") +
    geom_sf(data = rivers, color = "steelblue", size = 0.15) +
    geom_sf(data = waterbody, alpha = 1, fill = "slategray3",color = alpha("slategray3",1), size = 0.15) +
    geom_sf(data = df_sites, aes(shape = "Freshwater Sites")) +
    geom_sf(data = tceq_sites, aes(shape = "Lavaca Bay Sites")) +
    ## city labels
    geom_text_repel(data = urban |> filter(NAME10 != "Schulenburg", NAME10 != "Yoakum, TX", NAME10 != "Wharton", NAME10 != "Cuero",
                                           NAME10 != "El Campo"), 
                    aes(label = NAME10, geometry = Shape), size = 2, family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    hjust = 0,
                    nudge_x = -100,
                    box.padding = 0.5,
                    nudge_y = 8,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white",
                    bg.r = 0.15
    ) +
    ## el campo label
    geom_text_repel(data = urban |> filter(NAME10 == "El Campo"), 
                    aes(label = NAME10, geometry = Shape), size = 2, family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    # hjust = 0.5,
                    # vjust = 0,
                    # nudge_x = -10,
                    nudge_y = 10000,
                    direction = "x",
                    box.padding = 0.5,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white",
                    bg.r = 0.15
    ) +
    # ## schulenburg label
    # geom_text_repel(data = urban |> filter(NAME10 == "Schulenburg"), 
    #                 aes(label = NAME10, geometry = Shape), size = 3, family = "Atkinson Hyperlegible",
    #                 stat = "sf_coordinates",
    #                 hjust = 1,
    #                 # vjust = 0,
    #                 nudge_x = 10000,
    #                 nudge_y = 10000,
    #                 direction = "x",
    #                 box.padding = 0.5,
    #                 segment.curvature = -0.1,
    #                 segment.ncp = 3,
    #                 segment.angle = 20,
    #                 color = "grey30",
    #                 bg.color = "white",
    #                 bg.r = 0.15) +
    ##lavaca and navidad labs
    geom_text_repel(data = ws |> filter(label != "Garcitas Creek,\nPlacedo Creek\nand Cox Bay"), 
                    aes(label = label, geometry = Shape, color = label), 
                    size = 2.5, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    show.legend = FALSE) +
    ##garcitas labs
    geom_text_repel(data = ws |> filter(label == "Garcitas Creek,\nPlacedo Creek\nand Cox Bay"), 
                    aes(label = label, geometry = Shape, color = label), 
                    size = 1.5, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    min.segment.length = 10000,
                    vjust = 0,
                    nudge_x = -3000,
                    nudge_y = -25000,
                    show.legend = FALSE) +
    ## Matagorda Bay Label
    geom_text_repel(data = waterbody_labs |> filter(lab == "Matagorda Bay"), 
                    aes(label = lab, geometry = geometry), 
                    size = 2, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    hjust = 1,
                    min.segment.length = 10000,
                    color = "grey30",
                    bg.color = "white") +
    ## Lavaca Bay Label
    geom_text_repel(data = waterbody_labs |> filter(lab == "Lavaca Bay"), 
                    aes(label = lab, geometry = geometry), 
                    size = 2, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    angle = -45,
                    vjust = 0,
                    min.segment.length = 10000,
                    color = "grey30",
                    bg.color = "white") +
    ## Lk Texana Label
    geom_text_repel(data = waterbody_labs |> filter(lab == "Lake\nTexana"), 
                    aes(label = lab, geometry = geometry), 
                    size = 2, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    # angle = 70,
                    # vjust = 0.7,
                    # hjust = 0.7,
                    nudge_x = -500,
                    nudge_y = -500,
                    min.segment.length = 10000,
                    color = "grey30",
                    bg.color = "white", alpha = 0.85) +
    ## western site labels
    geom_text_repel(data = df_sites |> filter(site_no == "08164000" |
                                                site_no == "08164390"),
                    aes(label = glue::glue("USGS-{site_no}"),
                        geometry = geometry),
                    family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    size = 2.5,
                    direction = "y",
                    min.segment.length = 0,
                    nudge_x = -200000,
                    hjust = 1,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white") +
    ## eastern site labels
    geom_text_repel(data = df_sites |> filter(site_no == "08164450" |
                                                site_no == "08164504" |
                                                site_no == "08164503" |
                                                site_no == "08164525"),
                    aes(label = glue::glue("USGS-{site_no}"),
                        geometry = geometry),
                    family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    size = 2.5,
                    direction = "y",
                    min.segment.length = 0,
                    nudge_x = 200000,
                    hjust = 0,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white") +
    ## estuary sites
    geom_text_repel(data = tceq_sites,
                    aes(label = MonitoringLocationIdentifier,
                        geometry = geometry),
                    family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    size = 2.5,
                    direction = "y",
                    min.segment.length = 0,
                    nudge_x = 200000,
                    hjust = 0,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white") +
    ## scale bar
    annotation_scale(location = "bl", text_family = "Atkinson Hyperlegible") +
    coord_sf(xlim = c(1266631.4, 
                      #1363148.7
                      1374000), 
             ylim = c(715099.2, 855290.5 ),
             crs = st_crs(counties_sub)) +
    scale_fill_carto_d(type = "qualitative", palette = "Vivid", direction = -1) +
    scale_color_carto_d(type = "qualitative", palette = "Vivid", direction = -1) +
    scale_shape_manual("", values = c(21, 22)) +
    labs(x = "", y = "") +
    theme_TWRI_print() +
    theme(panel.grid = element_line(color = "grey80", size = 0.1),
          panel.background = element_rect(fill = "cornsilk2"),
          axis.text = element_text(size = 8))
  
  ## inset map
  project <- st_as_sfc(st_bbox(ws))
  
  p2 <- ggplot() +
    geom_sf(data = counties, fill = "white", size = 0.1) +
    geom_sf(data = project, fill = "transparent", color = "firebrick", size = 1) +
    theme_void()
  
  
  p1 + inset_element(p2, left = 0.7, bottom = 0.7, right = 1, top = 1,
                     align_to = "full")
}

fw_study_area_map <- function(){
  
  ## usgs sites
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
  
  ## read counties polygons
  counties <- read_sf("data/Spatial/lavaca.gpkg",
                      layer = "counties")
  
  ## combine watersheds into one sf
  ws <- bind_rows(lavaca_ws, navidad_ws, ds_ws)
  
  ## subset counties to just the ones near our porjec area
  counties_sub <- counties |> st_transform(crs = st_crs(lavaca_ws))
  
  counties_sub <- counties_sub[ws,]
  
  ws |> 
    mutate(label = c("Lavaca River\nWatershed", "Navidad River\nWatershed", "Garcitas Creek,\nPlacedo Creek\nand Cox Bay\nWatersheds")) -> ws
  
  ## read urbanized areas polygons
  urban <- read_sf("data/Spatial/lavaca.gpkg",
                   layer = "urban")
  
  
  ## download nhd data
  bounds <- st_as_sfc(st_bbox(counties_sub))
  bounds <- st_buffer(bounds, dist = 5000)
  
  nhd_stuff <- get_nhd(bounds,
                       "lavaca_plus",
                       force.redo = TRUE)
  
  ## subset flowlines to streams
  nhd_stuff$Flowline |>
    filter(ftype == 460) |>
    mutate(visibilityfilter = as.factor(visibilityfilter)) ->nhd_stuff$Flowline
  
  ## melt the waterbodies to remove subunit lines
  waterbody <- waterbody |> 
    summarise()
  
  nhd_stuff$Area <- nhd_stuff$Area |> 
    summarise()
  
  
  waterbody_labs <- tibble(lab = c("Lake\nTexana", "Lavaca Bay", "Matagorda Bay"),
                           x = c(-96.54, -96.6, -96.4),
                           y = c(28.95, 28.65, 28.55)) |> 
    st_as_sf(coords = c("x", "y"),
             crs = 4326)
  
  p1 <- ggplot() +
    ## watersheds
    geom_sf(data = ws, aes(fill = label, color = label), alpha = 0.45, size = 0.2, show.legend = FALSE) +
    ## colorado, wharton, dewit, calhoun county label
    geom_sf_text(data = counties_sub |> 
                   filter(CNTY_NM == "Colorado"|CNTY_NM == "Lavaca"| 
                            CNTY_NM == "Wharton"|CNTY_NM == "Calhoun"|
                            CNTY_NM == "De Witt"), 
                 aes(label = glue::glue("{CNTY_NM}\nCounty")), 
                 size = 2.5, family = "Atkinson Hyperlegible", 
                 alpha = 0.5, fontface = "bold") +
    ## Jackson county label
    geom_sf_text(data = counties_sub |> 
                   filter(CNTY_NM == "Jackson"), 
                 aes(label = glue::glue("{CNTY_NM}\nCounty")), 
                 size = 2.5, family = "Atkinson Hyperlegible", 
                 alpha = 0.5, fontface = "bold",
                 nudge_x = 10000) +
    ## victoria county label
    geom_sf_text(data = counties_sub |> 
                   filter(CNTY_NM == "Victoria"), 
                 aes(label = glue::glue("{CNTY_NM}\nCounty")), 
                 size = 2.5, family = "Atkinson Hyperlegible", 
                 alpha = 0.5, fontface = "bold",
                 nudge_x = -10000, nudge_y = -10000) +
    geom_sf(data = urban, fill = "azure4", size = 0.2, alpha = 0.5) +
    geom_sf(data = nhd_stuff$Area, color = alpha("steelblue",0.25), alpha = 0.25, fill = "steelblue", size = 0.15) +
    geom_sf(data = counties_sub, fill = "transparent", linetype = 3, size = 0.15, show.legend = FALSE) +
    geom_sf(data = nhd_stuff$Flowline, alpha = 0.25, size = 0.15, color = "steelblue") +
    geom_sf(data = rivers, color = "steelblue", size = 0.15) +
    geom_sf(data = waterbody, alpha = 1, fill = "slategray3",color = alpha("slategray3",1), size = 0.15) +
    geom_sf(data = df_sites, shape = 21) +
    ## city labels
    geom_text_repel(data = urban |> filter(NAME10 != "Schulenburg", NAME10 != "Yoakum, TX", NAME10 != "Wharton", NAME10 != "Cuero",
                                           NAME10 != "El Campo"), 
                    aes(label = NAME10, geometry = Shape), size = 3, family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    hjust = 0,
                    nudge_x = -100,
                    box.padding = 0.5,
                    nudge_y = 8,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white",
                    bg.r = 0.15
    ) +
    ## el campo label
    geom_text_repel(data = urban |> filter(NAME10 == "El Campo"), 
                    aes(label = NAME10, geometry = Shape), size = 3, family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    # hjust = 0.5,
                    # vjust = 0,
                    # nudge_x = -10,
                    nudge_y = 10000,
                    direction = "x",
                    box.padding = 0.5,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white",
                    bg.r = 0.15
    ) +
    ## schulenburg label
    geom_text_repel(data = urban |> filter(NAME10 == "Schulenburg"), 
                    aes(label = NAME10, geometry = Shape), size = 3, family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    hjust = 1,
                    # vjust = 0,
                    nudge_x = 10000,
                    nudge_y = 10000,
                    direction = "x",
                    box.padding = 0.5,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white",
                    bg.r = 0.15) +
    ##lavaca and navidad labs
    geom_text_repel(data = ws |> filter(label != "Garcitas Creek,\nPlacedo Creek\nand Cox Bay"), 
                    aes(label = label, geometry = Shape, color = label), 
                    size = 3, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    show.legend = FALSE) +
    ##garcitas labs
    geom_text_repel(data = ws |> filter(label == "Garcitas Creek,\nPlacedo Creek\nand Cox Bay"), 
                    aes(label = label, geometry = Shape, color = label), 
                    size = 2.5, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    min.segment.length = 10000,
                    vjust = 0,
                    nudge_x = -3000,
                    nudge_y = -25000,
                    show.legend = FALSE) +
    ## Matagorda Bay Label
    geom_text_repel(data = waterbody_labs |> filter(lab == "Matagorda Bay"), 
                    aes(label = lab, geometry = geometry), 
                    size = 3, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    hjust = 1,
                    min.segment.length = 10000,
                    color = "grey30",
                    bg.color = "white") +
    ## Lavaca Bay Label
    geom_text_repel(data = waterbody_labs |> filter(lab == "Lavaca Bay"), 
                    aes(label = lab, geometry = geometry), 
                    size = 3, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    angle = -45,
                    vjust = 0,
                    min.segment.length = 10000,
                    color = "grey30",
                    bg.color = "white") +
    ## Lk Texana Label
    geom_text_repel(data = waterbody_labs |> filter(lab == "Lake\nTexana"), 
                    aes(label = lab, geometry = geometry), 
                    size = 2.5, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    # angle = 70,
                    # vjust = 0.7,
                    # hjust = 0.7,
                    nudge_x = -500,
                    nudge_y = -500,
                    min.segment.length = 10000,
                    color = "grey30",
                    bg.color = "white", alpha = 0.85) +
    ## western site labels
    geom_text_repel(data = df_sites |> filter(site_no == "08164000" |
                                                site_no == "08164390"),
                    aes(label = glue::glue("USGS-{site_no}"),
                        geometry = geometry),
                    family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    size = 3.25,
                    direction = "y",
                    min.segment.length = 0,
                    nudge_x = -200000,
                    hjust = 1,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white") +
    ## eastern site labels
    geom_text_repel(data = df_sites |> filter(site_no == "08164450" |
                                                site_no == "08164504" |
                                                site_no == "08164503" |
                                                site_no == "08164525"),
                    aes(label = glue::glue("USGS-{site_no}"),
                        geometry = geometry),
                    family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    size = 3.25,
                    direction = "y",
                    min.segment.length = 0,
                    nudge_x = 200000,
                    hjust = 0,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white") +
    ## scale bar
    annotation_scale(location = "bl", text_family = "Atkinson Hyperlegible") +
    coord_sf(xlim = c(1266631.4, 
                      #1363148.7
                      1374000), 
             ylim = c(715099.2, 855290.5 ),
             crs = st_crs(counties_sub)) +
    scale_fill_carto_d(type = "qualitative", palette = "Vivid", direction = -1) +
    scale_color_carto_d(type = "qualitative", palette = "Vivid", direction = -1) +
    labs(x = "", y = "") +
    theme_TWRI_print() +
    theme(panel.grid = element_line(color = "grey80", size = 0.1),
          panel.background = element_rect(fill = "cornsilk2"))
  
  ## inset map
  project <- st_as_sfc(st_bbox(ws))
  
  p2 <- ggplot() +
    geom_sf(data = counties, fill = "white", size = 0.1) +
    geom_sf(data = project, fill = "transparent", color = "firebrick", size = 2) +
    theme_void()
  
  
  p1 + inset_element(p2, left = 0.7, bottom = 0.7, right = 1, top = 1,
                     align_to = "full")
}

est_study_area_map <- function(){
  
  ## usgs sites
  df_sites <- download_usgs_sites()
  
  df_sites <- st_as_sf(df_sites, coords = c("dec_long_va", "dec_lat_va"),
                       crs = 4326)  
  
  df_sites <- df_sites |> 
    filter(site_no == "08164000" | site_no == "08164525")
  
  ## tceq sites
  tceq_sites <- download_tceq_sites()
  tceq_sites <- st_as_sf(tceq_sites, coords = c("LongitudeMeasure", "LatitudeMeasure"),
                         crs = 4326)
  
  tceq_sites$MonitoringLocationIdentifier <- stringr::str_replace_all(tceq_sites$MonitoringLocationIdentifier, "MAIN", "")
  
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
  
  ## read counties polygons
  counties <- read_sf("data/Spatial/lavaca.gpkg",
                      layer = "counties")
  
  ## combine watersheds into one sf
  ws <- bind_rows(lavaca_ws, navidad_ws, ds_ws)
  
  ## subset counties to just the ones near our porjec area
  counties_sub <- counties |> st_transform(crs = st_crs(lavaca_ws))
  
  counties_sub <- counties_sub[ws,]
  
  ws |> 
    mutate(label = c("Lavaca River\nWatershed", "Navidad River\nWatershed", "Garcitas Creek,\nPlacedo Creek\nand Cox Bay\nWatersheds")) -> ws
  
  ## read urbanized areas polygons
  urban <- read_sf("data/Spatial/lavaca.gpkg",
                   layer = "urban")
  
  
  ## download nhd data
  bounds <- st_as_sfc(st_bbox(counties_sub))
  bounds <- st_buffer(bounds, dist = 5000)
  
  nhd_stuff <- get_nhd(bounds,
                       "lavaca_plus",
                       force.redo = TRUE)
  
  ## subset flowlines to streams
  nhd_stuff$Flowline |>
    filter(ftype == 460) |>
    mutate(visibilityfilter = as.factor(visibilityfilter)) ->nhd_stuff$Flowline
  
  ## melt the waterbodies to remove subunit lines
  waterbody <- waterbody |> 
    summarise()
  
  nhd_stuff$Area <- nhd_stuff$Area |> 
    summarise()
  
  
  waterbody_labs <- tibble(lab = c("Lake\nTexana", "Lavaca Bay", "Matagorda Bay"),
                           x = c(-96.54, -96.6, -96.4),
                           y = c(28.95, 28.65, 28.55)) |> 
    st_as_sf(coords = c("x", "y"),
             crs = 4326)
  
  p1 <- ggplot() +
    ## watersheds
    geom_sf(data = ws, aes(fill = label, color = label), alpha = 0.45, size = 0.2, show.legend = FALSE) +
    ## colorado, wharton, dewit, calhoun county label
    geom_sf_text(data = counties_sub |> 
                   filter(CNTY_NM == "Colorado"|CNTY_NM == "Lavaca"| 
                            CNTY_NM == "Wharton"|CNTY_NM == "Calhoun"|
                            CNTY_NM == "De Witt"), 
                 aes(label = glue::glue("{CNTY_NM}\nCounty")), 
                 size = 2.5, family = "Atkinson Hyperlegible", 
                 alpha = 0.5, fontface = "bold") +
    ## Jackson county label
    geom_sf_text(data = counties_sub |> 
                   filter(CNTY_NM == "Jackson"), 
                 aes(label = glue::glue("{CNTY_NM}\nCounty")), 
                 size = 2.5, family = "Atkinson Hyperlegible", 
                 alpha = 0.5, fontface = "bold",
                 nudge_x = 10000) +
    ## victoria county label
    geom_sf_text(data = counties_sub |> 
                   filter(CNTY_NM == "Victoria"), 
                 aes(label = glue::glue("{CNTY_NM}\nCounty")), 
                 size = 2.5, family = "Atkinson Hyperlegible", 
                 alpha = 0.5, fontface = "bold",
                 nudge_x = -10000, nudge_y = -10000) +
    geom_sf(data = urban, fill = "azure4", size = 0.2, alpha = 0.5) +
    geom_sf(data = nhd_stuff$Area, color = alpha("steelblue",0.25), alpha = 0.25, fill = "steelblue", size = 0.15) +
    geom_sf(data = counties_sub, fill = "transparent", linetype = 3, size = 0.15, show.legend = FALSE) +
    geom_sf(data = nhd_stuff$Flowline, alpha = 0.25, size = 0.15, color = "steelblue") +
    geom_sf(data = rivers, color = "steelblue", size = 0.15) +
    geom_sf(data = waterbody, alpha = 1, fill = "slategray3",color = alpha("slategray3",1), size = 0.15) +
    geom_sf(data = df_sites, aes(shape = "Freshwater Sites")) +
    geom_sf(data = tceq_sites, aes(shape = "Lavaca Bay Sites")) +
    ## city labels
    geom_text_repel(data = urban |> filter(NAME10 != "Schulenburg", NAME10 != "Yoakum, TX", NAME10 != "Wharton", NAME10 != "Cuero",
                                           NAME10 != "El Campo"), 
                    aes(label = NAME10, geometry = Shape), size = 3, family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    hjust = 0,
                    nudge_x = -100,
                    box.padding = 0.5,
                    nudge_y = 8,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white",
                    bg.r = 0.15
    ) +
    ## el campo label
    geom_text_repel(data = urban |> filter(NAME10 == "El Campo"), 
                    aes(label = NAME10, geometry = Shape), size = 3, family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    # hjust = 0.5,
                    # vjust = 0,
                    # nudge_x = -10,
                    nudge_y = 10000,
                    direction = "x",
                    box.padding = 0.5,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white",
                    bg.r = 0.15
    ) +
    ## schulenburg label
    geom_text_repel(data = urban |> filter(NAME10 == "Schulenburg"), 
                    aes(label = NAME10, geometry = Shape), size = 3, family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    hjust = 1,
                    # vjust = 0,
                    nudge_x = 10000,
                    nudge_y = 10000,
                    direction = "x",
                    box.padding = 0.5,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white",
                    bg.r = 0.15) +
    ##lavaca and navidad labs
    geom_text_repel(data = ws |> filter(label != "Garcitas Creek,\nPlacedo Creek\nand Cox Bay"), 
                    aes(label = label, geometry = Shape, color = label), 
                    size = 3, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    show.legend = FALSE) +
    ##garcitas labs
    geom_text_repel(data = ws |> filter(label == "Garcitas Creek,\nPlacedo Creek\nand Cox Bay"), 
                    aes(label = label, geometry = Shape, color = label), 
                    size = 2.5, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    min.segment.length = 10000,
                    vjust = 0,
                    nudge_x = -3000,
                    nudge_y = -25000,
                    show.legend = FALSE) +
    ## Matagorda Bay Label
    geom_text_repel(data = waterbody_labs |> filter(lab == "Matagorda Bay"), 
                    aes(label = lab, geometry = geometry), 
                    size = 3, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    hjust = 1,
                    min.segment.length = 10000,
                    color = "grey30",
                    bg.color = "white") +
    ## Lavaca Bay Label
    geom_text_repel(data = waterbody_labs |> filter(lab == "Lavaca Bay"), 
                    aes(label = lab, geometry = geometry), 
                    size = 3, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    angle = -45,
                    vjust = 0,
                    min.segment.length = 10000,
                    color = "grey30",
                    bg.color = "white") +
    ## Lk Texana Label
    geom_text_repel(data = waterbody_labs |> filter(lab == "Lake\nTexana"), 
                    aes(label = lab, geometry = geometry), 
                    size = 2.5, 
                    family = "Atkinson Hyperlegible",
                    fontface = "bold",
                    stat = "sf_coordinates",
                    # angle = 70,
                    # vjust = 0.7,
                    # hjust = 0.7,
                    nudge_x = -500,
                    nudge_y = -500,
                    min.segment.length = 10000,
                    color = "grey30",
                    bg.color = "white", alpha = 0.85) +
    ## western site labels
    geom_text_repel(data = df_sites |> filter(site_no == "08164000" |
                                                site_no == "08164390"),
                    aes(label = glue::glue("USGS-{site_no}"),
                        geometry = geometry),
                    family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    size = 3.25,
                    direction = "y",
                    min.segment.length = 0,
                    nudge_x = -200000,
                    hjust = 1,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white") +
    ## eastern site labels
    geom_text_repel(data = df_sites |> filter(site_no == "08164450" |
                                                site_no == "08164504" |
                                                site_no == "08164503" |
                                                site_no == "08164525"),
                    aes(label = glue::glue("USGS-{site_no}"),
                        geometry = geometry),
                    family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    size = 3.25,
                    direction = "y",
                    min.segment.length = 0,
                    nudge_x = 200000,
                    hjust = 0,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white") +
    ## estuary sites
    geom_text_repel(data = tceq_sites,
                    aes(label = MonitoringLocationIdentifier,
                        geometry = geometry),
                    family = "Atkinson Hyperlegible",
                    stat = "sf_coordinates",
                    size = 3.25,
                    direction = "y",
                    min.segment.length = 0,
                    nudge_x = 200000,
                    hjust = 0,
                    segment.curvature = -0.1,
                    segment.ncp = 3,
                    segment.angle = 20,
                    color = "grey30",
                    bg.color = "white") +
    ## scale bar
    annotation_scale(location = "bl", text_family = "Atkinson Hyperlegible") +
    coord_sf(xlim = c(1266631.4, 
                      #1363148.7
                      1374000), 
             ylim = c(715099.2, 855290.5 ),
             crs = st_crs(counties_sub)) +
    scale_fill_carto_d(type = "qualitative", palette = "Vivid", direction = -1) +
    scale_color_carto_d(type = "qualitative", palette = "Vivid", direction = -1) +
    scale_shape_manual("", values = c(21, 22)) +
    labs(x = "", y = "") +
    theme_TWRI_print() +
    theme(panel.grid = element_line(color = "grey80", size = 0.1),
          panel.background = element_rect(fill = "cornsilk2"))
  
  ## inset map
  project <- st_as_sfc(st_bbox(ws))
  
  p2 <- ggplot() +
    geom_sf(data = counties, fill = "white", size = 0.1) +
    geom_sf(data = project, fill = "transparent", color = "firebrick", size = 2) +
    theme_void()
  
  
  p1 + inset_element(p2, left = 0.7, bottom = 0.7, right = 1, top = 1,
                     align_to = "full")
}

download_usgs_sites <- function() {
  site_numbers <- c("08164000", #lavaca
                    "08164390", #navidad
                    "08164450", #sandy
                    "08164503", #w mustang
                    "08164504", #e mustang
                    "08164525")
  sites <- readNWISsite(site_numbers)
  sites
}

download_tceq_sites <-function() {
  site_numbers <- c("TCEQMAIN-13563",
                    "TCEQMAIN-13383",
                    "TCEQMAIN-13384")
  sites <- whatWQPsites(siteid = site_numbers)
  sites
}
