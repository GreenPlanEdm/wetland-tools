# Shared report helpers, sourced by the WAIR and monitoring templates. The
# leading underscore keeps Quarto from treating this as a renderable input.
#
# The calling document must define `figure_dir` (from params$figure_dir) before
# sourcing, e.g.:
#   figure_dir <- params$figure_dir
#   source(here::here("reports/_report_helpers.R"))

# Show a figure if it has been generated, otherwise emit a pending placeholder
# so a report renders before the vegetation/soils/water pipelines have run.
# `dir` defaults to the document's figure_dir, so call sites stay show_fig(file, what).
show_fig <- function(file, what, dir = figure_dir) {
  p <- here::here(dir, file)
  if (file.exists(p)) {
    knitr::include_graphics(p)
  } else {
    knitr::asis_output(paste0("*[Figure pending: ", what, "]*"))
  }
}
