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

## Reference datasets

Run `data-raw/build_reference_data.R` to rebuild all processed reference `.rda` files from source CSVs. Source files are not committed — see `.gitignore`.

## Dependencies

Core: `dplyr`, `tidyr`, `readxl`, `openxlsx`, `stringr`, `ggplot2`, `sf`, `terra`, `rmarkdown`

Install all with:

```r
install.packages(c("dplyr","tidyr","readxl","openxlsx","stringr","purrr",
                   "ggplot2","sf","terra","rmarkdown","knitr","here"))
```
