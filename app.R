library(shiny)

# Function to generate bulletin text
generateBulletinText <- function(met, ice, pollutant, station) {
  paste(
    "Air Quality Bulletin\n",
    "====================\n",
    "AQ Meteorologist: ", met, "\n",
    "ICE Status: ", ice, "\n",
    "Pollutant: ", pollutant, "\n",
    "Station: ", station, "\n",
    "--------------------\n",
    "This bulletin is automatically generated."
  )
}

# Function to save the bulletin to a file
saveBulletin <- function(text) {
  writeLines(text, "bulletin.txt")
}

# Define UI
ui <- fluidPage(
  titlePanel("Air Quality Warning - Non-wildfire smoke"),

    sidebarPanel(
      selectInput(
        inputId = "sel_aqMet",
        label = h5("Author:"),
        selected = "",
        choices = c("", "Sakshi", "Donna", "Gail", "James",
                    "Ben", "Gavin", "Nick", "Muntaseer"),
        width = "100%"
      ),
      selectInput(
        inputId = "ice",
        label = h5("I.C.E.:"),
        selected = "",
        choices = c("", "Issue", "Continue", "End"),
        width = "100%"
      ),
      selectInput(
        inputId = "pollutant",
        label = h5("Pollutant:"),
        selected = "",
        choices = c("", "PM25", "PM10", "O3"),
        width = "100%"
      ),
      selectInput(
        inputId = "station",
        label = h5("Station:"),
        selected = "",
        choices = c("", "Burns Lake", "Castlegar", "Colwood", "Courtenay", "Cranbrook", "Duncan",
                    "Elkford", "Fort St John", "Golden", "Grand Forks", "Houston",
                    "Hudson's Hope", "Kamloops", "Kelowna", "Penticton", "Powell River",
                    "Prince George", "Quesnel", "Smithers", "Sparwood", "Squamish",
                    "Terrace", "Valemount", "Vanderhoof", "Vernon", "Whistler", "Williams Lake"),
        width = "100%"
      ),
      selectInput(
        inputId = "burnRestrictions",
        label = h5("Burn Restrictions:"),
        selected = "No",
        choices = c("No", "Yes - Arvind", "Yes - Ben"),
        width = "100%"
      ),

      dateInput(
        inputId = "issuedate",
        label = h5("Date of last issued advisory"),
        value = Sys.Date() - 1,  # Default to yesterday (still in last month)
        min = Sys.Date() - 31,
        max = Sys.Date(),
        format = "yyyy-mm-dd",
        width = "100%"
      ),


      # Generate Button
      actionButton(
        inputId = "generate",
        label = h5("Generate Bulletin"),
        class = "btn-primary",
        width = "80%"
      ),

      hr(),
      ## Add the download button here:
      downloadButton(
          outputId = "download_report",
          label = "Download Files", style = "width: 100%"))
)



# Define Server
server <- function(input, output) {

  outputText <- reactiveVal()

  observeEvent(input$generate, {
    req(input$sel_aqMet, input$ice, input$pollutant, input$station, input$burnRestrictions, input$issuedate)

    # Choose the QMD file based on ICE status
    qmd_file <- if (input$ice == "End") "End-advisory.qmd" else "Issue-advisory.qmd"

    # Format today's date
    today <- format(Sys.Date(), "%Y-%m-%d")

    # Clean station name for file name
    station_clean <- gsub("\\s+", "_", input$station)

    # Set output file name
    output_file_name <- sprintf("%s_non-wildfire_smoke_%s_%s_%s", today, input$ice, input$pollutant, station_clean)


 #   Render the selected QMD file
    quarto::quarto_render(
      input = qmd_file,
      output_format = "markdown",
      output_file = paste0(output_file_name, ".md"),
      execute_params = list(
        sel_aqMet = input$sel_aqMet,
        pollutant = input$pollutant,
        ice = input$ice,
        station = input$station,
        burnRestrictions = input$burnRestrictions,
        issuedate = input$issuedate
      )
    )

    # Clean up any leftover folders ??
    unlink(paste0(tools::file_path_sans_ext(output_file_name), "_files"), recursive = TRUE)
    unlink(paste0(tools::file_path_sans_ext(output_file_name), ".lib"), recursive = TRUE)

    # Notify user
    showNotification("Bulletin generation completed.", type = "message", duration = 5)

  })

  # Download files
  output$download_report <- downloadHandler(
    filename = function() {
      sprintf("%s_non-wildfire_smoke_%s_%s_%s.md", format(Sys.Date(), "%Y-%m-%d"), input$ice, input$pollutant, station_clean <- gsub("\\s+", "_", input$station))
    },
    content = function(file) {
      # Construct the filename based on the app's logic
      file_to_download <- sprintf("%s_non-wildfire_smoke_%s_%s_%s.md", format(Sys.Date(), "%Y-%m-%d"), input$ice, input$pollutant, station_clean <- gsub("\\s+", "_", input$station))

      # Copy the generated file to the download path
      file.copy(from = file_to_download, to = file)
    },
    contentType = "text/markdown"
  )
}

# Run the Shiny App
shinyApp(ui = ui, server = server)
