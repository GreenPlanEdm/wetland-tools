# Rebuild all reference datasets from raw source files.
# Run this script whenever a source file is updated.
# Output goes to data/ as .rda files for use in package functions and Rmds.

library(dplyr)
library(tidyr)
library(stringr)
library(readxl)
library(usethis)
library(here)

# ── Species code generation helper ───────────────────────────────────────────
# Produces ACIMS-style codes: 4-letter genus + "." + 4-letter epithet (uppercase).
# Conflicts resolved by extending the epithet (up to 8 chars), then the genus
# (up to 6 chars), then a numeric suffix as a last resort.
# Identical binomials (same genus + epithet, e.g. duplicate rows or varieties
# with the same base species) receive the same code.
generate_spp_codes <- function(sci_names) {
  # Strip author citations and extract genus + primary specific epithet
  extract_binomial <- function(nm) {
    nm <- iconv(nm, to = "ASCII//TRANSLIT")          # remove diacritics
    nm <- gsub("\\s*\\([^)]*\\)", "", nm)             # drop parenthetical authors
    words <- strsplit(trimws(nm), "\\s+")[[1]]
    genus <- words[1]
    skip  <- c("x", "X", "ssp.", "ssp", "var.", "var", "f.", "fo.", "subsp.")
    rem   <- words[-1][!words[-1] %in% skip]
    epi   <- rem[grepl("^[a-z]", rem)]
    epi   <- if (length(epi)) epi[1] else "sp"
    paste(genus, epi)
  }

  binomials     <- vapply(sci_names, extract_binomial, character(1))
  unique_binom  <- unique(binomials)

  make_code <- function(binom, glen = 4, elen = 4) {
    p <- strsplit(binom, " ")[[1]]
    paste0(toupper(substr(p[1], 1, glen)), ".", toupper(substr(p[2], 1, elen)))
  }

  ucodes <- vapply(unique_binom, make_code, character(1))

  # Resolve conflicts iteratively: extend epithet then genus, suffix as fallback
  for (attempt in seq_len(20)) {
    dup_mask <- duplicated(ucodes) | duplicated(ucodes, fromLast = TRUE)
    if (!any(dup_mask)) break
    for (dc in unique(ucodes[dup_mask])) {
      idx      <- which(ucodes == dc)
      resolved <- FALSE
      for (elen in 5:8) {
        nc <- vapply(unique_binom[idx], make_code, character(1), glen = 4, elen = elen)
        if (length(unique(nc)) == length(idx) && !any(nc %in% ucodes[-idx])) {
          ucodes[idx] <- nc; resolved <- TRUE; break
        }
      }
      if (!resolved) {
        for (glen in 5:6) {
          for (elen in 4:8) {
            nc <- vapply(unique_binom[idx], make_code, character(1), glen = glen, elen = elen)
            if (length(unique(nc)) == length(idx) && !any(nc %in% ucodes[-idx])) {
              ucodes[idx] <- nc; resolved <- TRUE; break
            }
          }
          if (resolved) break
        }
      }
      if (!resolved) {
        for (i in seq_along(idx)[-1])
          ucodes[idx[i]] <- paste0(ucodes[idx[i]], "_", i)
      }
    }
  }

  names(ucodes) <- unique_binom
  unname(ucodes[binomials])
}

# ── Vegetation reference tables ───────────────────────────────────────────────

# AB Invasive Species Council (AISC) plant list — 4th ed. 2022
# Source: Alberta Invasive Species Council, "Invasive Plants of Alberta" 4th ed.
# CSV is extracted from the source PDF by data-raw/extract_aisc_invasive_plants.R.
# Categories: prohibited_noxious + noxious (regulated under AB Weed Control Act)
# and unregulated_invasive (AISC-listed but not statutorily regulated).
# 84 species total. Some overlap with `noxious_weeds.rda` is expected — that
# table holds the richer WCA metadata; this one is the AISC source list.
invasive_species <- read.csv(here("data-raw", "aisc_invasive_plants.csv"),
                              stringsAsFactors = FALSE)
usethis::use_data(invasive_species, overwrite = TRUE)

# AB Weed Control Act — Noxious and Nuisance weeds
# Source: AB King's Printer / AEP
noxious_weeds <- read.csv(here("data-raw", "noxious_weeds_ab.csv"))
usethis::use_data(noxious_weeds, overwrite = TRUE)

# ACIMS Alberta vascular plant list (used as species validation lookup in QA/QC)
# Note: source file is the full ACIMS provincial plant list, not an ANPC wetland
# communities list. It serves the downstream purpose of validating species codes.
# Has 9 leading blank columns from original Excel export — skipped by column selection.
# Source: ACIMS / Alberta Biodiversity Monitoring Institute
anpc_raw <- read.csv(here("data-raw", "ANPC_Native_Plant_List.csv"),
                     stringsAsFactors = FALSE, encoding = "latin1")
# check.names = TRUE (default): "Scientific Name" → "Scientific.Name", etc.
# Duplicate "ORIGIN" column → "ORIGIN" and "ORIGIN.1"; we take the first.
anpc_wetland_species <- anpc_raw |>
  select(
    scientific_name = Scientific.Name,
    common_name     = Common.Name,
    origin          = ORIGIN,
    s_rank          = S_RANK
  ) |>
  filter(nzchar(trimws(scientific_name))) |>
  mutate(species_code = generate_spp_codes(scientific_name))
usethis::use_data(anpc_wetland_species, overwrite = TRUE)

# Alberta Wetland Classification System — full provincial plant list with class
# and indicator assignments derived from AWCS 2015 (ESRD Water Policy Branch).
# 622 species; 107 flagged as AWCS text indicators with fen type, bog form,
# marsh zone/salinity/hydroperiod, and swamp form detail columns.
# Source: ESRD 2015 Appendix C + classification text; ITIS 2014 taxonomy
# spp_code: ACIMS-style codes generated by generate_spp_codes(); stable as long
# as the source CSV row order and scientific names are unchanged.
awcs_wetland_species <- read.csv(here("data-raw", "awcs_wetland_species.csv"),
                                  stringsAsFactors = FALSE, encoding = "latin1") |>
  mutate(spp_code = generate_spp_codes(scientific_name)) |>
  relocate(spp_code, .before = scientific_name)
usethis::use_data(awcs_wetland_species, overwrite = TRUE)

# USDA PLANTS / NatureServe wetland indicator status (UPL–OBL)
# Source: Alberta Wetland Plant List 2021 (adapted from US Army Corps of Engineers
# regional lists for WMVC, GP, NCNE, AK regions).
# Row 1 is a merged title row; skip=1 makes row 2 the header.
wi_raw <- read.csv(here("data-raw", "ABWetlandPlantList_2021.csv"),
                   skip = 1, check.names = FALSE, stringsAsFactors = FALSE,
                   encoding = "latin1")
wetland_indicator_status <- wi_raw |>
  select(
    scientific_name = `Scientific Name (ACIMS)`,
    common_name     = `Common Name (ACIMS)`,
    wmvc = WMVC,
    gp   = GP,
    ncne = NCNE,
    ak   = AK
  ) |>
  filter(nzchar(trimws(scientific_name))) |>
  mutate(species_code = generate_spp_codes(scientific_name))
usethis::use_data(wetland_indicator_status, overwrite = TRUE)

# AB Rangeland Plants
# Source: AEP Rangeland Plants of Alberta (2023 edition)
rangeland_plants <- read.csv(here("data-raw", "RangePlants_2023.csv"),
                              stringsAsFactors = FALSE) |>
  rename(
    common_name      = Common.name,
    scientific_name  = Scientific.name,
    life_span        = Life.span,
    origin           = Origin,
    grazing_response = Grazing.response,
    forage_value     = Forage.value,
    stratum          = Stratum
  )
usethis::use_data(rangeland_plants, overwrite = TRUE)

# Plant salinity tolerance — species-level lookup
# Source: BD2025.042 (Wetaskiwin Wetland Monitoring); see
# data-raw/extract_salinity_tolerance.R for the merge logic. Values are
# v1.2_curated (hand-assigned by the project analyst from primary literature
# in references.csv) where available, otherwise inherited from the project
# starter file. most_saline is the wetter end of the range, kept as an
# ordered factor (freshwater < slightly brackish < moderately brackish <
# brackish) so downstream code can compare/sort salinity classes directly.
species_salinity_tolerance <- read.csv(
  here("data-raw", "species_salinity_tolerance.csv"),
  stringsAsFactors = FALSE, encoding = "latin1"
) |>
  mutate(most_saline = factor(
    ifelse(most_saline == "Unknown", NA_character_, most_saline),
    levels  = c("freshwater", "slightly brackish", "moderately brackish", "brackish"),
    ordered = TRUE
  ))
usethis::use_data(species_salinity_tolerance, overwrite = TRUE)

# References / bibliography
# Source: hand-compiled from BD2025.042 wetland monitoring report (pp. 46–47),
# "References for salinity tolerance" section. Each row is one primary-
# literature citation with a stable source_id slug. ANPC 2023 and GoA 2016
# are intentionally NOT included here — those lookups are for native/exotic
# determination, not salinity, and live in anpc_wetland_species / rangeland_plants.
references <- read.csv(
  here("data-raw", "references.csv"),
  stringsAsFactors = FALSE, encoding = "latin1"
)
usethis::use_data(references, overwrite = TRUE)

# Ecosite ↔ Wetland Class crosswalk (Beckingham & Archibald 1996) ─────────────
# Source: Table from Beckingham & Archibald (1996) — NFC ecosite phases for four
# Boreal natural regions matched to AWCS wetland class/form.
# Raw CSV is a merged-cell Excel export; data sit in columns 1, 6, 13, 19, 28.
# Cells may contain multiple "Ecosite phase XX (name)" entries separated by
# newlines; .parse_ecosite_cell() splits and extracts each one.

# Extract content of the outermost parenthesised group (handles nested parens).
.outer_paren <- function(s) {
  depth <- 0L; start <- NA_integer_
  for (i in seq_len(nchar(s))) {
    ch <- substr(s, i, i)
    if (ch == "(") { if (depth == 0L) start <- i; depth <- depth + 1L }
    else if (ch == ")") {
      depth <- depth - 1L
      if (depth == 0L && !is.na(start)) return(substr(s, start + 1L, i - 1L))
    }
  }
  NA_character_
}

.parse_ecosite_cell <- function(text) {
  if (is.na(text) || !nzchar(trimws(text)) ||
      grepl("^Not recognized", trimws(text), ignore.case = TRUE)) {
    return(data.frame(ecosite_code = NA_character_, ecosite_name = NA_character_,
                      notes = NA_character_, recognized = FALSE,
                      stringsAsFactors = FALSE))
  }
  text <- gsub("\r", "", text)
  text <- gsub("\\s*\\|\\s*", " ", text)  # strip | artefacts from PDF export

  # Case-insensitive sentinel insertion before each "Ecosite phase/Phase"
  marked <- gsub("((?i)Ecosite phase\\s)", "\x01\\1", text, perl = TRUE)
  parts  <- strsplit(marked, "\x01")[[1]]
  parts  <- parts[grepl("Ecosite phase", parts, ignore.case = TRUE)]

  if (!length(parts)) {
    return(data.frame(ecosite_code = NA_character_, ecosite_name = NA_character_,
                      notes = trimws(text), recognized = TRUE,
                      stringsAsFactors = FALSE))
  }

  do.call(rbind, lapply(parts, function(p_orig) {
    p_orig <- trimws(p_orig)
    p_flat <- trimws(gsub("\n", " ", p_orig))

    # Code(s): token(s) immediately after "Ecosite phase "
    # Handles "Ecosite phase g1", "Ecosite Phase f2", "Ecosite phase h1 and h2"
    codes_raw <- sub("^(?i)Ecosite phase\\s+([^(\\n]+?)\\s*(\\(.*)?$", "\\1",
                     p_flat, perl = TRUE)
    codes <- trimws(unlist(strsplit(codes_raw, "\\s+and\\s+")))
    codes <- codes[grepl("^[a-zA-Z]\\d", codes)]
    if (!length(codes)) codes <- NA_character_

    # Name: outermost parenthesised group (handles nested parens like "(Sw)")
    nm <- trimws(.outer_paren(p_flat))

    # Notes: lines that begin with "-" in the original multiline text
    note_lines <- grep("^\\s*-", strsplit(p_orig, "\n")[[1]], value = TRUE)
    notes <- if (length(note_lines)) paste(trimws(note_lines), collapse = "; ") else NA_character_

    data.frame(ecosite_code = codes, ecosite_name = nm, notes = notes,
               recognized = TRUE, stringsAsFactors = FALSE)
  }))
}

xwalk_raw <- read.csv(
  here("data-raw", "Ecosite_to_WetClass.csv"),
  header = FALSE, stringsAsFactors = FALSE, check.names = FALSE,
  na.strings = c("", "NA"), encoding = "latin1"
)

# Rows 1-2 are title/region headers; rows 3-13 are data (5 columns)
xwalk_sub <- xwalk_raw[3:nrow(xwalk_raw), 1:5]
names(xwalk_sub) <- c("wetland_form", "Boreal Mixedwood", "Boreal Highlands",
                       "Subarctic", "Canadian Shield")

# Collapse embedded newlines in form names (artefact of multiline CSV cells)
xwalk_sub$wetland_form <- trimws(gsub("\\s+", " ", xwalk_sub$wetland_form))

class_lut <- c(
  "Wooded Bog"                            = "Bog",
  "Shrubby Bog"                           = "Bog",
  "Wooded Fen"                            = "Fen",
  "Shrubby Fen"                           = "Fen",
  "Graminoid Fen"                         = "Fen",
  "Graminoid Marsh"                       = "Marsh",
  "Submersed/Floating Shallow Open Water" = "Open Water",
  "Coniferous Wooded Swamp"               = "Swamp",
  "Mixedwood Wooded Swamp"                = "Swamp",
  "Deciduous Wooded Swamp"                = "Swamp",
  "Shrubby Swamp"                         = "Swamp"
)
xwalk_sub$wetland_class <- class_lut[xwalk_sub$wetland_form]

ecosite_wetclass <- xwalk_sub |>
  pivot_longer(
    cols      = c("Boreal Mixedwood", "Boreal Highlands", "Subarctic", "Canadian Shield"),
    names_to  = "natural_region",
    values_to = "raw_entry"
  ) |>
  mutate(parsed = lapply(raw_entry, .parse_ecosite_cell)) |>
  select(-raw_entry) |>
  unnest(cols = parsed) |>
  select(wetland_class, wetland_form, natural_region,
         ecosite_code, ecosite_name, notes, recognized) |>
  mutate(notes = ifelse(trimws(notes) %in% c("-", ""), NA_character_, notes)) |>
  arrange(wetland_class, wetland_form, natural_region)

usethis::use_data(ecosite_wetclass, overwrite = TRUE)
rm(.outer_paren, .parse_ecosite_cell)

# NFC ecosite classification table (Beckingham & Archibald 1996 species/site data)
# TODO (Track 2): extract ecosites_nfc.csv from Ecosite_nfc PDF and uncomment
# ecosites_nfc <- read.csv(here("data-raw", "ecosites_nfc.csv"))
# usethis::use_data(ecosites_nfc, overwrite = TRUE)

# NRC geography regions and USACE geographic region linkage
# Maps Alberta Natural Regions to corresponding USACE NWPL regional lists.
nrc_geography <- read.csv(here("data-raw", "nrc_geography_usace.csv"))
usethis::use_data(nrc_geography, overwrite = TRUE)

# WAIR wetland classification decision rules (structured table)
# TODO (Track 2): author wair_classification_rules.csv from WAIR document and uncomment
# wair_rules <- read.csv(here("data-raw", "wair_classification_rules.csv"))
# usethis::use_data(wair_rules, overwrite = TRUE)

# ── Soils reference tables ────────────────────────────────────────────────────

# Canadian System of Soil Classification — great groups / orders
cssc_great_groups <- read.csv(here("data-raw", "cssc_great_groups.csv"))
usethis::use_data(cssc_great_groups, overwrite = TRUE)

# Von Post peat humification scale (H1–H10)
# Source: Von Post (1922); standard as used in Canadian peat assessment.
# CSV is a clean 5-column table: degree, liquid, extruded, plant matter,
# description. (Earlier exports had merged-cell padding columns that have
# since been normalised away.)
von_post_raw <- read.csv(here("data-raw", "Van_Post_List.csv"),
                          check.names = FALSE, stringsAsFactors = FALSE)
von_post <- data.frame(
  von_post_code = paste0("H", trimws(von_post_raw[[1]])),
  liquid        = trimws(von_post_raw[[2]]),
  extruded      = trimws(von_post_raw[[3]]),
  plant_matter  = trimws(von_post_raw[[4]]),
  description   = trimws(von_post_raw[[5]]),
  stringsAsFactors = FALSE
)
usethis::use_data(von_post, overwrite = TRUE)

# Munsell soil colour chart — full renotation dataset (10 450 chips)
# Source: aqp R package (Beaudette et al.) — derived from the Munsell Color
# Science Laboratory renotation data (Newhall 1943 / ISCC-NBS).
# Columns: hue, value, chroma, r, g, b (sRGB 0–1), L, A, B (CIE L*a*b*), hex.
# Used for soil colour display and hydric indicator assessment (low chroma ≤ 2).
# Requires aqp >= 2.0: install.packages("aqp")
local({
  e <- new.env()
  data("munsell", package = "aqp", envir = e)
  m <- e$munsell
  rgb_c <- pmin(pmax(m[, c("r", "g", "b")], 0), 1)
  m$hex <- rgb(rgb_c$r, rgb_c$g, rgb_c$b)
  munsell <<- m
})
usethis::use_data(munsell, overwrite = TRUE)
rm(munsell)

# NOTE: AGRASID was previously listed as a Track 2 dataset but has been
# dropped (issue #4 closing note): the data is a large spatial layer
# (polygons + soil correlation tables), not a tabular reference, and the
# wetland pipeline doesn't depend on it. If polygon overlays are needed
# in future, load AGRASID directly from its source GIS layer with sf/terra
# rather than baking it into data/.
