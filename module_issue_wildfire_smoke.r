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
library(webshot)
library(zip)
if (is.null(suppressMessages(webshot:::find_phantom()))) { webshot::install_phantomjs() }
Sys.setenv(OPENSSL_CONF="/dev/null")


fireIcons <- awesomeIconList(
  #Out = makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "lightgray"),
  `Fire of Note` =  makeAwesomeIcon(icon = "fire", library = "fa", markerColor = "darkred", iconColor = "#FFF"),
  `Being Held` =  makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "orange", iconColor = "#DB9B3B"),
  `Out of Control`=  makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "red", iconColor = "#B54D2F"),
  `Under Control` =  makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "green", iconColor = "#86AA32")
)
fireIconFactorPalette <-  colorFactor(as.vector(sapply(fireIcons, get, x = "markerColor")), levels = names(fireIcons), ordered = TRUE)

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

        h4(tags$b("1. Complete the fields below")),

        selectInput(
          inputId = ns("sel_aqMet"),
          label = h4("Author:"),
          selected = "",
          choices = c("", aq_mets$fullname),
          width = "100%"),

        textInput(inputId = ns("smokeDuration"),
                  label = h4("Wildfire smoke expected to last:"),
                  value = "24-48 hours",
                  width = "100%"),

        dateInput(inputId = ns("nextUpdate"),
                  label = h4("Next update:"),
                  min = Sys.Date() +1,
                  value = Sys.Date() +1,
                  startview = "month",
                  weekstart = 0,
                  width = "100%"),

        textAreaInput(inputId = ns("smokeMessage"),
                      label = h4("Custom smoke outlook message:"),
                      value = "",
                      width = "100%",
                      height = "80px",
                      resize = "vertical"),

        h4(tags$b("2. Select regions on map")),
        
        selectizeInput(
          inputId = ns("location"),
          selected = "",
          label = h4(HTML("<b>3. Describe affected regions</b> (for warnings table on website)")),
          choices = c("", "Southeast B.C.", "Central Interior", "Cariboo", "Northeast B.C.", "Northwest B.C.", "Multiple regions in B.C." ),
          width = "100%",
          options = list(create = TRUE)
        ),
        
        h4(tags$b("4. Generate Warning")),

        actionButton(
          inputId = ns("genWarning"),
          label = "Go!",
          style = "width: 80%; color: #fff; background-color: #337ab7; border-color: #2e6da4;"
        ),
       
        hr(),
        
        downloadButton(ns("download_report"), "Download Files", style = "width: 80%"),
        
        hr(),
        
        actionButton(inputId = ns("cleanupdir"), label = "clean dir"),
        
        hr()
      ), #box

      #
      # map
      #

      box(
        width = 9,
        status = "primary",

        actionButton(inputId = ns("clearHighlight"),label = "Reset Map"),
        
        hr(),
        leafletOutput(outputId = ns("map"), width = "100%", height = 750)
      
      ),
      
      #
      # instructions
      #
      
      box(width=9,
          status="info",
          includeMarkdown("docs/instructions.md"))

    ) #fluidRow
  ) #tabItem
}

#--------------------------------------------------
# Server
#--------------------------------------------------

source(here::here("src", "assign_urls.r"))

issueWildfireSmoke <- function(input, output, session){

  initial_lat = 54.8
  initial_long = -124.253144
  initial_zoom = 5
  completeNotificationIDs <- character(0)
  
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
        fillColor = "grey",
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
  
  # clean up directories
  observeEvent(input$cleanupdir, {
    output_files <- dir(path = here::here("outputs"), full.names = TRUE)
    temp_files <- dir(full.names = TRUE, pattern = ".png|.html")
    
    filesToRemove <- c(output_files, temp_files)
    
    nfiles <- length(filesToRemove)
    if (nfiles == 0) {
      showNotification("No files or directories to remove", type = "message")
    } else {
      
      file.remove(filesToRemove)
      
      showNotification(paste("Files removed:", nfiles, "."), type = "message")  
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
                  fillColor = "grey",
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
  observeEvent(input$genWarning, {
    
    if (input$sel_aqMet == "") {
      showNotification("No author selected; please select an author.", type = "error")
    } else if (length(selRegions$ids) == 0) {
      showNotification("No region selected; please select a region.", type = "error")
    } else if (input$location == "") {
        showNotification("No location description provided; please select or type a location description.", type = "error")
    } else {

      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Preparing files...", value = 0)
      
      # prep image for PDF output
      issueBasename <- "wildfire_smoke_issue"
      cliprect <- c(140, 147, 610, 480)  # top, left, width, height
      
      usermap <- user_created_map()
      
      html_map <- sprintf("%s_%s_map.html", as.character(today), issueBasename)
      htmlwidgets::saveWidget(usermap, html_map)
      
      png_map <- sprintf("%s_%s_map.png", as.character(today), issueBasename)
      webshot(url = html_map,
              file = png_map,
              cliprect = cliprect
      )

      # generate markdown via Quarto
      progress$inc(amount = 0.3, message = "Generating Markdown file...", detail = "Step 1 of 2")
      quarto::quarto_render(input = sprintf(here::here("%s.qmd"), issueBasename),
                            output_file = sprintf("%s_%s.md", as.character(today), issueBasename),
                            output_format = "markdown",
                            execute_params = list(sel_aqMet = input$sel_aqMet,
                                                  nextUpdate = as.character(input$nextUpdate),
                                                  smokeDuration = input$smokeDuration,
                                                  selRegionsIDs = selRegions$ids,
                                                  customMessage = input$smokeMessage,
                                                  ice = "Issue",
                                                  location = input$location,
                                                  outputFormat = "markdown"),
                            debug = FALSE)
      
      # move the .md and .html to outputs/
      # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub-directory
      markdown_output_file <- list.files(pattern = sprintf("%s_%s.md", as.character(today), issueBasename), full.names = TRUE)
      fs::file_move(path = paste0(markdown_output_file), new_path = here::here("outputs"))
      
      map_output_file <- list.files(pattern = sprintf("%s_%s_map.html", as.character(today), issueBasename), full.names = TRUE)
      fs::file_move(path = paste0(map_output_file), new_path = here::here("outputs"))
      
      # generate pdf via Quarto 
      progress$inc(amount = 0.5, message = "Generating PDF file...", detail = "Step 2 of 2")
      quarto::quarto_render(input = sprintf(here::here("%s.qmd"), issueBasename),
                            output_file = sprintf("%s_%s.pdf", as.character(today), issueBasename),
                            output_format = "pdf",
                            execute_params = list(sel_aqMet = input$sel_aqMet,
                                                  nextUpdate = as.character(input$nextUpdate),
                                                  smokeDuration = input$smokeDuration,
                                                  selRegionsIDs = selRegions$ids,
                                                  customMessage = input$smokeMessage,
                                                  ice = "Issue",
                                                  location = input$location,
                                                  outputFormat = "pdf"),
                            debug = FALSE)
     
     # move the .pdf to outputs/
     # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub directory
     pdf_output_file <- list.files(pattern = sprintf("%s_%s.pdf", as.character(today), issueBasename), full.names = TRUE)
     fs::file_move(path = paste0(pdf_output_file), new_path = here::here("outputs"))
      
     progress$inc(amount = 1, message = "Processing complete.", detail = " Files are ready for downloading.") 
     Sys.sleep(5)

    } #end else
    }) #end observeEvent for generating report

## Download files

  output$download_report <- downloadHandler(
    filename = function() {
      sprintf("%s_wildfire_smoke_issue.zip", Sys.Date())
    },
    content = function(file) {
      # Build file paths correctly using sprintf()
      files_to_zip <- c(
        file.path("outputs", sprintf("%s_wildfire_smoke_issue.md", Sys.Date())),
        file.path("outputs", sprintf("%s_wildfire_smoke_issue.pdf", Sys.Date())),
        file.path("outputs", sprintf("%s_wildfire_smoke_issue_map.html", Sys.Date()))
      )
      
      # Zip the files into the download target
      zip::zip(zipfile = file, files = files_to_zip, mode = "cherry-pick")
    },
    contentType = "application/zip"
  )
}
