#' Convert Munsell notation to a ggplot-compatible hex colour
#'
#' Looks up the sRGB hex string for one or more Munsell chips. The return value
#' can be used directly with \code{scale_fill_identity()} or
#' \code{scale_colour_identity()} in ggplot2.
#'
#' @param hue    Character vector of Munsell hue tokens (e.g. \code{"10YR"}).
#' @param value  Numeric vector of Munsell value (1–9).
#' @param chroma Numeric vector of Munsell chroma (0–8, even numbers in the chart).
#' @param lut    Data frame with columns \code{hue}, \code{value}, \code{chroma},
#'   \code{hex}. Defaults to the package \code{munsell} dataset loaded into the
#'   calling environment (or the global environment after
#'   \code{load(here("data", "munsell.rda"))}).
#'
#' @return Character vector of \code{#RRGGBB} hex strings; \code{NA} where no
#'   matching chip exists.
#'
#' @examples
#' # After load(here("data", "munsell.rda")) or library(wetlandtools):
#' munsell_to_hex("10YR", 4, 2)   # "#6E5E4B"
#' munsell_to_hex("2.5Y", 6, 2)   # grey-brown typical of Ah horizon
munsell_to_hex <- function(hue, value, chroma, lut = get0("munsell")) {
  if (is.null(lut))
    stop("munsell dataset not found; call load(here('data', 'munsell.rda')) first")
  key_data <- paste(hue, value, chroma)
  key_lut  <- paste(lut$hue, lut$value, lut$chroma)
  lut$hex[match(key_data, key_lut)]
}
