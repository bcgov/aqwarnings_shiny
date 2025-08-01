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

aq_mets <- read.csv(here::here("data", "raw", "aq_mets_contact.csv"))
health_contact <- read.csv(here::here("data", "raw", "health_auth_contact.csv"))
match_eccc_health <- read.csv(here::here("data", "raw", "eccc_health_regions.csv"))
reg_description <- read.csv(here::here("data", "raw", "eccc_descriptions.csv"))
bc_map <- bcmaps::bc_bound() |>  sf::st_transform(crs = crs)

# Load pre-edited ECCC forecast regions and "points" within Metro Vancouver
# and the Fraser Valley Regional District (MV/FVRD). These points will be
# used to manually create a texture over the MV/FVRD area, to denote
# that is it not a Region available on our bulletins.
eccc_map_bc <- sf::st_read(here::here("data", "raw", "shapefiles","eccc_zones_bc.shp"))
# Create separate Lower Mainland shapefiles and ENV shapefiles
eccc_zones_lm <- eccc_map_bc[grepl("Metro Vancouver -|Fraser Valley", eccc_map_bc$NAME), ]
eccc_zones_lm_merged <- sf::st_union(eccc_zones_lm)
lm_pts <- sf::st_read(here::here("data", "raw", "shapefiles","lm_pts.shp"))

eccc_map_env <- eccc_map_bc[!grepl("Metro Vancouver -|Fraser Valley", eccc_map_bc$NAME), ]


labels <- sprintf("<strong>%s</strong>", eccc_map_env$NAME) |> 
  lapply(htmltools::HTML)

cities <- bcmaps::bc_cities() |> 
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
cities <- cities |>  
  tidyr::extract(geometry, c('lng', 'lat'), '\\((.*), (.*)\\)', convert = TRUE)  # to do: extract() has been superseded by separate_wider_regex()

