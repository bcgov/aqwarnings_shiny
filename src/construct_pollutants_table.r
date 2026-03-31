library(dplyr)

# This was extracted from the four QMD documents that make use of it for generating pollutant tables in their output

# CAUTION: It has the side-effect of setting the system timezone for the balance of script execution to the location specified in station_location

construct_pollutants_table <- function(pollutants, station_location, min_data_capture_pct = 75) {

  results <- list()

  for (i in seq_along(pollutants)) {
    pollutant <- pollutants[i]

    # ---- Check that locations are valid for this pollutant ----
    valid_locations <- buddy_stations |>
      filter(location %in% station_location) |>
      pull(Buddy_location) |>
      unique()

    if (length(valid_locations) == 0) {
      stop(sprintf("None of the specified locations are valid for %s.", pollutant))
    }

    # ---- Lookup table for units and averaging times ----
    lookup <- data.frame(
      units = c("μg/m^3^", "μg/m^3^", "ppb"),
      hours = c(24, 24, 8),
      row.names = c("PM25", "PM10", "O3")
    ) |>
      mutate(avgtimelabel = sprintf("%d-hr", hours))

    # ---- Read in CSV from FTP ----
    columndefs <- cols_only(
      DATE_PST = col_character(),  # time zone assigned below; col_datetime does not support time zone assignment
      STATION_NAME = col_factor(),
      INSTRUMENT = col_factor(),  #is instrument necessary?
      REPORTED_VALUE = col_double(),
      PARAMETER = col_character(),
      EMS_ID = col_character()
    )
    pollutant_csv_base_path <- "ftp://ftp.env.gov.bc.ca/pub/outgoing/AIR/Hourly_Raw_Air_Data/Air_Quality/"

    incoming_csv_data <- read_csv(
      sprintf("%s%s.csv", pollutant_csv_base_path, pollutant),
      col_types = columndefs
    ) |>
      rename_all(tolower)

    # ---- Filter data to retain only stations relevant to this warning (location + neighbouring sites) ----
    df <- incoming_csv_data |>
      mutate(date_pst = as.POSIXct(date_pst, format = "%Y-%m-%d %H:%M", tz = "Etc/GMT+8")) |>
      filter(instrument != "") |>   #is this needed?
      filter(station_name %in% valid_locations)

    # ---- Get time window per location ----
    dts <- df |>
      group_by(station_name) |>
      summarize(max_dt = max(date_pst), .groups = "drop") |>
      mutate(min_dt = max_dt - (3600 * (lookup[pollutant, "hours"] - 1)))

    df_filtered <- df |>
      left_join(dts, by = "station_name") |>
      filter(date_pst >= min_dt & date_pst <= max_dt) |>
      select(-min_dt, -max_dt)

    # ---- Summarize concentrations ----
    integrated <- df_filtered |>
      group_by(station_name, parameter) |>
      summarize(
        n_hours = n(),
        n_na = sum(is.na(reported_value)),
        pct_valid = 100 * (n_hours - n_na) / n_hours,
        mean_conc = if_else(n_hours == n_na, NA_real_, mean(reported_value, na.rm = TRUE)),
        max_conc = if_else(n_hours == n_na, NA_real_, max(reported_value, na.rm = TRUE)),
        start_dt = min(date_pst),
        end_dt = max(date_pst),
        .groups = "drop"
      ) |>
      mutate(
        mean_conc = na_if(mean_conc, pct_valid < min_data_capture_pct),
        max_conc = na_if(max_conc, pct_valid < min_data_capture_pct)
      )

    bc_monitoring_stations_file <- "ftp://ftp.env.gov.bc.ca/pub/outgoing/AIR/Hourly_Raw_Air_Data/Year_to_Date/bc_air_monitoring_stations.csv"

    station_metadata_raw <- read_csv(bc_monitoring_stations_file, show_col_types = FALSE)
    station_metadata <- station_metadata_raw |>
      rename_all(tolower) |>
      select(station_name, location = city) |>
      distinct()

    # Join with station info using STATION_NAME
    integrated <- integrated |>
      left_join(station_metadata, by = "station_name")

    # ---- Define most recent hour of data and express as 12 hour clock and local time

    # set system to local time of location
    Sys.setenv(TZ = local_tz(station_location))

    local_time <- integrated |>
      filter(location == station_location) |>
      pull(end_dt) |>
      as.POSIXct(., tz = local_tz(station_location))

    local_hour <- format(lubridate::floor_date(local_time, "hour"), format = "%l:00 %p")

    # ---- Format final table ----
    formatted_table <- integrated |>
      mutate(
        mean_conc = ifelse(is.finite(mean_conc), sprintf("%.1f", mean_conc), "NA"),
        max_conc = ifelse(is.finite(max_conc), sprintf("%.1f", max_conc), "NA")
      ) |>
      pivot_wider(
        names_from = parameter,
        id_cols = c(station_name, location),
        values_from = c(mean_conc, max_conc)
      )

    # clean up names, drop station_name and sort by location then other stations alphabetically
    formatted_table <- formatted_table |>
      rename_with(~gsub(sprintf("_%s", pollutant), "", .x), everything()) |>
      select(-station_name) |>
      arrange(location != station_location)  # arrange rows with location first, then rest

    # transpose
    formatted_table <- formatted_table |>
      pivot_longer(cols = -location, names_to = "Community", values_to = "concentration") |>
      pivot_wider(names_from = "location", values_from = "concentration")

    # handle special case for O3
    if (pollutant != "O3") { formatted_table <- formatted_table |>  filter(Community != "max_conc") }

    # clean up labels
    final_table <- formatted_table |>
      mutate(Community = case_when(
        Community == "mean_conc" ~ sprintf("%s average (%s)", lookup[pollutant, "avgtimelabel"], lookup[pollutant, "units"]),
        Community == "max_conc" ~ sprintf("Max. within %s (%s)", gsub("-", " ", lookup[pollutant, "avgtimelabel"]), lookup[pollutant, "units"]),
        TRUE ~ Community
      ))

    results[[paste0("final_table", i)]] <- final_table
  }

  return(list(results = results, local_hour = local_hour, final_table = final_table))

}
