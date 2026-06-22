# Reusable drone-orthomosaic area-overview figure (committed; not project-specific).
#
# Renders the project's orthomosaic, cropped to the study area, with the
# ownership and approved-harvest boundaries and the labelled test holes overlaid
# — the lead "area overview" figure for the report Introduction. A full-resolution
# orthomosaic is far too large to embed directly, so this produces a right-sized
# PNG. Project-specific paths (the orthomosaic location) are passed by the caller.
#
# Source it and call render_area_overview(); skips gracefully if the orthomosaic
# is not present, so the report still builds without it.

library(terra)
library(sf)
library(here)
source(here::here("analysis/peat/spatial_helpers.R"))  # project_holes()

#' @param project_id e.g. "AD2026.015".
#' @param ortho_path Repo-relative path to the orthomosaic raster (GeoTIFF).
#' @param ownership_boundary,approved_boundary Shapefile paths (repo-relative).
#' @param output_dir Where the PNG is written (default reports/figures).
#' @param margin Fractional buffer around the study area when cropping the ortho.
render_area_overview <- function(project_id, ortho_path,
                                 ownership_boundary, approved_boundary,
                                 output_dir = "reports/figures",
                                 margin = 0.04) {
  if (!nzchar(ortho_path) || !file.exists(here(ortho_path))) {
    message("  area overview skipped: orthomosaic not found (", ortho_path, ")")
    return(invisible(NULL))
  }
  dir.create(here(output_dir), showWarnings = FALSE, recursive = TRUE)

  ortho <- terra::rast(here(ortho_path))
  ocrs  <- terra::crs(ortho)

  # Overlays reprojected to the orthomosaic's CRS (cheap), so the raster is never
  # resampled. Holes are built per-UTM-zone then reprojected (see spatial_helpers).
  hole_summary <- readRDS(here("data-raw", paste0(project_id, "_peat_hole_summary.rds")))
  ownership <- st_transform(st_read(here(ownership_boundary), quiet = TRUE), ocrs)
  approved  <- st_transform(st_read(here(approved_boundary),  quiet = TRUE), ocrs)
  pts       <- project_holes(hole_summary, sf::st_crs(ocrs))

  # Crop the orthomosaic to the study area plus a small margin.
  own_v <- terra::vect(ownership)
  e  <- terra::ext(own_v)
  dx <- (e[2] - e[1]) * margin; dy <- (e[4] - e[3]) * margin
  ortho <- terra::crop(ortho, terra::ext(e[1] - dx, e[2] + dx, e[3] - dy, e[4] + dy))

  out <- here(output_dir, paste0(project_id, "_area_overview.png"))
  png(out, width = 2400, height = 2000, res = 220)
  on.exit(dev.off(), add = TRUE)

  if (terra::nlyr(ortho) >= 3) {
    terra::plotRGB(ortho, r = 1, g = 2, b = 3, stretch = "lin", mar = c(2, 2, 2, 2))
  } else {
    terra::plot(ortho, col = grDevices::grey.colors(256), legend = FALSE,
                mar = c(2, 2, 2, 2))
  }
  terra::plot(own_v,                border = "grey15", lwd = 1.6, add = TRUE)
  terra::plot(terra::vect(approved), border = "red",   lwd = 2.2, add = TRUE)
  pv <- terra::vect(pts)
  terra::plot(pv, add = TRUE, col = "black", pch = 21, bg = "yellow", cex = 1.2)
  terra::text(pv, labels = "plot_id", pos = 3, cex = 0.6,
              halo = TRUE, hc = "white", hw = 0.2)
  terra::add_legend("bottomleft",
    legend = c("Ownership boundary", "Approved harvest area", "Test holes"),
    col = c("grey15", "red", "black"), pch = c(NA, NA, 21), pt.bg = c(NA, NA, "yellow"),
    lwd = c(1.6, 2.2, NA), bg = "white", box.col = "grey70", cex = 0.8)
  terra::sbar()   # scale bar

  message("  - ", basename(out))
  invisible(out)
}
