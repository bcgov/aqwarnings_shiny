# function to assign local time zone based on location

local_tz <- function(x) {
  if (x %in% c("Cranbrook", "Golden", "Invermere")) {
    "America/Edmonton"  
  } else if (x %in% c("Fort St John", "Dawson Creek", "Fort Nelson", "Creston")) {
    "America/Fort_Nelson"
  } else {
    "America/Vancouver"
  }
}