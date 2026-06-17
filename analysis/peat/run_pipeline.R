# Reusable peat pipeline runner (committed; not project-specific).
#
# Renders the four peat analysis steps in order, passing each Rmd ONLY the
# params it declares in its YAML front matter. That means per-step differences
# (e.g. 04_visualize has no `utilities_boundary`) and any future param changes
# never break the call — the runner adapts automatically.
#
# Project-specific values (paths, setback overrides) live in a thin caller under
# data-raw/projects/<PROJECT_ID>/run_peat.R, which sources this file and calls
# run_peat_pipeline() with a `config` list. See WORKFLOW.md.

library(rmarkdown)
library(here)

#' Run the peat pipeline for one project
#'
#' @param project_id Project identifier (e.g. "AD2026.015"); becomes params$project_id.
#' @param config Named list of any other Rmd params (file paths, setback
#'   distances, ...). Only entries a given step declares are passed to it, so
#'   you can supply the full set once and it is routed correctly. Anything not
#'   supplied falls back to the Rmd's own default.
#' @param steps Which steps to render, as indices into the four-step sequence
#'   (default all). e.g. steps = 3:4 re-runs only transform + visualize.
run_peat_pipeline <- function(project_id, config = list(), steps = 1:4) {
  rmds <- c("01_ingest.Rmd", "02_qaqc.Rmd", "03_transform.Rmd", "04_visualize.Rmd")
  all_params <- c(list(project_id = project_id), config)

  for (i in steps) {
    rmd      <- here::here("analysis/peat", rmds[i])
    declared <- names(rmarkdown::yaml_front_matter(rmd)$params)
    rmarkdown::render(
      rmd,
      params = all_params[intersect(names(all_params), declared)],
      envir  = new.env(),
      quiet  = TRUE
    )
    message("  - rendered: ", rmds[i])
  }
  message("Peat pipeline complete for ", project_id)
}
