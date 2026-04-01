# This file reads bylaw definitions from a companion YAML file for inclusion in the local_emissions_issue template

library(yaml)
library(tidyverse)

local_data_bylaws_df <- read_yaml(here::here(file.path("src", "local_emissions_bylaws_definitions.yaml"))) %>% map_df(as_tibble)

build_bylaw_information <- function(selected_location) {
  if (local_data_bylaws_df %>% filter(location == selected_location) %>% nrow() > 0)
    return (local_data_bylaws_df$text[local_data_bylaws_df$location == selected_location])
  else
    return (NULL)
}
