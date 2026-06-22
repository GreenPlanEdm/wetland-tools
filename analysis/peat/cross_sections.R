# Reusable cross-section figure generator (committed; not project-specific).
#
# Produces a *series* of labelled stratigraphic fence diagrams (Cross-Section A,
# B, C, ...) for arbitrary groups of test holes, plus a single overview map
# showing where each section runs. Intended for the Figures appendix of a peat
# exploration report.
#
# This reuses the same honest-logged-stratigraphy approach as the single
# cross-section in 04_visualize.Rmd: each hole is drawn as its real logged grade
# column at its true along-transect distance; the ground between holes is left
# blank (Von Post grade is not interpolated with depth — see DESIGN).
#
# Project-specific section definitions (which holes, in what order, under which
# letter) live in a thin caller under data-raw/projects/<ID>/cross_sections.R,
# which sources this file and calls run_cross_sections().

library(dplyr)
library(ggplot2)
library(sf)
library(here)

# Grade palette, legend labels, and classify_grade() — shared with 04_visualize
# so the appendix fence diagrams read identically to the main peat figures.
source(here::here("analysis/peat/grade_palette.R"))

# Turn a vector of plot *numbers* (e.g. c(15,16,17)) or full IDs ("PL15") into
# zero-padded hole IDs matching the data.
as_hole_ids <- function(x) {
  if (is.numeric(x)) sprintf("PL%02d", x)
  else ifelse(grepl("^PL", x), x, sprintf("PL%02d", as.integer(x)))
}

# Order a section's holes for natural left-to-right, top-to-bottom reading so the
# main cross-section reads the same way as the inset/overview map (west on the
# left, north at the top): west -> east primary (ascending UTM easting), then
# north -> south (descending northing) as the tie-breaker for near-vertical (N-S)
# segments. This keeps the transect a clean, continuous line and matches standard
# map orientation, rather than reading inverted against the map.
order_holes_reading <- function(ids, hole_summary) {
  sx <- hole_summary[match(ids, hole_summary$plot_id), ]
  sx$plot_id[order(sx$gps_easting, -sx$gps_northing)]
}

# Build an sf of all test holes (handles split UTM zones), in the ownership CRS.
hole_points <- function(hole_summary, ownership) {
  make_points <- function(df, zone, epsg) {
    sub <- dplyr::filter(df, utm_zone == zone)
    if (nrow(sub) == 0) return(NULL)
    st_as_sf(sub, coords = c("gps_easting", "gps_northing"), crs = epsg, remove = FALSE)
  }
  dplyr::bind_rows(
    { p <- make_points(hole_summary, "11N", 26911); if (!is.null(p)) st_transform(p, st_crs(ownership)) },
    { p <- make_points(hole_summary, "12N", 26912); if (!is.null(p)) st_transform(p, st_crs(ownership)) }
  )
}

# Per-hole transect geometry (cumulative along-section distance, depths, etc.)
section_xy <- function(sec_ids, hole_summary, intervals) {
  sx <- hole_summary |>
    distinct(plot_id, gps_easting, gps_northing, mineral_depth_cm, water_table_depth_m)
  sx <- sx[match(sec_ids, sx$plot_id), ]
  if (anyNA(sx$gps_easting))
    stop("section holes not found in data: ",
         paste(sec_ids[is.na(sx$gps_easting)], collapse = ", "))
  sx$dist_m <- cumsum(c(0, sqrt(diff(sx$gps_easting)^2 + diff(sx$gps_northing)^2)))
  sx <- left_join(sx, distinct(intervals, plot_id, recl_line_cm), by = "plot_id")
  sx$wt_cm <- sx$water_table_depth_m * 100
  sx
}

#' Draw one labelled cross-section and save it.
#'
#' @param label Section letter ("A", "B", ...).
#' @param ylim_bottom Shared lower y-limit (negative cm) so the series is
#'   comparable across panels; NULL = auto per panel.
draw_section <- function(label, sec_ids, intervals, hole_summary, ownership, pts,
                         output_dir, project_id, ylim_bottom = NULL) {
  sec_xy <- section_xy(sec_ids, hole_summary, intervals)
  sec_intervals <- intervals |>
    filter(plot_id %in% sec_ids) |>
    classify_grade() |>
    left_join(sec_xy[, c("plot_id", "dist_m")], by = "plot_id")

  span    <- max(sec_xy$dist_m)
  bar_w   <- if (span > 0) 0.012 * span else 1   # core column half-width (m)
  ann_lvls <- c("Mineral base", "50 cm reclamation buffer", "Water table")
  top_head <- if (!is.null(ylim_bottom)) 0.28 * abs(ylim_bottom) else NA

  p_section <- ggplot() +
    geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.4) +
    geom_rect(data = sec_intervals,
              aes(xmin = dist_m - bar_w, xmax = dist_m + bar_w,
                  ymin = -depth_bot_cm, ymax = -depth_top_cm, fill = grade)) +
    geom_line(data = sec_xy, aes(x = dist_m, y = -mineral_depth_cm,
              colour = "Mineral base"), linetype = "dashed") +
    geom_line(data = sec_xy, aes(x = dist_m, y = -pmax(recl_line_cm, 0),       # clamp to surface
              colour = "50 cm reclamation buffer"), linetype = "dashed") +
    geom_line(data = sec_xy, aes(x = dist_m, y = -wt_cm,
              colour = "Water table"), linetype = "dashed") +
    geom_text(data = sec_xy, aes(x = dist_m, y = 20, label = plot_id),
              angle = 90, hjust = 0, size = 2.6) +
    scale_fill_manual(values = band_cols, name = "Layer", drop = FALSE,
                      labels = grade_labels) +
    scale_colour_manual(name = NULL, breaks = ann_lvls,
      values = c("Mineral base" = "grey40",
                 "50 cm reclamation buffer" = "red",
                 "Water table" = "dodgerblue3"),
      guide = guide_legend(order = 2, override.aes = list(linetype = "dashed"))) +
    scale_y_continuous(labels = ~ abs(.), expand = expansion(mult = c(0.04, 0.22))) +
    labs(title = paste0("Cross-Section ", label),
         x = "Distance along transect (m)", y = "Depth (cm)") +
    theme_bw() +
    theme(legend.justification = "top") +   # park legend at top-right; inset sits below it
    guides(fill = guide_legend(order = 1))

  if (!is.null(ylim_bottom))
    p_section <- p_section +
      coord_cartesian(ylim = c(ylim_bottom, top_head))

  # Inset location map: study area, all holes, this transect highlighted with
  # its plot numbers labelled so the inset cross-references to the section.
  transect_line <- sf::st_sfc(
    sf::st_linestring(as.matrix(sec_xy[, c("gps_easting", "gps_northing")])),
    crs = sf::st_crs(ownership))
  sec_pts <- pts |> filter(plot_id %in% sec_ids)
  bb  <- sf::st_bbox(pts)
  nud <- as.numeric(bb["ymax"] - bb["ymin"]) * 0.05   # label offset in map units

  inset <- ggplot() +
    geom_sf(data = ownership, fill = "grey92", colour = "grey55", linewidth = 0.25) +
    geom_sf(data = pts, colour = "grey60", size = 0.3) +
    geom_sf(data = transect_line, colour = "black", linewidth = 0.6) +
    geom_sf(data = sec_pts, colour = "red", size = 0.8) +
    geom_sf_text(data = sec_pts, aes(label = plot_id), colour = "red",
                 size = 1.4, fontface = "bold", nudge_y = nud) +
    theme_void() +
    theme(panel.background = element_rect(fill = "white", colour = "grey40"),
          plot.margin = margin(1, 1, 1, 1))

  # Inset placed in the right margin, BELOW the (top-justified) legend and
  # outside the cross-section panel, so it never overlaps the cores or lines.
  draw <- function() {
    print(p_section)
    print(inset, vp = grid::viewport(x = 0.89, y = 0.18, width = 0.19, height = 0.26))
  }
  out <- here(output_dir, paste0(project_id, "_cross_section_", label, ".png"))
  png(out, width = 10, height = 5, units = "in", res = 300)
  draw(); dev.off()
  message("  - ", basename(out))
  invisible(out)
}

# Overview map: ownership + approved boundaries, all holes, every section drawn
# as a coloured polyline labelled with its letter at the line midpoint.
draw_overview <- function(sections, intervals, hole_summary, ownership, approved,
                          pts, output_dir, project_id) {
  lines <- lapply(names(sections), function(lab) {
    sx <- section_xy(as_hole_ids(sections[[lab]]), hole_summary, intervals)
    st_sf(label = lab,
          geometry = st_sfc(st_linestring(as.matrix(sx[, c("gps_easting", "gps_northing")])),
                            crs = 26911))
  })
  lines_sf <- st_transform(do.call(rbind, lines), st_crs(ownership))
  mids <- st_point_on_surface(lines_sf)
  pal  <- setNames(grDevices::hcl.colors(length(sections), "Dark 3"), names(sections))

  p <- ggplot() +
    geom_sf(data = ownership, fill = "grey95", colour = "grey55", linewidth = 0.3) +
    geom_sf(data = approved, fill = NA, colour = "red", linewidth = 0.6) +
    geom_sf(data = pts, colour = "grey45", size = 0.9) +
    geom_sf_text(data = pts, aes(label = plot_id), size = 2, colour = "grey30",
                 nudge_y = 60, check_overlap = TRUE) +
    geom_sf(data = lines_sf, aes(colour = label), linewidth = 1.1) +
    geom_sf_label(data = mids, aes(label = label, colour = label),
                  size = 3.4, fontface = "bold", label.size = 0.3, show.legend = FALSE) +
    scale_colour_manual(values = pal, name = "Cross-section") +
    labs(title = "Cross-Section Location Overview",
         subtitle = paste0(project_id, " — test-hole transects A–",
                           tail(names(sections), 1)),
         x = NULL, y = NULL) +
    theme_bw()

  out <- here(output_dir, paste0(project_id, "_cross_section_overview.png"))
  ggsave(out, p, width = 9, height = 7, dpi = 300)
  message("  - ", basename(out))
  invisible(out)
}

#' Generate the full cross-section series + overview for one project.
#'
#' @param project_id e.g. "AD2026.015".
#' @param sections Ordered named list: names are section letters, values are
#'   ordered plot numbers or hole IDs, e.g.
#'   list(A = c(15,16,17), B = c(2,11,12,13)).
#' @param ownership_boundary,approved_boundary Shapefile paths (repo-relative).
#' @param output_dir Where PNGs are written (default reports/figures).
#' @param shared_depth_axis If TRUE, every panel uses one depth axis (the
#'   deepest hole in the series) so sections are directly comparable. Default
#'   FALSE: each panel auto-scales to its own holes, which reads better when
#'   section depths vary widely (here ~35 cm to 4 m).
#' @param reorder If TRUE (default), the holes *within* each section are ordered
#'   for left-to-right, top-to-bottom reading (west->east, then north->south) so
#'   the transect is a clean continuous line that matches the map orientation.
#'   Set FALSE to keep the holes in the order supplied.
#' @param letter_by_location If TRUE (default), the section *letters* (A, B, C,
#'   ...) are (re)assigned by each section's location — north->south, then
#'   west->east by hole centroid — so the lettering progresses sensibly across
#'   the overview map instead of jumping around. The supplied list names are
#'   ignored. Set FALSE to keep the supplied names/order.
run_cross_sections <- function(project_id, sections,
                               ownership_boundary, approved_boundary,
                               output_dir = "reports/figures",
                               shared_depth_axis = FALSE, reorder = TRUE,
                               letter_by_location = TRUE) {
  dir.create(here(output_dir), showWarnings = FALSE, recursive = TRUE)
  intervals    <- readRDS(here("data-raw", paste0(project_id, "_peat_transformed.rds")))
  hole_summary <- readRDS(here("data-raw", paste0(project_id, "_peat_hole_summary.rds")))
  ownership <- st_read(here(ownership_boundary), quiet = TRUE)
  approved  <- st_transform(st_read(here(approved_boundary), quiet = TRUE), st_crs(ownership))
  pts <- hole_points(hole_summary, ownership)

  sections <- lapply(sections, as_hole_ids)
  if (isTRUE(reorder))
    sections <- lapply(sections, order_holes_reading, hole_summary = hole_summary)

  # Re-letter sections by location so A->...->Z reads top-to-bottom, left-to-right
  # across the overview map (north->south primary, west->east tie-break on the
  # section centroid), rather than wherever they were listed.
  if (isTRUE(letter_by_location)) {
    cen <- t(vapply(sections, function(ids) {
      sx <- hole_summary[match(ids, hole_summary$plot_id), ]
      c(E = mean(sx$gps_easting), N = mean(sx$gps_northing))
    }, numeric(2)))
    sections <- sections[order(-cen[, "N"], cen[, "E"])]
    names(sections) <- LETTERS[seq_along(sections)]
  }

  # Optional shared depth axis: deepest mineral contact among all holes used in
  # any section, so every panel reads at the same vertical scale.
  ylim_bottom <- NULL
  if (isTRUE(shared_depth_axis)) {
    used <- unique(unlist(sections))
    gmax <- max(hole_summary$mineral_depth_cm[hole_summary$plot_id %in% used], na.rm = TRUE)
    ylim_bottom <- -gmax * 1.05
  }

  message("Cross-sections for ", project_id, ":")
  for (lab in names(sections)) {
    message("  ", lab, ": ", paste(sections[[lab]], collapse = " -> "))
    draw_section(lab, sections[[lab]], intervals, hole_summary, ownership, pts,
                 output_dir, project_id, ylim_bottom = ylim_bottom)
  }
  draw_overview(sections, intervals, hole_summary, ownership, approved,
                pts, output_dir, project_id)
  message("Done.")
}
