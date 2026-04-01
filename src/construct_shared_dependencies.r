 get_meteorologist_contact <- function(met_name, sep_type) {
   ENVcontact <- aq_mets |>
     filter(fullname == met_name) |>
     mutate(contact = paste(fullname_typeset, title, ministry, phone, sep = sep_type)) |>
     pull(contact)

   return (ENVcontact)
 }

 get_health_authority_details <- function(for_location) {
   HAauth <- match_health_city |>
     filter(location == for_location) |>
     pull(health_city)

   HAcontact <- health_contact |>
     filter(authority == HAauth) |>
     select(authority, contact) |>
     group_by(authority) |>
     summarise(html_string = paste(contact, collapse = sep_type))

   return (list(health_authority=HAauth, health_authority_contact=HAcontact))
 }
