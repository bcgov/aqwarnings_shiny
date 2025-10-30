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

# Air Quality Warning UI

library(shiny)
library(shinydashboard)
library(markdown)

#--------------------------------------------------
# Dashboard
#--------------------------------------------------
# 3 sections: header, sidebar, body

header <- dashboardHeader(title = "Air Quality Warnings")

sidebar <- dashboardSidebar(
  sidebarMenu(
    id = "tabs",
    menuItem("Wildfire Smoke Warnings"),
    menuSubItem("Issue",
                icon = icon("pen"),
                tabName = "issue-wildfire"
                ),
    menuSubItem("End",
                icon = icon("pen"),
                tabName = "end-wildfire"
                ),
    menuItem("", tabName = NULL), # Empty item for spacing
    menuItem("Community Warnings"),
    menuSubItem("Issue",
                icon = icon("pencil"),
                tabName = "issue-community"
                ),
    menuSubItem(
      "End",
      icon = icon("pencil"),
      tabName = "end-community"
    )
    )
  )

body <- dashboardBody(
  shinyjs::useShinyjs(),
  tags$head(
    tags$style(HTML("
                    .leaflet-container { background: white; }
                    .main-sidebar { font-size: 18px; }
                    "))
    ), 
  tabItems(
    tabItem(tabName = "issue-wildfire", issueWildfireSmokeUI("issue_wildfire_smoke")),
    tabItem(tabName = "end-wildfire", endWildfireSmokeUI("end_wildfire_smoke")),
    tabItem(tabName = "issue-community", issueLocalEmissionsUI("issue_local_emissions")),
    tabItem(tabName = "end-community", endLocalEmissionsUI("end_local_emissions"))
  )
 )

shinyUI(dashboardPage(header, sidebar, body))
