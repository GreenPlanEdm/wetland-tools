# inst/templates/create_excel_template.R
# Generates the blank vegetation & hydrology data-entry workbook.
# Run from project root: source("inst/templates/create_excel_template.R")
# Requires: openxlsx, here

library(openxlsx)
library(here)

OUT       <- here::here("inst", "templates", "vegetation_hydrology_data_entry.xlsx")
DATA_ROWS <- 2:1001   # 1000 data rows per sheet

wb <- createWorkbook(
  creator = "Green Plan Ltd.",
  title   = "Wetland Assessment — Vegetation & Hydrology Data Entry"
)

# ── Shared styles ─────────────────────────────────────────────────────────────
s_hdr <- createStyle(
  fgFill = "#2E5090", fontColour = "white", textDecoration = "bold",
  fontSize = 8, halign = "center", valign = "center", wrapText = TRUE,
  border = "TopBottomLeftRight", borderColour = "#FFFFFF"
)
s_eg <- createStyle(
  fontColour = "#999999", textDecoration = "italic", fontSize = 8,
  fgFill = "#F7FBFF"
)

# Helper: inline list dropdown validation
dv_list <- function(sheet, col_idx, choices) {
  dataValidation(wb, sheet,
    cols  = col_idx,
    rows  = DATA_ROWS,
    type  = "list",
    value = paste0('"', paste(choices, collapse = ","), '"')
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# plots sheet  (one row per field form)
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "plots", tabColour = "#2E5090", gridLines = TRUE)

plots_cols <- c(
  # Identification
  "project_id", "site_id", "plot_id", "observer",
  # Location & date
  "date", "gps_e", "gps_n", "datum",
  # General
  "awcs_class_obs", "photos_taken", "photo_numbers", "weather",
  # Hydrology — water presence
  "water_present", "water_depth_cm", "outlet",
  # Hydrology — inundation / saturation indicators (11 columns)
  "ind_watermarks", "ind_water_stained", "ind_oxidized_rhizo",
  "ind_saturation", "ind_iron_deposits", "ind_algal_mats",
  "ind_salt_crust", "ind_stunted_plants", "ind_marl_deposits",
  "ind_soil_cracks", "ind_frost_hummocks",
  # Hydrology — permanence
  "permanence_class",
  # Vegetation summary outcomes
  "determination", "dom_criterion",
  # Ecosite
  "ecosite", "nm_regime", "tree_mod", "structural_stage", "wi_region",
  # Remarks
  "remarks"
)
n_p <- length(plots_cols)
ci  <- setNames(seq_len(n_p), plots_cols)

# Write header row (0-row data frame so only column names are written)
writeData(wb, "plots",
  setNames(data.frame(matrix(nrow = 0, ncol = n_p)), plots_cols),
  startRow = 1
)

# Example row (row 2) — grey italic; delete before submitting
eg_plots <- data.frame(
  project_id         = "AB-2024-01",
  site_id            = "WL-01",
  plot_id            = "P-01",
  observer           = "J. Smith",
  date               = "2024-06-15",
  gps_e              = "350000",
  gps_n              = "5900000",
  datum              = "NAD83",
  awcs_class_obs     = "Marsh",
  photos_taken       = "TRUE",
  photo_numbers      = "001-005",
  weather            = "Sunny, 18°C",
  water_present      = "TRUE",
  water_depth_cm     = "12",
  outlet             = "Surface",
  ind_watermarks     = "TRUE",
  ind_water_stained  = "FALSE",
  ind_oxidized_rhizo = "TRUE",
  ind_saturation     = "TRUE",
  ind_iron_deposits  = "FALSE",
  ind_algal_mats     = "FALSE",
  ind_salt_crust     = "FALSE",
  ind_stunted_plants = "FALSE",
  ind_marl_deposits  = "FALSE",
  ind_soil_cracks    = "FALSE",
  ind_frost_hummocks = "FALSE",
  permanence_class   = "Semi-permanent",
  determination      = "Wetland",
  dom_criterion      = "Met",
  ecosite            = "w2b",
  nm_regime          = "C3",
  tree_mod           = "Sw",
  structural_stage   = "3",
  wi_region          = "WMVC",
  remarks            = "Riparian marsh. Saturated at surface throughout."
)
writeData(wb, "plots", eg_plots, startRow = 2, colNames = FALSE)

# ── Data validation ───────────────────────────────────────────────────────────
dv_list("plots", ci["datum"],         c("NAD83", "WGS84"))
dv_list("plots", ci["photos_taken"],  c("TRUE",  "FALSE"))
dv_list("plots", ci["water_present"], c("TRUE",  "FALSE"))
dv_list("plots", ci["outlet"],        c("None", "Surface", "Subsurface", "Both"))

for (nm in c("ind_watermarks",    "ind_water_stained", "ind_oxidized_rhizo",
             "ind_saturation",    "ind_iron_deposits", "ind_algal_mats",
             "ind_salt_crust",    "ind_stunted_plants","ind_marl_deposits",
             "ind_soil_cracks",   "ind_frost_hummocks")) {
  dv_list("plots", ci[nm], c("TRUE", "FALSE"))
}

dv_list("plots", ci["permanence_class"],
        c("Ephemeral", "Intermittent", "Semi-permanent", "Permanent"))
dv_list("plots", ci["determination"], c("Wetland", "Non-wetland", "Inconclusive"))
dv_list("plots", ci["dom_criterion"], c("Met", "Not met", "Marginal"))
dv_list("plots", ci["structural_stage"], as.character(1:7))
dv_list("plots", ci["wi_region"], c("AK", "WMVC", "GP", "NCNE"))

dataValidation(wb, "plots",
  cols = ci["water_depth_cm"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0"
)

# ── Column widths ─────────────────────────────────────────────────────────────
widths_p <- c(
  project_id = 14, site_id = 12, plot_id = 12, observer = 16,
  date = 12, gps_e = 12, gps_n = 12, datum = 9,
  awcs_class_obs = 22, photos_taken = 9, photo_numbers = 12, weather = 16,
  water_present = 10, water_depth_cm = 10, outlet = 12,
  ind_watermarks = 10, ind_water_stained = 10, ind_oxidized_rhizo = 10,
  ind_saturation = 10, ind_iron_deposits = 10, ind_algal_mats = 10,
  ind_salt_crust = 10, ind_stunted_plants = 10, ind_marl_deposits = 10,
  ind_soil_cracks = 10, ind_frost_hummocks = 10,
  permanence_class = 16, determination = 13, dom_criterion = 11,
  ecosite = 10, nm_regime = 10, tree_mod = 10,
  structural_stage = 9, wi_region = 9,
  remarks = 40
)
setColWidths(wb, "plots", cols = seq_len(n_p), widths = unname(widths_p))
setRowHeights(wb, "plots", rows = 1, heights = 38)
freezePane(wb, "plots", firstActiveRow = 2, firstActiveCol = 4)

addStyle(wb, "plots", s_hdr, rows = 1, cols = seq_len(n_p), gridExpand = TRUE)
addStyle(wb, "plots", s_eg,  rows = 2, cols = seq_len(n_p), gridExpand = TRUE)


# ══════════════════════════════════════════════════════════════════════════════
# species sheet  (one row per species observation)
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "species", tabColour = "#4A7C59", gridLines = TRUE)

species_cols <- c("plot_id", "spp_code", "spp_name",
                  "stratum", "pct_cover", "native_exotic", "notes")
n_s  <- length(species_cols)
ci_s <- setNames(seq_len(n_s), species_cols)

writeData(wb, "species",
  setNames(data.frame(matrix(nrow = 0, ncol = n_s)), species_cols),
  startRow = 1
)

eg_species <- data.frame(
  plot_id       = "P-01",
  spp_code      = "TYPH.LATI",
  spp_name      = "Typha latifolia",
  stratum       = "G",
  pct_cover     = "30",
  native_exotic = "N",
  notes         = ""
)
writeData(wb, "species", eg_species, startRow = 2, colNames = FALSE)

dv_list("species", ci_s["stratum"],       c("T", "S", "G", "M"))
dv_list("species", ci_s["native_exotic"], c("N", "E"))
dataValidation(wb, "species",
  cols = ci_s["pct_cover"], rows = DATA_ROWS,
  type = "decimal", operator = "between", value = c("0", "100")
)

setColWidths(wb, "species",
  cols = seq_len(n_s), widths = c(12, 14, 28, 8, 10, 12, 30))
setRowHeights(wb, "species", rows = 1, heights = 30)
freezePane(wb, "species", firstActiveRow = 2, firstActiveCol = 1)

addStyle(wb, "species", s_hdr, rows = 1, cols = seq_len(n_s), gridExpand = TRUE)
addStyle(wb, "species", s_eg,  rows = 2, cols = seq_len(n_s), gridExpand = TRUE)


# ══════════════════════════════════════════════════════════════════════════════
# README sheet
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "README", tabColour = "#CC4400", gridLines = FALSE)

readme <- as.data.frame(rbind(
  c("OVERVIEW",
    paste("One row in 'plots' per field form; one row per species in 'species'.",
          "Delete the grey example rows before submitting.",
          "Sheet names must not be renamed — 01_ingest.Rmd reads them by name.")),
  c("DATE FORMAT",
    "Enter dates as YYYY-MM-DD text (e.g. 2024-06-15). Do not use Excel date serial numbers."),
  c("DO NOT TRANSCRIBE",
    paste("The following are computed by R from the species list and reference tables",
          "and must NOT be entered here:",
          "WI Status per species (OBL / FACW / FAC / FACU / UPL / NL),",
          "Invasive (Y/N) and Noxious (Y/N) per species,",
          "Vegetation Summary counts (sum_obl ... sum_total),",
          "and Dominance Test counts (dom_obl_facw_fac, dom_total_spp).")),
  c("plots — columns",
    paste("plot_id: primary key (must match species sheet) |",
          "date: YYYY-MM-DD |",
          "datum: NAD83 or WGS84 |",
          "outlet: None / Surface / Subsurface / Both |",
          "ind_*: TRUE if indicator was observed, FALSE if not (11 indicator columns) |",
          "permanence_class: Ephemeral / Intermittent / Semi-permanent / Permanent (per GWPWB) |",
          "determination: Wetland / Non-wetland / Inconclusive |",
          "dom_criterion: Met / Not met / Marginal |",
          "remarks: combined hydrology notes and general observations")),
  c("species — columns",
    paste("plot_id: foreign key matching plots sheet |",
          "spp_code: ACIMS-style code (4-letter genus + '.' + 4-letter epithet, e.g. TYPH.LATI for Typha latifolia) — must match the spp_code column in the awcs_wetland_species reference table (data/awcs_wetland_species.rda) |",
          "spp_name: scientific name (optional — R looks up from reference table) |",
          "stratum: T (tree >10 m) / S (shrub >5 m) / G (ground 1x1 m) / M (moss 1x1 m) |",
          "native_exotic: N (native) or E (exotic/introduced)")),
  c("SPECIES CODES",
    paste("Codes follow the ACIMS (Alberta Centre for Information on Alberta Species) binomial convention:",
          "first 4 letters of genus + '.' + first 4 letters of specific epithet, all uppercase (e.g. CARE.AQUA, TYPH.LATI, SALI.EXIG).",
          "The complete code list is in the R package reference table: data/awcs_wetland_species.rda (column spp_code).",
          "Source plant list: Alberta Wetland Plant List (ACIMS / AEP) —",
          "INSERT ACIMS URL HERE (contact Alberta Environment and Protected Areas or search 'ACIMS wetland plant list Alberta')."))
), stringsAsFactors = FALSE)

writeData(wb, "README", readme, startRow = 1, colNames = FALSE)

s_rm_key <- createStyle(
  fgFill = "#2E5090", fontColour = "white", textDecoration = "bold",
  fontSize = 9, valign = "top", wrapText = TRUE
)
s_rm_val <- createStyle(
  fontSize = 9, valign = "top", wrapText = TRUE,
  border = "Bottom", borderColour = "#CCCCCC"
)

addStyle(wb, "README", s_rm_key, rows = 1:6, cols = 1, gridExpand = TRUE)
addStyle(wb, "README", s_rm_val, rows = 1:6, cols = 2, gridExpand = TRUE)
setColWidths(wb, "README", cols = 1:2, widths = c(20, 85))
setRowHeights(wb, "README", rows = 1:6, heights = c(36, 28, 60, 80, 60, 72))


# ── Save ───────────────────────────────────────────────────────────────────────
saveWorkbook(wb, OUT, overwrite = TRUE)
message("Saved: ", OUT)
