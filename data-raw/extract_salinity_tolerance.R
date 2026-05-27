# Extract canonical species_salinity_tolerance.csv from a project starter file.
#
# Source:  data-raw/projects/BD2025.042/VegSalinity_Starter.csv (not committed;
#          plot-level observations with salinity range repeated per row)
# Output:  data-raw/species_salinity_tolerance.csv (committed)
#
# The starter file is internally consistent — every species shares the same
# (salinity_range, most_saline, native_status, source) tuple across all of its
# observation rows. We dedup by normalised Latin name, keep the most common
# capitalisation of the common name, and remap the free-text "Source" column
# to a stable source_id slug that joins to references.csv.
#
# Re-run this only when the starter table is updated (new species or revised
# salinity calls). The committed CSV is the reference of record.

library(dplyr)
library(here)

starter_path <- here("data-raw", "projects", "BD2025.042", "VegSalinity_Starter.csv")
stopifnot(file.exists(starter_path))

source_map <- c(
  "ANPC origin"               = "anpc_2023",
  "GoA 2016 backup"           = "goa_2016",
  "Unmatched"                 = NA_character_,
  "Not a plant (bare/thatch)" = NA_character_
)

starter <- read.csv(starter_path, stringsAsFactors = FALSE, encoding = "latin1",
                    check.names = FALSE)

species_salinity_tolerance <- starter |>
  rename(
    species_latin   = `Latin Name`,
    species_common  = `Common Name`,
    wi_status       = `Vegetation Class`,
    salinity_range  = `Salinity Range`,
    most_saline     = `Most Saline`,
    latin_norm      = `Latin Name Norm`,
    native_status   = `Native Status`,
    source_raw      = Source
  ) |>
  mutate(across(c(species_latin, species_common, wi_status, salinity_range,
                  most_saline, latin_norm, native_status, source_raw), trimws)) |>
  filter(!latin_norm %in% c("", "-")) |>
  group_by(latin_norm) |>
  summarise(
    species_latin    = first(species_latin),
    # Most-frequent capitalisation of the common name
    species_common   = names(sort(table(species_common[nzchar(species_common)]),
                                   decreasing = TRUE))[1],
    wi_status        = first(wi_status),
    salinity_range   = first(salinity_range),
    most_saline      = first(most_saline),
    native_status    = first(native_status),
    lookup_source_id = unname(source_map[first(source_raw)]),
    n_observations   = dplyr::n(),
    .groups = "drop"
  ) |>
  select(species_latin, species_common, wi_status, salinity_range, most_saline,
         native_status, lookup_source_id, n_observations) |>
  arrange(species_latin)

out_path <- here("data-raw", "species_salinity_tolerance.csv")
write.csv(species_salinity_tolerance, out_path, row.names = FALSE, na = "")
message("Wrote: ", out_path, " (", nrow(species_salinity_tolerance), " species)")
