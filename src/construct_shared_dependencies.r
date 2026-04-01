 get_meteorologist_contact <- function(met_name, sep_type) {
   contact <- reference_aq_mets |>
     filter(fullname == met_name) |>
     mutate(contact = paste(fullname_typeset, title, ministry, phone, sep = sep_type)) |>
     pull(contact)

   return (contact)
 }

 get_health_authority_details <- function(for_location, sep_type) {
   health_authority <- reference_match_health_city |>
     filter(location == for_location) |>
     pull(health_city)

   health_authority_contact <- reference_health_authority_contact |>
     filter(authority == health_authority) |>
     select(authority, contact) |>
     group_by(authority) |>
     summarise(html_string = paste(contact, collapse = sep_type))

   return (list(health_authority=health_authority, health_authority_contact=health_authority_contact))
 }
