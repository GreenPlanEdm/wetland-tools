# Vegetation Analysis — Design

Status: **draft / agreed direction** — source of truth for the vegetation analysis
build-out. Supersedes the placeholder logic currently in
`04_visualize.Rmd` (which references `_plot_wi.rds` / `_plot_class.rds`
artefacts that nothing produces yet).

Worked examples that drove this design live in
`analysis/vegetation/examples/` (a WAIR methods excerpt, a multi-year
monitoring dominance figure, an `App A` species-data appendix, and the 14
per-plot / per-wetland metric figures).

---

## 1. Two report types, one core

The firm produces two deliverables from the same field data:

| | **WAIR** (single instance) | **Wetland Monitoring** (multi-year) |
|---|---|---|
| Frequency | Most common; the default | Annual / periodic |
| Survey instances | 1 | Many (one per year) |
| Time component | None | Year axis / change-over-time |
| Reference wetland | None | Present (compliance comparator) |
| Compliance band | Computed, **hidden** | Computed at baseline, **shown** + assessed |

**WAIR is the core.** The shared pipeline (steps 01–04) *is* a complete WAIR
analysis, including the baseline ±10 compliance band (computed, just not
drawn). Monitoring is a strict **extension**: it reuses the baseline year's
core outputs unchanged and adds year-binding, reference comparison, and
band reveal/assessment on top.

Rationale: the hydrophytic determination is the regulatory core. WAIR and
Monitoring must compute it identically, so it lives in exactly one place and
neither report type forks it.

---

## 2. Module structure

```
analysis/vegetation/
  01_ingest.Rmd            shared core — Excel -> tidy R (per survey instance)
  02_qaqc.Rmd              shared core — flag issues
  03_transform.Rmd         shared core — per-plot WI lookup, dominance fields, joins
  04_analysis.Rmd          shared core — determination + per-plot/per-wetland
                           metrics + compute (not draw) the +/-10 band
  05_monitoring.Rmd        Monitoring only — bind years, fix baseline band,
                           reference comparison, compliance assessment
  06_visualize.Rmd         branches on params$report_type ("wair" | "monitoring")
  tables_vegetation.Rmd    App A species table + per-plot determination table
  methods_vegetation.Rmd   verbatim methodology + Table 6, cited; report child
  DESIGN.md                this document
R/
  veg_figures.R            shared figure builders, parameterised by
                           (group_by_year, include_reference, show_band)
  veg_determination.R      the tiered 3-method test (extracted from 04 as it matures)
```

Data flow:

```
            per survey instance (one site, one year)
01_ingest -> 02_qaqc -> 03_transform -> 04_analysis
                                            |  _plot_class.rds (determination, %hydro, band)
                                            |  _plot_summary.rds (+ per-wetland rollups)
                                            v
   WAIR  -------------------------------> 06_visualize (report_type="wair", band hidden)
                                            ^
   Monitoring: 04_analysis x N years ----> 05_monitoring --> 06_visualize
                                            (baseline band fixed, reference, compliance)
```

---

## 3. Shared core (steps 01–04)

### 01_ingest.Rmd (exists; one change)
- **Add `wetland_id`** to the `plots` sheet and carry it through. Plots group
  by `wetland_id` for every `_per_wetland` figure. Do **not** parse it from the
  `1.x` plot-ID prefix — that is fragile; capture it explicitly.
- (Monitoring only) an optional `is_reference` flag on `plots` marks the
  reference/control wetland. Unused by WAIR.

### 02_qaqc.Rmd (exists)
- Validate `wetland_id` is present and `wi_region` is in the allowed set
  (`WMVC`, `GP`, `NCNE`, `AK`) — already done for `wi_region`.

### 03_transform.Rmd (extend)
Per-plot wetland-indicator lookup (replaces the global region-priority list):

- **Primary region = the plot's own `wi_region`** (the field crew's per-plot
  call). Not a project parameter. Usually uniform across plots; per-plot
  capture covers the rare split.
- **Secondary region = `params$region_secondary`** — one project-level fallback,
  assigned manually. May be empty for single-region projects.
- For each species row: look up WI status in the plot's `wi_region`; if the
  reference table is blank there, fall back to `region_secondary`; record
  **`wi_region_used`** (drives the table footnote in §7).

Also emit the fields the determination needs:
- `stratum_cover` and **`is_dominant`** = species cover ≥ 20% of its stratum total.
- **`wi_numeric`** rank for the prevalence index: OBL=1, FACW=2, FAC=3, FACU=4, UPL=5.
- `origin` (native/exotic), invasive/noxious flags, salinity category — as today.

Keep the existing per-plot aggregates (cover per stratum, bare, invasive,
native/exotic, richness).

### 04_analysis.Rmd (new — the regulatory core)

**Hydrophytic determination — the tiered 3-method test.** Traceable to USDA
2007, Wakeley & Lichvar 1997, USACE 2018; this is the firm's documented interpretation
(see `methods_vegetation.Rmd`). A *dominant* species is ≥20% areal cover within
its stratum. Hydrophytic indicator statuses are OBL, FACW, FAC.

1. **Method 1 — dominance of identified dominants.** If > 50% of the dominant
   species across all strata are OBL/FACW/FAC, the plot is a wetland.
2. **Method 2 — 50/20 rule (USDA 2007).** If *no* dominants were identified,
   pick dominants via the 50/20 rule (rank species by cover descending within
   stratum; take species cumulatively to 50%, plus any other species > 20%),
   then apply the dominance test. An exact 50% tie falls to Method 3.
3. **Method 3 — prevalence index (Wakeley & Lichvar 1997).**
   `PI = Σ(cover_i × wi_numeric_i) / Σ(cover_i)`. `PI < 3` ⇒ wetland.

Record which method produced the call (`deciding_method`) so every
determination is auditable.

**% hydrophytic vegetation** (the headline monitoring metric / `Dominance_Plot`
y-axis): `(# dominant species that are OBL/FACW/FAC) / (# dominant species) × 100`.
The example values (25, 40, 50, 67, 75 %) confirm this is *% of dominant
species*, with 50% as the Method-1 threshold line.

**Per-wetland rollups** for each metric (mean across plots in the `wetland_id`,
plus dispersion — see §5 open item).

**Compliance band (compute, do not draw here).** Treating the current instance
as baseline, compute the ±band for every plot × metric and store it (§4). WAIR
stores it for a future monitoring program to inherit; Monitoring's baseline
year is the band everyone else is tested against.

Outputs:
- `_plot_class.rds` — per plot: dominants, `deciding_method`, determination,
  `pct_hydrophytic`, baseline band per metric.
- `_plot_summary.rds` — per-plot metrics + per-wetland rollups.

---

## 4. Compliance band model

A fixed band around the **baseline** value of each variable. A later year
outside the band ⇒ the project is **non-compliant** for that variable/plot.

| Metric family | Band half-width | Example |
|---|---|---|
| Cover metrics (total, bare, invasive, native, exotic) | **±10 percentage points** (absolute) | baseline 95% → 85–105% |
| Species richness (count) | **±⌈0.10 × baseline⌉ species** | 8 → ±1; 20 → ±2 |

- Half-width controlled by `params$compliance_band_pct` (default `10`); applied
  as percentage points for cover and as % of count rounded **up** for richness.
- Lower bound clamped at 0. Total cover may exceed 100 (overlapping strata), so
  no hard upper clamp.
- **Computed in `04_analysis`** for the current instance (= baseline values).
- **WAIR:** computed and stored, **not drawn**, no compliance assessment
  (nothing to compare yet).
- **Monitoring:** the band from the *designated baseline year* is fixed and
  reused for all years; each year's value is tested against it and flagged
  compliant / non-compliant (`05_monitoring`), and the band is drawn as the
  error bars.

### Error bars mean different things by report type × level

The same red dashed error bars carry different meaning because the two reports
answer different questions — WAIR *characterises current state*; Monitoring
*tests for change against a fixed baseline*.

| | per-plot | per-wetland |
|---|---|---|
| **WAIR** | none (single value, nothing to compare) | **mean ± SD across plots** — within-wetland variability, relative to the mean |
| **Monitoring** | ±band from baseline (absolute, compliance) | ±band from **baseline wetland mean** (absolute, compliance) |

Monitoring example: baseline mean cover 25% across a wetland → lower compliance
bound 15%; dropping below 15% is non-compliant. An SD bar would be useless here
(no prior baseline to test against); a fixed compliance band would be useless in
a WAIR (the wetland has no history yet). Every figure caption must state which
of the two the error bars represent.

**Compliance is directional.** A symmetric ±band is drawn, but the *adverse*
direction is metric-specific: a **decrease** below the lower bound is adverse
for cover and richness, whereas an **increase** above the upper bound is adverse
for invasive and bare-ground cover (desirable gains are positive, not a breach).
`04_analysis` carries a per-metric `adverse_direction` so compliance flags read
correctly.

---

## 5. Monitoring extension (05_monitoring.Rmd)

Runs only when `report_type = "monitoring"`. Inputs: the `_plot_class.rds` /
`_plot_summary.rds` from `04_analysis` for **each** year.

- Bind years into one long table keyed by `plot_id × wetland_id × year`.
- Identify the **baseline year** (`params$baseline_year`); take its stored band
  as the fixed compliance band for all years, at **both** plot and wetland level
  (per-wetland band = baseline wetland mean ± band).
- Assess compliance per plot × metric × year and per wetland × metric × year
  against the baseline band, honouring each metric's `adverse_direction`.
- Attach the **reference wetland** (`is_reference`) as the comparison baseline
  for narrative/figures.
- Output a bound, compliance-flagged dataset for `06_visualize`.

---

## 6. Visualization (06_visualize.Rmd) + R/veg_figures.R

One figure builder per metric in `R/veg_figures.R`, written once and called by
both report types with different switches:

```
veg_bar(data, metric, level = c("plot","wetland"),
        group_by_year = FALSE,     # Monitoring: TRUE
        include_reference = FALSE,  # Monitoring: TRUE
        errorbar = c("none","sd","compliance"))
```

Error-bar mode follows report type × level (§4):

| | per-plot | per-wetland |
|---|---|---|
| **WAIR** | `"none"` | `"sd"` |
| **Monitoring** | `"compliance"` | `"compliance"` |

### Figure inventory

| Figure | per-plot | per-wetland | WAIR | Monitoring | Optional |
|---|:--:|:--:|:--:|:--:|:--:|
| Total vegetation cover | ✓ | ✓ | ✓ | ✓ | |
| Bare ground cover | ✓ | ✓ | ✓ | ✓ | |
| Invasive species cover | ✓ | ✓ | ✓ | ✓ | |
| Native vs exotic cover | ✓ | ✓ | ✓ | ✓ | |
| Species richness | ✓ | ✓ | ✓ | ✓ | |
| WI status (UPL–OBL) composition | ✓ | ✓ | ✓ | ✓ | |
| % hydrophytic / dominance test | ✓ | ✓ | ✓ | ✓ (by year) | |
| Salinity-tolerance composition | ✓ | ✓ | | | **default off** |
| Noxious-weed heatmap | ✓ | | | | optional |

Differences are switches, not separate figures:
- **WAIR:** `group_by_year = FALSE`, `include_reference = FALSE`,
  `show_band = FALSE`. Single-instance snapshot.
- **Monitoring:** the dominance figure groups bars by year (the `Dominance_Plot`
  example); metric figures add the year dimension, the reference wetland, and
  the per-plot compliance band with non-compliant plots flagged.

Optional figures (salinity, heatmap) are driven by a `params$figures` toggle;
core figures always render. Defaults keep salinity **off** (not needed for most
projects).

---

## 7. Region priority & per-plot table footnotes

- Primary = per-plot `wi_region`; secondary = `params$region_secondary`
  (manual, project-level). Recorded per row as `wi_region_used` in transform.
- **App A per-plot table** (`tables_vegetation.Rmd`) annotates source region:
  - Column/table footnote describing the scheme, e.g. *"Indicator status from
    the Great Plains (GP) region; where no GP status was available, the
    secondary region (WMVC) was used."*
  - **Per-row superscript** only on statuses drawn from the **secondary**
    region (primary stays unmarked) → footnote: *"from secondary region (WMVC);
    no status available in primary region (GP)."*
  - Existing `M*` / AWCS-only-species superscript pattern retained for species
    with no NWPL status but an AWCS classification (GoA 2015a).

---

## 8. Wetland grouping & reference designation

- `wetland_id` (required, both report types) groups plots for per-wetland
  figures and rollups.
- `is_reference` (Monitoring only) marks the comparison wetland. Use a single
  standard term in legends — **"Reference"** (the examples are inconsistent:
  "Control (W3)" vs "Reference (W3)"; standardise to Reference).

---

## 9. Tables (tables_vegetation.Rmd)

- **App A — Vegetation Plot Data:** per-plot species listing — ID, `wetland_id`,
  wetland class, veg plot, UTM E/N, common + scientific name, stratum, % cover,
  WI status (+ region/AWCS footnotes from §7), per-plot comments row. Rendered
  with flextable/gt for Word.
- **Per-plot determination summary:** plot → dominants → `deciding_method` →
  `pct_hydrophytic` → determination. The auditable trace behind the dominance
  figure.

---

## 10. Methods appendix (methods_vegetation.Rmd)

Verbatim methodology written out for the vegetation analysis appendix: plot
sizes per stratum, dominant-species definition, AWPL 2021 + NWPL referencing,
the per-plot primary / project secondary region scheme, the tiered 3-method
determination, and Table 6 (WI status ratings). Every claim cited to a
`source_id` in `references.rda` (USDA 2007, Wakeley & Lichvar 1997, USACE 2018, GoA 2015a,
AB Wetland Plant List 2021). Included as a knitr child in the report appendix so
the prose is version-controlled, not pasted.

---

## 11. Parameters (by module)

| Param | Module(s) | Notes |
|---|---|---|
| `project_id` | all | as today |
| `input_file` | 01 | as today |
| `region_secondary` | 03+ | single manual fallback region; may be empty |
| `report_type` | 06 | `"wair"` (default) or `"monitoring"` |
| `compliance_band_pct` | 04/05 | default `10` |
| `baseline_year` | 05 | designates the fixed-band baseline |
| `figures` | 06 | optional-figure toggles (salinity off by default) |
| `output_dir` | 06 | as today |

---

## 12. Reference-data dependencies

`wetland_indicator_status`, `awcs_wetland_species`, `anpc_wetland_species`,
`invasive_species`, `noxious_weeds`, `species_salinity_tolerance`,
`references`. No new reference tables required for the determination; WAIR
scoring (`wair_rules`, issue #4) remains out of scope here.

---

## 13. Open items to confirm

1. **Richness y-axis label.** Examples read "Species Richness (%)" — richness is
   a count; drop the "(%)". (Assumed yes.)
2. **Renumbering.** Introduce `04_analysis`, `05_monitoring`, rename current
   `04_visualize` → `06_visualize`. (Assumed yes.)

Resolved: per-wetland error bars are mean ± SD (WAIR, descriptive) vs ±band from
baseline wetland mean (Monitoring, compliance) — see §4.
```
