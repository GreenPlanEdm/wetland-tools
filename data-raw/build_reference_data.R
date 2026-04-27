# Rebuild all reference datasets from raw source files.
# Run this script whenever a source file is updated.
# Output goes to data/ as .rda files for use in package functions and Rmds.

library(dplyr)
library(readxl)
library(usethis)
library(here)

# ── Vegetation reference tables ───────────────────────────────────────────────

# AB Invasive Species Council species list
# Source: https://abinvasives.ca/
invasive_species <- read.csv(here("data-raw", "invasive_species_ab.csv"))
usethis::use_data(invasive_species, overwrite = TRUE)

# AB Weed Control Act — Noxious and Nuisance weeds
# Source: AB King's Printer / AEP
noxious_weeds <- read.csv(here("data-raw", "noxious_weeds_ab.csv"))
usethis::use_data(noxious_weeds, overwrite = TRUE)

# ANPC Wetland Classification System — indicator species and wetland classes
# Source: ANPC Wetland Plant Communities of Alberta field guide
anpc_wetland_species <- read.csv(here("data-raw", "anpc_wetland_species.csv"))
usethis::use_data(anpc_wetland_species, overwrite = TRUE)

# Alberta Wetland Classification System — full provincial plant list with class
# and indicator assignments derived from AWCS 2015 (ESRD Water Policy Branch).
# 622 species; 107 flagged as AWCS text indicators with fen type, bog form,
# marsh zone/salinity/hydroperiod, and swamp form detail columns.
# Source: ESRD 2015 Appendix C + classification text; ITIS 2014 taxonomy
awcs_wetland_species <- read.csv(here("data-raw", "awcs_wetland_species.csv"),
                                  stringsAsFactors = FALSE)
usethis::use_data(awcs_wetland_species, overwrite = TRUE)

# USDA PLANTS / NatureServe wetland indicator status (UPL–OBL)
# Source: USDA PLANTS Database; adapted for AB / NRC geography
wetland_indicator_status <- read.csv(here("data-raw", "wetland_indicator_status.csv"))
usethis::use_data(wetland_indicator_status, overwrite = TRUE)

# AB Rangeland Plants
# Source: AEP Rangeland Plants of Alberta
rangeland_plants <- read.csv(here("data-raw", "rangeland_plants_ab.csv"))
usethis::use_data(rangeland_plants, overwrite = TRUE)

# Plant salinity tolerance
# Source: literature compilation
salinity_tolerance <- read.csv(here("data-raw", "salinity_tolerance.csv"))
usethis::use_data(salinity_tolerance, overwrite = TRUE)

# Northern Forestry Centre ecosites
# Source: NRCan/CFS ecosite classification
ecosites_nfc <- read.csv(here("data-raw", "ecosites_nfc.csv"))
usethis::use_data(ecosites_nfc, overwrite = TRUE)

# NRC geography regions and USACE geographic region linkage
nrc_geography <- read.csv(here("data-raw", "nrc_geography_usace.csv"))
usethis::use_data(nrc_geography, overwrite = TRUE)

# WAIR wetland classification decision rules (structured table)
wair_rules <- read.csv(here("data-raw", "wair_classification_rules.csv"))
usethis::use_data(wair_rules, overwrite = TRUE)

# ── Soils reference tables ────────────────────────────────────────────────────

# Canadian System of Soil Classification — great groups / orders
cssc_great_groups <- read.csv(here("data-raw", "cssc_great_groups.csv"))
usethis::use_data(cssc_great_groups, overwrite = TRUE)

# Von Post peat humification scale
von_post <- read.csv(here("data-raw", "von_post.csv"))
usethis::use_data(von_post, overwrite = TRUE)

# Munsell soil colour chart
munsell <- read.csv(here("data-raw", "munsell.csv"))
usethis::use_data(munsell, overwrite = TRUE)

# AGRASID soil map units (Alberta Geomatic Reference for Agriculture and Soils)
# Source: AB Agriculture
agrasid <- read.csv(here("data-raw", "agrasid.csv"))
usethis::use_data(agrasid, overwrite = TRUE)
