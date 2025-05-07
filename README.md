[![Apache 2.0 License](https://img.shields.io/github/license/bcgov/nr-epd-aq-statements.svg)](/LICENSE)  [![Creative Commons BY 4.0 License](https://img.shields.io/badge/license-CC--BY--4.0-green.svg
)](/LICENSE-docs)  [![Lifecycle:Maturing](https://img.shields.io/badge/Lifecycle-Maturing-007EC6)](<Redirect-URL>)

# aqwarnings_shiny

An interactive app to issue or end Air Quality Warnings built using [RStudio's](https://www.rstudio.com/)
[Shiny](https://www.rstudio.com/products/shiny/) open source R package. 

## Usage

**Only to be used by ENV Air Quality Meteorologists contact the team for usage.**

## Development

### Technologies used

- [R](https://cran.rstudio.com/) 4.4.X
- [Quarto](https://quarto.org/docs/get-started/) 1.4.X
- [Shiny](https://shiny.posit.co/r/getstarted/shiny-basics/lesson1/) 1.10.X

#### R Packages

```
bcmaps
fs
here
htmlwidgets
knitr
leaflet
leaflet.esri
mapview
sf
shiny
shinydashboard
shinyjs
tidyverse # mostly using dplyr, tidyr, readr, lubridate
quarto
webshot
zip
```

### Getting Started

Here is high-level documentation on the development of applications, use of GitHub, and Openshift in the Government of BC:

- ["Working in github.com/bcgov" Cheatsheet](https://github.com/bcgov/BC-Policy-Framework-For-GitHub/blob/master/BC-Gov-Org-HowTo/Cheatsheet.md)
- [DevHub DC Developer guide](https://developer.gov.bc.ca/docs/default/component/bc-developer-guide/)

### Running the application in local development environment

Instructions are geared toward the following tools:

- [RStudio Desktop](https://posit.co/download/rstudio-desktop/)
- [GitHub Desktop](https://github.com/apps/desktop)

1. Ensure R, RStudio, and Quarto are installed on the machine
1. Clone this repository using GitHub Desktop
1. Open project in RStudio
1. Install required packages. 
    Run `source("src/run_app_locally/install_packages.r")` in the console or select "Run" from RStudio's Source Pane.
1. Make and required changes.
1. Run the app locally to review.
    Run `shiny::runApp()` or select "Run App" from RStudio's Source Pane

### Deploying

To deploy to TEST and PROD you require a shinyapps.io account.

1. Install rsconnect.
    - Before deploying for the first time, you need to ensure you have the rsconnect R package from CRAN installed. Run the following command in your R console to check:
    `library(rsconnect)`
    - If you get an Error that says “there is no package called ‘rsconnect’, try to install it the usual way:
    `install.packages(rsconnect)`

1. Configure rsconnect with your shinyapps.io token.
    Follow the [shinyapps.io instructions](https://docs.posit.co/shinyapps.io/guide/getting_started/#configure-rsconnect) to copy your token from the account page and configure it in the R console:
    `rsconnect::setAccountInfo(name="<ACCOUNT>", token="<TOKEN>", secret="<SECRET>")`

1. Publish the app.
    - Run `deployApp()` or select "Publish" from RStudio's Source Pane with either the `ui.R` or `server.R` file open.
    - Fill in all the required details in the dialog box, noting them for future reference:
        - On the left side, choose which files to publish (or not publish)
        - On the right side, ensure you have the correct account selected
        - Enter a name that is at least 4 alphanumeric characters (no spaces). the name will be part of the URL to access your app, for example: `https://<ACCOUNT>.shinyapps.io/<APPNAME>`
    - For PROD the app name is `aqwarnings_shiny`, we publish new apps for major test versions following the convention `aqwarnings_shiny_test_<date>`.

1. Set up athentication for the app. (Note: you only have to do this when publishing a **new app**)
    - Go to the [shinyapps.io dashboard](https://www.shinyapps.io/admin/#/dashboard). 
    - Navigate to the administrative interface, select the application to modify, and click on the Users tab. - Follow [the instructions](https://docs.posit.co/shinyapps.io/guide/authentication_and_user_management/) to change the Application Visibility setting to "**Private**" and restart the app.

## Getting Help or Reporting an Issue

To report bugs/issues/feature requests, please file an [issue](https://github.com/bcgov/aqwarnings_shiny/issues/new).

## How to Contribute

If you would like to contribute, please see our [CONTRIBUTING](CONTRIBUTING.md) guidelines.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## License

Copyright 2025 Province of British Columbia

**Code** is licensed under the [Apache License, Version 2.0](./LICENSE) (the “License”); you may not use this file except in compliance with the License. You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

**Documentation including the content of air quality warnings and bulletins** by the Province of British Columbia is licensed under a [Creative Commons Attribution 4.0 International License](./LICENSE-docs): https://creativecommons.org/licenses/by/4.0/.     

### Third party intellectual property material

This repository contains information in the [`/data/raw/shapefiles`](/data/raw/shapefiles) folder adapted from [Meteorological Service of Canada (MSC) Forecast Regions Polygons](https://eccc-msc.github.io/open-data/msc-data/forecast-regions/readme_forecast-regions_en/), which is information licenced under the [Data Server End-use Licence](https://eccc-msc.github.io/open-data/licence/readme_en/) of Environment and Climate Change Canada. 


------------------------------------------------------------------------

*This project was created using the [bcgovr](https://github.com/bcgov/bcgovr) package.*
