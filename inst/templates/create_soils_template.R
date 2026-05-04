# inst/templates/create_soils_template.R
# Generates the blank soils data-entry workbook.
# Column layout matches soils_field_form.pdf exactly.
# Run from project root: source("inst/templates/create_soils_template.R")
# Requires: openxlsx, here

library(openxlsx)
library(here)

OUT <- here::here("inst", "templates", "soils_data_entry.xlsx")

# Title row 1, column-header row 2, example row 3, data from row 4 onward
DATA_ROWS <- 4:1003

wb <- createWorkbook(
  creator = "Green Plan Ltd.",
  title   = "Wetland Assessment — Soils Data Entry"
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


# ══════════════════════════════════════════════════════════════════════════════
# plots sheet  — header + footer fields from the field form (one row per plot)
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "plots", tabColour = "#2E5090", gridLines = TRUE)

plots_cols <- c(
  # ── Form header ──────────────────────────────────────────────────────────
  "project_id", "site_id", "plot_id", "observer",
  "method",              # Pit or Probe
  "depth_restrict_cm",   # Depth to Restrictive Layer
  "date",                # YYYY-MM-DD
  "gps_easting", "gps_northing",
  # ── Form footer ──────────────────────────────────────────────────────────
  "hydric_ind_present",  # Hydric Soil Indicators Present
  "hydric_criterion_met",# Hydric Soil Criterion Met
  "soil_great_group",    # Soil Great Group (field assessment)
  "additional_notes"
)
n_p  <- length(plots_cols)
ci_p <- setNames(seq_len(n_p), plots_cols)

# Title banner — row 1
mergeCells(wb, "plots", cols = 1:n_p, rows = 1)
writeData(wb, "plots",
  "SOILS FIELD DATA FORM  ·  Alberta Wetland Assessment",
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
  site_id             = "WL-01",
  plot_id             = "SP-01",
  observer            = "J. Smith",
  method              = "Pit",
  depth_restrict_cm   = "85",
  date                = "2024-06-15",
  gps_easting         = "350000",
  gps_northing        = "5900000",
  hydric_ind_present  = "Yes",
  hydric_criterion_met= "Yes",
  soil_great_group    = "Humic Gleysol",
  additional_notes    = "Strong sulphidic odour; saturated at surface."
)
writeData(wb, "plots", eg_plots, startRow = 3, colNames = FALSE)
addStyle(wb, "plots", s_eg, rows = 3, cols = 1:n_p, gridExpand = TRUE)

# ── Data validation ───────────────────────────────────────────────────────────
dv_list("plots", ci_p["method"],
        c("Pit", "Probe"))
dv_list("plots", ci_p["hydric_ind_present"],
        c("Yes", "No"))
dv_list("plots", ci_p["hydric_criterion_met"],
        c("Yes", "No", "Marginal"))
dataValidation(wb, "plots",
  cols = ci_p["depth_restrict_cm"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0")

# ── Column widths & freeze ─────────────────────────────────────────────────────
widths_p <- c(
  project_id = 14, site_id = 12, plot_id = 12, observer = 16,
  method = 8, depth_restrict_cm = 12,
  date = 12, gps_easting = 13, gps_northing = 13,
  hydric_ind_present = 13, hydric_criterion_met = 13,
  soil_great_group = 24, additional_notes = 44
)
setColWidths(wb, "plots", cols = seq_len(n_p), widths = unname(widths_p))
freezePane(wb, "plots", firstActiveRow = 4, firstActiveCol = 4)


# ══════════════════════════════════════════════════════════════════════════════
# horizons sheet  — one row per soil horizon; columns match form table exactly
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "horizons", tabColour = "#5C3A1E", gridLines = TRUE)

horizons_cols <- c(
  # Keys
  "project_id", "plot_id",
  # Form columns (left to right as on the field form)
  "horizon",        # Horiz.
  "depth_top_cm",   # Top (cm)
  "depth_bot_cm",   # Bot. (cm)
  "munsell_hue",    # Munsell Hue
  "munsell_val",    # Val.
  "munsell_chr",    # Chr.
  "texture",        # Texture  (dropdown of form classes)
  "structure",      # Structure (dropdown of form codes)
  "von_post",       # Von Post
  "material",       # Material (Min / Peat / Muck / Marl)
  "mottles",        # Mottles  (None / Few / Com / Many)
  "redox",          # Redox    (None / Few / Com / Many)
  "notes"           # Notes
)
n_h  <- length(horizons_cols)
ci_h <- setNames(seq_len(n_h), horizons_cols)

# Title banner — row 1
mergeCells(wb, "horizons", cols = 1:n_h, rows = 1)
writeData(wb, "horizons",
  "SOILS FIELD DATA FORM  ·  Horizon Data",
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
  project_id  = "AB-2024-01",
  plot_id     = "SP-01",
  horizon     = "Ah",
  depth_top_cm= "0",
  depth_bot_cm= "18",
  munsell_hue = "10YR",
  munsell_val = "3",
  munsell_chr = "2",
  texture     = "SiCL",
  structure   = "SBK",
  von_post    = "",
  material    = "Min",
  mottles     = "Few",
  redox       = "Few",
  notes       = "Oxidized root channels; abrupt smooth lower boundary."
)
writeData(wb, "horizons", eg_horizons, startRow = 3, colNames = FALSE)
addStyle(wb, "horizons", s_eg, rows = 3, cols = 1:n_h, gridExpand = TRUE)

# ── Data validation ───────────────────────────────────────────────────────────
# Texture classes as on the field form (left to right)
dv_list("horizons", ci_h["texture"],
        c("S", "LS", "SL", "L", "SiL", "Si",
          "SCL", "CL", "SiCL", "SC", "SiC", "C", "Muck", "Peat"))
# Structure codes as on the field form
# GR=granular, PL=platy, BK=blocky (angular), SBK=subangular blocky, PR=prismatic, MA=massive
dv_list("horizons", ci_h["structure"],
        c("GR", "PL", "BK", "SBK", "PR", "MA"))
# Von Post humification scale H1–H10
dv_list("horizons", ci_h["von_post"],
        paste0("H", 1:10))
# Material type
dv_list("horizons", ci_h["material"],
        c("Min", "Peat", "Muck", "Marl"))
# Mottles abundance
dv_list("horizons", ci_h["mottles"],
        c("None", "Few", "Com", "Many"))
# Redox features abundance
dv_list("horizons", ci_h["redox"],
        c("None", "Few", "Com", "Many"))

dataValidation(wb, "horizons",
  cols = ci_h["depth_top_cm"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0")
dataValidation(wb, "horizons",
  cols = ci_h["depth_bot_cm"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0")
dataValidation(wb, "horizons",
  cols = ci_h["munsell_val"], rows = DATA_ROWS,
  type = "decimal", operator = "between", value = c("0", "10"))
dataValidation(wb, "horizons",
  cols = ci_h["munsell_chr"], rows = DATA_ROWS,
  type = "decimal", operator = "between", value = c("0", "8"))

# ── Column widths & freeze ─────────────────────────────────────────────────────
widths_h <- c(
  project_id   = 14, plot_id = 12,
  horizon      = 9,
  depth_top_cm = 8,  depth_bot_cm = 8,
  munsell_hue  = 10, munsell_val = 7, munsell_chr = 7,
  texture      = 9,
  structure    = 9,
  von_post     = 8,
  material     = 9,
  mottles      = 9,
  redox        = 9,
  notes        = 44
)
setColWidths(wb, "horizons", cols = seq_len(n_h), widths = unname(widths_h))
freezePane(wb, "horizons", firstActiveRow = 4, firstActiveCol = 3)


# ══════════════════════════════════════════════════════════════════════════════
# README sheet
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "README", tabColour = "#CC4400", gridLines = FALSE)

readme <- as.data.frame(rbind(
  c("OVERVIEW",
    paste("One row in 'plots' per field form (one plot per row).",
          "One row per soil horizon in 'horizons'.",
          "Delete the grey example rows before submitting.",
          "Sheet names must not be renamed — 01_ingest.Rmd reads them by name.",
          "plot_id must match exactly between the two sheets.")),
  c("DATE FORMAT",
    "Enter dates as YYYY-MM-DD text (e.g. 2024-06-15). Do not use Excel date serial numbers."),
  c("plots — header fields",
    paste(
      "project_id / site_id / plot_id: identifiers (plot_id is primary key) |",
      "method: Pit (soil pit excavated) or Probe (soil probe only) |",
      "depth_restrict_cm: depth in cm to restrictive layer (bedrock, dense till, etc.) |",
      "gps_easting / gps_northing: UTM Zone 11N or 12N, NAD83"
    )),
  c("plots — footer fields",
    paste(
      "hydric_ind_present: Yes / No — were any hydric soil indicators observed? |",
      "hydric_criterion_met: Yes / No / Marginal — overall hydric soil determination |",
      "soil_great_group: CSSC great group from field assessment",
      "(e.g. Humic Gleysol, Mesisol, Luvic Gleysol) — classify after field season if uncertain |",
      "additional_notes: free-text notes from the form footer"
    )),
  c("horizons — Munsell colour",
    paste(
      "Record moist Munsell colour in three columns:",
      "munsell_hue (e.g. 10YR, 2.5Y, 5GY, GLEY1),",
      "munsell_val (numeric 0-10),",
      "munsell_chr (numeric 0-8).",
      "Gleyed colours: use Gley chart hue notation (e.g. GLEY1)."
    )),
  c("horizons — texture",
    paste(
      "Select one texture class matching the field form checkboxes:",
      "S=Sand, LS=Loamy Sand, SL=Sandy Loam, L=Loam, SiL=Silt Loam, Si=Silt,",
      "SCL=Sandy Clay Loam, CL=Clay Loam, SiCL=Silty Clay Loam,",
      "SC=Sandy Clay, SiC=Silty Clay, C=Clay, Muck, Peat."
    )),
  c("horizons — structure",
    paste(
      "Select one structure code matching the field form checkboxes:",
      "GR=Granular, PL=Platy, BK=Angular Blocky, SBK=Subangular Blocky,",
      "PR=Prismatic, MA=Massive."
    )),
  c("horizons — Von Post",
    paste(
      "Von Post humification scale H1–H10 for organic horizons.",
      "H1-H3 = Fibric (>40% fibre, raw peat);",
      "H4-H6 = Mesic (17-40% fibre, moderately decomposed);",
      "H7-H10 = Humic (<17% fibre, well decomposed).",
      "Leave blank for mineral horizons."
    )),
  c("DO NOT COMPUTE",
    paste(
      "The following are derived by R in 03_transform.Rmd — do NOT enter manually:",
      "peat_depth_cm (sum of Peat/Muck horizon thicknesses),",
      "organic_fibre_class (from von_post: Fi/Me/Hu),",
      "hydric_indicators list (from colour, mottles, redox, horizon sequence),",
      "cssc_great_group_confirmed (CSSC classification from horizon sequence)."
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
              heights = c(44, 28, 60, 72, 60, 72, 60, 72, 72))


# ── Save ───────────────────────────────────────────────────────────────────────
saveWorkbook(wb, OUT, overwrite = TRUE)
message("Saved: ", OUT)
