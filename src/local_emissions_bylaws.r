# This file reads bylaw definitions from a companion YAML file for inclusion in the local_emissions_issue template

library(yaml)
library(tidyverse)

bylaws_dataframe <- read_yaml(here::here(file.path("src", "local_emissions_bylaws_definitions.yaml"))) %>% map_df(as_tibble)

build_bylaw_information <- function(selected_location) {
  if (bylaws_dataframe %>% filter(location == selected_location) %>% nrow() > 0)
    return (bylaws_dataframe$text[bylaws_dataframe$location == selected_location])
  else
    return (NULL)
}
