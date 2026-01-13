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

## Module: end Air Quality Warning - Wildfire Smoke

library(shiny)
library(shinydashboard)
library(zip)
library(dplyr)

#--------------------------------------------------
# UI
#--------------------------------------------------

endWildfireSmokeUI <- function(id) {
  ns <- NS(id)
  tabItem(tabName = "end",
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

        dateInput(inputId = ns("lastWarning"),
          label = h4("Date warning was last issued:"),
          max = Sys.Date(),
          value = Sys.Date()-1,
          startview = "month",
          weekstart = 0
        ),

        textAreaInput(inputId = ns("customMessage"),
          label = h4("Custom message:"),
          value = "Wildfire smoke concentrations have reduced over the past 24 hours.",
          placeholder = "(example) Wildfire smoke concentrations have reduced over the past 24 hours.",
          height = "80px",
          resize = "vertical"
        ),

        checkboxGroupInput(
          inputId = ns("healthAuth"),
          label = h4("Health Authorities included on last warning (select all that apply; FNHA is automatically selected):"),
          choices = unique(health_contact$authority)[unique(health_contact$authority) != "First Nations Health Authority"],   #exclude FNHA as a choice - exists on all bulletins
        ),
        
        tags$div(style = "margin-top: 40px;"),  # Adds vertical space
        
        h4(tags$b("2. Affected location")),
        
        ## for warninig table on website
        radioButtons(
          inputId = ns("regions"),
          label = h4("Describe affected location(s):"),
          selected = "Multiple regions in B.C.",
          choices = c("Multiple regions in B.C.", "Southeast B.C.", "Central Interior", "Cariboo", "Northeast B.C.", "Northwest B.C.")
        ),
        
        tags$div(style = "margin-top: 40px;"),  # Adds vertical space
        
        h4(tags$b("3. Generate Warning")),
        actionButton(
          inputId = ns("genWarning"),
          label = "Go!",
          style = "width: 100%; color: #fff; background-color: #3c8dbc; border-color: #2e6da4;"
        ),
       
       hr(),
       ## Add the download button here:
       downloadButton(ns("download_report"), "Download Files", style = "font: 16pt"),

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

endWildfireSmoke <- function(input, output, session){
  
  # Generate warning
  observeEvent(input$genWarning, {
    
    if (input$aqMet == "") {
      showNotification("No author selected; please select an author.", type = "error")
    } else if (length(input$healthAuth) == 0) {
      showNotification("No health authority selected; please select a health authority", type = "error")
    } else if (input$location == "") {
      showNotification("No location description provided; please select or type a location description.", type = "error")
    } else {
      
      # create progress object; ensure it closes when reactive exits
      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Preparing files...", value = 0)
      
      endBasename <- "wildfire_smoke_end"

      # generate markdown via Quarto
      progress$inc(amount = 0.3, message = "Generating Markdown file...", detail = "Step 1 of 2")
      quarto::quarto_render(input = sprintf(here::here("%s.qmd"), endBasename),
                            output_file = sprintf("%s_%s.md", Sys.Date(), endBasename),
                            output_format = "markdown",
                            execute_params = list(aqMet = input$aqMet,
                                                  lastWarning = input$lastWarning,
                                                  customMessage = input$customMessage,
                                                  healthAuth = input$healthAuth,
                                                  location = input$location,
                                                  outputFormat = "markdown"),
                            debug = FALSE)
      
      # move the .md to outputs/
      # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub directory
      markdown_output_file <- list.files(pattern = sprintf("%s_%s.md", Sys.Date(), endBasename), full.names = TRUE)
      fs::file_move(path = paste0(markdown_output_file), new_path = here::here("outputs"))
      
      # generate pdf via Quarto
      progress$inc(amount = 0.5, message = "Generating PDF file...", detail = "Step 2 of 2")
      quarto::quarto_render(input = sprintf(here::here("%s.qmd"), endBasename),
                            output_file = sprintf("%s_%s.pdf", Sys.Date(), endBasename),
                            output_format = "pdf",
                            execute_params = list(aqMet = input$aqMet,
                                                  lastWarning = input$lastWarning,
                                                  customMessage = input$customMessage,
                                                  healthAuth = input$healthAuth,
                                                  location = input$location,
                                                  outputFormat = "pdf"),
                            debug = FALSE)
  
      
      # move the .pdf to outputs/
      # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub directory
      pdf_output_file <- list.files(pattern = sprintf("%s_%s.pdf", Sys.Date(), endBasename), full.names = TRUE)
      fs::file_move(path = paste0(pdf_output_file), new_path = here::here("outputs"))
      
      progress$inc(amount = 1, message = "Processing complete.", detail = " Files are ready for downloading.") 
      Sys.sleep(5)
      
    } #end else
  }) #end observeEvent
  
  # Download files
  output$download_report <- downloadHandler(
    filename = function() {
      sprintf("%s_wildfire_smoke_end.zip", Sys.Date())
    },
    content = function(file) {
      # Build file paths correctly using sprintf()
      files_to_zip <- c(file.path("outputs", sprintf(
        "%s_wildfire_smoke_end.md", Sys.Date()
      )),
      file.path("outputs", sprintf(
        "%s_wildfire_smoke_end.pdf", Sys.Date()
      )))
      
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
