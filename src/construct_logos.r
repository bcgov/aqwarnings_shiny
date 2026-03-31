# This file defines construct_logos, functionality that is common across all templates
library(magick)

logos_list <- list(
  "Government of British Columbia" = "BCID_V_RGB_pos",
  "First Nations Health Authority" = "FNHA",
  "Interior Health Authority" = "IH",
  "Fraser Health Authority" = "FH",
  "Vancouver Coastal Health Authority" = "VCH",
  "Vancouver Island Health Authority" = "VIH",
  "Northern Health Authority" = "NH"
)

construct_logos <- function(format = "markdown", selected_health_authorities) {
  # Logos selected by user, always select BC and FNHA, and sort as per logos_list
  logos_names_selected <- c("Government of British Columbia",
                            "First Nations Health Authority",
                            selected_health_authorities)

  logos_selected <- logos_list[logos_names_selected]

  # Count number of logos to display
  n_logos <- length(logos_selected)

  logo_image_line <- c()
  logos_combined <- c()

  # Set logo path based on output format
  if (format == "markdown") {
    logo_path <- " logo](//assets/logo_"

    # Build a vector of quarto lines to insert image for each logo
    # It is more efficient to use `sapply` but this might be more readable

    # Add each logo's insert line to the vector
    for (logo_name in names(logos_selected)) {
      logo_image_line <- c(logo_image_line,
                           paste0("![", logo_name, logo_path, logos_selected[[logo_name]], ".png)\\"))
    } }


  if (format == "pdf") {

    logo_path <- "https://github.com/bcgov/aqwarnings/blob/main/frontend/assets/logo_"
    logo_urls <- c() #start with empty vector

    # create vector of urls
    for (logo_name in names(logos_selected)) {
      logo_urls <- c(
        logo_urls,
        paste0(logo_path,
               logos_selected[[logo_name]],
               ".png?raw=true"
        )
      )
    }

    # format logos
    logos <- magick::image_read(logo_urls) |>
      magick::image_trim() |> # remove all white space
      magick::image_border(color = "none", geometry = "100x25") |> # add uniform white space to top and right side of each image
      magick::image_scale("x200") # scale

    # Combine logos into single image and scale
    logos_combined <- magick::image_append(logos) |>
      magick::image_write(path = "logo.png")
  }

  return (list(n_logos = n_logos, logos_combined = logos_combined, logo_image_line = logo_image_line))
}
