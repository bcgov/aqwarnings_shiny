# generate and save stations_pmXX.rds: dataframe of the form STATION_NAME, PARAMETER, COMMUNITY
# for use with concentration table (utility/calc_24hr_conc_pmXX.R)

source("./functions/listStations.R")

# TODO consolidate into single file
purrr::walk(c("pm25","pm10","o3"),
            function(p){

              listStations(p) %>%

                dplyr::mutate(PARAMETER=p) %>%

                dplyr::mutate(COMMUNITY=dplyr::case_when(

                  stringr::str_detect(STATION_NAME,"Abbotsford") ~ "Abbotsford",
                  stringr::str_detect(STATION_NAME,"Agassiz") ~ "Agassiz",
                  stringr::str_detect(STATION_NAME,"Burnaby") ~ "Burnaby",
                  stringr::str_detect(STATION_NAME,"Burns Lake") ~ "Burns Lake",
                  stringr::str_detect(STATION_NAME,"Castlegar") ~ "Castlegar",
                  stringr::str_detect(STATION_NAME,"Chilliwack") ~ "Chilliwack",
                  stringr::str_detect(STATION_NAME,"Colwood") ~ "Colwood",
                  stringr::str_detect(STATION_NAME,"Courtenay") ~ "Courtenay",
                  stringr::str_detect(STATION_NAME,"Cranbrook") ~ "Cranbrook",
                  stringr::str_detect(STATION_NAME,"Crofton") ~ "Crofton",
                  stringr::str_detect(STATION_NAME,"Duncan") ~ "Duncan",
                  stringr::str_detect(STATION_NAME,"Elk Falls") ~ "Campbell River",
                  stringr::str_detect(STATION_NAME,"Elkford") ~ "Elkford",
                  stringr::str_detect(STATION_NAME,"Fort St John") ~ "Fort St John",
                  stringr::str_detect(STATION_NAME,"Golden") ~ "Golden",
                  stringr::str_detect(STATION_NAME,"Grand Forks") ~ "Grand Forks",
                  stringr::str_detect(STATION_NAME,"Harmac") ~ "Harmac",
                  stringr::str_detect(STATION_NAME,"Horseshoe Bay") ~ "Horseshoe Bay",
                  stringr::str_detect(STATION_NAME,"Houston") ~ "Houston",
                  stringr::str_detect(STATION_NAME,"Hudsons Hope") ~ "Hudsons Hope",
                  stringr::str_detect(STATION_NAME,"Kamloops") ~ "Kamloops",
                  stringr::str_detect(STATION_NAME,"Kelowna") ~ "Kelowna",
                  stringr::str_detect(STATION_NAME,"Kitimat") ~ "Kitimat",
                  stringr::str_detect(STATION_NAME,"Langdale") ~ "Langdale",
                  stringr::str_detect(STATION_NAME,"Langley") ~ "Abbotsford",
                  stringr::str_detect(STATION_NAME,"Mission") ~ "Mission",
                  stringr::str_detect(STATION_NAME,"Nanaimo") ~ "Nanaimo",
                  stringr::str_detect(STATION_NAME,"New Westminster") ~ "New Westminster",
                  stringr::str_detect(STATION_NAME,"North Delta") ~ "North Delta",
                  stringr::str_detect(STATION_NAME,"North Vancouver") ~ "North Vancouver",
                  stringr::str_detect(STATION_NAME,"Peace Valley Attachie Flat") ~ "Peace Valley Attachie Flat",
                  stringr::str_detect(STATION_NAME,"Penticton") ~ "Penticton",
                  stringr::str_detect(STATION_NAME,"Pitt Meadows") ~ "Pitt Meadows",
                  stringr::str_detect(STATION_NAME,"Port Alberni") ~ "Port Alberni",
                  stringr::str_detect(STATION_NAME,"Port Moody") ~ "Port Moody",
                  stringr::str_detect(STATION_NAME,"Powell River") ~ "Powell River",
                  stringr::str_detect(STATION_NAME,"Prince George") ~ "Prince George",
                  stringr::str_detect(STATION_NAME,"Prince Rupert") ~ "Prince Rupert",
                  stringr::str_detect(STATION_NAME,"Quesnel") ~ "Quesnel",
                  stringr::str_detect(STATION_NAME,"Richmond") ~ "Richmond",
                  stringr::str_detect(STATION_NAME,"Smithers") ~ "Smithers",
                  stringr::str_detect(STATION_NAME,"Sparwood") ~ "Sparwood",
                  stringr::str_detect(STATION_NAME,"Squamish") ~ "Squamish",
                  stringr::str_detect(STATION_NAME,"Surrey") ~ "Surrey",
                  stringr::str_detect(STATION_NAME,"Terrace") ~ "Terrace",
                  stringr::str_detect(STATION_NAME,"Tsawwassen") ~ "Tsawwassen",
                  stringr::str_detect(STATION_NAME,"Valemount") ~ "Valemount",
                  stringr::str_detect(STATION_NAME,"Vancouver") ~ "Vancouver",
                  stringr::str_detect(STATION_NAME,"Vanderhoof") ~ "Vanderhoof",
                  stringr::str_detect(STATION_NAME,"Vernon") ~ "Vernon",
                  stringr::str_detect(STATION_NAME,"Victoria") ~ "Victoria",
                  stringr::str_detect(STATION_NAME,"Whistler") ~ "Whistler",
                  stringr::str_detect(STATION_NAME,"Williams Lake") ~ "Williams Lake"

                )) %>%

                readr::write_rds(.,
                                 stringr::str_c(
                                   "./utility/stations_",
                                   p,
                                   ".rds",
                                   sep = ""))


            })

