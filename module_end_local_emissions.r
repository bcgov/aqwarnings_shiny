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

#UI function for the "Community Warning - End" tab

endLocalEmissionsUI <- function(id) {
  ns <- NS(id)
  tabItem(tabName = "end",
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
                choices = c("", aq_mets$fullname),
              ),
              
              # Date the warning was first issued
              dateInput(
                inputId = ns("issuedate"),
                label = h4("Date warning was first issued:"),
                max = Sys.Date(),
                value = Sys.Date() -1,
                startview = "month",
                weekstart = 0,
              ),
              
              # Pollutant selection
              radioButtons(
                inputId = ns("pollutant"),
                label = h4("Pollutant:"),
                selected = "PM25",
                choices = c("PM25", "PM10", "O3", "PM25 & PM10"),
                inline = TRUE
              ),
              
              # -------------------------------
              # Burn restriction information
              # Shown/hidden field dynamically based on burn restriction status
              # -------------------------------
              
              box(
                # Width intentionally left unset so the box spans the available app width
                width = NULL,
                
                # Background colour set to match the overall app theme
                background = "light-blue",
                
                # Burn prohibition status
                radioButtons(
                  inputId = ns("burnRestrictionStatus"),
                  label = h4("Burn prohibition was:"),
                  choices = list(
                    "not issued" = 0, 
                    "issued but ends with this warning" = 1,
                    "issued and remains in effect beyond this warning" = 2),
                  selected = 0,
                  width = "100%"
                ),
                
                # Statutory Decision Maker
                # Only relevant when restriction remains in effect
                shinyjs::hidden(
                  radioButtons(
                  inputId = ns("burnRestrictionSDM"),
                  label = h4("Statuatory decision maker:"),
                  choices = c(
                    "Ben" = 1
                    #"TBD" = 2
                    ),
                  selected = NULL,
                  width = "100%",
                  inline = TRUE
                )
                ),
                
                # Textbox to describe the burn prohibition area
                shinyjs::hidden(
                  textAreaInput(
                    inputId = ns("burnRestrictionArea"),
                    label = HTML("<h4>Burn prohibition details:</h4><h5>The Director has prohibited open burning within</h5>"),
                    value = "<location>",
                    width = "100%",
                    height = "80px",
                    resize = "vertical"
                  )
                ),
                
                # End date and time of burn restriction
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
                ) # end splitLayout
                ), # end burn restriction box
              
              # Optional custom message included in warning text
              textAreaInput(
                inputId = ns("customMessage"),
                label = h4("Custom message (optional): retain, edit or delete"),
                value = "Local air quality has improved due to changing meteorological conditions.",
                height = "80px",
                resize = "vertical"
              ),
              
              # -------------------------------
              # Section 2: Affected location
              # -------------------------------
              
              tags$div(style = "margin-top: 40px;"), # Adds vertical space
              h4(tags$b("2. Affected location")),
              
              # Location selection
              selectInput(
                inputId = ns("location"),
                label = h4("Location:"),
                selected = "",
                choices = c("", match_health_city$location),
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
              
              # Utility button to clean working directories
              hr(),
              actionButton(
                inputId = ns("cleanupdir"),
                label = "clean dir"
              )
              
            ) # end main box
          ) # end fluidRow
          ) # end tabItem
} 

#--------------------------------------------------
# Server
#--------------------------------------------------

# Server logic for the "Community Warning - End" tab

endLocalEmissions <- function(input, output, session){
  
  # -------------------------------
  # Conditional UI logic
  # -------------------------------
  
  # Hide burn restriction section when pollutant is O3
    observeEvent(input$pollutant, {
    if (input$pollutant == "O3") {
      shinyjs::hide("burnRestrictionStatus") 
    } else {
      shinyjs::show("burnRestrictionStatus")
    }
  })
  
  # Show additional burn restriction fields only when
  # restriction remains in effect beyond this warning
  observeEvent(input$burnRestrictionStatus, {
    if (input$burnRestrictionStatus == 2) {
      
      shinyjs::showElement("burnRestrictionSDM")
      shinyjs::showElement("burnRestrictionArea")
      shinyjs::showElement("burnRestrictionEndDate")
      shinyjs::showElement("burnRestrictionEndTime")
    
      } else {
    
      shinyjs::hideElement("burnRestrictionSDM")
      shinyjs::hideElement("burnRestrictionArea")
      shinyjs::hideElement("burnRestrictionEndDate")
      shinyjs::hideElement("burnRestrictionEndTime")
    
      }
  })
  
  # Reset burn restriction fields when pollutant changes
  
  observeEvent(input$pollutant, {
    
    updateRadioButtons(
      session,
      inputId = "burnRestrictionStatus",
      selected = 0
    )

    updateRadioButtons(
      session,
      inputId = "burnRestrictionSDM",
      selected = NULL
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
  
  # --------------------------------------------------
  # Generate Markdown + PDF warning
  # --------------------------------------------------
  
  observeEvent(input$genWarning, {
    
    # Input validation
    if (input$aqMet == "") {
      showNotification("No author selected; please select an author.", type = "error")
    } else if (length(input$pollutant) == "") {
      showNotification("No pollutant selected; please select a pollutant", type = "error")
    } else if (input$location == "") {
      showNotification("No location selected; please select a location", type = "error")
    } else {
      
      # Progress indicator
      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Preparing files...", value = 0)
      
      # Clean strings for safe filenames
      location_clean <- gsub("\\s+", "_", input$location)
      pollutant_clean <- tolower(gsub(" ", "", gsub("&", "_", input$pollutant)))
      
      # Set output file name
      if (input$burnRestrictionStatus == 0) {  # no burn restriction
        output_file_name <- sprintf("%s_%s_%s", location_clean, "end", pollutant_clean) 
      } else if(input$burnRestrictionStatus == 1) { # warning and open burn restrictions both
        output_file_name <- sprintf("%s_%s_%s_%s", location_clean, "end", pollutant_clean, "and_obr") 
      } else {
        output_file_name <- sprintf("%s_%s_%s_%s", location_clean, "end", pollutant_clean, "obr_in_effect") 
      }
      
      # -------------------------------
      # Markdown output
      # -------------------------------
      progress$inc(amount = 0.3, message = "Generating Markdown file...", detail = "Step 1 of 2")
      quarto::quarto_render(input = here::here("local_emissions_end.qmd"),
                            output_file = sprintf("%s_%s.md", Sys.Date(), output_file_name),
                            output_format = "markdown",
                            execute_params = list(
                              aqMet = input$aqMet,
                              pollutant = input$pollutant,
                              location = input$location,
                              burnRestrictionStatus = input$burnRestrictionStatus,
                              burnRestrictionSDM = input$burnRestrictionSDM,
                              burnRestrictionArea = input$burnRestrictionArea,
                              burnRestrictionEndDate = input$burnRestrictionEndDate,
                              burnRestrictionEndTime = input$burnRestrictionEndTime,
                              issuedate = input$issuedate,
                              customMessage = input$customMessage,
                              outputFormat = "markdown"),
                            debug = FALSE)
      
      # Relocate the .md file to outputs/ directory
      # quarto_render() plays nice if output is written to main directory, fails if output is written to a sub directory
      markdown_output_file <- list.files(pattern = sprintf("%s_%s.md", Sys.Date(), output_file_name), full.names = TRUE)
      fs::file_move(path = paste0(markdown_output_file), new_path = here::here("outputs"))
      
      # -------------------------------
      # PDF output
      # -------------------------------
      progress$inc(amount = 0.5, message = "Generating PDF file...", detail = "Step 2 of 2")
      quarto::quarto_render(input = here::here("local_emissions_end.qmd"),
                            output_file = sprintf("%s_%s.pdf", Sys.Date(), output_file_name),
                            output_format = "pdf",
                            execute_params = list(
                              aqMet = input$aqMet,
                              pollutant = input$pollutant,
                              location = input$location,
                              burnRestrictionStatus = input$burnRestrictionStatus,
                              burnRestrictionSDM = input$burnRestrictionSDM,
                              burnRestrictionArea = input$burnRestrictionArea,
                              burnRestrictionEndDate = input$burnRestrictionEndDate,
                              burnRestrictionEndTime = input$burnRestrictionEndTime,
                              issuedate = input$issuedate,
                              customMessage = input$customMessage,
                              outputFormat = "pdf"),
                            debug = FALSE)
    
    # Relocate the .pdf to outputs/ directory
    # to keep it consistent with the Markdown files
    pdf_output_file <- list.files(pattern = sprintf("%s_%s.pdf", Sys.Date(), output_file_name), full.names = TRUE)
    fs::file_move(path = paste0(pdf_output_file), new_path = here::here("outputs"))
    
    progress$inc(amount = 1, message = "Processing complete.", detail = " Files are ready for downloading.") 
    Sys.sleep(5)
    
    } # end else
  }) # end observeEvent
  
  # --------------------------------------------------
  # Download handler: zip all outputs
  # --------------------------------------------------
  output$download_report <- downloadHandler(
    
     filename = function() {
      # Set output file name
      sprintf("%s_local_emissions.zip", Sys.Date())
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
  
  # --------------------------------------------------
  # Cleanup directory
  # --------------------------------------------------
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