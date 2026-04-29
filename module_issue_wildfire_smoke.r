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

# Module: Air Quality Warning - Wildfire Smoke

library(shiny)
library(shinydashboard)
library(leaflet)
library(dplyr)
library(webshot)
library(zip)
library(sf)

# Ensure PhantomJS is installed for webshot (used for map snapshots)
if (is.null(suppressMessages(webshot:::find_phantom()))) { webshot::install_phantomjs() }

# Set OpenSSL config to /dev/null to avoid potential SSL issues in webshot
Sys.setenv(OPENSSL_CONF = "/dev/null")

# Define custom icons for fire incidents on maps
local_reference_fire_icons <- awesomeIconList(
  #Out = makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "lightgray"),
  `Fire of Note` = makeAwesomeIcon(icon = "fire", library = "fa", markerColor = "darkred", iconColor = "#FFF"),
  `Being Held` = makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "orange", iconColor = "#DB9B3B"),
  `Out of Control` = makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "red", iconColor = "#B54D2F"),
  `Under Control` = makeAwesomeIcon(icon = "circle", library = "fa", markerColor = "green", iconColor = "#86AA32")
)

# Create a color palette for fire markers using the markerColor of each icon
# Ordered factor ensures consistent legend ordering on maps
local_fire_palette <- colorFactor(as.vector(sapply(local_reference_fire_icons, get, x = "markerColor")), levels = names(local_reference_fire_icons), ordered = TRUE)

source("src/warning_level_definitions.r") # shared warning level definitions

#--------------------------------------------------
# UI
#--------------------------------------------------

#UI function for the "Wildfire Smoke Warning - Issue" tab

issueWildfireSmokeUI <- function(id) {

  ns <- NS(id)

  tabItem(tabName = "issue",
          fluidRow(
            box(
              width = 3,
              status = "primary",

              # -------------------------------
              # Section 1: Metadata required to generate warning
              # -------------------------------

              h4(tags$b("1. Warning Information")),

              # Author selection (Air Quality Meteorologist)
              selectInput(
                inputId = ns("aqMet"),
                label = h4("Author:"),
                selected = "",
                choices = c("", reference_aq_mets$fullname)),

              # Custom text to predict the smoke duration - default value is 24-48 hours
              textInput(inputId = ns("smokeDuration"),
                        label = h4("Wildfire smoke expected to last:"),
                        value = "24-48 hours"),

              # Optional custom message included in warning text
              textAreaInput(inputId = ns("smokeMessage"),
                            label = h4("Custom smoke outlook message:"),
                            value = "",
                            height = "80px",
                            resize = "vertical"),

              # Date for the next warning update - default is tomorrow
              dateInput(inputId = ns("nextUpdate"),
                        label = h4("Next update:"),
                        min = Sys.Date() + 1,
                        value = Sys.Date() + 1,
                        startview = "month",
                        weekstart = 0),

              # -------------------------------
              # Section 2: Affected location
              # -------------------------------

              tags$div(style = "margin-top: 40px;"),  # Adds vertical space
              h4(tags$b("2. Affected location")),

              # Select affected location(s) visually on the map
              h4("a) Select affected location(s) on the map:"),

              # Describe affected location(s) for the warning table on the website
              selectizeInput(
                inputId = ns("location"),
                label = h4(HTML("<b>2. Describe affected regions</b> (for warnings table on website)")),
                selected = "",
                choices = c("", "Southeast B.C.", "Central Interior", "Cariboo", "Northeast B.C.", "Northwest B.C.", "Multiple regions in B.C."),
                options = list(create = TRUE)
              ),

              # -------------------------------
              # Section 3: Generate outputs
              # -------------------------------

              tags$div(style = "margin-top: 40px;"),  # Adds vertical space
              h4(tags$b("3. Generate Warning")),

              # Trigger report generation
              actionButton(
                inputId = ns("genWarning"),
                label = "Go!",
                style = "width: 100%; color: #fff; background-color: #3c8dbc; border-color: #2e6da4;"
              ),

              hr(),

              # Download button
              downloadButton(ns("download_report"), "Download Files", style = "font: 16pt"),

              hr(),

              # Utility button to clean working directories
              actionButton(inputId = ns("cleanupdir"), label = "clean dir"),

              hr()
            ), #end main box

            # -------------------------------
            # Map display and controls
            # -------------------------------

            box(
              width = 9,
              status = "primary",

              # Button to reset any highlighted selections on the map
              actionButton(inputId = ns("clearHighlight"), label = "Reset Map"),

              hr(),

              # Leaflet map output for selecting affected locations
              leafletOutput(outputId = ns("map"), height = 750)

            ),

            # -------------------------------
            # Instructions panel
            # -------------------------------

            box(width = 9,
                status = "info",

                # Include user instructions from an external Markdown file
                includeMarkdown("docs/instructions-aqwarnings.md"))

          ) #end fluidRow
  ) #end tabItem
}

#--------------------------------------------------
# Server
#--------------------------------------------------

# Server logic for the "Wildfire Smoke Warning - Issue" tab

# Import URL assignments
source(here::here("src", "assign_urls.r"))

# Load BCWFS Fires Data

bcwfs_fire_point_data <- st_read(reference_url_bcwfs_fire_data)


issueWildfireSmoke <- function(input, output, session) {

  # -------------------------------
  # Initial map view parameters
  # -------------------------------

  initial_lat = 54.8 # Center latitude for the initial map view
  initial_long = -124.253144 # Center longitude for the initial map view
  initial_zoom = 5 # Default zoom level when map loads

  completeNotificationIDs <- character(0)

  # -------------------------------
  # Reactive Leaflet map object
  # -------------------------------

  map_reactive <- reactive({
    leaflet(options = leafletOptions(zoomControl = TRUE, # Allow user to zoom in/out
                                     dragging = TRUE)) |> # Allow map dragging

      # Set initial map view and configure map layers
      # Center map at initial coordinates with default zoom
      setView(lng = initial_long, lat = initial_lat, zoom = initial_zoom) |>

      # Ensures polygons appear below city markers on the map
      addMapPane("ames_polygons", zIndex = 410) |>

      #add the BC map (outlines of the province)
      addTiles(layerId = "geomap") |>
      addPolygons(
        data = reference_bc_map,
        color = "black",
        fillColor = "#f7f7f7",
        opacity = 0.75,
        fillOpacity = 0.025,
        stroke = TRUE,
        weight = 0.5,
        smoothFactor = 0.2,
        group = "background"
      ) |>

      # Add the ECCC polygons
      addPolygons(
        data = reference_eccc_map_env,
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
      ) -> m

    # Add ECCC for selections (user clicks) - from warning DF
    for (i in seq_len(nrow(reference_warning_levels_df))) {
      warning_level <- reference_warning_levels_df[i,]

      addPolygons(
        m,
        data = reference_eccc_map_env,
        stroke = TRUE,
        fillOpacity = warning_level$PolygonOpacity,
        opacity = 1,
        color = "black",
        weight = 1.75,
        fillColor = warning_level$Colour,
        options = pathOptions(pane = "ames_polygons"),
        label = ~NAME,
        labelOptions = labelOptions(textsize = "15px"),
        layerId = ~OBJECTID,
        group = paste0(reference_eccc_map_env$NAME, "-", i)
      ) |>

        hideGroup(group = paste0(reference_eccc_map_env$NAME, "-", i)) -> m # hide until clicked
    }

      addLegend(
        m,
        pal = local_fire_palette,
        values = names(local_reference_fire_icons),
        position = "topright",
        group = "BCWFS Fires"
      ) |>
      addAwesomeMarkers(
       data = bcwfs_fire_point_data,
       label = ~paste0(FIRE_ID, " - ", GEOGRAPHIC_DESCRIPTION),
       labelOptions = labelOptions(textsize = "12px"),
       options = markerOptions(),
       icon = ~local_reference_fire_icons[FIRE_STATUS],
       group = "BCWFS Fires"
      ) -> m

      # Current weather
      addWMSTiles(
        m,
        reference_url_current_weather,
        layers = "CURRENT_CONDITIONS",
        options = WMSTileOptions(format = "image/png", transparent = TRUE, freezeAtZoom = "max"),
        group = "Wx current",
        attribution = paste0("'<a href =", reference_url_msc_attribution, ">MSC Open Data</a>'")
      ) |>

      # GOES visible sat
      addWMSTiles(
        reference_url_goes_vis_sat,
        layers = "GOES-West_ABI_GeoColor",
        options = WMSTileOptions(format = "image/png", transparent = TRUE),
        attribution = paste0("'NASA <a href = ", reference_url_goes_vis_sat, ">GIBS</a>'"),
        group = "GOES West"
      ) |>

      # RADAR rain rate
      # NOTE: there are many other WMS layers available from
      # this service; consider for future.
      addWMSTiles(
        reference_url_current_weather,
        layers = "RADAR_1KM_RRAI",
        options = WMSTileOptions(format = "image/png", transparent = TRUE),
        attribution = paste0("'<a href =", reference_url_msc_attribution, ">MSC Open Data</a>'"),
        group = "RADAR"
      ) |>

      # ECCC FireWork - current hour forecast
      addWMSTiles(
        reference_url_current_weather,
        layers = "RAQDPS-FW.SFC_PM2.5",
        options = WMSTileOptions(format = "image/png", transparent = TRUE, opacity = 0.55),
        attribution = paste0("'<a href =", reference_url_msc_attribution, ">MSC Open Data</a>'"),
        group = "FireWork PM2.5 Sfc"
      ) |>

      # NRCan Fire perimeters
      addWMSTiles(
        reference_url_nrcan_fire_perim,
        layers = "m3_polygons_current",
        options = WMSTileOptions(format = "image/png", transparent = TRUE),
        attribution = paste0("'<a href =", reference_url_nrcan_cwfis_attribution, ">CWFIS Datamart</a>'"),
        group = "NRCan Fire perimeters"
      ) |>

      addLayersControl(
        overlayGroups = c("GOES West", "Wx current", "RADAR", "FireWork PM2.5 Sfc", "BCWFS Fires", "NRCan Fire perimeters"),
        options = layersControlOptions(collapsed = FALSE)) |>
      hideGroup(c("GOES West", "Wx current", "RADAR", "FireWork PM2.5 Sfc", "BCWFS Fires", "NRCan Fire perimeters"))

  })

  # Render the initial reactive Leaflet map
  output$map <- renderLeaflet({
    map_reactive()
  })

  # Create a Leaflet proxy to update the map dynamically without re-rendering
  proxy <- leafletProxy("map")


  # create a vector of reactive values to store the the selected polygons
  selRegions <- reactiveValues()
  selRegions$DF <- data.frame(
    id = character(),
    colour = integer(),
    stringsAsFactors = FALSE
  )

  # -------------------------------
  # Handle user interaction with the map polygons
  # -------------------------------

  observeEvent(input$map_shape_click, {
    # The selection states of polygons are represented by a 2-column dataframe
    # $id is the name of the polygon region on the map
    # $colour is an index into the reference_warning_levels_df dataframe used to represent the currently-selected index

    # input$map_shape_click$group --> group of map objects, e.g., "regions"
    # input$map_shape_click$id    --> name/ID of the individual region clicked

    IDToModify <- input$map_shape_click$group
    if (IDToModify == "regions") {
      IDToModify <- input$map_shape_click$id
    }
    IDToModify <- gsub("\\-\\d$", "", IDToModify) # strip trailing -digit if exists

    currentlySelectedColour <- 1 # unselected to start
    if (selRegions$DF %>%
      filter(id == IDToModify) %>%
      nrow() > 0) {
      currentlySelectedColour <- (selRegions$DF %>% filter(id == IDToModify))$colour
    }

    updatedColour <- currentlySelectedColour

    for (i in seq_len(nrow(reference_warning_levels_df))) {
      nextIndex <- 1 + (i + currentlySelectedColour - 1) %% nrow(reference_warning_levels_df) # use modulus operator to circularly visit the dataframe

      # skip colours that are not selectable
      if (reference_warning_levels_df[nextIndex,]$Selectable == TRUE) {
        updatedColour <- nextIndex
        break
      }
    }

    updated <- tibble(id = IDToModify, colour = updatedColour)
    selRegions$DF <- rows_upsert(selRegions$DF, updated, by = "id")

    by(selRegions$DF, seq_len(nrow(selRegions$DF)), function(row) {

      # iterate over the selRegion dataframe, calling the map proxy to hide inactive and show active selections
      for (i in seq_len(nrow(reference_warning_levels_df))) {
        active <- row$colour == i
        group_name <- paste0(row$id, "-", i)

        if (active) {
          proxy |>  showGroup(group = group_name)
        } else {
          proxy |>  hideGroup(group = group_name)
        }
      }
    })

  })

  # -------------------------------
  # Create a Leaflet map for user interaction
  # -------------------------------

  user_created_map <- function() {

    m <- leaflet() |>

      # Set initial map view centered at default coordinates and zoom level
      setView(lng = initial_long, lat = initial_lat, zoom = initial_zoom) |>

      # Add custom map panes with zIndex for layer ordering
      # Polygons below city markers
      addMapPane("ames_polygons", zIndex = 420) |>
      addMapPane("ames_cities", zIndex = 430) |>

      # Add white background
      addRectangles(initial_long - 15.5, initial_lat - 7,
                    initial_long + 11.5, initial_lat + 5.5,
                    fillColor = "#FFF", # White fill
                    fillOpacity = 1, # Fully opaque
                    opacity = 0) |> # No border
      # Add the BC map (outlines of the province)
      addPolygons(data = reference_bc_map,
                  color = "black",
                  opacity = 0.7,
                  fillOpacity = 0,
                  weight = 0.5,
                  smoothFactor = 0.2,
                  group = "background") |>
      # Add the eccc polygons
      addPolygons(data = reference_eccc_map_env,
                  fillColor = "white",
                  color = "black",
                  opacity = 0.7,
                  weight = 1,
                  smoothFactor = 0.2) |>

      # Add city labels as circle markers
      addCircleMarkers(data = reference_cities,
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

      # Add additional monitoring points (lm_pts) as small non-interactive markers
      addCircleMarkers(data = reference_lm_pts,
                       options = markerOptions(interactive = FALSE),
                       stroke = FALSE,
                       fillColor = "black",
                       fillOpacity = 0.3,
                       radius = 0.75)

    for (i in seq_len(nrow(reference_warning_levels_df))) {
      warning_level <- reference_warning_levels_df[i,]

      if (selRegions$DF %>% filter(colour == i) %>% nrow() > 0) {
        m <- addPolygons(
          m,
          data = reference_eccc_map_env[which(reference_eccc_map_env$NAME %in% (selRegions$DF %>% filter(colour == i))$id),],
          stroke = FALSE,
          fillOpacity = warning_level$PolygonOpacity,
          opacity = 0.75,
          fillColor = warning_level$Colour,
        )
      }
    }

    # Return the fully constructed map object
    return(m)
  }

  # -------------------------------
  # Clear map highlights action
  # -------------------------------

  # Create the logic for the "clear the map" action button
  # Clears all user-selected/highlighted regions from the map
  observeEvent(input$clearHighlight, {

    # Clear any alternative text or messages related to map selection
    output$alttext <- renderText("")

    # FIXME: Clearing polygons should be accomplished natively in the app,
    # but I suspect the layerId names in the Polygon layers are in
    # conflict and preventing this from working.

    selRegions$DF <- selRegions$DF[0,]

    # Re-render the map to reflect cleared selections
    output$map <- renderLeaflet({
      map_reactive()
    })
  })

  # -------------------------------
  # Generate warning
  # -------------------------------

  observeEvent(input$genWarning, {

    atLeastOneRegionSelected <- FALSE
    for (i in seq_len(nrow(reference_warning_levels_df))) {
      warning_level <- reference_warning_levels_df[i,]
      if (warning_level$IsTemplateParameter == TRUE && selRegions$DF %>% filter(colour == i) %>% nrow() > 0) {
        atLeastOneRegionSelected <- TRUE
        break
      }
    }

    # Input validation
    if (input$aqMet == "") {
      showNotification("No author selected; please select an author.", type = "error")
    } else if (atLeastOneRegionSelected == FALSE) {
      showNotification("No region selected; please select a region.", type = "error")
    } else if (input$location == "") {
      showNotification("No location description provided; please select or type a location description.", type = "error")
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

      # Progress indicator
      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Preparing files...", value = 0)

      # Prep image for PDF output
      issueBasename <- "wildfire_smoke_issue"
      cliprect <- c(140, 147, 610, 480)  # top, left, width, height

      usermap <- user_created_map()

      # Set output file name for map as .html
      html_map <- sprintf("%s_%s_map.html", Sys.Date(), issueBasename)
      htmlwidgets::saveWidget(usermap, html_map)

      # Set output file name for map as .png
      png_map <- sprintf("%s_%s_map.png", Sys.Date(), issueBasename)
      webshot(url = html_map,
              file = png_map,
              cliprect = cliprect
      )


      # Compute `level` metadata for document (used in recent warnings table)
      levels <- c()
      for (i in seq_len(nrow(reference_warning_levels_df))) {
        warning_level <- reference_warning_levels_df[i,]
        if (warning_level$IsTemplateParameter == TRUE && selRegions$DF %>% filter(colour == i) %>% nrow() > 0) {
          levels <- append(levels, warning_level$Name)
        }
      }

      # Compute a list of selected regions for each warning level ( + 1 for allRegions) for inclusion in parameters
      regionSelectionsForTemplate <- list()
      for (i in seq_len(nrow(reference_warning_levels_df))) {
        warning_level <- reference_warning_levels_df[i,]
        if (warning_level$IsTemplateParameter == TRUE) {
          regionSelectionsForTemplate[[warning_level$Name]] <- list()
          if (selRegions$DF %>% filter(colour == i) %>% nrow() > 0) {
            regionSelectionsForTemplate[[warning_level$Name]] <- as.list(selRegions$DF %>% filter(colour == i))$id
          }
          regionSelectionsForTemplate[["all"]] <- append(regionSelectionsForTemplate[["all"]], as.list(selRegions$DF %>% filter(colour == i))$id)
        }
      }

      # -------------------------------
      # Markdown output
      # -------------------------------
      progress$inc(amount = 0.3, message = "Generating Markdown file...", detail = "Step 1 of 2")

      renderParameters <- list(aqMet = input$aqMet,
                               nextUpdate = as.character(input$nextUpdate),
                               smokeDuration = input$smokeDuration,
                               customMessage = input$smokeMessage,
                               location = input$location,
                               warningLevel = regionSelectionsForTemplate,
                               twoLevels = length(regionSelectionsForTemplate$yellow) > 0 && length(regionSelectionsForTemplate$orange) > 0,
                               outputFormat = "markdown")


      quarto::quarto_render(input = sprintf(here::here("%s.qmd"), issueBasename),
                            output_file = sprintf("%s_%s.md", Sys.Date(), issueBasename),
                            output_format = "markdown",
                            execute_params = renderParameters,
                            metadata = list(
                              author = input$aqMet,
                              ice = "Issue",
                              level = paste(levels, collapse = " / "),
                              location = input$location,
                              title = "Air quality warning in effect for wildfire smoke",
                              type = "wildfire_smoke",
                              parametersAsRendered = renderParameters # save all param actual values in the front matter for future reference
                            ),
                            debug = FALSE)

      # Relocate the .md file to outputs/ directory
      # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub directory
      markdown_output_file <- list.files(pattern = sprintf("%s_%s.md", Sys.Date(), issueBasename), full.names = TRUE)
      fs::file_move(path = paste0(markdown_output_file), new_path = here::here("outputs"))

      map_output_file <- list.files(pattern = sprintf("%s_%s_map.html", Sys.Date(), issueBasename), full.names = TRUE)
      fs::file_move(path = paste0(map_output_file), new_path = here::here("outputs"))

      # -------------------------------
      # PDF output
      # -------------------------------
      renderParameters[["outputFormat"]] <- "pdf"
      
      progress$inc(amount = 0.5, message = "Generating PDF file...", detail = "Step 2 of 2")
      quarto::quarto_render(input = sprintf(here::here("%s.qmd"), issueBasename),
                            output_file = sprintf("%s_%s.pdf", Sys.Date(), issueBasename),
                            output_format = "pdf",
                            execute_params = renderParameters,
                            metadata = list(
                              title = "Air quality warning in effect for wildfire smoke",
                              parametersAsRendered = renderParameters # save all param actual values in the front matter for future reference
                            ),
                            debug = FALSE)

      # Relocate the .pdf to outputs/ directory
      # to keep it consistent with the Markdown files
      pdf_output_file <- list.files(pattern = sprintf("%s_%s.pdf", Sys.Date(), issueBasename), full.names = TRUE)
      fs::file_move(path = paste0(pdf_output_file), new_path = here::here("outputs"))

      progress$inc(amount = 1, message = "Processing complete.", detail = " Files are ready for downloading.")
      Sys.sleep(5)

    } #end else
  }) #end observeEvent

  # --------------------------------------------------
  # Download handler: zip all outputs
  # --------------------------------------------------

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

  # --------------------------------------------------
  # Cleanup directory
  # --------------------------------------------------
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
}
