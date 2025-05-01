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

        dateInput(inputId = ns("lastWarning"),
          label = h5("Date last warning was issued:"),
          max = Sys.Date(),
          value = Sys.Date() -1,
          startview = "month",
          weekstart = 0,
          width = "50%"
        ),

        textAreaInput(inputId = ns("customMessage"),
          label = h5("Custom message:"),
          value = "Wildfire smoke concentrations have reduced over the past 24 hours.",
          placeholder = "(example) Wildfire smoke concentrations have reduced over the past 24 hours.",
          width = "100%",
          height = "100%",
          resize = "vertical"
        ),

        checkboxGroupInput(
          inputId = ns("sel_healthAuth"),
          label = h5("Health Authorities included on last warning (select all that apply; FNHA is automatically selected):"),
          choices = unique(health_contact$authority)[unique(health_contact$authority) != "First Nations Health Authority"],   #exclude FNHA as a choice - exists on all bulletins
          width = "100%"
        ),
        
        h5("2. Select or create summary description of affected regions (for AQ Warnings Table)."),
        
        selectizeInput(
          inputId = ns("location"),
          label = h5("Describe regions affected:"),
          selected = "",
          choices = c("", "Southeast B.C.", "Central Interior", "Cariboo", "Northeast B.C.", "Northwest B.C.", "Multiple regions in B.C." ),
          width = "100%",
          options = list(create = TRUE)
        ),
        

       h5("3. Generate Warning:"),
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

endWildfireSmoke <- function(input, output, session){

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
  
  # Compile LaTeX report and save as .pdf:
  observeEvent(input$genWarning, {

    if (input$sel_aqMet == "") {
      showNotification("No author selected; please select an author.", type = "error")
    } else if (length(input$sel_healthAuth) == 0) {
      showNotification("No health authority selected; please select a health authority", type = "error")
    } else {

      currentDate <- Sys.Date()
      endBasename <- "wildfire_smoke_end"

      # PDF
      showNotification("Generating PDF...")
      knitr::knit2pdf(sprintf(here::here("src", "rnw", "%s.rnw"), endBasename), clean = TRUE,
                      output = sprintf(here::here("outputs", "rnw", "%s_%s.tex"), currentDate, endBasename))

      showNotification("PDF generation complete!", duration = NULL)
      
      # Quarto
      showNotification("Generating Markdown...")

      quarto::quarto_render(input = sprintf(here::here("%s.qmd"), endBasename),
                            output_format = "markdown",
                            output_file = sprintf("%s_%s.md", currentDate, endBasename),
                            execute_params = list(sel_aqMet = input$sel_aqMet,
                                                  lastWarning = input$lastWarning,
                                                  customMessage = input$customMessage,
                                                  sel_healthAuth = input$sel_healthAuth,
                                                  ice = "End",
                                                  location = input$location),
                            debug = FALSE)
      
      id <- showNotification("Markdown generation complete!", duration = NULL)
      
      markdown_output_file <- list.files(pattern = sprintf("%s_%s.md", currentDate, endBasename), full.names = TRUE)
      fs::file_move(path = paste0(markdown_output_file), new_path = here::here("outputs", "qmd"))
      
      id <- showNotification("Markdown file moved to outputs/qmd directory.")
    }
  })
  ## Download files
  
  output$download_report <- downloadHandler(
    filename = function() {
      sprintf("%s_wildfire_smoke_end.zip", Sys.Date())
    },
    content = function(file) {
      # Build file paths correctly using sprintf()
      files_to_zip <- c(
        file.path("outputs", "qmd", sprintf("%s_wildfire_smoke_end.md", Sys.Date())),
        file.path("outputs", "rnw", sprintf("%s_wildfire_smoke_end.pdf", Sys.Date()))
      )
      
      # Zip the files into the download target
      zip::zip(zipfile = file, files = files_to_zip, mode = "cherry-pick")
    },
    contentType = "application/zip"
  )
  
}
