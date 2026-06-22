# Shared Von Post product-grade palette and classifier for peat figures.
#
# Single source of truth for the grade colours, legend labels, and the
# horizon -> grade classification used by BOTH 04_visualize.Rmd (the per-hole
# profiles, the single cross-section, the thickness bar chart) and
# cross_sections.R (the appendix A-I fence diagrams). Keeping these here stops
# the report's figures from drifting apart on colour or legend wording — they
# share one legend key.
#
# Source it with here::here("analysis/peat/grade_palette.R").

# Non-peat layers carry no Von Post grade (band = NA); they are split for the
# figures into forest floor (LFH / L-F-H folic) and mineral substrate (C/Cg, A/B).
forest_floor_pat <- "^(LFH|LF|FH|L|F|H)$"

grade_levels <- c("professional", "retail", "non_saleable", "forest_floor", "mineral")

band_cols <- c(professional = "#1a9850", retail = "#fee08b",
               non_saleable = "#8c510a", forest_floor = "#c8a165",
               mineral = "#9e9e9e")

grade_labels <- c(professional = "Professional (H1-H4)",
                  retail = "Retail (H5-H6)",
                  non_saleable = "Non-saleable (H7-H10)",
                  forest_floor = "Forest floor (LFH)",
                  mineral = "Mineral substrate (C)")

# Two-colour subset for the harvestable-thickness bar chart (named by the
# capitalised facet labels that chart uses).
harvest_cols <- c(Professional = unname(band_cols["professional"]),
                  Retail       = unname(band_cols["retail"]))

# Classify each logged interval to a grade factor: graded peat keeps its band,
# otherwise forest-floor horizons vs mineral substrate by horizon code.
classify_grade <- function(df) {
  dplyr::mutate(df, grade = dplyr::case_when(
    !is.na(band)                                       ~ band,
    grepl(forest_floor_pat, toupper(trimws(horizon)))  ~ "forest_floor",
    TRUE                                               ~ "mineral"),
    grade = factor(grade, levels = grade_levels))
}
