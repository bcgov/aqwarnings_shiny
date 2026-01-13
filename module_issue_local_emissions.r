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

#--------------------------------------------------
# UI
#--------------------------------------------------

issueLocalEmissionsUI <- function(id) {
  ns <- NS(id)
  tabItem(tabName = "issue",
          fluidRow(
            box(
              width = 3,
              status = "primary",
              
              h4(tags$b("1. Complete the fields below")),
              
              selectInput(
                inputId = ns("aqMet"),
                label = h4("Author:"),
                selected = "",
                choices = c("", aq_mets$fullname)
              ),
              
              radioButtons(
                inputId = ns("ice"),
                label = h4("Issue Type:"),
                choices = list("Issue", "Continue"),
                selected = "Issue",
                inline = TRUE
              ),
              
              shinyjs::hidden(
                dateInput(
                  inputId = ns("issuedate"),
                  label = h4("Date warning was first issued:"),
                  max = Sys.Date(),
                  value = Sys.Date() - 1,
                  startview = "month",
                  weekstart = 0,
                )
              ),
              
              radioButtons(
                inputId = ns("pollutant"),
                label = h4("Pollutant:"),
                selected = "PM25",
                choices = c("PM25", "PM10", "O3", "PM25 & PM10"),
                inline = TRUE
              ),
              
              box(
                width = NULL,
                background = "light-blue",
                
                radioButtons(
                  inputId = ns("burnRestrictions"),
                  label = h4("Burn prohibition issued:"),
                  choices = list(
                    "No" = 0, 
                    "Yes (Ben)" = 1
                    #"Yes (Arvind)" = 2
                    ),
                  selected = 0,
                  inline = TRUE
                ),
                
                shinyjs::hidden(
                  textAreaInput(
                    inputId = ns("burnRestrictionArea"),
                    label = HTML("<h4>Burn prohibition details:<br><br> The Director has prohibited open burning within</h4>"),
                    value = "<location>",
                    height = "40px",
                    resize = "vertical"
                  )
                ),
                
                splitLayout(
                  cellWidths = c("50%", "50%"),
                  shinyjs::hidden(
                    dateInput(
                      inputId = ns("burnRestrictionEndDate"),
                      startview = "month",
                      weekstart = 0,
                      label = h5("until"),
                      value = Sys.Date() + 1,
                      min = Sys.Date(),
                      width = "75%"
                    )
                  ),
                  
                  shinyjs::hidden(
                    textInput(
                      inputId = ns("burnRestrictionEndTime"), 
                      label = h5("HH:00 AM/PM"),
                      value = "HH:00 AM",
                      width = "75%"
                    )
                  )
                ) # splitLayout
              ), # box
              
              
              textAreaInput(
                inputId = ns("customMessage"),
                label = h4("Custom message (optional): retain, edit or delete"),
                value = "Current conditions are expected to persist until weather conditions change and/or local emissions are reduced.",
                height = "80px",
                resize = "vertical"),
              
              dateInput(
                inputId = ns("nextUpdate"),
                label = h4("Next update:"),
                max = Sys.Date() + 7,
                value = Sys.Date() + 1,
                startview = "month",
                weekstart = 0,
              ),
              
              tags$div(style = "margin-top: 40px;"),  # Adds vertical space
              h4(tags$b("2. Affected location")),
              
              
              selectInput(
                inputId = ns("location"),
                label = h4("Location:"),
                selected = "",
                choices = c("", match_health_city$location),
              ),
              
              tags$div(style = "margin-top: 40px;"),  # Adds vertical space
              h4(tags$b("3. Generate Warning")),
              
              actionButton(
          inputId = ns("genWarning"),
          label = "Go!",
          style = "width: 100%; color: #fff; background-color: #3c8dbc; border-color: #2e6da4;"
        ),
              
              hr(),
              
              downloadButton(ns("download_report"), "Download Files", style = "font: 16pt"),
              
              hr(),
              actionButton(
                inputId = ns("cleanupdir"),
                label = "clean dir"
              )
            )
          ) #fluidRow
  ) # tabItem
} 

#--------------------------------------------------
# Server
#--------------------------------------------------

issueLocalEmissions <- function(input, output, session){
  
  # show/hide conditional inputs
  observeEvent(input$pollutant, {
    if (input$pollutant == "O3") {
      shinyjs::hide("burnRestrictions") 
    } else {
      shinyjs::show("burnRestrictions")
    }
  })
  
  observeEvent(input$burnRestrictions, {
    if (input$burnRestrictions > 0) {
      shinyjs::show("burnRestrictionArea")
      shinyjs::show("burnRestrictionEndDate")
      shinyjs::show("burnRestrictionEndTime")
    } else {
      shinyjs::hide("burnRestrictionArea")
      shinyjs::hide("burnRestrictionEndDate")
      shinyjs::hide("burnRestrictionEndTime")
      }
  })
  
  observeEvent(input$ice, {
    if (input$ice == "Continue") {
      shinyjs::show("issuedate") 
    } else {
      shinyjs::hide("issuedate")
    }
  })
  
  # reset burn restriction info when pollutant changed; action button but didn't seem to work? Consider uiOuput to streamline?
  observeEvent(input$pollutant, {
    
    updateRadioButtons(
      session,
      inputId = "burnRestrictions",
      selected = 0
    )
    
    updateTextAreaInput(
      session,
      inputId = "burnRestrictionArea",
      value = "<location>"
    )
    
    updateDateInput(
      session,
      inputId = "burnRestrictionEndDate",
      value = Sys.Date() + 1
    )
    
    updateTextInput(
      session,
      inputId = "burnRestrictionEndTime",
      value = "HH:00 PM"
      )
    
  })
  
  # Generate report: markdown and pdf
  observeEvent(input$genWarning, {
    
    if (input$aqMet == "") {
      showNotification("No author selected; please select an author.", type = "error")
    } else if (length(input$ice) == "") {
      showNotification("No warning status selected; please select a status", type = "error")
    } else if (length(input$pollutant) == "") {
      showNotification("No pollutant selected; please select a pollutant", type = "error")
    } else if (input$location == "") {
      showNotification("No location selected; please select a location", type = "error")
    } else {
      
      # create progress object; ensure it closes when reactive exits
      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Preparing files...", value = 0)
      
      # Clean location name for file name
      location_clean <- gsub("\\s+", "_", input$location)
      pollutant_clean <- tolower(gsub(" ", "", gsub("&", "_", input$pollutant)))
      
      # Set output file name
      if (input$burnRestrictions < 1) {  # no burn restriction
        
        output_file_name <- sprintf("%s_%s_%s", location_clean, tolower(input$ice), pollutant_clean) 
        
      } else { # burn restriction; obr = open burning restriction
        
        output_file_name <- sprintf("%s_%s_%s_%s", location_clean, tolower(input$ice), pollutant_clean, "obr") 
        
      }
      
      # generate warning: markdown and pdf formats
      progress$inc(amount = 0.3, message = "Generating Markdown file...", detail = "Step 1 of 2")
      quarto::quarto_render(input = here::here("local_emissions_issue.qmd"),
                            output_file = sprintf("%s_%s.md", Sys.Date(), output_file_name),
                            output_format = "markdown",
                            execute_params = list(
                              aqMet = input$aqMet,
                              pollutant = input$pollutant,
                              ice = input$ice,
                              location = input$location,
                              burnRestrictions = input$burnRestrictions,
                              burnRestrictionArea = input$burnRestrictionArea,
                              burnRestrictionEndDate = input$burnRestrictionEndDate,
                              burnRestrictionEndTime = input$burnRestrictionEndTime,
                              issuedate = input$issuedate,
                              nextUpdate = input$nextUpdate,
                              customMessage = input$customMessage,
                              outputFormat = "markdown"),
                            debug = FALSE)
      
      # move the .md to outputs/
      # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub directory
      markdown_output_file <- list.files(pattern = sprintf("%s_%s.md", Sys.Date(), output_file_name), full.names = TRUE)
      fs::file_move(path = paste0(markdown_output_file), new_path = here::here("outputs"))
      
      progress$inc(amount = 0.5, message = "Generating PDF file...", detail = "Step 2 of 2")
      quarto::quarto_render(input = here::here("local_emissions_issue.qmd"),
                            output_file = sprintf("%s_%s.pdf", Sys.Date(), output_file_name),
                            output_format = "pdf",
                            execute_params = list(
                              aqMet = input$aqMet,
                              pollutant = input$pollutant,
                              ice = input$ice,
                              location = input$location,
                              burnRestrictions = input$burnRestrictions,
                              burnRestrictionArea = input$burnRestrictionArea,
                              burnRestrictionEndDate = input$burnRestrictionEndDate,
                              burnRestrictionEndTime = input$burnRestrictionEndTime,
                              issuedate = input$issuedate,
                              nextUpdate = input$nextUpdate,
                              customMessage = input$customMessage,
                              outputFormat = "pdf"),
                            debug = FALSE)
      
      # move the .pdf to outputs/
      # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub directory
      pdf_output_file <- list.files(pattern = sprintf("%s_%s.pdf", Sys.Date(), output_file_name), full.names = TRUE)
      fs::file_move(path = paste0(pdf_output_file), new_path = here::here("outputs"))
      
      progress$inc(amount = 1, message = "Processing complete.", detail = " Files are ready for downloading.") 
      Sys.sleep(5)
      
    } #else
  }) #observeEvent
  
  # Download files
  output$download_report <- downloadHandler(
    
    filename = function() {
      # Set output file name
      sprintf("%s_%s.zip", Sys.Date(), "local_emissions")
    },
    content = function(file) {
      # find files with today's date; "*" allows multiple locations to be included in one zip file
        files_to_zip <- list.files(
        path = here::here("outputs"),
        pattern = paste0("^", Sys.Date(), ".*\\.(pdf|md)$"),
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