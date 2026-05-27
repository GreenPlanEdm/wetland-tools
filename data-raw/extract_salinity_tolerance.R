# Extract canonical species_salinity_tolerance.csv from BD2025.042 project files.
#
# Inputs (both gitignored; project-private):
#   data-raw/projects/BD2025.042/VegSalinity_Starter.csv
#     - plot-level observations with a per-row Salinity Range column populated
#       by an earlier upstream lookup; 57 unique species.
#   data-raw/projects/BD2025.042/Veg_Analysis_v1.2.Rmd
#     - hand-curated salinity tribble (36 species) representing the analyst's
#       gold-standard literature-backed assignments; values trace to the
#       primary papers in references.csv.
#
# Output (committed):
#   data-raw/species_salinity_tolerance.csv
#
# Merge policy: starter rows form the base; v1.2 entries override where both
# exist. Of the 36 v1.2 entries, 29 filled "Unknown" gaps in the starter and
# 1 narrowed a wider range (Carex atherodes: "slightly brackish -
# moderately brackish" → "slightly brackish"). After merge all 57 species
# have a known salinity range.
#
# most_saline is derived from salinity_range by taking the last "-" segment
# (the wetter / more saline end of the band), or the value as-is when there
# is no range. Matches the logic in Veg_Analysis_v1.2.Rmd.
#
# provenance column ("v1.2_curated" | "starter") makes the source of each
# row's value auditable; QA/QC reviewers can spot-check v1.2_curated rows
# against references.csv directly.
#
# Note: the starter file's "Source" column ("ANPC origin" / "GoA 2016 backup")
# refers to native/exotic determination, NOT salinity provenance, and is
# intentionally dropped from this reference table.

library(dplyr)
library(stringr)
library(tibble)
library(here)

starter_path <- here("data-raw", "projects", "BD2025.042", "VegSalinity_Starter.csv")
stopifnot(file.exists(starter_path))

# v1.2 hand-curated tribble (transcribed from Veg_Analysis_v1.2.Rmd lines ~407-446)
v12 <- tribble(
  ~species_latin,                     ~salinity_range,
  "Carex atherodes",                  "slightly brackish",
  "Cirsium arvense",                  "freshwater - moderately brackish",
  "Typha latifolia",                  "freshwater",
  "Schoenoplectus tabernaemontani",   "slightly brackish - brackish",
  "Plantago major",                   "freshwater",
  "Hordeum jubatum",                  "slightly brackish - brackish",
  "Poa pratensis",                    "freshwater",
  "Phalaris arundinacea",             "moderately brackish",
  "Bromus inermis",                   "moderately brackish",
  "Populus balsamifera",              "freshwater",
  "Brassica napus",                   "moderately brackish",
  "Chenopodium album",                "brackish",
  "Sonchus asper",                    "moderately brackish",
  "Linaria vulgaris",                 "slightly brackish",
  "Calamagrostis canadensis",         "slightly brackish",
  "Populus tremuloides",              "freshwater",
  "Fallopia convolvulus",             "freshwater",
  "Rorippa sylvestris",               "slightly brackish",
  "Capsella bursa-pastoris",          "slightly brackish",
  "Rumex fueginus",                   "slightly brackish",
  "Schoenoplectus acutus",            "slightly brackish - brackish",
  "Tanacetum vulgare",                "slightly brackish",
  "Agrostis scabra",                  "slightly brackish",
  "Brassica rapa",                    "moderately brackish",
  "Juncus compressus",                "slightly brackish",
  "Avena sativa",                     "freshwater",
  "Rosa acicularis",                  "freshwater",
  "Chamerion angustifolium",          "freshwater",
  "Galium boreale",                   "freshwater",
  "Salix discolor",                   "freshwater",
  "Salix interior",                   "freshwater",
  "Salix serissima",                  "freshwater",
  "Scutellaria galericulata",         "freshwater",
  "Setaria viridis",                  "freshwater",
  "Elymus albicans",                  "freshwater",
  "Silene latifolia",                 "freshwater",
) |>
  mutate(latin_norm = str_to_lower(str_trim(species_latin)))

# Most-saline end of a range string (matches Veg_Analysis_v1.2.Rmd derivation).
.most_saline <- function(rng) {
  rng <- trimws(rng)
  out <- ifelse(rng == "" | tolower(rng) == "unknown", "Unknown",
         ifelse(grepl("-", rng), trimws(sub(".*-", "", rng)), rng))
  out
}

starter <- read.csv(starter_path, stringsAsFactors = FALSE, encoding = "latin1",
                    check.names = FALSE) |>
  rename(
    species_latin   = `Latin Name`,
    species_common  = `Common Name`,
    salinity_range  = `Salinity Range`,
    latin_norm      = `Latin Name Norm`
  ) |>
  mutate(across(c(species_latin, species_common, salinity_range, latin_norm), trimws),
         latin_norm = str_to_lower(latin_norm)) |>
  filter(!latin_norm %in% c("", "-"))

# Per-species summary from starter (one row per species, most-frequent common-name spelling)
starter_species <- starter |>
  group_by(latin_norm) |>
  summarise(
    species_latin   = first(species_latin),
    species_common  = names(sort(table(species_common[nzchar(species_common)]),
                                  decreasing = TRUE))[1],
    salinity_range  = first(salinity_range),
    .groups = "drop"
  )

# Merge: v1.2 wins on overlap; v1.2-only species (none in current data) would
# be added as new rows.
species_salinity_tolerance <- starter_species |>
  full_join(v12 |> select(latin_norm, v12_range = salinity_range, v12_latin = species_latin),
            by = "latin_norm") |>
  mutate(
    provenance     = if_else(!is.na(v12_range), "v1.2_curated", "starter"),
    salinity_range = if_else(!is.na(v12_range), v12_range, salinity_range),
    species_latin  = if_else(is.na(species_latin), v12_latin, species_latin),
    species_common = if_else(is.na(species_common), "", species_common),
    most_saline    = .most_saline(salinity_range)
  ) |>
  select(species_latin, species_common, salinity_range, most_saline, provenance) |>
  arrange(species_latin)

out_path <- here("data-raw", "species_salinity_tolerance.csv")
write.csv(species_salinity_tolerance, out_path, row.names = FALSE, na = "")
message("Wrote: ", out_path, " (", nrow(species_salinity_tolerance), " species; ",
        sum(species_salinity_tolerance$provenance == "v1.2_curated"), " v1.2-curated, ",
        sum(species_salinity_tolerance$provenance == "starter"), " starter)")
