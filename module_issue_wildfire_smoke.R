# Copyright 2025 Province of British Columbia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

## Module: issue Air Quality Warning - Wildfire Smoke

library(shiny)
library(shinydashboard)
library(leaflet)
library(dplyr)


fireIcons <- awesomeIconList(
  #Out = makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "lightgray"),
  `Fire of Note` =  makeAwesomeIcon(icon = "fire", library = "fa", markerColor = "darkred", iconColor = "#FFF"),
  `Being Held` =  makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "orange", iconColor = "#DB9B3B"),
  `Out of Control`=  makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "red", iconColor = "#B54D2F"),
  `Under Control` =  makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "green", iconColor = "#86AA32")
)
fireIconFactorPalette <-  colorFactor(as.vector(sapply(fireIcons, get, x = "markerColor")), levels = names(fireIcons), ordered = TRUE)

format_datestring <- function(date) {
  sprintf("%s %i, %d", format(as.Date(date), "%B"), lubridate::day(date), lubridate::year(date))
}

#--------------------------------------------------
# UI
#--------------------------------------------------

issueWildfireSmokeUI <- function(id) {
  
  ns <- NS(id)

  tabItem(tabName = "issue",
    fluidRow(

      #
      # sidebar
      #

      box(
        width = 3,
        status = "primary",

        h5("1. Complete fields below:"),

        selectInput(
          inputId = ns("sel_aqMet"),
          label = h5("Author:"),
          selected = "",
          choices = c("", aq_mets$nickname),
          width = "100%"
        ),

        textInput(inputId = ns("smokeDuration"),
                  label = h5("Wildfire smoke expected to last:"),
                  value = "24-48 hours",
                  width = "100%"),

        dateInput(inputId = ns("nextUpdate"),
                  label = h5("Next update:"),
                  min = Sys.Date() +1,
                  value = Sys.Date() +1,
                  startview = "month",
                  weekstart = 0,
                  width = "100%"),

        textAreaInput(inputId = ns("smokeMessage"),
                      label = h5("Custom smoke outlook message:"),
                      value = "",
                      width = "100%",
                      height = "80px",
                      resize = "vertical"),

        h5("2. Select regions on map."),
        h5("3. Generate Warning:"),

        actionButton(
          inputId = ns("genWarning"),
          label = "Go!",
          style = "width: 80%; color: #fff; background-color: #337ab7; border-color: #2e6da4;"
        ),
       
        hr(),
        h5("alt-text:"),
        div(textOutput(ns("alttext")),
            class = "form-control",
            style = "width: 100%; min-height: 40px; height: auto;"),
       
        hr(),
        actionButton(inputId = ns("cleanupdir"), label = "clean dir")
       
      ),

      #
      # map
      #

      box(
        width = 9,
        status = "primary",

        actionButton(inputId = ns("clearHighlight"),label = "Reset Map"),
        
        hr(),
        leafletOutput(outputId = ns("map"), width = "100%", height = 750)
      
      )

    )
  )
}

#--------------------------------------------------
# Server
#--------------------------------------------------

source(here::here("src", "assign_urls.R"))

issueWildfireSmoke <- function(input, output, session){

  initial_lat = 54.8
  initial_long = -124.253144
  initial_zoom = 5
  completeNotificationIDs <- character(0)
  
  currentDate <- Sys.Date()
  currentDateString <- format_datestring(currentDate)

  map_reactive <- reactive({
    leaflet(options = leafletOptions(zoomControl = TRUE, dragging = TRUE)) |> 
      
      setView(lng = initial_long, lat = initial_lat, zoom = initial_zoom) |> 
      addMapPane("ames_polygons", zIndex = 410) |>  # layer ordering (polygons under cities)

      #add the BC map (outlines of the province)
      addTiles(layerId = "geomap") |> 
      addPolygons(
        data = bc_map,
        color = "black",
        fillColor = "#f7f7f7",
        opacity = 0.75,
        fillOpacity = 0.025,
        stroke = TRUE,
        weight = 0.5,
        smoothFactor = 0.2,
        group = "background"
        ) |> 

      #add the eccc polygons
      addPolygons(
        data = eccc_map_env,
        fillOpacity = 0.025,
        opacity = 0.75,
        color = "black",
        fillColor = "#f7f7f7",
        stroke = TRUE,
        weight = 1,
        smoothFactor = 0.2,
        layerId = ~NAME,
        group = "regions",
        label = ~NAME,
        labelOptions = labelOptions(textsize = "15px"),
        ) |> 
      # add eccc for selections (user clicks)
      addPolygons(
        data = eccc_map_env,
        stroke = TRUE,
        fillOpacity = 0.57,
        opacity = 0.75,
        color = "black",
        weight = 2.5,
        fillColor = "#FFF716",
        options = pathOptions(pane = "ames_polygons"),
        label = ~NAME,
        labelOptions = labelOptions(textsize = "15px"),
        layerId = ~OBJECTID,
        group = ~NAME
        ) |> 
      hideGroup(group = eccc_map_env$NAME) |>  # hide selections (fills) initially

      # BCWFS fire layer
      leaflet.esri::addEsriFeatureLayer(
        url = bcwfs_fire_layer,
        useServiceSymbology = FALSE,
        labelProperty = "FIRE_ID",     #"FIRE_STATUS" redundant with legend
        labelOptions = labelOptions(textsize = "12px"),
        markerType = "marker",    # "circleMarker" won't work with icon symbols
        markerIconProperty = "FIRE_STATUS",
        markerIcons = fireIcons,
        options = leaflet.esri::featureLayerOptions(where = "FIRE_STATUS <> 'Out'"),
        group = "BCWFS Fires"
        ) |> 
      addLegend(
        pal = fireIconFactorPalette,
        values = names(fireIcons),
        position = "topright",
        group = "BCWFS Fires"
        ) |> 

      # Current weather
      addWMSTiles(
        current_weather,
        layers = "CURRENT_CONDITIONS",
        options = WMSTileOptions(format = "image/png", transparent = TRUE, freezeAtZoom = "max"),
        group = "Wx current",
        attribution = paste0("'<a href =" , msc_attribution, ">MSC Open Data</a>'")
        ) |> 

      # GOES visible sat
      addWMSTiles(
        goes_vis_sat,
        layers = "GOES-West_ABI_GeoColor",
        options = WMSTileOptions(format = "image/png", transparent = TRUE),
        attribution = paste0("'NASA <a href = " , goes_vis_sat, ">GIBS</a>'"),
        group = "GOES West"
        ) |> 

      # RADAR rain rate
      # NOTE: there are many other WMS layers available from
      # this service; consider for future.
      addWMSTiles(
        current_weather,
        layers = "RADAR_1KM_RRAI",
        options = WMSTileOptions(format = "image/png", transparent = TRUE),
        attribution = paste0("'<a href =" , msc_attribution, ">MSC Open Data</a>'"),
        group = "RADAR"
        ) |> 

      # ECCC FireWork - current hour forecast
      addWMSTiles(
        current_weather,
        layers = "RAQDPS-FW.SFC_PM2.5",
        options = WMSTileOptions(format = "image/png", transparent = TRUE, opacity = 0.55),
        attribution = paste0("'<a href =" , msc_attribution, ">MSC Open Data</a>'"),
        group = "FireWork PM2.5 Sfc"
        ) |> 

      # NRCan Fire perimeters
      addWMSTiles(
        nrcan_fire_perim,
        layers = "m3_polygons_current",
        options = WMSTileOptions(format = "image/png", transparent = TRUE),
        attribution = paste0("'<a href =", nrcan_cwfis_attribution, ">CWFIS Datamart</a>'"),
        group = "NRCan Fire perimeters"
        ) |> 

      addLayersControl(
        overlayGroups = c("GOES West", "Wx current", "RADAR", "FireWork PM2.5 Sfc", "BCWFS Fires", "NRCan Fire perimeters"),
        options = layersControlOptions(collapsed = FALSE)) |> 
      hideGroup(c("GOES West", "Wx current", "RADAR", "FireWork PM2.5 Sfc", "BCWFS Fires", "NRCan Fire perimeters"))

   })

  output$map <- renderLeaflet({
    map_reactive()
   })
  
  proxy <- leafletProxy("map")

  # create a vector of reactive values to store the the selected polygons
  selRegions <- reactiveValues(ids = vector())
  
  # Remove
  observeEvent(input$cleanupdir, {
    rnw_dirs <- list.dirs(path = here::here("outputs", "rnw"), recursive = FALSE, full.names = TRUE)
    rnw_files <- list.files(path = here::here("outputs", "rnw"), full.names = TRUE)
    qmd_dirs <- list.dirs(path = here::here("outputs", "qmd"), recursive = FALSE, full.names = TRUE)
    qmd_files <- dir(path = here::here("outputs", "qmd"), full.names = TRUE)
    
    dirsToRemove <- c(rnw_dirs, qmd_dirs)
    files <- c(rnw_files, qmd_files)
    filesToRemove <- setdiff(files, dirsToRemove)
    
    nfiles <- length(filesToRemove)
    ndirs <- length(dirsToRemove)
    if (nfiles == 0 & ndirs == 0) {
      showNotification("No files or directories to remove", type = "message")
    } else {
      
      fs::dir_delete(dirsToRemove)
      file.remove(filesToRemove)
      
      showNotification(paste("Directories removed:", ndirs, ". ", "Files removed:", nfiles, "."), type = "message")  
    }
  })

  #create map as viewed by user
  observeEvent(input$map_shape_click, {

    # input$map_shape_click$group --> group of map objects = "regions"
    # input$map_shape_click$id --> individual name of clicked region

    if(input$map_shape_click$group == "regions") {
      selRegions$ids <- c(selRegions$ids, input$map_shape_click$id)
      proxy |>  showGroup(group = input$map_shape_click$id)
    } else {
      selRegions$ids <- setdiff(selRegions$ids, input$map_shape_click$group)
      proxy |>  hideGroup(group = input$map_shape_click$group)
    }

  })


  user_created_map <- function(){
    m <- leaflet() |> 
      setView(lng = initial_long, lat = initial_lat, zoom = initial_zoom) |> 
      addMapPane("ames_polygons", zIndex = 420) |> 
      addMapPane("ames_cities", zIndex = 430) |> 
      # add white background
      addRectangles(initial_long - 15.5, initial_lat - 7,
                    initial_long + 11.5, initial_lat + 5.5,
                    fillColor = "#FFF",
                    fillOpacity = 1,
                    opacity = 0) |> 
      #add the BC map (outlines of the province)
      addPolygons(data = bc_map,
                  color = "black",
                  opacity = 0.7,
                  fillOpacity = 0,
                  weight = 0.5,
                  smoothFactor = 0.2,
                  group = "background") |> 
      #add the eccc polygons
      addPolygons(data = eccc_map_env,
                  fillColor = "white",
                  color = "black",
                  opacity = 0.7,
                  weight = 1,
                  smoothFactor = 0.2) |>
      addPolygons(data = eccc_map_env[which(eccc_map_env$NAME %in% selRegions$ids), ],
                  ##layerId = ~NAME,
                  fillOpacity = 1,
                  opacity = 1,
                  color = "black",
                  weight = 1.75,
                  fillColor = "#FFF716",
                  options = pathOptions(pane = "ames_polygons"),
                  highlightOptions = highlightOptions(sendToBack = TRUE)) |> 
      addCircleMarkers(data = cities,
                       radius = 1,
                       color = "black",
                       opacity = 1,
                       fillColor = "black",
                       label = ~as.character(NAME),
                       group = "labels",
                       options = pathOptions(pane = "ames_cities"),
                       labelOptions = labelOptions(
                         direction = "right",
                         offset = c(2, -10),
                         noHide = TRUE,
                         textOnly = TRUE,
                         permanent = TRUE,
                         textsize = "12px",
                         crs = "+init=epsg:4326",
                         style = list(
                           "font-style" = "bold"))) |> 
      addCircleMarkers(data = lm_pts,
                       options = markerOptions(interactive = FALSE),
                       stroke = FALSE,
                       fillColor = "black",
                       fillOpacity = 0.3,
                       radius = 0.75)
    return(m)
  }
  
# Create the logic for the "clear the map" action button
# clear all user-created highlighted regions from map
  observeEvent(input$clearHighlight, {
    
    output$alttext <- renderText("")
    
    # FIXME: Clearing polygons should be accomplished natively in the app,
    # but I suspect the layerId names in the Polygon layers are in 
    # conflict and preventing this from working.
    
    selRegions$ids <- NULL

    # recreate $map
    output$map <- renderLeaflet({
      map_reactive()
    })

   })


# Generate report
# Automatically generate map and then create the PDF
  observeEvent(input$genWarning, {
    
    if (input$sel_aqMet == "") {
      showNotification("No author selected; please select an author.", type = "error")
    } else if (length(selRegions$ids) == 0) {
      showNotification("No region selected; please select a region.", type = "error")
    } else {

      ncomplete <- length(completeNotificationIDs)
      if (ncomplete > 0) {
        # remove the notification for completed steps if the genWarning
        # button is clicked again
        for (i in seq(ncomplete)) {
          # must remove these individually
          removeNotification(completeNotificationIDs[i])
        }
        completeNotificationIDs <<- completeNotificationIDs[-c(seq(ncomplete))]
      }
      
      showNotification("Rendering map...")
      
      issueBasename <- "wildfire_smoke_issue"
      cliprect <- c(140, 147, 610, 480)  # top, left, width, height
      
      usermap <- user_created_map()
      
      html_map <- sprintf(here::here("outputs", "rnw", "%s_%s_map.html"), currentDate, issueBasename)
      htmlwidgets::saveWidget(usermap, html_map)
      
      png_map <- here::here("outputs", "rnw", "map.png")
      webshot::webshot(url = html_map,  
                       file = png_map,
                       cliprect = cliprect
      )

      usermapForWebsite <- usermap |> 
        addLabelOnlyMarkers(lng = -137.25, lat = 56.25,
                          label = HTML(paste0("Updated:<br/>", currentDate)),
                          group = "labels",
                          options = pathOptions(pane = "ames_cities"),
                          labelOptions = labelOptions(
                            direction = "right",
                            noHide = TRUE,
                            textOnly = TRUE,
                            textsize = "15px",
                            crs = "+init=epsg:4326",
                            style = list("color" = "#5c5c5c")))
      
      html_map_for_web <- here::here("outputs", "rnw", "usermapForWebsite.html")
      htmlwidgets::saveWidget(usermapForWebsite, file = html_map_for_web)
      
      png_map_for_web <- sprintf(here::here("outputs", "rnw", "%s_%s_map.png"), currentDate, issueBasename)
      webshot::webshot(url = html_map_for_web,  
                       file = png_map_for_web,
                       cliprect = cliprect
      )
      
      # Write selected polygon IDs to CSV file
      regionsOut <- eccc_map_bc |> 
        mutate(STATE = case_when(
                  NAME %in% selRegions$ids ~ as.integer(1),
                  OBJECTID %in% eccc_zones_lm ~ as.integer(NA),  #could eccc_map_env be used to remove this line?
                  TRUE ~ as.integer(0)
                  ),
              DATE = currentDate
              ) |> 
        select(OBJECTID, NAME, STATE, DATE) |> 
        arrange(OBJECTID) |> 
        sf::st_drop_geometry()

      write.csv(regionsOut, file = sprintf(here::here("outputs", "rnw", "%s_issued_regions.csv"), currentDate), row.names = FALSE)

      # Note: text update is after the PDF is generated, so there is a
      # delay in the appearance on the UI. For now, this is by design.
      alttext <- sprintf("Air Quality Warning - Wildfire Smoke Regions for %s: %s.",
                         currentDate,
                         paste(sort(selRegions$ids), sep = "", collapse = ", "))
      
      writeLines(alttext, sprintf(here::here("outputs", "rnw", "%s_%s_map_alttext.txt"), currentDate, issueBasename))
      
      id2 <- showNotification("Writing text files complete!", duration = NULL)
      completeNotificationIDs <<- c(completeNotificationIDs, c(id, id2))

      output$alttext <- renderText(alttext)

      # PDF
      showNotification("Generating PDF...")
      knitr::knit2pdf(sprintf(here::here("src", "rnw", "%s.Rnw"), issueBasename), clean = TRUE,
                      output = sprintf(here::here("outputs", "rnw", "%s_%s.tex"), currentDate, issueBasename))

      id <- showNotification("PDF generation complete!", duration = NULL)
      
      # Quarto
      showNotification("Generating Markdown...")
      
      quarto::quarto_render(input = sprintf(here::here("src", "qmd", "%s.qmd"), issueBasename),
                            output_format = "markdown",
                            output_file = sprintf("%s_%s.md", currentDate, issueBasename),
                            execute_params = list(sel_aqMet = input$sel_aqMet,
                                                  nextUpdate = as.character(input$nextUpdate),
                                                  smokeDuration = input$smokeDuration,
                                                  selRegionsIDs = selRegions$ids,
                                                  customMessage = input$smokeMessage,
                                                  ice = "Issue"),
                            execute_dir = here::here("outputs", "qmd"),
                            debug = FALSE)
      
      id <- showNotification("Markdown generation complete!", duration = NULL)
      
      markdown_output_file <- list.files(pattern = sprintf("%s_%s.md", currentDate, issueBasename), full.names = TRUE)
      fs::file_move(path = paste0(markdown_output_file), new_path = here::here("outputs", "qmd"))
      
      id <- showNotification("Markdown file moved to outputs/qmd directory.")

    } #end else
  }) #end observeEvent for generating report
}
