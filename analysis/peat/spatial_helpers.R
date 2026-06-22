# Shared spatial helpers for the peat module: map a recorded UTM zone to its
# EPSG code, and build reprojected test-hole points in one common CRS.
#
# The UTM zone is captured per hole on the data-entry form (the `utm_zone`
# column, NAD83, e.g. "11N" / "12N"). All geometry — transect lines, along-
# transect distances, nearest-neighbour spacing — must be derived from
# coordinates REPROJECTED to one common CRS, never from the raw zone-relative
# eastings (a 12N easting tagged as 11N lands hundreds of km away).
#
# Source with here::here("analysis/peat/spatial_helpers.R").

library(sf)

#' NAD83 / UTM North zone -> EPSG code.
#'
#' EPSG 26901..26923 = NAD83 / UTM zone 1N..23N, so the code is simply
#' 26900 + zone number. Accepts "12N", "12", or 12. Data-driven: adding a zone
#' to the form's dropdown needs no code change here.
zone_epsg <- function(utm_zone) {
  z <- suppressWarnings(as.integer(gsub("\\D", "", as.character(utm_zone))))
  bad <- is.na(z) | z < 1 | z > 23
  if (any(bad))
    stop("Unrecognised UTM zone(s): ",
         paste(unique(as.character(utm_zone)[bad]), collapse = ", "),
         " (expected NAD83 UTM North, zones 1-23, e.g. \"11N\"/\"12N\").")
  26900L + z
}

#' Build test-hole points in one common CRS.
#'
#' Each hole is created in the CRS of its own recorded UTM zone, then reprojected
#' to `target_crs`. The returned sf also carries `proj_x` / `proj_y` columns
#' holding the coordinates in `target_crs`, so downstream distance and transect
#' geometry can be computed in a single consistent metric CRS regardless of how
#' many zones the deposit spans.
#'
#' @param df Data frame with `utm_zone` and the easting/northing columns.
#' @param target_crs A crs object or EPSG code (e.g. st_crs(ownership)).
#' @param coords Names of the easting/northing columns.
project_holes <- function(df, target_crs,
                          coords = c("gps_easting", "gps_northing")) {
  parts <- lapply(split(df, as.character(df$utm_zone)), function(sub) {
    p <- st_as_sf(sub, coords = coords, crs = zone_epsg(sub$utm_zone[1]),
                  remove = FALSE)
    st_transform(p, target_crs)
  })
  out <- do.call(rbind, parts)
  xy <- st_coordinates(out)
  out$proj_x <- xy[, 1]
  out$proj_y <- xy[, 2]
  out
}
