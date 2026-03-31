# common functionality for including coloured warning banners
# expects format to be "markdown" or "pdf". the remaining parameters are boolean

build_banners <- function(format = "markdown", includeYellow = FALSE, includeOrange = FALSE, includeRed = FALSE) {

  banners <- ""

  if (includeYellow) {
    if (format == "markdown") {
      banners <- paste(banners, "{{< banner_alert_start title='Yellow Warning - Air Quality' variant='yellow'>}}")
      banners <- paste(banners, "{{< banner_alert_end >}}")
    } else if (format == "pdf") {
      banners <- paste(banners, "\\YellowBanner")
    }
  }

  if (includeOrange) {
    if (format == "markdown") {
      banners <- paste(banners, "{{< banner_alert_start title='Orange Warning - Air Quality' variant='orange'>}}")
      banners <- paste(banners, "{{< banner_alert_end >}}")
    } else if (format == "pdf") {
      banners <- paste(banners, "\\OrangeBanner")
    }
  }

  if (includeRed) {
    if (format == "markdown") {
      banners <- paste(banners, "{{< banner_alert_start title='Red Warning - Air Quality' variant='red'>}}")
      banners <- paste(banners, "{{< banner_alert_end >}}")
    } else if (format == "pdf") {
      banners <- paste(banners, "\\RedBanner")
    }
  }

  return (banners)
}
