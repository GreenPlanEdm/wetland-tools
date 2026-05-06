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

`data-raw/` holds **source files** (CSVs, Excel, PDFs) and the build script.
`data/` holds **compiled R datasets** (`.rda` files) that the package and analysis Rmds load via `data()`.

The workflow is:

```
data-raw/*.csv  →  build_reference_data.R  →  data/*.rda
```

Run the build script whenever a source CSV is updated:

```r
source("data-raw/build_reference_data.R")
```

### Currently built datasets

| `.rda` file | Source CSV | Description |
|---|---|---|
| `wetland_indicator_status` | `ABWetlandPlantList_2021.csv` | UPL–OBL status for AB species (WMVC/GP/NCNE/AK regions) |
| `awcs_wetland_species` | `awcs_wetland_species.csv` | AWCS 2015 provincial plant list with indicator assignments |
| `anpc_wetland_species` | `ANPC_Native_Plant_List.csv` | ACIMS native plant list used for species code validation |
| `rangeland_plants` | `RangePlants_2023.csv` | AEP rangeland plants with forage/grazing attributes |
| `noxious_weeds` | `noxious_weeds_ab.csv` | AB Weed Control Act noxious and nuisance weed list |
| `cssc_great_groups` | `cssc_great_groups.csv` | Canadian System of Soil Classification great groups |
| `von_post` | `Van_Post_List.csv` | Von Post peat humification scale (H1–H10) |

### Pending datasets (Track 2)

The build script contains commented-out stubs for these — source CSVs do not yet exist and need to be authored or obtained:

- `invasive_species` — AB Invasive Species Council list
- `ecosites_nfc` — NRC Northern Forestry Centre ecosite classification
- `salinity_tolerance` — plant salinity tolerance (literature compilation)
- `munsell` — Munsell soil colour chart
- `agrasid` — AGRASID soil map units
- `nrc_geography` — NRCan geographic regions / USACE linkage
- `wair_rules` — WAIR wetland classification decision rules

To add a new dataset: place the source CSV in `data-raw/`, add a read + `usethis::use_data()` block in `build_reference_data.R`, then re-run the script.

## Dependencies

Core: `dplyr`, `tidyr`, `readxl`, `openxlsx`, `stringr`, `ggplot2`, `sf`, `terra`, `rmarkdown`

Install all with:

```r
install.packages(c("dplyr","tidyr","readxl","openxlsx","stringr","purrr",
                   "ggplot2","sf","terra","rmarkdown","knitr","here"))
```
