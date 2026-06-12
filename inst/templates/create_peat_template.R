# inst/templates/create_peat_template.R
# Generates the blank peatland data-entry workbook.
# Column layout matches "Peatland Field Sheet.pdf" exactly.
# Run from project root: source("inst/templates/create_peat_template.R")
# Requires: openxlsx, here

library(openxlsx)
library(here)

OUT <- here::here("inst", "templates", "peat_data_entry.xlsx")

# Title row 1, column-header row 2, example row 3, data from row 4 onward
DATA_ROWS <- 4:1003

wb <- createWorkbook(
  creator = "Green Plan Ltd.",
  title   = "Peatland Assessment — Data Entry"
)

# ── Shared styles ─────────────────────────────────────────────────────────────
s_title <- createStyle(
  fgFill = "#2E5090", fontColour = "white", textDecoration = "bold",
  fontSize = 11, halign = "left", valign = "center"
)
s_hdr <- createStyle(
  fgFill = "#5C3A1E", fontColour = "white", textDecoration = "bold",
  fontSize = 8, halign = "center", valign = "center", wrapText = TRUE,
  border = "TopBottomLeftRight", borderColour = "#FFFFFF"
)
s_eg <- createStyle(
  fontColour = "#999999", textDecoration = "italic", fontSize = 8,
  fgFill = "#FDF5EE"
)

dv_list <- function(sheet, col_idx, choices) {
  dataValidation(wb, sheet,
    cols  = col_idx,
    rows  = DATA_ROWS,
    type  = "list",
    value = paste0('"', paste(choices, collapse = ","), '"')
  )
}

# AWCS wetland class-and-form vocabulary — first column of
# data-raw/Ecosite_to_WetClass.csv. Keeps the dropdown traceable to the
# project's reference data (AWCS). Edit there + here if the list changes.
awcs_classes <- c(
  "Wooded Bog", "Shrubby Bog",
  "Wooded Fen", "Shrubby Fen", "Graminoid Fen",
  "Graminoid Marsh",
  "Submersed/Floating Shallow Open Water",
  "Coniferous Wooded Swamp", "Mixedwood Wooded Swamp",
  "Deciduous Wooded Swamp", "Shrubby Swamp"
)


# ══════════════════════════════════════════════════════════════════════════════
# plots sheet  — header-band fields from the field sheet (one row per test hole)
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "plots", tabColour = "#2E5090", gridLines = TRUE)

plots_cols <- c(
  # ── Field-sheet header band ────────────────────────────────────────────────
  "project_id",          # Project
  "plot_id",             # Plot
  "date",                # Date (YYYY-MM-DD)
  "crew",                # Crew
  "awcs_wetland_class",  # AWCS Wetland Class (dropdown)
  "utm_zone",            # UTM (11N / 12N)
  "gps_easting",         # Easting
  "gps_northing",        # Northing
  "elevation_m",         # Elevation above Sea Level (m)
  "dominant_bryophyte",  # Dominant Bryophyte
  "water_table_depth_m", # Depth to Water Table (m)
  "ph",                  # pH (one value per test hole)
  "conductivity_us_cm",  # Conductivity (uS/cm) (one value per test hole)
  # ── Field-sheet footer ─────────────────────────────────────────────────────
  "remarks"              # Remarks
)
n_p  <- length(plots_cols)
ci_p <- setNames(seq_len(n_p), plots_cols)

# Title banner — row 1
mergeCells(wb, "plots", cols = 1:n_p, rows = 1)
writeData(wb, "plots",
  "PEATLAND FIELD DATA SHEET  ·  Alberta Wetland Assessment",
  startRow = 1, startCol = 1, colNames = FALSE)
addStyle(wb, "plots", s_title, rows = 1, cols = 1:n_p, gridExpand = TRUE)
setRowHeights(wb, "plots", rows = 1, heights = 26)

# Column headers — row 2
writeData(wb, "plots",
  setNames(data.frame(matrix(nrow = 0, ncol = n_p)), plots_cols),
  startRow = 2)
addStyle(wb, "plots", s_hdr, rows = 2, cols = 1:n_p, gridExpand = TRUE)
setRowHeights(wb, "plots", rows = 2, heights = 38)

# Example row — row 3
eg_plots <- data.frame(
  project_id          = "AB-2024-01",
  plot_id             = "TH-01",
  date                = "2024-06-15",
  crew                = "J. Smith, A. Lee",
  awcs_wetland_class  = "Wooded Fen",
  utm_zone            = "12N",
  gps_easting         = "350000",
  gps_northing        = "5900000",
  elevation_m         = "720",
  dominant_bryophyte  = "Sphagnum fuscum",
  water_table_depth_m = "0.25",
  ph                  = "5.2",
  conductivity_us_cm  = "140",
  remarks             = "Hummock-hollow microtopography; Larix laricina scattered."
)
writeData(wb, "plots", eg_plots, startRow = 3, colNames = FALSE)
addStyle(wb, "plots", s_eg, rows = 3, cols = 1:n_p, gridExpand = TRUE)

# ── Data validation ───────────────────────────────────────────────────────────
dv_list("plots", ci_p["awcs_wetland_class"], awcs_classes)
dv_list("plots", ci_p["utm_zone"], c("11N", "12N"))
dataValidation(wb, "plots",
  cols = ci_p["elevation_m"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0")
dataValidation(wb, "plots",
  cols = ci_p["water_table_depth_m"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0")
dataValidation(wb, "plots",
  cols = ci_p["ph"], rows = DATA_ROWS,
  type = "decimal", operator = "between", value = c("0", "14"))
dataValidation(wb, "plots",
  cols = ci_p["conductivity_us_cm"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0")
dataValidation(wb, "plots",
  cols = ci_p["gps_easting"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0")
dataValidation(wb, "plots",
  cols = ci_p["gps_northing"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0")

# ── Column widths & freeze ─────────────────────────────────────────────────────
widths_p <- c(
  project_id = 14, plot_id = 12, date = 12, crew = 18,
  awcs_wetland_class = 22, utm_zone = 9,
  gps_easting = 13, gps_northing = 13, elevation_m = 14,
  dominant_bryophyte = 22, water_table_depth_m = 14,
  ph = 7, conductivity_us_cm = 14,
  remarks = 44
)
setColWidths(wb, "plots", cols = seq_len(n_p), widths = unname(widths_p))
freezePane(wb, "plots", firstActiveRow = 4, firstActiveCol = 3)


# ══════════════════════════════════════════════════════════════════════════════
# horizons sheet  — one row per peat interval; columns match the field-sheet table
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "horizons", tabColour = "#5C3A1E", gridLines = TRUE)

horizons_cols <- c(
  # Keys
  "project_id", "plot_id",
  # Field-sheet table columns (left to right)
  "horizon",            # Horizon
  "depth_top_cm",       # Top depth of the interval (cm)
  "depth_bot_cm",       # Bottom depth of the interval (cm)
  "peat_water_colour",  # Color of Peat Water
  "squeeze_escape",     # Escape of peat material from squeeze
  "peat_colour",        # Peat Colour
  "von_post"            # Von Post Humification (H1–H10) (dropdown)
)
n_h  <- length(horizons_cols)
ci_h <- setNames(seq_len(n_h), horizons_cols)

# Title banner — row 1
mergeCells(wb, "horizons", cols = 1:n_h, rows = 1)
writeData(wb, "horizons",
  "PEATLAND FIELD DATA SHEET  ·  Peat Profile (per interval)",
  startRow = 1, startCol = 1, colNames = FALSE)
addStyle(wb, "horizons", s_title, rows = 1, cols = 1:n_h, gridExpand = TRUE)
setRowHeights(wb, "horizons", rows = 1, heights = 26)

# Column headers — row 2
writeData(wb, "horizons",
  setNames(data.frame(matrix(nrow = 0, ncol = n_h)), horizons_cols),
  startRow = 2)
addStyle(wb, "horizons", s_hdr, rows = 2, cols = 1:n_h, gridExpand = TRUE)
setRowHeights(wb, "horizons", rows = 2, heights = 38)

# Example row — row 3
eg_horizons <- data.frame(
  project_id         = "AB-2024-01",
  plot_id            = "TH-01",
  horizon            = "Of",
  depth_top_cm       = "0",
  depth_bot_cm       = "25",
  peat_water_colour  = "Slightly turbid, brown",
  squeeze_escape     = "None",
  peat_colour        = "10YR 3/2",
  von_post           = "H3"
)
writeData(wb, "horizons", eg_horizons, startRow = 3, colNames = FALSE)
addStyle(wb, "horizons", s_eg, rows = 3, cols = 1:n_h, gridExpand = TRUE)

# ── Data validation ───────────────────────────────────────────────────────────
# Von Post humification scale H1–H10 (dropdown)
dv_list("horizons", ci_h["von_post"], paste0("H", 1:10))
dataValidation(wb, "horizons",
  cols = ci_h["depth_top_cm"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0")
dataValidation(wb, "horizons",
  cols = ci_h["depth_bot_cm"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0")

# ── Column widths & freeze ─────────────────────────────────────────────────────
widths_h <- c(
  project_id = 14, plot_id = 12,
  horizon = 9, depth_top_cm = 9, depth_bot_cm = 9,
  peat_water_colour = 26, squeeze_escape = 20,
  peat_colour = 14, von_post = 10
)
setColWidths(wb, "horizons", cols = seq_len(n_h), widths = unname(widths_h))
freezePane(wb, "horizons", firstActiveRow = 4, firstActiveCol = 3)


# ══════════════════════════════════════════════════════════════════════════════
# README sheet
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "README", tabColour = "#CC4400", gridLines = FALSE)

readme <- as.data.frame(rbind(
  c("OVERVIEW",
    paste("One row in 'plots' per test hole (the field-sheet header band).",
          "One row per peat interval in 'horizons' (the field-sheet table).",
          "Delete the grey example rows before submitting.",
          "Sheet names must not be renamed — 01_ingest.Rmd reads them by name.",
          "plot_id must match exactly between the two sheets.")),
  c("DATE FORMAT",
    "Enter dates as YYYY-MM-DD text (e.g. 2024-06-15). Do not use Excel date serial numbers."),
  c("plots — header fields",
    paste(
      "project_id / plot_id: identifiers (plot_id is the primary key for the test hole) |",
      "crew: field crew names |",
      "awcs_wetland_class: AWCS class-and-form from the dropdown (Bog / Fen / Marsh / Swamp / Shallow Open Water variants) |",
      "utm_zone: UTM zone 11N or 12N (NAD83) |",
      "gps_easting / gps_northing: UTM coordinates in the zone above |",
      "elevation_m: ground elevation above sea level (m) |",
      "dominant_bryophyte: dominant surface bryophyte (scientific name, e.g. Sphagnum fuscum) |",
      "water_table_depth_m: depth to water table (m) below ground surface — one value per test hole |",
      "ph: peat / pore-water pH — one value per test hole |",
      "conductivity_us_cm: electrical conductivity (uS/cm) — one value per test hole |",
      "remarks: free-text notes from the field-sheet footer"
    )),
  c("horizons — peat profile",
    paste(
      "One row per peat interval, top of profile downward, ending at the mineral contact.",
      "horizon: field-recorded horizon designation (e.g. Of / Om / Oh) |",
      "depth_top_cm / depth_bot_cm: top and bottom depth (cm) of the interval.",
      "Intervals should be contiguous (each row's depth_top_cm = previous row's depth_bot_cm,",
      "starting at 0); the deepest depth_bot_cm is the mineral contact = peat depth.",
      "03_transform.Rmd derives interval thickness from these. |",
      "peat_water_colour: colour of water squeezed from the peat (Von Post liquid description) |",
      "squeeze_escape: amount of peat material escaping between the fingers on squeeze",
      "(Von Post field test, e.g. None / One third / One half) |",
      "peat_colour: Munsell or descriptive colour of the peat matrix |",
      "von_post: Von Post humification class H1–H10 from the dropdown"
    )),
  c("horizons — Von Post",
    paste(
      "Von Post humification scale H1–H10.",
      "H1-H3 = Fibric (raw, undecomposed peat);",
      "H4-H6 = Mesic (moderately decomposed);",
      "H7-H10 = Humic (well decomposed).",
      "See data-raw/Van_Post_List.csv for the full squeeze-test descriptions."
    )),
  c("DO NOT COMPUTE",
    paste(
      "The following are derived by R in 03_transform.Rmd — do NOT enter manually:",
      "interval_thickness_cm (from depth_bot_cm - depth_top_cm),",
      "peat_depth_cm (depth to mineral contact),",
      "professional vs retail peat thickness (von_post H1-H4 vs H5-H6),",
      "harvestable volume (with the 0.5 m reclamation allowance removed from the base of the profile)."
    ))
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

n_rows <- nrow(readme)
addStyle(wb, "README", s_rm_key, rows = seq_len(n_rows), cols = 1, gridExpand = TRUE)
addStyle(wb, "README", s_rm_val, rows = seq_len(n_rows), cols = 2, gridExpand = TRUE)
setColWidths(wb, "README", cols = 1:2, widths = c(22, 85))
setRowHeights(wb, "README", rows = seq_len(n_rows),
              heights = c(60, 28, 132, 144, 60, 72))


# ── Save ───────────────────────────────────────────────────────────────────────
saveWorkbook(wb, OUT, overwrite = TRUE)
message("Saved: ", OUT)
