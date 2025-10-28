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

## Module: Air Quality Warning - Non Wildfire Smoke

library(shiny)
library(shinydashboard)
library(zip)
library(dplyr)

source(here::here("load_metadata.r"))

#--------------------------------------------------
# UI
#--------------------------------------------------

endLocalEmissionsUI <- function(id) {
  ns <- NS(id)
  tabItem(tabName = "end",
          fluidRow(
            
            box(
              width = 6,
              status = "primary",
              
              h5("1. Complete fields below:"),
              
              selectInput(
                inputId = ns("sel_aqMet"),
                label = h5("Author:"),
                selected = "",
                choices = c("", aq_mets$fullname),
                width = "50%"
              ),
              
              selectInput(
                inputId = ns("ice"),
                label = h5("I.C.E.:"),
                selected = "",
                choices = c("", "End"),
                width = "50%"
              ),
              selectInput(
                inputId = ns("pollutant"),
                label = h5("Pollutant:"),
                selected = "",
                choices = c("", "PM25", "PM10", "O3", "PM25 & PM10"),
                width = "50%"
              ),
              selectInput(
                inputId = ns("location"),
                label = h5("Location:"),
                selected = "",
                choices = c("", match_health_city$location),
                width = "50%"
              ),
              
              dateInput(inputId = ns("issuedate"),
                        label = h5("Date warning was first issued:"),
                        max = Sys.Date(),
                        value = Sys.Date() -1,
                        startview = "month",
                        weekstart = 0,
                        width = "50%"
              ),
              
              helpText("Add an optional custom message below. The default message can be retained, edited or deleted."),
              
              textAreaInput(inputId = ns("customMessage"),
                            label = h5("Custom smoke outlook message:"),
                            value = "Local air quality has improved due to changing meteorological conditions.",
                            width = "100%",
                            height = "80px",
                            resize = "vertical"),
              
              h5("2. Generate Warning:"),
              actionButton(
                inputId = ns("genWarning"),
                label = "Go!",
                style = "width: 50%; color: #fff; background-color: #337ab7; border-color: #2e6da4;"
              ),
              
              hr(),
              ## Add the download button here:
              downloadButton(ns("download_report"), "Download Files", style = "width: 100%"),
              
              hr(),
              actionButton(
                inputId = ns("cleanupdir"),
                label = "clean dir"
              )
              
            )
          )
  )
} 

#--------------------------------------------------
# Server
#--------------------------------------------------

endLocalEmissions <- function(input, output, session){
  
  completeNotificationIDs <- character(0)
  today <- as.Date(lubridate::with_tz(Sys.time(), "America/Los_Angeles"))

  # Generate report: markdown and pdf
  observeEvent(input$genWarning, {
    
    if (input$sel_aqMet == "") {
      showNotification("No author selected; please select an author.", type = "error")
    } else if (length(input$ice) == "") {
      showNotification("No advisory status selected; please select a status", type = "error")
    } else if (length(input$pollutant) == "") {
      showNotification("No pollutant selected; please select a pollutant", type = "error")
    } else if (input$location == "") {
      showNotification("No location selected; please select a location", type = "error")
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
      
      showNotification("Preparing files. Please wait for completion notification.")
      
      # Clean location name for file name
      location_clean <- gsub("\\s+", "_", input$location)
      
      # Set output file name
      output_file_name <- sprintf("%s_%s_%s", input$ice, input$pollutant, location_clean)
      
      # generate warning: markdown and pdf formats
      showNotification("Generating Markdown file...")
      quarto::quarto_render(input = here::here("local_emissions_end.qmd"),
                            output_file = sprintf("%s_%s.md", today, output_file_name),
                            output_format = "markdown",
                            execute_params = list(
                              sel_aqMet = input$sel_aqMet,
                              pollutant = input$pollutant,
                              ice = input$ice,
                              location = input$location,
                              issuedate = input$issuedate,
                              customMessage = input$customMessage,
                              # customMessageBanArea = input$customMessageBanArea,
                              outputFormat = "markdown"),
                            debug = FALSE)
      
      showNotification("Generating PDF file...")
      quarto::quarto_render(input = here::here("local_emissions_end.qmd"),
                            output_file = sprintf("%s_%s.pdf", today, output_file_name),
                            output_format = "pdf",
                            execute_params = list(
                              sel_aqMet = input$sel_aqMet,
                              pollutant = input$pollutant,
                              ice = input$ice,
                              location = input$location,
                              issuedate = input$issuedate,
                              customMessage = input$customMessage,
                              # customMessageBanArea = input$customMessageBanArea,
                              outputFormat = "pdf"),
                            debug = FALSE)
    }
    
    # move the .md and .pdf to outputs/
    # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub directory
    markdown_output_file <- list.files(pattern = sprintf("%s_%s.md", today, output_file_name), full.names = TRUE)
    fs::file_move(path = paste0(markdown_output_file), new_path = here::here("outputs"))
    
    pdf_output_file <- list.files(pattern = sprintf("%s_%s.pdf", today, output_file_name), full.names = TRUE)
    fs::file_move(path = paste0(pdf_output_file), new_path = here::here("outputs"))
    
    showNotification("File generation complete!", duration = NULL)
  })
  
  # Download files
  output$download_report <- downloadHandler(
    
    filename = function() {
      # Set output file name
      sprintf("%s_local_emissions.zip", today)
    },
    content = function(file) {
      # find files with today's date; "*" allows multiple locations to be included in one zip file
      files_to_zip <- list.files(
        path = here::here("outputs"),
        pattern = paste0("^", today, ".*\\.(pdf|md)$"),
        full.names = TRUE
      )
      
      # Zip the files into the download target
      zip::zip(zipfile = file,
               files = files_to_zip,
               mode = "cherry-pick")
    },
    contentType = "application/zip"
  )
  
  # Clean up directories
  observeEvent(input$cleanupdir, {
    output_files <- dir(path = here::here("outputs"), full.names = TRUE)
    temp_files <- dir(full.names = TRUE, pattern = ".png")
    
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