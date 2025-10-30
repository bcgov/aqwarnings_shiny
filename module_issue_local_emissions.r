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

issueLocalEmissionsUI <- function(id) {
  ns <- NS(id)
  tabItem(tabName = "end",
          shinyjs::useShinyjs(),
          fluidRow(
            box(
              width = 6,
              status = "primary",
              
              h4(tags$b("1. Complete fields below")),
              
              selectInput(
                inputId = ns("sel_aqMet"),
                label = h4("Author:"),
                selected = "",
                choices = c("", aq_mets$fullname),
                width = "50%"
              ),
              
              radioButtons(
                inputId = ns("ice"),
                label = h4("Issue Type:"),
                choices = list("Issue", "Continue"),
                selected = "Issue",
                width = "50%",
                inline = TRUE
              ),
              
              shinyjs::hidden(
                dateInput(inputId = ns("issuedate"),
                          label = h4("Date warning was first issued:"),
                          max = today,
                          value = today - 1,
                          startview = "month",
                          weekstart = 0,
                          width = "50%"
                )
              ),
              
              selectInput(
                inputId = ns("pollutant"),
                label = h4("Pollutant:"),
                selected = "",
                choices = c("", "PM25", "PM10", "O3", "PM25 & PM10"),
                width = "50%"
              ),
              
              selectInput(
                inputId = ns("location"),
                label = h4("Location:"),
                selected = "",
                choices = c("", match_health_city$location),
                width = "50%"
              ),
              
              radioButtons(
                inputId = ns("burnRestrictions"),
                label = h4("Burn prohibition issued:"),
                choices = list(
                  "No" = 1, 
                  "Yes (Ben)" = 2,
                  "Yes (Arvind)" = 3),
                selected = 1,
                width = "50%",
                inline = TRUE
              ),
              
              shinyjs::hidden(
                textAreaInput(inputId = ns("customMessageBanArea"),
                              label = h4("Burn prohibition details: location and end date/time"),
                              value = "<location> until <mmmm, dd, yyyy hh:mm AM/PM> local time.",
                              width = "100%",
                              height = "80px",
                              resize = "vertical"
                )
              ),
              
              dateInput(inputId = ns("nextUpdate"),
                        label = h4("Date of next update: "),
                        max = today + 7,
                        value = today + 1,
                        startview = "month",
                        weekstart = 0,
                        width = "50%"
              ),
              
              helpText("Add an optional custom message below. The default message can be retained, edited or deleted."),
              
              textAreaInput(inputId = ns("customMessage"),
                            label = h4("Custom outlook message:"),
                            value = "Current conditions are expected to persist until weather conditions change and/or local emissions are reduced.",
                            width = "100%",
                            height = "80px",
                            resize = "vertical"),
              
              h4(tags$b("2. Generate Warning")),
              actionButton(
                inputId = ns("genWarning"),
                label = "Go!",
                style = "width: 50%; color: #fff; background-color: #337ab7; border-color: #2e6da4;"
              ),
              
              hr(),
              
              downloadButton(ns("download_report"), "Download Files", style = "width: 50%; font: 16pt"),
              
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

issueLocalEmissions <- function(input, output, session){
  
  observeEvent(input$burnRestrictions, {
    if (input$burnRestrictions > 1) {
      shinyjs::show("customMessageBanArea") 
    } else {
      shinyjs::hide("customMessageBanArea")
      }
  })
  
  observeEvent(input$ice, {
    if (input$ice == "Continue") {
      shinyjs::show("issuedate") 
    } else {
      shinyjs::hide("issuedate")
    }
  })
  
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

      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Preparing files...", value = 0)
    
      # Clean location name for file name
      location_clean <- gsub("\\s+", "_", input$location)
      
      # Set output file name
      output_file_name <- sprintf("%s_%s_%s", input$ice, input$pollutant, location_clean)
      
      # generate warning: markdown and pdf formats
      progress$inc(amount = 0.3, message = "Generating Markdown file...", detail = "Step 1 of 2")
      quarto::quarto_render(input = here::here("local_emissions_issue.qmd"),
                            output_file = sprintf("%s_%s.md", as.character(today), output_file_name),
                            output_format = "markdown",
                            execute_params = list(
                              sel_aqMet = input$sel_aqMet,
                              pollutant = input$pollutant,
                              ice = input$ice,
                              location = input$location,
                              burnRestrictions = input$burnRestrictions,
                              issuedate = input$issuedate,
                              nextUpdate = input$nextUpdate,
                              customMessage = input$customMessage,
                              customMessageBanArea = input$customMessageBanArea,
                              outputFormat = "markdown"),
                            debug = FALSE)
      
      progress$inc(amount = 0.5, message = "Generating PDF file...", detail = "Step 2 of 2")
      quarto::quarto_render(input = here::here("local_emissions_issue.qmd"),
                            output_file = sprintf("%s_%s.pdf", as.character(today), output_file_name),
                            output_format = "pdf",
                            execute_params = list(
                              sel_aqMet = input$sel_aqMet,
                              pollutant = input$pollutant,
                              ice = input$ice,
                              location = input$location,
                              burnRestrictions = input$burnRestrictions,
                              issuedate = input$issuedate,
                              nextUpdate = input$nextUpdate,
                              customMessage = input$customMessage,
                              customMessageBanArea = input$customMessageBanArea,
                              outputFormat = "pdf"),
                            debug = FALSE)
    }
    
    # move the .md and .pdf to outputs/
    # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub directory
    markdown_output_file <- list.files(pattern = sprintf("%s_%s.md", as.character(today), output_file_name), full.names = TRUE)
    fs::file_move(path = paste0(markdown_output_file), new_path = here::here("outputs"))
    
    pdf_output_file <- list.files(pattern = sprintf("%s_%s.pdf", as.character(today), output_file_name), full.names = TRUE)
    fs::file_move(path = paste0(pdf_output_file), new_path = here::here("outputs"))
    
    progress$inc(amount = 1, message = "Processing complete.", detail = " Files are ready for downloading.") 
    Sys.sleep(5)
  })
  
  # Download files
  output$download_report <- downloadHandler(
    
    filename = function() {
      # Set output file name
      sprintf("%s_%s.zip", as.character(today), "local_emissions")
    },
    content = function(file) {
      # find files with today's date; "*" allows multiple locations to be included in one zip file
        files_to_zip <- list.files(
        path = here::here("outputs"),
        pattern = paste0("^", as.character(today), ".*\\.(pdf|md)$"),
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