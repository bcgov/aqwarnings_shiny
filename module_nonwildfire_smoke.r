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

## Module: issue Air Quality Warning - Non Wildfire Smoke

library(shiny)
library(shinydashboard)
library(zip)
library(dplyr)

source(here::here("load_metadata.r"))

#--------------------------------------------------
# UI
#--------------------------------------------------

nonWildfireSmokeUI <- function(id) {
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
                choices = c("", "Issue", "Continue", "End"),
                width = "50%"
              ),
              selectInput(
                inputId = ns("pollutant"),
                label = h5("Pollutant:"),
                selected = "",
                choices = c("", "PM25", "PM10", "O3"),
                width = "50%"
              ),
              selectInput(
                inputId = ns("station"),
                label = h5("Station:"),
                selected = "",
                choices = c("", Health_Authority$Station),
                width = "50%"
              ),
              selectInput(
                inputId = ns("burnRestrictions"),
                label = h5("Burn Restrictions:"),
                selected = "No",
                choices = c("No", "Yes - Arvind", "Yes - Ben"),
                width = "50%"
              ),
              
              dateInput(inputId = ns("issuedate"),
                        label = h5("Date last warning was issued:"),
                        max = Sys.Date(),
                        value = Sys.Date() -1,
                        startview = "month",
                        weekstart = 0,
                        width = "50%"
              ),
              
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

nonWildfireSmoke <- function(input, output, session){
  
  completeNotificationIDs <- character(0)
  today <- format(Sys.Date(), "%Y-%m-%d")

  # Generate report: markdown and pdf
  observeEvent(input$genWarning, {
    
    if (input$sel_aqMet == "") {
      showNotification("No author selected; please select an author.", type = "error")
    } else if (length(input$ice) == "") {
      showNotification("No advisory status selected; please select a status", type = "error")
    } else if (length(input$pollutant) == "") {
      showNotification("No pollutant selected; please select a pollutant", type = "error")
    } else if (input$station == "") {
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
      
      qmd_file <- if (input$ice == "End") "non-wildfire_smoke_end.qmd" else "non-wildfire_smoke_issue.qmd"
      
      # Clean station name for file name
      station_clean <- gsub("\\s+", "_", input$station)
      
      # Set output file name
      output_file_name <- sprintf("%s_non-wildfire_smoke_%s_%s_%s", today, input$ice, input$pollutant, station_clean)
      
      # generate warning: markdown and pdf formats
      showNotification("Generating Markdown file...")
      quarto::quarto_render(input = here::here(qmd_file),
                            output_file = sprintf("%s_%s.md", today, output_file_name),
                            output_format = "markdown",
                            execute_params = list(
                              sel_aqMet = input$sel_aqMet,
                              pollutant = input$pollutant,
                              ice = input$ice,
                              station = input$station,
                              burnRestrictions = input$burnRestrictions,
                              issuedate = input$issuedate,
                              outputFormat = "markdown"),
                            debug = FALSE)
      
      showNotification("Generating PDF file...")
      quarto::quarto_render(input = here::here(qmd_file),
                            output_file = sprintf("%s_%s.pdf", today, output_file_name),
                            output_format = "pdf",
                            execute_params = list(
                              sel_aqMet = input$sel_aqMet,
                              pollutant = input$pollutant,
                              ice = input$ice,
                              station = input$station,
                              burnRestrictions = input$burnRestrictions,
                              issuedate = input$issuedate,
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
      sprintf("%s_non-wildfire_smoke.zip", today)
    },
    content = function(file) {
      # Build file paths correctly using sprintf()
      files_to_zip <- list.files(
        path = here::here("outputs"),
        pattern = "non-wildfire_smoke",
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


## For testing the standalone app

# ui <- dashboardPage(
#   dashboardHeader(title = "Non-Wildfire Smoke Advisory"),
#   dashboardSidebar(
#     sidebarMenu(
#       menuItem("End", tabName = "end", icon = icon("exclamation-triangle"))
#     )
#   ),
#   dashboardBody(
#     tabItems(
#       nonWildfireSmokeUI("nonWildfireSmoke")  # call your module UI here inside tabItems
#     )
#   )
# )
# 
# server <- function(input, output, session) {
#   moduleServer("nonWildfireSmoke", nonWildfireSmoke)
# }
# 
# shinyApp(ui, server)