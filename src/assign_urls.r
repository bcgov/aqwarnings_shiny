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

library(httr)

## URLs assignments (module_issue_wildfire_smoke.r)

reference_url_current_weather <- "https://geo.weather.gc.ca/geomet"
reference_url_msc_attribution <- "https://eccc-msc.github.io/open-data/msc-datamart/readme_en/"
reference_url_goes_vis_sat <- "https://gibs.earthdata.nasa.gov/wms/epsg4326/best/wms.cgi"
reference_url_nrcan_fire_perim <- "http://cwfis.cfs.nrcan.gc.ca/geoserver/ows"
reference_url_nrcan_cwfis_attribution <- "https://cwfis.cfs.nrcan.gc.ca/datamart/metadata/fm3buffered"

local_bcwfs_fire_data <- parse_url("https://services6.arcgis.com/ubm4tcTYICKBpist/arcgis/rest/services")
local_bcwfs_fire_data$path <- paste(local_bcwfs_fire_data$path, "BCWS_ActiveFires_PublicView/FeatureServer/0/query", sep = "/")
local_bcwfs_fire_data$query <- list(where = "FIRE_STATUS <> 'OUT'",
                                    geometryType="esriGeometryPoint",
                                    outFields = "FIRE_STATUS, GEOGRAPHIC_DESCRIPTION, FIRE_TYPE, FIRE_ID",
                                    returnGeometry = "true",
                                    f = "geojson")

reference_url_bcwfs_fire_data <- build_url(local_bcwfs_fire_data)
