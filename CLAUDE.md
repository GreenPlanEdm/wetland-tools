# wetland-tools — Project Guidance for Claude Code

## Project Purpose

`wetlandtools` is an R-based data pipeline and analysis toolkit built by Green Plan Ltd. for producing **Wetland Assessment and Impact Reports** in Alberta. Outputs are reviewed by regulators and clients; all methods must be **scientifically defensible** and aligned with Alberta-specific regulatory frameworks.

The tool handles field data collected by ecologists, processes it through a standardised pipeline, and produces figures and tables ready for insertion into Word/HTML technical reports.

---

## Regulatory Alignment (non-negotiable)

All vegetation, soils, and water permanence analyses must align with:

- **Alberta Wetland Classification System (AWCS)** — wetland class/form/type determination
- **Alberta Wetland Identification and Delineation Directive (AWIDD)** — delineation criteria and plot methodology
- **Wetland Assessment and Impact Rating (WAIR)** — scoring framework used in Impact Reports
- **Guidance to Determining Water Permanence (Alberta Environment)** — permanence scoring from imagery and LiDAR

Classification logic, thresholds, and terminology should be traceable to these documents. When in doubt, favour the more conservative/defensible interpretation, and flag assumptions explicitly in code comments.

---

## Stack

- **Language:** R (primary), Python (only for PDF form generation in `inst/templates/`)
- **Report output:** R Markdown knitting to Word (`.docx` via `reference_docx`) and HTML
- **Key packages:** `dplyr`, `tidyr`, `readxl`, `openxlsx`, `ggplot2`, `sf`, `terra`, `rmarkdown`, `knitr`, `here`
- **Optional/suggested:** `stars`, `leaflet`, `plotly`, `testthat`
- **Package structure:** Standard R package (`DESCRIPTION`, `R/`, `data/`, `inst/`)

---

## Repository Structure

```
analysis/
  vegetation/       # UPL–OBL scoring, invasive/noxious flags, WAIR inputs
  soils/            # Horizon classification, Von Post, peat isopachs
  water/            # Water permanence from NDWI imagery + LiDAR
R/                  # Shared functions extracted from Rmds as they mature
data-raw/           # Source reference CSVs + build_reference_data.R
data/               # Processed .rda reference datasets (built, not hand-edited)
inst/templates/     # Fillable PDF field forms; Excel data entry templates
reports/            # Parameterized report_template.Rmd + style .docx
```

---

## Pipeline Pattern

Each analysis module follows a four-step Rmd sequence:

| Step | File | Purpose |
|------|------|---------|
| 1 | `01_ingest.Rmd` | Read Excel field forms → tidy R data frame; save `.rds` |
| 2 | `02_qaqc.Rmd` | Flag unrecognised species, out-of-range values, missing fields; save clean `.rds` + flags `.csv` |
| 3 | `03_transform.Rmd` | Cross-reference lookup tables, classify plots, compute scores |
| 4 | `04_visualize.Rmd` | Produce publication-quality figures saved to `reports/figures/` |

All Rmds are **parameterized** (`params$project_id`, `params$input_file`, etc.) so the same scripts run for any project without editing code.

---

## Reference Data

Reference tables (species indicator status, invasive/noxious lists, ANPC wetland plant communities, soil horizon codes, etc.) are stored as `.rda` files in `data/`. They are rebuilt from source CSVs by running:

```r
source("data-raw/build_reference_data.R")
```

Reference CSVs **are** committed (whitelisted in `.gitignore`); project-specific client field data goes under `data-raw/projects/` and is ignored. See the "Reference data pipeline" section of `README.md` for the full policy. Never hand-edit `.rda` files directly — always update the source CSV and re-run the build script.

---

## Key Scientific Concepts (context for coding decisions)

- **UPL–OBL scoring:** Each vascular plant species has a wetland indicator status (UPL, FACU, FAC, FACW, OBL). Plot-level scores summarise the proportion of obligate/facultative wetland species, which is a primary criterion for wetland delineation.
- **Von Post scale:** A 1–10 humification scale for peat; values ≥ 6 indicate well-decomposed peat relevant to wetland class determination.
- **Munsell colour:** Soil matrix and mottle colours are recorded in Munsell notation (hue value/chroma) and used to identify hydric soil indicators (e.g., low chroma, redoximorphic features).
- **Water permanence classes:** Alberta uses a semi-permanent/permanent/ephemeral/intermittent typology; permanence is assessed from multi-year NDWI time series and LiDAR-derived depressions.
- **WAIR score:** A composite wetland significance score combining vegetation, soils, water permanence, and landscape context. Used directly in regulatory impact assessments.

---

## Report Standards

- Reports render to **Word** (`.docx`) using a `reference_docx` style template for client delivery, and to **HTML** for internal QA review.
- Figures must include proper captions, axis labels with units, and species/code labels that are interpretable without the underlying data.
- All classification decisions appearing in a report should be traceable to a specific step in the pipeline (i.e., the `03_transform.Rmd` output).
- Avoid hardcoded project-specific values anywhere except `params`; the pipeline must be reusable across projects.

---

## Coding Conventions

- Prefer `|>` (base pipe) over `%>%`
- `here::here()` for all file paths — never relative string paths
- Snake_case for all column names (enforced at ingest with `janitor::clean_names()`)
- Intermediate `.rds` files are named `{project_id}_{step}.rds` (e.g., `AB-2024-01_veg_clean.rds`)
- Functions mature from inline Rmd chunks → shared `R/` functions when used in more than one module
