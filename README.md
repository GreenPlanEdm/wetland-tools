# wetlandtools

R-based tools for wetland field data ingestion, QA/QC, transformation, and visualization in Alberta. Designed to support regulatory-facing technical reports aligned with ABWRET-A, WAIR, and the ANPC Wetland Classification System.

## Structure

```
analysis/
  vegetation/   # UPL-OBL classification, invasive species, WAIR methodology
  soils/        # soil profile classification, peat isopachs, Van Post
  water/        # water permanence from imagery and LiDAR
R/              # shared functions (extracted from Rmds as they mature)
data-raw/       # source reference tables + rebuild script
data/           # processed .rda reference datasets
inst/templates/ # blank Excel field data entry templates
reports/        # parameterized client report templates
```

## Workflow

Each tool follows a four-step Rmd sequence:

1. `01_ingest.Rmd` — read Excel field forms into tidy R tables
2. `02_qaqc.Rmd` — flag typos, unexpected values, and out-of-region anomalies
3. `03_transform.Rmd` — cross-reference tables, classify plots
4. `04_visualize.Rmd` — produce figures for insertion into client reports

## Reference data pipeline

Two folders, two roles:

- **`data-raw/`** — human-readable source files (CSVs) plus the build script. This is what you edit when reference data changes.
- **`data/`** — compiled R datasets (`.rda`) that `analysis/*.Rmd` and package functions load via `data()`. Never hand-edit these; they are generated.

The flow is one-way:

```
data-raw/*.csv  ─►  build_reference_data.R  ─►  data/*.rda
                  (also pulls aqp::munsell)
```

Run the build script whenever any source changes:

```r
source("data-raw/build_reference_data.R")
```

### What's tracked in git

| Path | Tracked? | Why |
|---|---|---|
| `data-raw/build_reference_data.R` | ✅ yes | Canonical mapping from CSV → `.rda` |
| `data-raw/*.csv` (reference tables) | ✅ yes | Whitelisted in `.gitignore`; needed to rebuild `data/` |
| `data-raw/*.rda` outputs in `data/` | ✅ yes | Built artefacts; package consumers load these |
| `data-raw/*.xlsx`, `*.pdf` | ❌ no | Original sources; CSV is the canonical form |
| `data-raw/projects/` | ❌ no | Client field data — never committed |

**Where do I put new client field data?** Under `data-raw/projects/<project_id>/` — gitignored by default.
**Where do I put a new reference CSV?** Drop it in `data-raw/`, add an `!data-raw/<file>.csv` line to `.gitignore`, and add a read block to `build_reference_data.R`.

### Currently built datasets (10)

| `.rda` file | Source | Description |
|---|---|---|
| `wetland_indicator_status` | `ABWetlandPlantList_2021.csv` | UPL–OBL status for AB species (WMVC/GP/NCNE/AK regions) |
| `awcs_wetland_species` | `awcs_wetland_species.csv` | AWCS 2015 provincial plant list with indicator assignments |
| `anpc_wetland_species` | `ANPC_Native_Plant_List.csv` | ACIMS native plant list used for species code validation |
| `rangeland_plants` | `RangePlants_2023.csv` | AEP rangeland plants with forage/grazing attributes |
| `noxious_weeds` | `noxious_weeds_ab.csv` | AB Weed Control Act noxious and nuisance weed list |
| `ecosite_wetclass` | `Ecosite_to_WetClass.csv` | Beckingham & Archibald 1996 ecosite phase ↔ AWCS wetland class crosswalk (Boreal NRs) |
| `nrc_geography` | `nrc_geography_usace.csv` | Alberta Natural Region ↔ USACE NWPL regional list bridge |
| `cssc_great_groups` | `cssc_great_groups.csv` | Canadian System of Soil Classification great groups |
| `von_post` | `Van_Post_List.csv` | Von Post peat humification scale (H1–H10) |
| `munsell` | `aqp::munsell` (R package, no CSV) | 10,450 Munsell chips with sRGB + L\*a\*b\* + hex |

### Pending datasets (Track 2)

The build script contains commented-out stubs for these — source CSVs need to be authored or obtained before they can be built:

- `invasive_species` — AB Invasive Species Council list
- `ecosites_nfc` — full NRC ecosite phase classification (distinct from `ecosite_wetclass`, which is only the wetland crosswalk)
- `salinity_tolerance` — plant salinity tolerance (Thurber Wetland Monitoring Project + literature)
- `agrasid` — AGRASID soil map units
- `wair_rules` — WAIR wetland classification decision rules

These are tracked in [issue #4](https://github.com/GreenPlanEdm/wetland-tools/issues/4).

## Dependencies

Core: `dplyr`, `tidyr`, `readxl`, `openxlsx`, `stringr`, `ggplot2`, `sf`, `terra`, `rmarkdown`

Install all with:

```r
install.packages(c("dplyr","tidyr","readxl","openxlsx","stringr","purrr",
                   "ggplot2","sf","terra","rmarkdown","knitr","here"))
```
