"""
Generate fillable PDF field forms for wetland data collection.
Requires: pip install reportlab
"""

from reportlab.lib.pagesizes import landscape, letter
from reportlab.lib import colors
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch, mm
from reportlab.pdfbase.acroform import AcroForm
import os

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
W, H = landscape(letter)   # 792 x 612 pts

MARGIN_L = 18
MARGIN_R = 18
USABLE_W = W - MARGIN_L - MARGIN_R

HEADER_BG   = colors.HexColor("#D6E4F0")
ROW_ALT     = colors.HexColor("#F7FBFF")
LABEL_COLOR = colors.HexColor("#1A1A1A")
GRID_COLOR  = colors.HexColor("#7F7F7F")
TITLE_BG    = colors.HexColor("#2E5090")

FONT_LABEL  = ("Helvetica-Bold", 6)
FONT_FIELD  = ("Helvetica",      7)
FONT_TITLE  = ("Helvetica-Bold", 11)
FONT_TINY   = ("Helvetica",      5)


def draw_text(c, x, y, text, font=FONT_FIELD, color=LABEL_COLOR, align="left"):
    c.saveState()
    c.setFont(*font)
    c.setFillColor(color)
    if align == "center":
        c.drawCentredString(x, y, text)
    elif align == "right":
        c.drawRightString(x, y, text)
    else:
        c.drawString(x, y, text)
    c.restoreState()


def cell_rect(c, x, y, w, h, fill=None, border=True):
    c.saveState()
    if fill:
        c.setFillColor(fill)
        c.rect(x, y, w, h, fill=1, stroke=0)
    if border:
        c.setStrokeColor(GRID_COLOR)
        c.setLineWidth(0.4)
        c.rect(x, y, w, h, fill=0, stroke=1)
    c.restoreState()


def text_field(c, name, x, y, w, h, tooltip="", multiline=False):
    form = c.acroForm
    flags = "multiline" if multiline else ""
    form.textfield(
        name=name,
        tooltip=tooltip,
        x=x, y=y, width=w, height=h,
        borderColor=colors.HexColor("#888888"),
        fillColor=colors.white,
        textColor=colors.black,
        fontSize=7,
        borderWidth=0.5,
        fieldFlags=flags,
        forceBorder=True,
    )


def checkbox(c, name, x, y, size=8, tooltip=""):
    form = c.acroForm
    form.checkbox(
        name=name,
        tooltip=tooltip,
        x=x, y=y, size=size,
        borderColor=colors.HexColor("#888888"),
        fillColor=colors.white,
        textColor=colors.black,
        borderWidth=0.5,
        forceBorder=True,
    )


def page_title(c, title, subtitle=""):
    c.saveState()
    c.setFillColor(TITLE_BG)
    c.rect(MARGIN_L, H - 28, USABLE_W, 22, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 12)
    c.drawString(MARGIN_L + 6, H - 19, title)
    if subtitle:
        c.setFont("Helvetica", 8)
        c.drawRightString(W - MARGIN_R - 4, H - 19, subtitle)
    c.restoreState()


# ─────────────────────────────────────────────────────────────────────────────
# VEGETATION + HYDROLOGY FORM
# ─────────────────────────────────────────────────────────────────────────────

def build_veg_form(path):
    c = canvas.Canvas(path, pagesize=landscape(letter))
    c.setTitle("Vegetation & Hydrology Field Form — Wetland Assessment")

    page_title(c, "VEGETATION & HYDROLOGY FIELD DATA FORM",
               "Alberta Wetland Assessment  ·  AWCS / AWIDD")

    # ── Header helper ─────────────────────────────────────────────────────────
    def hdr_field(label, name, x, y_top, w):
        cell_rect(c, x, y_top - 26, w, 26, fill=HEADER_BG)
        draw_text(c, x + 2, y_top - 7, label, FONT_LABEL)
        text_field(c, name, x + 2, y_top - 25, w - 4, 13, tooltip=label)

    # ── Header row 1 — project metadata ──────────────────────────────────────
    # Widths: 130+120+90+140+96+44+136 = 756
    R1 = H - 30
    x = MARGIN_L
    for label, name, w in [
        ("Project ID", "project_id", 130),
        ("Site ID",    "site_id",    120),
        ("Plot ID",    "plot_id",     90),
        ("Observer",   "observer",   140),
        ("Weather",    "weather",     96),
    ]:
        hdr_field(label, name, x, R1, w)
        x += w

    # Photos Taken — checkbox in a header-style cell
    cell_rect(c, x, R1 - 26, 44, 26, fill=HEADER_BG)
    draw_text(c, x + 2, R1 - 7,  "Photos", FONT_LABEL)
    draw_text(c, x + 2, R1 - 14, "Taken?", FONT_LABEL)
    checkbox(c, "photos_taken", x + 27, R1 - 21, size=11, tooltip="Photos Taken")
    x += 44

    # Photo numbers — fills rest of row 1 (136 pts)
    hdr_field("Photo #'s:", "photo_numbers", x, R1, 136)

    # ── Header row 2 — location and date ─────────────────────────────────────
    R2 = H - 60
    x = MARGIN_L
    for label, name, w in [
        ("Date (DD)", "date_dd",   50),
        ("MM",        "date_mm",   50),
        ("YYYY",      "date_yyyy", 60),
    ]:
        hdr_field(label, name, x, R2, w)
        x += w

    for label, name, w in [
        ("GPS Easting",  "gps_e", 130),
        ("GPS Northing", "gps_n", 130),
    ]:
        hdr_field(label, name, x, R2, w)
        x += w

    # Datum checkboxes
    cell_rect(c, x, R2 - 26, 86, 26, fill=HEADER_BG)
    draw_text(c, x + 2, R2 - 7, "Datum:", FONT_LABEL)
    checkbox(c, "datum_nad83", x + 2,  R2 - 24, size=9, tooltip="NAD83")
    draw_text(c, x + 13, R2 - 17, "NAD83", FONT_TINY)
    checkbox(c, "datum_wgs84", x + 46, R2 - 24, size=9, tooltip="WGS84")
    draw_text(c, x + 57, R2 - 17, "WGS84", FONT_TINY)
    x += 86

    # AWCS class — fills remaining row-2 width
    awcs_w = MARGIN_L + USABLE_W - x
    hdr_field("AWCS Wetland Class (observed):", "awcs_class_obs", x, R2, awcs_w)

    # ── Column layout ─────────────────────────────────────────────────────────
    ML = MARGIN_L
    # N/E and Nox. dropped from form — derived in 03_transform.Rmd from
    # ANPC native list and Alberta noxious weeds reference table.
    # Moss (M) stratum dropped — Green Plan field protocol records Tree /
    # Shrub / Ground only; freed width given to the Scientific/Common Name col.
    C_SPP  = (ML,        90)
    C_NAME = (ML +  90, 238)
    C_T    = (ML + 328,  18)
    C_S    = (ML + 346,  18)
    C_G    = (ML + 364,  18)
    C_COV  = (ML + 382,  58)
    C_OBL  = (ML + 440,  18)
    C_FACW = (ML + 458,  20)
    C_FAC  = (ML + 478,  18)
    C_FACU = (ML + 496,  20)
    C_UPL  = (ML + 516,  18)
    C_NL   = (ML + 534,  16)
    C_INV  = (ML + 550,  26)
    C_NOT  = (ML + 576, 180)

    # ── Main column header row ────────────────────────────────────────────────
    MAIN_H = 14
    SUB_H  = 12
    chy = H - 90

    def hdr_col(cx, cw, label):
        cell_rect(c, cx, chy - MAIN_H, cw, MAIN_H, fill=TITLE_BG)
        draw_text(c, cx + cw / 2, chy - MAIN_H + 4, label,
                  ("Helvetica-Bold", 8), colors.white, align="center")

    hdr_col(*C_SPP,  "Species Code")
    hdr_col(*C_NAME, "Scientific / Common Name")
    hdr_col(C_T[0], C_T[1]+C_S[1]+C_G[1], "Stratum")
    hdr_col(*C_COV,  "% Cover")
    hdr_col(C_OBL[0], C_OBL[1]+C_FACW[1]+C_FAC[1]+C_FACU[1]+C_UPL[1]+C_NL[1],
            "WI Status")
    hdr_col(*C_INV,  "Inv.")
    hdr_col(*C_NOT,  "Notes")

    # ── Sub-header row ────────────────────────────────────────────────────────
    shy = chy - MAIN_H
    cell_rect(c, MARGIN_L, shy - SUB_H, USABLE_W, SUB_H)

    def sub(cx, cw, label):
        draw_text(c, cx + cw / 2, shy - SUB_H + 3, label,
                  ("Helvetica", 6), align="center")

    sub(*C_T,    "T")
    sub(*C_S,    "S")
    sub(*C_G,    "G")
    sub(*C_OBL,  "OBL")
    sub(*C_FACW, "FACW")
    sub(*C_FAC,  "FAC")
    sub(*C_FACU, "FACU")
    sub(*C_UPL,  "UPL")
    sub(*C_NL,   "NL")
    sub(C_INV[0],      13, "Y")
    sub(C_INV[0] + 13, 13, "N")

    # ── Data rows (15 rows × 18 pt) ───────────────────────────────────────────
    N_ROWS = 15
    ROW_H  = 18
    row_top = shy - SUB_H

    for r in range(N_ROWS):
        ry   = row_top - (r + 1) * ROW_H
        fill = ROW_ALT if r % 2 == 0 else colors.white
        cell_rect(c, MARGIN_L, ry, USABLE_W, ROW_H, fill=fill)
        rn = f"{r + 1:02d}"

        text_field(c, f"spp_code_{rn}", C_SPP[0] + 1, ry + 2,
                   C_SPP[1] - 2, ROW_H - 4, tooltip=f"Species code row {r+1}")
        text_field(c, f"spp_name_{rn}", C_NAME[0] + 1, ry + 2,
                   C_NAME[1] - 2, ROW_H - 4, tooltip=f"Species name row {r+1}")

        for col, lbl in [(C_T, "T"), (C_S, "S"), (C_G, "G")]:
            checkbox(c, f"strat_{lbl}_{rn}", col[0] + 4, ry + 4,
                     size=9, tooltip=f"Stratum {lbl} row {r+1}")

        text_field(c, f"pct_cover_{rn}", C_COV[0] + 1, ry + 2,
                   C_COV[1] - 2, ROW_H - 4, tooltip=f"% Cover row {r+1}")

        for col, lbl in [
            (C_OBL,  "OBL"),
            (C_FACW, "FACW"),
            (C_FAC,  "FAC"),
            (C_FACU, "FACU"),
            (C_UPL,  "UPL"),
            (C_NL,   "NL"),
        ]:
            checkbox(c, f"wi_{lbl}_{rn}", col[0] + (col[1] - 9) // 2, ry + 4,
                     size=9, tooltip=f"WI {lbl} row {r+1}")

        checkbox(c, f"inv_y_{rn}", C_INV[0] + 4,  ry + 4, size=9, tooltip="Invasive Yes")
        checkbox(c, f"inv_n_{rn}", C_INV[0] + 17, ry + 4, size=9, tooltip="Invasive No")

        text_field(c, f"notes_{rn}", C_NOT[0] + 1, ry + 2,
                   C_NOT[1] - 2, ROW_H - 4, tooltip=f"Notes row {r+1}")

    # Vertical dividers between the major species-table categories, drawn
    # once across the full data row block so the eye can find each column
    # without having to scan back up to the header.
    c.saveState()
    c.setStrokeColor(GRID_COLOR)
    c.setLineWidth(0.5)
    div_top = row_top
    div_bot = row_top - N_ROWS * ROW_H
    for x in (C_T[0], C_COV[0], C_OBL[0], C_INV[0], C_NOT[0]):
        c.line(x, div_bot, x, div_top)
    c.restoreState()

    # ── Vegetation Summary ────────────────────────────────────────────────────
    VS_BAR = 13
    VS_ROW = 16
    vs_top = row_top - N_ROWS * ROW_H - 2

    cell_rect(c, MARGIN_L, vs_top - VS_BAR, USABLE_W, VS_BAR, fill=TITLE_BG)
    draw_text(c, MARGIN_L + 4, vs_top - VS_BAR + 4, "VEGETATION SUMMARY",
              ("Helvetica-Bold", 7), colors.white)

    # Row A — WI status species counts, then plot determination after Total
    vs_a = vs_top - VS_BAR - VS_ROW
    cell_rect(c, MARGIN_L, vs_a, USABLE_W, VS_ROW, fill=HEADER_BG)
    draw_text(c, MARGIN_L + 2, vs_a + 10, "Dominant Species Count by WI Status:", FONT_LABEL)
    wx = MARGIN_L + 124
    for lbl, nm, lw, fw in [
        ("OBL",   "sum_obl",   20, 26),
        ("FACW",  "sum_facw",  26, 26),
        ("FAC",   "sum_fac",   20, 26),
        ("FACU",  "sum_facu",  26, 26),
        ("UPL",   "sum_upl",   20, 26),
        ("NL",    "sum_nl",    14, 26),
        ("Total", "sum_total", 26, 34),
    ]:
        draw_text(c, wx, vs_a + 10, lbl + ":", FONT_LABEL)
        text_field(c, nm, wx + lw, vs_a + 2, fw, VS_ROW - 5, tooltip=f"{lbl} count")
        wx += lw + fw + 10
    # wx ≈ 542; ~232 pts remain to page right edge — fit determination checkboxes
    draw_text(c, wx + 4, vs_a + 10, "Determination:", FONT_LABEL)
    for lbl, nm, ox in [
        ("Wetland",      "det_wetland",  56),
        ("Non-wetland",  "det_upland",  106),
        ("Inconclusive", "det_inconc",  160),
    ]:
        checkbox(c, nm, wx + ox, vs_a + 4, size=9, tooltip=lbl)
        draw_text(c, wx + ox + 11, vs_a + 8, lbl, FONT_TINY)

    # Row B — Wetland Indicator Region (NWPL / AWIDD lookup region used for
    # indicator-status assignment). Moved here from the Ecosite row so the
    # determination + region call are co-located under the Vegetation Summary.
    vs_b = vs_a - VS_ROW
    cell_rect(c, MARGIN_L, vs_b, USABLE_W, VS_ROW, fill=colors.white)
    draw_text(c, MARGIN_L + 2, vs_b + 10, "Wetland Indicator Region:", FONT_LABEL)
    rx = MARGIN_L + 124
    for lbl, nm, step in [
        ("AK (Boreal)",                    "wi_reg_ak",    90),
        ("WMVC (Mountains and Foothills)", "wi_reg_wmvc", 170),
        ("GP (Grasslands)",                "wi_reg_gp",    95),
        ("NCNE (Parkland)",                "wi_reg_ncne",   0),
    ]:
        checkbox(c, nm, rx, vs_b + 4, size=9, tooltip=f"WI Region {lbl}")
        draw_text(c, rx + 12, vs_b + 8, lbl, FONT_FIELD)
        rx += step

    # Row C — Structural Stage (1–7) with stage-name labels. Kept on the form
    # in the Vegetation Summary block. The broader ecosite classification
    # (Ecosite phase / nutrient-moisture regime / tree-species modifier) is
    # deferred from the form and will be folded into the 03_transform stage
    # rather than collected on paper.
    vs_c = vs_b - VS_ROW
    cell_rect(c, MARGIN_L, vs_c, USABLE_W, VS_ROW, fill=HEADER_BG)
    draw_text(c, MARGIN_L + 2, vs_c + 10, "Structural Stage (1–7):", FONT_LABEL)
    sx = MARGIN_L + 124
    for stage, name, step in [
        (1, "Herb",          70),
        (2, "Shrub",         75),
        (3, "sapling",       80),
        (4, "pole",          75),
        (5, "Young Forest", 100),
        (6, "Mature Forest", 105),
        (7, "Old Forest",     0),
    ]:
        label = f"{stage} ({name})"
        checkbox(c, f"stage_{stage}", sx, vs_c + 4, size=9,
                 tooltip=f"Structural Stage {stage} ({name})")
        draw_text(c, sx + 12, vs_c + 8, label, FONT_FIELD)
        sx += step

    # ── Hydrology Section ─────────────────────────────────────────────────────
    HY_BAR = 13
    HY_ROW = 22
    hy_top = vs_c - 2

    cell_rect(c, MARGIN_L, hy_top - HY_BAR, USABLE_W, HY_BAR, fill=TITLE_BG)
    draw_text(c, MARGIN_L + 4, hy_top - HY_BAR + 4, "HYDROLOGY",
              ("Helvetica-Bold", 7), colors.white)

    # Row A — water presence, depth, outlet
    ry_a = hy_top - HY_BAR - HY_ROW
    cell_rect(c, MARGIN_L, ry_a, USABLE_W, HY_ROW, fill=HEADER_BG)
    draw_text(c, MARGIN_L + 2, ry_a + 13, "Water at surface at time of survey:", FONT_LABEL)
    checkbox(c, "hydro_water_y", MARGIN_L + 140, ry_a + 7, size=8, tooltip="Water present Yes")
    draw_text(c, MARGIN_L + 150, ry_a + 11, "Y", FONT_TINY)
    checkbox(c, "hydro_water_n", MARGIN_L + 162, ry_a + 7, size=8, tooltip="Water present No")
    draw_text(c, MARGIN_L + 172, ry_a + 11, "N", FONT_TINY)
    draw_text(c, MARGIN_L + 186, ry_a + 13, "Water depth (cm):", FONT_LABEL)
    text_field(c, "hydro_depth_cm", MARGIN_L + 244, ry_a + 2, 34, HY_ROW - 4,
               tooltip="Water depth (cm)")
    draw_text(c, MARGIN_L + 284, ry_a + 13, "Outlet:", FONT_LABEL)
    ox = MARGIN_L + 308
    for lbl, nm, step in [
        ("None",       "none",       34),
        ("Surface",    "surface",    46),
        ("Subsurface", "subsurface", 58),
        ("Both",       "both",       34),
    ]:
        checkbox(c, f"outlet_{nm}", ox, ry_a + 7, size=8, tooltip=f"Outlet {lbl}")
        draw_text(c, ox + 10, ry_a + 11, lbl, FONT_TINY)
        ox += step

    # In-situ water chemistry (multi-probe readings collected at the plot).
    ax = MARGIN_L + 510
    for lbl, nm, label_w, field_w, gap in [
        ("pH:",   "hydro_ph",   12, 28, 8),
        ("EC:",   "hydro_ec",   12, 38, 8),
        ("ppm:",  "hydro_ppm",  16, 38, 8),
        ("Temp:", "hydro_temp", 22, 30, 0),
    ]:
        draw_text(c, ax, ry_a + 13, lbl, FONT_LABEL)
        text_field(c, nm, ax + label_w, ry_a + 2, field_w, HY_ROW - 4,
                   tooltip=lbl.rstrip(":"))
        ax += label_w + field_w + gap

    # Row B — inundation / saturation indicators
    # Split across three lines so labels can be set at 7 pt for legibility;
    # AWIDD-standard indicators occupy lines 1–2, additional site indicators
    # (saline / periglacial / stress) sit on line 3 below a thin divider.
    HY_ROW_B = 52
    ry_b = ry_a - HY_ROW_B
    cell_rect(c, MARGIN_L, ry_b, USABLE_W, HY_ROW_B, fill=colors.white)
    draw_text(c, MARGIN_L + 2, ry_b + 42, "Inundation / saturation indicators:", FONT_LABEL)

    # Line 1 — AWIDD indicators (1/2)
    ix = MARGIN_L + 138
    for lbl, nm, step in [
        ("Watermarks / drift lines", "watermarks",     200),
        ("Water-stained leaves",     "water_stained",  180),
        ("Oxidized rhizospheres",    "oxidized_rhizo",   0),
    ]:
        checkbox(c, f"ind_{nm}", ix, ry_b + 38, size=8, tooltip=lbl)
        draw_text(c, ix + 10, ry_b + 42, lbl, FONT_FIELD)
        ix += step

    # Line 2 — AWIDD indicators (2/2)
    ix = MARGIN_L + 138
    for lbl, nm, step in [
        ("Saturation ≤30 cm", "saturation",    170),
        ("Iron deposits",     "iron_deposits", 130),
        ("Algal mats",        "algal_mats",      0),
    ]:
        checkbox(c, f"ind_{nm}", ix, ry_b + 21, size=8, tooltip=lbl)
        draw_text(c, ix + 10, ry_b + 25, lbl, FONT_FIELD)
        ix += step

    # Thin divider separating AWIDD indicators from additional site indicators
    c.saveState()
    c.setStrokeColor(GRID_COLOR)
    c.setLineWidth(0.3)
    c.line(MARGIN_L + 2, ry_b + 17, MARGIN_L + USABLE_W, ry_b + 17)
    c.restoreState()

    # Line 3 — additional site indicators (saline / periglacial / stress)
    ix = MARGIN_L + 138
    for lbl, nm, step in [
        ("Salt crust",              "salt_crust",      90),
        ("Stunted/stressed plants", "stunted_plants", 140),
        ("Marl deposits",           "marl_deposits",  110),
        ("Surface soil cracks",     "soil_cracks",    140),
        ("Frost-heave hummocks",    "frost_hummocks",   0),
    ]:
        checkbox(c, f"ind_{nm}", ix, ry_b + 4, size=8, tooltip=lbl)
        draw_text(c, ix + 10, ry_b + 8, lbl, FONT_FIELD)
        ix += step

    # ── Remarks (combined hydrology notes + general remarks) ─────────────────
    rem_top = ry_b - 2
    rem_h   = 36
    cell_rect(c, MARGIN_L, rem_top - rem_h, USABLE_W, rem_h, fill=ROW_ALT)
    draw_text(c, MARGIN_L + 2, rem_top - 7, "Remarks:", FONT_LABEL)
    text_field(c, "remarks", MARGIN_L + 50, rem_top - rem_h + 2,
               USABLE_W - 52, rem_h - 4, tooltip="Remarks", multiline=True)

    c.save()
    print(f"Saved: {path}")


# ─────────────────────────────────────────────────────────────────────────────
# SOILS FORM
# ─────────────────────────────────────────────────────────────────────────────

def build_soils_form(path):
    c = canvas.Canvas(path, pagesize=landscape(letter))
    c.setTitle("Soils Field Form — Wetland Assessment")

    # Issue 4: added version identifier to subtitle
    page_title(c, "SOILS FIELD DATA FORM",
               "Alberta Wetland Assessment  ·  AWCS / AWIDD  ·  v1.1 (2025)")

    # ── Header helper — 26 pt cell matching veg/hydrology form style ────────────
    # Label in top half, text field in bottom half; they never overlap.
    def hdr_field_s(label, name, x, y_top, w):
        cell_rect(c, x, y_top - 26, w, 26, fill=HEADER_BG)
        draw_text(c, x + 2, y_top - 7, label, FONT_LABEL)
        text_field(c, name, x + 2, y_top - 25, w - 4, 13, tooltip=label)

    # ── Header row 1 ──────────────────────────────────────────────────────────
    R1 = H - 30   # top of row-1 cells (2 pt below title bar, same as veg form)
    x  = MARGIN_L
    for label, name, w in [
        ("Project ID", "s_project_id", 160),
        ("Site ID",    "s_site_id",    140),
        ("Plot ID",    "s_plot_id",    110),
        ("Observer",   "s_observer",   150),
    ]:
        hdr_field_s(label, name, x, R1, w)
        x += w + 4  # 4 pt gap preserved from original layout

    # Method — label at top of 26 pt cell, checkboxes in lower portion
    cell_rect(c, x, R1 - 26, 90, 26, fill=HEADER_BG)
    draw_text(c, x + 2, R1 - 7, "Method", FONT_LABEL)
    checkbox(c, "method_pit",   x + 4,  R1 - 21, size=9, tooltip="Pit")
    draw_text(c, x + 15, R1 - 17, "Pit",   FONT_TINY)
    checkbox(c, "method_probe", x + 42, R1 - 21, size=9, tooltip="Probe")
    draw_text(c, x + 53, R1 - 17, "Probe", FONT_TINY)
    x += 94  # 90 pt cell + 4 pt gap

    # Depth to restrictive layer — fills remainder of row 1
    hdr_field_s("Depth to Restr. Layer (cm)", "depth_restrict",
                x, R1, MARGIN_L + USABLE_W - x)

    # ── Header row 2 ──────────────────────────────────────────────────────────
    R2 = H - 60   # top of row-2 cells (4 pt below row-1 bottom, same as veg form)
    x  = MARGIN_L
    for label, name, cell_w, step in [
        ("Date (DD)",    "s_date_dd",    70, 74),
        ("MM",           "s_date_mm",    70, 74),
        ("YYYY",         "s_date_yyyy",  62, 66),
        ("GPS Easting",  "s_gps_e",     120, 124),
        ("GPS Northing", "s_gps_n",     120, 124),
        ("UTM Zone",     "s_utm_zone",   54, 58),
    ]:
        hdr_field_s(label, name, x, R2, cell_w)
        x += step  # step = cell_w + 4 pt gap (matches original x spacing)

    # Datum — label at top, checkboxes below
    cell_rect(c, x, R2 - 26, 90, 26, fill=HEADER_BG)
    draw_text(c, x + 2, R2 - 7, "Datum", FONT_LABEL)
    checkbox(c, "s_datum_nad83", x + 4,  R2 - 21, size=9, tooltip="NAD83")
    draw_text(c, x + 15, R2 - 17, "NAD83", FONT_TINY)
    checkbox(c, "s_datum_wgs84", x + 50, R2 - 21, size=9, tooltip="WGS84")
    draw_text(c, x + 61, R2 - 17, "WGS84", FONT_TINY)
    x += 94

    # AWCS class — fills remainder of row 2 (matches veg form pattern)
    hdr_field_s("AWCS Wetland Class (obs.)", "s_awcs_class_obs",
                x, R2, MARGIN_L + USABLE_W - x)

    # ── Column definitions ────────────────────────────────────────────────────
    # Total must equal USABLE_W = 756 pts.
    # History: Redox column removed (freed 90 pts → Texture +36, Structure +20,
    # Mottles +34); Material column removed (freed 72 pts → Coarse Frags +10
    # so "Coarse" fits at the larger header font, Notes +62 for transcribable room).
    # Peat/Muck/Min material is inferable from the horizon code and Von Post
    # score; record it in Notes if the field call differs from the obvious read.
    cols = [
        (MARGIN_L,       28,  "Horiz."),
        (MARGIN_L + 28,  28,  "Top\n(cm)"),
        (MARGIN_L + 56,  28,  "Bot.\n(cm)"),
        (MARGIN_L + 84,  34,  "Munsell\nHue"),
        (MARGIN_L + 118, 22,  "Val."),
        (MARGIN_L + 140, 22,  "Chr."),
        (MARGIN_L + 162, 144, "Texture"),        # 12 mineral classes
        (MARGIN_L + 306, 75,  "Structure"),       # PL BK SBK PR MA
        (MARGIN_L + 381, 26,  "Von\nPost"),
        (MARGIN_L + 407, 32,  "Coarse\nFrags"),
        (MARGIN_L + 439, 124, "Mottles"),         # Abund + Size + Contrast
        (MARGIN_L + 563, 193, "Notes"),
    ]

    chy = H - 90
    ROW_H = 22

    for cx, cw, clabel in cols:
        cell_rect(c, cx, chy - 22, cw, 22, fill=TITLE_BG)
        lines = clabel.split("\n")
        for li, line in enumerate(lines):
            draw_text(c, cx + cw / 2, chy - 9 - li * 9, line,
                      ("Helvetica-Bold", 8), colors.white, align="center")

    shy = chy - 22
    # Increased from 12 to 20 to fit two-row sub-header for Mottles/Redox
    sub_h = 20

    cell_rect(c, MARGIN_L, shy - sub_h, USABLE_W, sub_h)

    # Texture: 12 mineral classes (Muck/Peat removed — they belong in Material)
    tex_labels = ["S", "LS", "SL", "L", "SiL", "Si", "SCL", "CL", "SiCL", "SC", "SiC", "C"]
    tx0 = cols[6][0]
    tw = cols[6][1] / len(tex_labels)
    for i, lbl in enumerate(tex_labels):
        draw_text(c, tx0 + i * tw + tw / 2, shy - sub_h + 7, lbl,
                  ("Helvetica", 4), align="center")

    # Structure: 5 types (GR removed — gravel is not a structure type)
    str_labels = ["PL", "BK", "SBK", "PR", "MA"]
    sx0 = cols[7][0]
    sw = cols[7][1] / len(str_labels)
    for i, lbl in enumerate(str_labels):
        draw_text(c, sx0 + i * sw + sw / 2, shy - sub_h + 7, lbl,
                  ("Helvetica", 4), align="center")

    # Coarse Frags: Y / N  (Material column removed — index shifted from 10 to 9)
    cf_x, cf_w = cols[9][0], cols[9][1]
    draw_text(c, cf_x + cf_w * 0.25, shy - sub_h + 7, "Y", ("Helvetica", 4), align="center")
    draw_text(c, cf_x + cf_w * 0.75, shy - sub_h + 7, "N", ("Helvetica", 4), align="center")

    # Format hints in otherwise-blank sub-header cells
    _hint = ("Helvetica-Oblique", 4)
    _hint_col = colors.Color(0.55, 0.55, 0.55)
    for ci, hint in [(3, "10YR"), (4, "x/"), (5, "/y"), (8, "H1–H10")]:
        cx, cw, _ = cols[ci]
        draw_text(c, cx + cw / 2, shy - sub_h + 7, hint, _hint, _hint_col, align="center")

    # Mottles and Redox: two-row sub-header
    # Sub-column widths within each 90-pt column: 36 (abundance) + 27 (contrast) + 27 (colour)
    mot_abund_w = 49   # 4 abundance checkboxes
    mot_contr_w = 38   # 3 contrast checkboxes
    mot_size_w   = 38   # Munsell size checkboxes

    for ci in [10]:
        cx0 = cols[ci][0]
        cw0 = cols[ci][1]

        # Top row: group labels
        draw_text(c, cx0 + mot_abund_w / 2,                       shy - 5,
                  "Abundance", ("Helvetica", 3.5), align="center")
        draw_text(c, cx0 + mot_abund_w + mot_size_w / 2, shy - 5,
                  "Size", ("Helvetica", 3.5), align="center")
        draw_text(c, cx0 + mot_abund_w + mot_size_w + mot_contr_w / 2, shy - 5,
                  "Contrast",  ("Helvetica", 3.5), align="center")


        # Horizontal divider between group row and item row
        c.saveState()
        c.setStrokeColor(GRID_COLOR)
        c.setLineWidth(0.2)
        c.line(cx0, shy - 10, cx0 + cw0, shy - 10)
        # Vertical dividers between sub-columns
        c.setLineWidth(0.3)
        c.line(cx0 + mot_abund_w,              shy, cx0 + mot_abund_w,              shy - sub_h)
        c.line(cx0 + mot_abund_w + mot_size_w, shy, cx0 + mot_abund_w + mot_size_w, shy - sub_h)
        c.restoreState()

        # Bottom row: item labels
        for i, lbl in enumerate(["None", "Few", "Com", "Many"]):
            draw_text(c, cx0 + i * 9 + 4.5, shy - 15, lbl, ("Helvetica", 3.5), align="center")
        for i, lbl in enumerate(["F", "M", "C"]):
            draw_text(c, cx0 + mot_abund_w + i * 9 + 4.5, shy - 15, lbl,
                      ("Helvetica", 4), align="center")
        for i, lbl in enumerate(["F", "D", "P"]):
            draw_text(c, cx0 + mot_abund_w + mot_size_w + i * 9 + 4.5, shy - 15, lbl,
                        ("Helvetica", 4), align="center")

    # ── Data rows ─────────────────────────────────────────────────────────────
    N_ROWS = 15
    row_top = shy - sub_h

    for r in range(N_ROWS):
        ry = row_top - (r + 1) * ROW_H
        fill = ROW_ALT if r % 2 == 0 else colors.white
        cell_rect(c, MARGIN_L, ry, USABLE_W, ROW_H, fill=fill)

        rn = f"{r+1:02d}"

        # Text fields — standard columns (Material removed, Notes now at index 11)
        for ci, fname, tip in [
            (0,  f"horizon_{rn}",     "Horizon code"),
            (1,  f"depth_top_{rn}",   "Depth top (cm)"),
            (2,  f"depth_bot_{rn}",   "Depth bottom (cm)"),
            (3,  f"munsell_hue_{rn}", "Munsell Hue"),
            (4,  f"munsell_val_{rn}", "Munsell Value"),
            (5,  f"munsell_chr_{rn}", "Munsell Chroma"),
            (8,  f"von_post_{rn}",    "Von Post (H1-H10)"),
            (11, f"s_notes_{rn}",     "Notes"),
        ]:
            cx, cw, _ = cols[ci]
            text_field(c, fname, cx + 1, ry + 2, cw - 2, ROW_H - 4, tooltip=tip)

        # Texture checkboxes (12 mineral classes)
        tx0 = cols[6][0]
        tw = cols[6][1] / len(tex_labels)
        for i, lbl in enumerate(tex_labels):
            checkbox(c, f"tex_{lbl.lower()}_{rn}", tx0 + i * tw + 1, ry + 6,
                     size=9, tooltip=f"Texture {lbl}")

        # Structure checkboxes (5 types, no GR)
        sx0 = cols[7][0]
        sw = cols[7][1] / len(str_labels)
        for i, lbl in enumerate(str_labels):
            checkbox(c, f"str_{lbl.lower()}_{rn}", sx0 + i * sw + 1, ry + 6,
                     size=9, tooltip=f"Structure {lbl}")

        # Coarse Frags Y/N (replaces GR in Structure)
        checkbox(c, f"cf_y_{rn}", cf_x + 1,        ry + 6, size=9, tooltip="Coarse Fragments present")
        checkbox(c, f"cf_n_{rn}", cf_x + cf_w / 2, ry + 6, size=9, tooltip="Coarse Fragments absent")

        # Mottles: abundance (4) + size  + contrast (3) — index shifted from 11 to 10
        mot_x = cols[10][0]
        for i, lbl in enumerate(["none", "few", "common", "many"]):
            checkbox(c, f"mot_{lbl}_{rn}", mot_x + i * 9 + 1, ry + 6,
                     size=9, tooltip=f"Mottles {lbl}")
        for i, lbl in enumerate(["fine", "medium", "coarse"]):
            checkbox(c, f"mot_{lbl}_{rn}", mot_x + mot_abund_w + i * 9 + 1, ry + 6,
                     size=9, tooltip=f"Mottle size {lbl}")
        for i, lbl in enumerate(["faint", "distinct", "prominent"]):
            checkbox(c, f"mot_contr_{lbl}_{rn}", mot_x + mot_abund_w + mot_size_w + i * 9 + 1, ry + 6,
                     size=9, tooltip=f"Mottle contrast {lbl}")

    # ── Column group dividers spanning full data-row height ───────────────────
    data_bot = row_top - N_ROWS * ROW_H
    c.saveState()
    c.setStrokeColor(GRID_COLOR)
    c.setLineWidth(0.4)
    for cx, cw, _ in cols:
        c.line(cx, data_bot, cx, row_top)
    last_cx, last_cw, _ = cols[-1]
    c.line(last_cx + last_cw, data_bot, last_cx + last_cw, row_top)
    c.restoreState()

    # ── Hydric Soil Summary ───────────────────────────────────────────────────
    HS_BAR = 13
    HS_ROW = 16
    hs_top = row_top - N_ROWS * ROW_H - 4

    cell_rect(c, MARGIN_L, hs_top - HS_BAR, USABLE_W, HS_BAR, fill=TITLE_BG)
    draw_text(c, MARGIN_L + 4, hs_top - HS_BAR + 4, "HYDRIC SOIL SUMMARY",
              ("Helvetica-Bold", 7), colors.white)

    hs_ry = hs_top - HS_BAR - HS_ROW
    cell_rect(c, MARGIN_L, hs_ry, USABLE_W, HS_ROW, fill=HEADER_BG)
    draw_text(c, MARGIN_L + 2, hs_ry + 10, "Hydric Soil Indicators Present:", FONT_LABEL)
    checkbox(c, "hydric_ind_yes", MARGIN_L + 120, hs_ry + 3, size=9, tooltip="Yes")
    draw_text(c, MARGIN_L + 131, hs_ry + 7,  "Yes",      FONT_TINY)
    checkbox(c, "hydric_ind_no",  MARGIN_L + 148, hs_ry + 3, size=9, tooltip="No")
    draw_text(c, MARGIN_L + 159, hs_ry + 7,  "No",       FONT_TINY)
    draw_text(c, MARGIN_L + 182, hs_ry + 10, "Hydric Soil Criterion Met:", FONT_LABEL)
    checkbox(c, "hydric_met_yes",      MARGIN_L + 290, hs_ry + 3, size=9, tooltip="Yes")
    draw_text(c, MARGIN_L + 301, hs_ry + 7,  "Yes",      FONT_TINY)
    checkbox(c, "hydric_met_no",       MARGIN_L + 316, hs_ry + 3, size=9, tooltip="No")
    draw_text(c, MARGIN_L + 327, hs_ry + 7,  "No",       FONT_TINY)
    checkbox(c, "hydric_met_marginal", MARGIN_L + 340, hs_ry + 3, size=9, tooltip="Marginal")
    draw_text(c, MARGIN_L + 351, hs_ry + 7,  "Marginal", FONT_TINY)
    draw_text(c, MARGIN_L + 420, hs_ry + 10, "Soil Great Group (field assessment):", FONT_LABEL)
    text_field(c, "great_group", MARGIN_L + 560, hs_ry + 2, 188, 12, tooltip="Soil Great Group")

    # ── Additional Notes ──────────────────────────────────────────────────────
    AN_BAR   = 13
    AN_FIELD = 24
    an_top = hs_ry - 2

    cell_rect(c, MARGIN_L, an_top - AN_BAR, USABLE_W, AN_BAR, fill=TITLE_BG)
    draw_text(c, MARGIN_L + 4, an_top - AN_BAR + 4, "ADDITIONAL NOTES",
              ("Helvetica-Bold", 7), colors.white)

    an_ry = an_top - AN_BAR - AN_FIELD
    cell_rect(c, MARGIN_L, an_ry, USABLE_W, AN_FIELD, fill=ROW_ALT)
    text_field(c, "s_add_notes", MARGIN_L + 2, an_ry + 2,
               USABLE_W - 4, AN_FIELD - 4, tooltip="Additional Notes", multiline=True)

    # ── Physiogeography ───────────────────────────────────────────────────────
    PG_BAR = 13
    PG_ROW = 16
    pg_top = an_ry - 2

    cell_rect(c, MARGIN_L, pg_top - PG_BAR, USABLE_W, PG_BAR, fill=TITLE_BG)
    draw_text(c, MARGIN_L + 4, pg_top - PG_BAR + 4, "PHYSIOGEOGRAPHY",
              ("Helvetica-Bold", 7), colors.white)

    # Row 1 — Slope Position, Slope %, Aspect, Drainage
    pg_r1 = pg_top - PG_BAR - PG_ROW
    cell_rect(c, MARGIN_L, pg_r1, USABLE_W, PG_ROW, fill=HEADER_BG)
    draw_text(c, MARGIN_L + 2, pg_r1 + 10, "Slope Position:", FONT_LABEL)
    sp_x = MARGIN_L + 66
    for lbl, nm, step in [
        ("C",     "crest",       20),
        ("U",     "upper",       20),
        ("M",     "mid",         20),
        ("L",     "lower",       20),
        ("D",     "depression",  20),
        ("Level", "level",       36),
    ]:
        checkbox(c, f"slope_pos_{nm}", sp_x, pg_r1 + 4, size=8, tooltip=f"Slope Position {lbl}")
        draw_text(c, sp_x + 10, pg_r1 + 8, lbl, FONT_TINY)
        sp_x += step
    draw_text(c, sp_x + 4,   pg_r1 + 10, "Slope %:",   FONT_LABEL)
    text_field(c, "slope_pct",  sp_x + 34, pg_r1 + 2, 34, PG_ROW - 4, tooltip="Slope (%)")
    draw_text(c, sp_x + 76,  pg_r1 + 10, "Aspect (°):", FONT_LABEL)
    text_field(c, "aspect_deg", sp_x + 114, pg_r1 + 2, 36, PG_ROW - 4, tooltip="Aspect (degrees from N)")
    draw_text(c, sp_x + 160, pg_r1 + 10, "Drainage:", FONT_LABEL)
    dr_x = sp_x + 198
    for lbl, nm, step in [
        ("R",  "rapid",     18),
        ("W",  "well",      18),
        ("MW", "mod_well",  26),
        ("I",  "imperfect", 18),
        ("P",  "poor",      18),
        ("VP", "very_poor", 28),
    ]:
        checkbox(c, f"drainage_{nm}", dr_x, pg_r1 + 4, size=8, tooltip=f"Drainage {lbl}")
        draw_text(c, dr_x + 10, pg_r1 + 8, lbl, FONT_TINY)
        dr_x += step

    # Row 2 — Surface Stones, Surface Expression
    pg_r2 = pg_r1 - PG_ROW
    cell_rect(c, MARGIN_L, pg_r2, USABLE_W, PG_ROW, fill=colors.white)
    draw_text(c, MARGIN_L + 2, pg_r2 + 10, "Surface Stones:", FONT_LABEL)
    ss_x = MARGIN_L + 66
    for lbl, nm in [("S0","s0"),("S1","s1"),("S2","s2"),("S3","s3"),("S4","s4"),("S5","s5")]:
        checkbox(c, f"surf_stones_{nm}", ss_x, pg_r2 + 4, size=8, tooltip=f"Surface Stones {lbl}")
        draw_text(c, ss_x + 10, pg_r2 + 8, lbl, FONT_TINY)
        ss_x += 28
    draw_text(c, ss_x + 4, pg_r2 + 10, "Surface Expression:", FONT_LABEL)
    se_x = ss_x + 76
    for lbl in ["a","b","f","h","i","l","m","r","s","t","u","v"]:
        checkbox(c, f"surf_expr_{lbl}", se_x, pg_r2 + 4, size=8, tooltip=f"Surface Expression {lbl}")
        draw_text(c, se_x + 10, pg_r2 + 8, lbl, FONT_TINY)
        se_x += 20

    draw_text(c, MARGIN_L + 2, pg_r2 - 8,
              "Attach soil profile sketch on reverse side.",
              ("Helvetica-Oblique", 6.5), colors.HexColor("#555555"))

    c.save()
    print(f"Saved: {path}")


if __name__ == "__main__":
    veg_path   = os.path.join(OUT_DIR, "vegetation_hydrology_field_form.pdf")
    soils_path = os.path.join(OUT_DIR, "soils_field_form.pdf")
    build_veg_form(veg_path)
    build_soils_form(soils_path)
    print("Done.")
