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

issuePollutionPreventionUI <- function(id) {
  ns <- NS(id)
  tabItem(tabName = "issue",
          fluidRow(
            box(
              width = 3,
              status = "primary",
              
              h4(tags$b("1. Complete the fields belows")),
              
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
                  label = h4("Date notice was first issued:"),
                  max = Sys.Date(),
                  value = Sys.Date() - 1,
                  startview = "month",
                  weekstart = 0
                )
              ),
              
              box(
                width = NULL,
                background = "light-blue",
                
                radioButtons(
                  inputId = ns("burnRestrictions"),
                  label = h4("Burn prohibition issued:"),
                  choices = list(
                    "Yes (Ben)" = 1
                    #"Yes (TBD)" = 2
                    ),
                  selected = 1,
                  width = "100%",
                  inline = TRUE
                ),
                
                textAreaInput(
                    inputId = ns("burnRestrictionArea"),
                    label = HTML("<h4>Burn prohibition details:<br><br> The Director has prohibited open burning within</h4>"),
                    value = "<location>",
                    width = "100%",
                    height = "40px",
                    resize = "vertical"
                ),
                
                splitLayout(
                  cellWidths = c("50%", "50%"),
                  dateInput(
                      inputId = ns("burnRestrictionEndDate"),
                      startview = "month",
                      weekstart = 0,
                      label = h5("until"),
                      value = Sys.Date() + 1,
                      min = Sys.Date(),
                      width = "75%"
                    ),
                  
                  textInput(
                      inputId = ns("burnRestrictionEndTime"), 
                      label = h5("HH:00 AM/PM"),
                      value = "HH:00 AM",
                      width = "75%"
                    )
                  )# splitLayout
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
                inputId = ns("nearestMonitor"),
                label = h4("Nearest monitor:"),
                selected = "",
                choices = c("", match_health_city$location)
              ),
              
              tags$div(style = "margin-top: 40px;"),  # Adds vertical space
              h4(tags$b("3. Generate Pollution Prevention Notice")),
              
              actionButton(
                inputId = ns("genNotice"),
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
            ) # box
          ) #fluidRow
  ) # tabItem
} 

#--------------------------------------------------
# Server
#--------------------------------------------------

issuePollutionPrevention <- function(input, output, session){
  
  # show/hide conditional inputs
  observeEvent(input$ice, {
    if (input$ice == "Continue") {
      shinyjs::show("issuedate") 
    } else {
      shinyjs::hide("issuedate")
    }
  })
  
 # Generate report: markdown and pdf
  observeEvent(input$genNotice, {
    
    if (input$aqMet == "") {
      showNotification("No author selected; please select an author.", type = "error")
    } else if (length(input$ice) == "") {
      showNotification("No burn prohibition status selected; please select a status", type = "error")
    } else if (input$nearestMonitor == "") {
      showNotification("Nearest monitor not selected; please select the nearest monitor", type = "error")
    } else {
      
      # create progress object; ensure it closes when reactive exits
      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Preparing files...", value = 0)
      
      output_file_name <- sprintf("%s_%s_%s", input$nearestMonitor, tolower(input$ice), "pollution_prevention") 

      # generate warning: markdown and pdf formats
      progress$inc(amount = 0.3, message = "Generating Markdown file...", detail = "Step 1 of 2")
      quarto::quarto_render(input = here::here("pollution_prevention_issue.qmd"),
                            output_file = sprintf("%s_%s.md", Sys.Date(), output_file_name),
                            output_format = "markdown",
                            execute_params = list(
                              aqMet = input$aqMet,
                              ice = input$ice,
                              nearestMonitor = input$nearestMonitor,
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
      quarto::quarto_render(input = here::here("pollution_prevention_issue.qmd"),
                            output_file = sprintf("%s_%s.pdf", Sys.Date(), output_file_name),
                            output_format = "pdf",
                            execute_params = list(
                              aqMet = input$aqMet,
                              ice = input$ice,
                              nearestMonitor = input$nearestMonitor,
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
      sprintf("%s_%s.zip", Sys.Date(), "pollution_prevention")
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