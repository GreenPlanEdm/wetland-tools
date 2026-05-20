# Extract AISC Invasive Plants of Alberta (4th ed. 2022) species list to CSV.
#
# Source PDF: data-raw/AB_2022_Invasive_Plant_Guide.pdf (not committed; ~12 MB)
# Output:     data-raw/aisc_invasive_plants.csv (committed)
#
# Each species fact sheet (pages ~48–135) has the title "Common Name (Genus
# species)" and a "WEED CONTROL ACT DESIGNATION: PROHIBITED NOXIOUS|NOXIOUS|
# UNREGULATED" line. Multi-page species are deduped by scientific name.

library(pdftools)
library(stringr)
library(here)

pdf_path <- here("data-raw", "AB_2022_Invasive_Plant_Guide.pdf")
stopifnot(file.exists(pdf_path))

pages <- pdf_text(pdf_path)

# Designation line regex
desig_re <- regex(
  "WEED\\s+CONTROL\\s+ACT\\s+DESIGNATION:\\s*(PROHIBITED\\s+NOXIOUS|NOXIOUS|UNREGULATED)",
  ignore_case = TRUE
)

# Species title regex — works on a flattened (single-line, no designation) page.
# Allows:
#   - common names that span multiple words / commas / apostrophes / hyphens
#     (e.g. "Hawkweed, Meadow", "St John's-wort, Common")
#   - hybrid markers between genus and species (× or x)
#   - parenthetical content after species (subsp., "formerly Foo bar")
title_re <- regex(
  paste0(
    "([A-Z][A-Za-z'\\u2019\\-]+(?:[\\s,]+[A-Za-z'\\u2019\\-]+)*)",  # common name
    "\\s*\\(\\s*",
    "([A-Z][a-z\\-]+)",                                                 # genus
    "\\s+(?:\\u00D7\\s+|x\\s+)?",                                       # hybrid marker
    "([a-z\\-]+|spp\\.)"                                                # species epithet
  )
)

records <- list()
for (i in seq_along(pages)) {
  page <- pages[i]
  if (!str_detect(page, desig_re)) next

  desig_match <- str_match(page, desig_re)[1, 2] |> toupper() |> str_squish()
  designation <- switch(
    desig_match,
    "PROHIBITED NOXIOUS" = "prohibited_noxious",
    "NOXIOUS"            = "noxious",
    "UNREGULATED"        = "unregulated_invasive",
    NA_character_
  )

  # Flatten whitespace and strip the designation line so it doesn't fall
  # between the common name and the (Binomial) on multi-line titles.
  flat <- str_replace_all(page, "\\s+", " ")
  flat <- str_replace_all(flat, desig_re, " ")

  tm <- str_match(flat, title_re)
  if (is.na(tm[1, 1])) next  # continuation pages (e.g. p68, p86) — skip silently

  common  <- str_squish(tm[1, 2])
  genus   <- tm[1, 3]
  species <- tm[1, 4]
  # Detect and preserve hybrid marker
  is_hybrid <- str_detect(flat, paste0("\\(\\s*", genus, "\\s+\\u00D7\\s+", species)) |
               str_detect(flat, paste0("\\(\\s*", genus, "\\s+x\\s+",       species))
  sci <- if (is_hybrid) paste(genus, "×", species) else paste(genus, species)

  records[[length(records) + 1]] <- data.frame(
    scientific_name = sci,
    common_name     = common,
    aisc_category   = designation,
    stringsAsFactors = FALSE
  )
}

df <- do.call(rbind, records)
df <- df[!duplicated(df$scientific_name), ]

# Normalise typographic apostrophes to ASCII so downstream string joins work
df$common_name <- str_replace_all(df$common_name, "’", "'")

# Convenience boolean: regulated under the AB Weed Control Act?
df$wca_regulated <- df$aisc_category %in% c("prohibited_noxious", "noxious")

df <- df[order(df$aisc_category, df$scientific_name),
         c("scientific_name", "common_name", "aisc_category", "wca_regulated")]
rownames(df) <- NULL

cat("Extracted", nrow(df), "species:\n")
print(table(df$aisc_category))

write.csv(df, here("data-raw", "aisc_invasive_plants.csv"),
          row.names = FALSE, quote = TRUE)
cat("\nWrote", here("data-raw", "aisc_invasive_plants.csv"), "\n")
