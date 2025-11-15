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

endPollutionPreventionUI <- function(id) {
  ns <- NS(id)
  tabItem(tabName = "end",
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
              
              selectInput(
                inputId = ns("nearestMonitor"),
                label = h4("Nearest Monitor:"),
                selected = "",
                choices = c("", match_health_city$location),
                width = "50%"
              ),
              
              textAreaInput(
                inputId = ns("burnRestrictionArea"),
                label = HTML("<h4>Burn prohibition details:<br><br> Open burning was prohibited within</h4>"),
                value = "<location>",
                width = "100%",
                height = "40px",
                resize = "vertical"
              ),

              dateInput(
                inputId = ns("issuedate"),
                label = h4("Date Pollution Prevention Notice was first issued:"),
                max = Sys.Date(),
                value = Sys.Date() -1,
                startview = "month",
                weekstart = 0,
                width = "50%"
              ),
              
              textAreaInput(
                inputId = ns("customMessage"),
                label = h4("Custom message (optional): retain, edit or delete"),
                value = "Local air quality has improved due to changing meteorological conditions.",
                width = "75%",
                height = "80px",
                resize = "vertical"
              ),
              
              tags$div(style = "margin-top: 40px;"),  # Adds vertical space
              h4(tags$b("2. Generate Pollution Prevention Notice")),
              
                actionButton(
                  inputId = ns("genNotice"),
                  label = "Go!",
                  style = "width: 50%; color: #fff; background-color: #337ab7; border-color: #2e6da4;"
                ),
 
              hr(),
              
              ## Add the download button here:
              downloadButton(ns("download_report"), "Download Files", style = "width: 50%"),
              
              hr(),
              actionButton(
                inputId = ns("cleanupdir"),
                label = "clean dir"
              )
              
            ) # box
          ) # fluidRow
          ) # tabItem
} 

#--------------------------------------------------
# Server
#--------------------------------------------------

endPollutionPrevention <- function(input, output, session){
  
  
  # show/hide conditional inputs
   # Generate report: markdown and pdf
  observeEvent(input$genNotice, {
    
    if (input$sel_aqMet == "") {
      showNotification("No author selected; please select an author.", type = "error")
    } else if (input$nearestMonitor == "") {
      showNotification("Nearest monitor not selected; please select the nearest monitor", type = "error")
    } else {
      
      # create progress object; ensure it closes when reactive exits
      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Preparing files...", value = 0)
      
      output_file_name <- "end_pollution_prevention_notice" 

      # generate warning: markdown and pdf formats
      progress$inc(amount = 0.3, message = "Generating Markdown file...", detail = "Step 1 of 2")
      quarto::quarto_render(input = here::here("pollution_prevention_end.qmd"),
                            output_file = sprintf("%s_%s.md", Sys.Date(), output_file_name),
                            output_format = "markdown",
                            execute_params = list(
                              sel_aqMet = input$sel_aqMet,
                              nearestMonitor = input$nearestMonitor,
                              burnRestrictionArea = input$burnRestrictionArea,
                              issuedate = input$issuedate,
                              customMessage = input$customMessage,
                              outputFormat = "markdown"),
                            debug = FALSE)
      
      # move the .md to outputs/
      # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub directory
      markdown_output_file <- list.files(pattern = sprintf("%s_%s.md", Sys.Date(), output_file_name), full.names = TRUE)
      fs::file_move(path = paste0(markdown_output_file), new_path = here::here("outputs"))
      
      progress$inc(amount = 0.5, message = "Generating PDF file...", detail = "Step 2 of 2")
      quarto::quarto_render(input = here::here("pollution_prevention_end.qmd"),
                            output_file = sprintf("%s_%s.pdf", Sys.Date(), output_file_name),
                            output_format = "pdf",
                            execute_params = list(
                              sel_aqMet = input$sel_aqMet,
                              nearestMonitor = input$nearestMonitor,
                              burnRestrictionArea = input$burnRestrictionArea,
                              issuedate = input$issuedate,
                              customMessage = input$customMessage,
                              outputFormat = "pdf"),
                            debug = FALSE)
    
    # move the .pdf to outputs/
    # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub directory
    pdf_output_file <- list.files(pattern = sprintf("%s_%s.pdf", Sys.Date(), output_file_name), full.names = TRUE)
    fs::file_move(path = paste0(pdf_output_file), new_path = here::here("outputs"))
    
    progress$inc(amount = 1, message = "Processing complete.", detail = " Files are ready for downloading.") 
    Sys.sleep(5)
    
    } # end else
  }) # end observeEvent
  
  # Download files
  output$download_report <- downloadHandler(
    
     filename = function() {
      # Set output file name
      sprintf("%s_pollution_prevention.zip", Sys.Date())
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