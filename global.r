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

## Air Quality Warning - Wildfire Smoke App

# Load meta data and maps for Air Quality Warning - Wildfire Smoke
source(file.path("load_metadata.r"))

# Load  modules
source(file.path("module_issue_wildfire_smoke.r"))
source(file.path("module_end_wildfire_smoke.r"))
source(file.path("module_issue_local_emissions.r"))
source(file.path("module_end_local_emissions.r"))