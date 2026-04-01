# common functionality for including coloured warning banners
# expects format to be "markdown" or "pdf". the remaining parameters are boolean

build_banners <- function(format = "markdown", include_yellow = FALSE, include_orange = FALSE, include_red = FALSE) {

  banners <- ""

  if (include_yellow) {
    if (format == "markdown") {
      banners <- paste(banners, "{{< banner_alert_start title='Yellow Warning - Air Quality' variant='yellow'>}}")
      banners <- paste(banners, "{{< banner_alert_end >}}")
    } else if (format == "pdf") {
      banners <- paste(banners, "\\YellowBanner")
    }
  }

  if (include_orange) {
    if (format == "markdown") {
      banners <- paste(banners, "{{< banner_alert_start title='Orange Warning - Air Quality' variant='orange'>}}")
      banners <- paste(banners, "{{< banner_alert_end >}}")
    } else if (format == "pdf") {
      banners <- paste(banners, "\\OrangeBanner")
    }
  }

  if (include_red) {
    if (format == "markdown") {
      banners <- paste(banners, "{{< banner_alert_start title='Red Warning - Air Quality' variant='red'>}}")
      banners <- paste(banners, "{{< banner_alert_end >}}")
    } else if (format == "pdf") {
      banners <- paste(banners, "\\RedBanner")
    }
  }

  return (banners)
}
