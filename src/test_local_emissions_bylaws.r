
source(here::here(file.path("src", "local_emissions_bylaws.r")))

library(tinytest) # Not included in install_packages.r since it is not required at runtime, only for development

# verify string data returned in positive cases
tinytest::expect_true(build_bylaw_information("Duncan") %>% nchar() > 10)
tinytest::expect_true(build_bylaw_information("Burns Lake") %>% nchar() > 10)
tinytest::expect_true(build_bylaw_information("Houston") %>% nchar() > 10)
tinytest::expect_true(build_bylaw_information("Smithers") %>% nchar() > 10)
tinytest::expect_true(build_bylaw_information("Prince George") %>% nchar() > 10)
tinytest::expect_true(build_bylaw_information("Valemount") %>% nchar() > 10)

# verify NULL returned in negative case
tinytest::expect_equal(build_bylaw_information("Nonexistent Place"), NULL)

# Return NULL if supplied a vector (this case should not occur in the templates as currently defined)
tinytest::expect_equal(build_bylaw_information(c("Duncan", "Burns Lake")), NULL)
