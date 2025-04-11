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

# check and install packages from CRAN that are necessary to run the app locally
# this script only needs to be run once and only if the app is run locally (exclude from shiny.io)

# packages required to run the app locally
list_of_packages <- c(
  "bcmaps",
  "data.table", #to do: consider using readr:read_csv instead of data.table::fread (see load_metadata.R)
  "htmlwidgets",
  "knitr",
  "leaflet",
  "leaflet.esri",
  "lubridate",
  "mapview",
  "shiny",
  "shinydashboard",
  "shinyjs",
  "sf",
  "tidyverse",
  "quarto",
  "webshot",
  "mapshot",
  "fs"
)

# identify which packages are not yet installed on user computer
# and install missing ones

new_packages <- list_of_packages[!(list_of_packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, dependencies = TRUE)

# Load all packages
lapply(list_of_packages,function(x){library(x, character.only = TRUE)})

# install_phantomjs() - an external program to take screenshots. It is required by the webshot package
webshot::install_phantomjs()



