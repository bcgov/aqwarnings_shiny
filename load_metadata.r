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


## meta data

crs = "epsg:4326"

reference_aq_mets <- read.csv(here::here("data", "raw", "aq_mets_contact.csv")) # used in all templates
reference_health_authority_contact <- read.csv(here::here("data", "raw", "health_auth_contact.csv")) # used in most templates
reference_match_eccc_health <- read.csv(here::here("data", "raw", "eccc_health_regions.csv")) # used in wildfire_smoke_issue
reference_reg_description <- read.csv(here::here("data", "raw", "eccc_descriptions.csv"))  # used in wildfire_smoke_issue
reference_buddy_stations <- read.csv(here::here("data", "raw", "buddy_stations.csv")) # used in pollutant table generation
reference_match_health_city <- read.csv(here::here("data", "raw", "match_health_city.csv")) # used in most modules and templates
reference_bc_map <- bcmaps::bc_bound() |>  sf::st_transform(crs = crs) # used in wildfire_smoke_issue

# Load pre-edited ECCC forecast regions and "points" within Metro Vancouver
# and the Fraser Valley Regional District (MV/FVRD). These points will be
# used to manually create a texture over the MV/FVRD area, to denote
# that is it not a Region available on our bulletins.
reference_eccc_map_bc <- sf::st_read(here::here("data", "raw", "shapefiles", "eccc_zones_bc.shp"))  # used in wildfire_smoke_issue
# Create separate Lower Mainland shapefiles and ENV shapefiles
local_eccc_zones_lm <- reference_eccc_map_bc[grepl("Metro Vancouver -|Fraser Valley", reference_eccc_map_bc$NAME), ]
reference_lm_pts <- sf::st_read(here::here("data", "raw", "shapefiles", "lm_pts.shp"))

reference_eccc_map_env <- reference_eccc_map_bc[!grepl("Metro Vancouver -|Fraser Valley", reference_eccc_map_bc$NAME), ]


labels <- sprintf("<strong>%s</strong>", reference_eccc_map_env$NAME) |>
  lapply(htmltools::HTML)

reference_cities <- bcmaps::bc_cities() |>
  sf::st_transform(crs = crs) |>
  dplyr::filter(NAME %in% c("Kamloops",
                            "Cranbrook",
                            "Kelowna",
                            "Victoria",
                            "Prince George",
                            "Terrace",
                            "Fort St. John",
                            "Fort Nelson",
                            "Williams Lake",
                            "Atlin"))

# convert geometry to lat and lng columns; drop geometry
reference_cities <- reference_cities |>
  tidyr::extract(geometry, c('lng', 'lat'), '\\((.*), (.*)\\)', convert = TRUE)  # to do: extract() has been superseded by separate_wider_regex()

# shiny app runs on a server with UTC. Specify local tz to ensure local date is applied
Sys.setenv(TZ = "America/Vancouver")

