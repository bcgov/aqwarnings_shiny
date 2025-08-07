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

## Air Quality Warning - Wildfire Smoke UI

library(shiny)
library(shinydashboard)
library(markdown)

#--------------------------------------------------
# Dashboard
#--------------------------------------------------
# 3 sections: header, sidebar, body

header <- dashboardHeader(title = "Air Quality Warning - Wildfire Smoke")

sidebar <- dashboardSidebar(
  sidebarMenu(
    id = "tabs",
    menuItem(
      "Issue Warning",
      icon = icon("pencil"),
      tabName = "issue"
      ),
    menuItem(
      "End Warning",
      icon = icon("pencil"),
      tabName = "end"
      ),
    menuItem(
      "Non-wildfire Warning",
      icon = icon("pencil"),
      tabName = "non-wildfire"
    )
    )
  )

body <- dashboardBody(
  shinyjs::useShinyjs(),
  tags$head(
    tags$style(HTML(".leaflet-container { background: white; }"))
    ), 
  tabItems(
    tabItem(tabName = "issue", issueWildfireSmokeUI("issue_wildfire_smoke")),
    tabItem(tabName = "end", endWildfireSmokeUI("end_wildfire_smoke")),
    tabItem(tabName = "non-wildfire", nonWildfireSmokeUI("non_wildfire_smoke"))
  )
 )

shinyUI(dashboardPage(header, sidebar, body))
