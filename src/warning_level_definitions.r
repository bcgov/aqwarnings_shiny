#--------------------------------------------------
# Warning Level Definitions
#--------------------------------------------------

# You can add more layers if required. This is shared between several modules

reference_warning_levels_df <- data.frame(Name = c("unselected", "yellow", "orange", "red"), # names as they will appear in template parameters
                                          Colour = c("#656565", "#FFFF00", "#FF9500", "#D10000"), # used both in UI and PDF generation
                                          PolygonOpacity = c(0.0, 0.75, 0.75, 0.75),
                                          IsTemplateParameter = c(FALSE, TRUE, TRUE, TRUE), # If it is passed through as a template param
                                          Selectable = c(TRUE, TRUE, TRUE, FALSE)) # set to FALSE to disable click-to-select for a given layer
