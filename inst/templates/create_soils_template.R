# inst/templates/create_soils_template.R
# Generates the blank soils data-entry workbook.
# Run from project root: source("inst/templates/create_soils_template.R")
# Requires: openxlsx, here

library(openxlsx)
library(here)

OUT       <- here::here("inst", "templates", "soils_data_entry.xlsx")
DATA_ROWS <- 2:1001   # 1000 data rows per sheet

wb <- createWorkbook(
  creator = "Green Plan Ltd.",
  title   = "Wetland Assessment — Soils Data Entry"
)

# ── Shared styles ─────────────────────────────────────────────────────────────
# Brown earth-tone header to distinguish from the blue vegetation workbook
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
# plots sheet  (one row per field form / per plot)
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "plots", tabColour = "#5C3A1E", gridLines = TRUE)

plots_cols <- c(
  # Identification
  "project_id", "site_id", "plot_id", "observer",
  # Location & date
  "date", "gps_e", "gps_n", "datum", "waypoint",
  # Site description
  "water_table_cm",
  "series", "subgroup", "parent_material",
  "slope_pct", "slope_position", "aspect",
  "surface_stones", "drainage", "surface_expression",
  # Remarks
  "comments"
)
n_p  <- length(plots_cols)
ci_p <- setNames(seq_len(n_p), plots_cols)

writeData(wb, "plots",
  setNames(data.frame(matrix(nrow = 0, ncol = n_p)), plots_cols),
  startRow = 1
)

eg_plots <- data.frame(
  project_id        = "AB-2024-01",
  site_id           = "WL-01",
  plot_id           = "SP-01",
  observer          = "J. Smith",
  date              = "2024-06-15",
  gps_e             = "350000",
  gps_n             = "5900000",
  datum             = "NAD83",
  waypoint          = "WP-12",
  water_table_cm    = "8",
  series            = "Loon River",
  subgroup          = "Orthic Humic Gleysol",
  parent_material   = "GL",
  slope_pct         = "2",
  slope_position    = "L",
  aspect            = "NW",
  surface_stones    = "S0",
  drainage          = "P",
  surface_expression = "l",
  comments          = "Saturated at surface; strong sulphidic odour."
)
writeData(wb, "plots", eg_plots, startRow = 2, colNames = FALSE)

# ── Data validation ───────────────────────────────────────────────────────────
dv_list("plots", ci_p["datum"],
        c("NAD83", "WGS84"))
dv_list("plots", ci_p["slope_position"],
        c("C", "U", "M", "L", "D", "Level"))
dv_list("plots", ci_p["surface_stones"],
        c("S0", "S1", "S2", "S3", "S4", "S5"))
dv_list("plots", ci_p["drainage"],
        c("R", "W", "MW", "I", "P", "VP"))
dv_list("plots", ci_p["surface_expression"],
        c("a", "b", "f", "h", "i", "l", "m", "r", "s", "t", "u", "v"))

dataValidation(wb, "plots",
  cols = ci_p["water_table_cm"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0"
)
dataValidation(wb, "plots",
  cols = ci_p["slope_pct"], rows = DATA_ROWS,
  type = "decimal", operator = "between", value = c("0", "100")
)

# ── Column widths ─────────────────────────────────────────────────────────────
widths_p <- c(
  project_id = 14, site_id = 12, plot_id = 12, observer = 16,
  date = 12, gps_e = 12, gps_n = 12, datum = 9, waypoint = 10,
  water_table_cm = 11,
  series = 16, subgroup = 26, parent_material = 12,
  slope_pct = 8, slope_position = 11, aspect = 8,
  surface_stones = 10, drainage = 10, surface_expression = 11,
  comments = 40
)
setColWidths(wb, "plots", cols = seq_len(n_p), widths = unname(widths_p))
setRowHeights(wb, "plots", rows = 1, heights = 38)
freezePane(wb, "plots", firstActiveRow = 2, firstActiveCol = 4)
addStyle(wb, "plots", s_hdr, rows = 1, cols = seq_len(n_p), gridExpand = TRUE)
addStyle(wb, "plots", s_eg,  rows = 2, cols = seq_len(n_p), gridExpand = TRUE)


# ══════════════════════════════════════════════════════════════════════════════
# horizons sheet  (one row per soil horizon)
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "horizons", tabColour = "#8B5E3C", gridLines = TRUE)

horizons_cols <- c(
  # Keys
  "project_id", "plot_id", "layer",
  # Horizon designation & depth
  "horizon", "depth_top_cm", "depth_bot_cm",
  # Moist Munsell colour — split into components
  "color_hue", "color_value", "color_chroma",
  # Mottles — split into three descriptors
  "mottle_abundance", "mottle_size", "mottle_contrast",
  # Texture
  "texture",
  # Structure — split into kind, class, grade
  "structure_kind", "structure_class", "structure_grade",
  # Consistence (moist)
  "consistence",
  # Coarse fragments
  "cf_pct", "cf_type",
  # Organics (for peat/organic horizons)
  "organics_comp", "organics_fib_cl",
  # pH
  "ph",
  # Notes
  "notes"
)
n_h  <- length(horizons_cols)
ci_h <- setNames(seq_len(n_h), horizons_cols)

writeData(wb, "horizons",
  setNames(data.frame(matrix(nrow = 0, ncol = n_h)), horizons_cols),
  startRow = 1
)

eg_horizons <- data.frame(
  project_id       = "AB-2024-01",
  plot_id          = "SP-01",
  layer            = "1",
  horizon          = "Ah",
  depth_top_cm     = "0",
  depth_bot_cm     = "15",
  color_hue        = "10YR",
  color_value      = "3",
  color_chroma     = "2",
  mottle_abundance = "few",
  mottle_size      = "fine",
  mottle_contrast  = "faint",
  texture          = "SiCL",
  structure_kind   = "AB",
  structure_class  = "M",
  structure_grade  = "2",
  consistence      = "FR",
  cf_pct           = "0",
  cf_type          = "",
  organics_comp    = "",
  organics_fib_cl  = "",
  ph               = "6.2",
  notes            = "Strong redoximorphic features; oxidized root channels."
)
writeData(wb, "horizons", eg_horizons, startRow = 2, colNames = FALSE)

# ── Data validation ───────────────────────────────────────────────────────────
dv_list("horizons", ci_h["mottle_abundance"],
        c("none", "few", "common", "many"))
dv_list("horizons", ci_h["mottle_size"],
        c("fine", "medium", "coarse"))
dv_list("horizons", ci_h["mottle_contrast"],
        c("faint", "distinct", "prominent"))
dv_list("horizons", ci_h["texture"],
        c("O", "S", "LS", "SL", "FSL", "VFSL", "L", "SiL", "Si",
          "SCL", "CL", "SiCL", "SC", "SiC", "C"))
# Structure kind: M=massive, PL=platy, PR=prismatic, CO=columnar,
#   AB=angular blocky, SB=subangular blocky, GR=granular, CR=crumb, SG=single grain
dv_list("horizons", ci_h["structure_kind"],
        c("M", "PL", "PR", "CO", "AB", "SB", "GR", "CR", "SG"))
# Structure class: VF=very fine, F=fine, M=medium, C=coarse, VC=very coarse
dv_list("horizons", ci_h["structure_class"],
        c("VF", "F", "M", "C", "VC"))
# Structure grade: 0=structureless, 1=weak, 2=moderate, 3=strong
dv_list("horizons", ci_h["structure_grade"],
        c("0", "1", "2", "3"))
# Consistence (moist): L=loose, VFR=very friable, FR=friable,
#   FI=firm, VFI=very firm, EFI=extremely firm
dv_list("horizons", ci_h["consistence"],
        c("L", "VFR", "FR", "FI", "VFI", "EFI"))
dv_list("horizons", ci_h["cf_type"],
        c("gravel", "cobble", "stone", "boulder", "flagstone", "channer"))
# Organic fibre class (CSSC): Fi=Fibric (~H1-H3), Me=Mesic (~H4-H6), Hu=Humic (~H7-H10)
dv_list("horizons", ci_h["organics_fib_cl"],
        c("Fi", "Me", "Hu"))

dataValidation(wb, "horizons",
  cols = ci_h["depth_top_cm"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0"
)
dataValidation(wb, "horizons",
  cols = ci_h["depth_bot_cm"], rows = DATA_ROWS,
  type = "decimal", operator = "greaterThanOrEqual", value = "0"
)
dataValidation(wb, "horizons",
  cols = ci_h["cf_pct"], rows = DATA_ROWS,
  type = "decimal", operator = "between", value = c("0", "100")
)
dataValidation(wb, "horizons",
  cols = ci_h["ph"], rows = DATA_ROWS,
  type = "decimal", operator = "between", value = c("0", "14")
)
dataValidation(wb, "horizons",
  cols = ci_h["color_value"], rows = DATA_ROWS,
  type = "decimal", operator = "between", value = c("0", "10")
)
dataValidation(wb, "horizons",
  cols = ci_h["color_chroma"], rows = DATA_ROWS,
  type = "decimal", operator = "between", value = c("0", "8")
)

# ── Column widths ─────────────────────────────────────────────────────────────
widths_h <- c(
  project_id = 14, plot_id = 12, layer = 7,
  horizon = 9, depth_top_cm = 9, depth_bot_cm = 9,
  color_hue = 9, color_value = 8, color_chroma = 8,
  mottle_abundance = 10, mottle_size = 9, mottle_contrast = 10,
  texture = 9,
  structure_kind = 10, structure_class = 10, structure_grade = 10,
  consistence = 10,
  cf_pct = 7, cf_type = 10,
  organics_comp = 14, organics_fib_cl = 10,
  ph = 7,
  notes = 40
)
setColWidths(wb, "horizons", cols = seq_len(n_h), widths = unname(widths_h))
setRowHeights(wb, "horizons", rows = 1, heights = 38)
freezePane(wb, "horizons", firstActiveRow = 2, firstActiveCol = 3)
addStyle(wb, "horizons", s_hdr, rows = 1, cols = seq_len(n_h), gridExpand = TRUE)
addStyle(wb, "horizons", s_eg,  rows = 2, cols = seq_len(n_h), gridExpand = TRUE)


# ══════════════════════════════════════════════════════════════════════════════
# README sheet
# ══════════════════════════════════════════════════════════════════════════════
addWorksheet(wb, "README", tabColour = "#CC4400", gridLines = FALSE)

readme <- as.data.frame(rbind(
  c("OVERVIEW",
    paste("One row in 'plots' per field form; one row per soil horizon in 'horizons'.",
          "Delete the grey example rows before submitting.",
          "Sheet names must not be renamed — 01_ingest.Rmd reads them by name.",
          "plot_id must match exactly between the two sheets.")),
  c("DATE FORMAT",
    "Enter dates as YYYY-MM-DD text (e.g. 2024-06-15). Do not use Excel date serial numbers."),
  c("plots — columns",
    paste(
      "project_id: project code |",
      "site_id: wetland site identifier |",
      "plot_id: primary key (must match horizons sheet) |",
      "water_table_cm: depth to water table in cm from surface (0 = at surface) |",
      "series: soil series name if known |",
      "subgroup: CSSC subgroup (e.g. Orthic Humic Gleysol) — classify after field season |",
      "parent_material: PM code (e.g. GL=glaciolacustrine, GT=glacial till, FL=fluvial, CO=colluvial) |",
      "slope_position: C=Crest, U=Upper, M=Middle, L=Lower, D=Depression, Level |",
      "surface_stones: S0 (none) to S5 (>50% surface covered) |",
      "drainage: R=Rapid, W=Well, MW=Moderately Well, I=Imperfect, P=Poor, VP=Very Poor |",
      "surface_expression: CSSC surface expression codes (a=level, l=depression, etc.)"
    )),
  c("horizons — Munsell colour",
    paste(
      "Record moist Munsell colour in three separate columns:",
      "color_hue (e.g. 10YR, 2.5Y, 5GY, GLEY1),",
      "color_value (numeric, 0-10),",
      "color_chroma (numeric, 0-8).",
      "For gleyed colours use Gley chart notation in hue (e.g. GLEY1 5/10GY).",
      "Leave all three blank if colour not recorded for that horizon."
    )),
  c("horizons — structure",
    paste(
      "structure_kind: M=massive, PL=platy, PR=prismatic, CO=columnar,",
      "AB=angular blocky, SB=subangular blocky, GR=granular, CR=crumb, SG=single grain. |",
      "structure_class: VF=very fine, F=fine, M=medium, C=coarse, VC=very coarse. |",
      "structure_grade: 0=structureless, 1=weak, 2=moderate, 3=strong.",
      "Leave blank for structureless (massive/single grain) horizons."
    )),
  c("horizons — consistence",
    paste(
      "Moist consistence: L=loose, VFR=very friable, FR=friable,",
      "FI=firm, VFI=very firm, EFI=extremely firm."
    )),
  c("horizons — organics",
    paste(
      "organics_comp: dominant organic component (e.g. Sphagnum, Sedge, Reed, Wood, Mixed).",
      "organics_fib_cl: CSSC organic fibre class —",
      "Fi=Fibric (Von Post H1-H3; >40% unrubbed fibre),",
      "Me=Mesic (H4-H6; 17-40% unrubbed fibre),",
      "Hu=Humic (H7-H10; <17% unrubbed fibre).",
      "Only complete for O and Of/Om/Oh horizon designations."
    )),
  c("DO NOT COMPUTE",
    paste(
      "The following are computed by R from the horizons table and reference tables —",
      "do NOT enter them here:",
      "von_post (Von Post humification score from organics_fib_cl),",
      "hydric_indicators (derived from colour, mottles, horizon sequence),",
      "peat_depth_cm (sum of organic horizon thicknesses),",
      "cssc_great_group (classified in 03_transform.Rmd from horizon sequence)."
    ))
), stringsAsFactors = FALSE)

writeData(wb, "README", readme, startRow = 1, colNames = FALSE)

s_rm_key <- createStyle(
  fgFill = "#5C3A1E", fontColour = "white", textDecoration = "bold",
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
              heights = c(36, 28, 90, 72, 72, 36, 72, 72))


# ── Save ───────────────────────────────────────────────────────────────────────
saveWorkbook(wb, OUT, overwrite = TRUE)
message("Saved: ", OUT)
