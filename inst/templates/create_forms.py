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
    C_SPP  = (ML,        80)
    C_NAME = (ML +  80, 162)
    C_T    = (ML + 242,  18)
    C_S    = (ML + 260,  18)
    C_G    = (ML + 278,  18)
    C_M    = (ML + 296,  18)
    C_COV  = (ML + 314,  54)
    C_NE   = (ML + 368,  46)
    C_OBL  = (ML + 414,  18)
    C_FACW = (ML + 432,  20)
    C_FAC  = (ML + 452,  18)
    C_FACU = (ML + 470,  20)
    C_UPL  = (ML + 490,  18)
    C_NL   = (ML + 508,  16)
    C_INV  = (ML + 524,  26)
    C_NOX  = (ML + 550,  26)
    C_NOT  = (ML + 576, 180)

    # ── Main column header row ────────────────────────────────────────────────
    MAIN_H = 14
    SUB_H  = 12
    chy = H - 90

    def hdr_col(cx, cw, label):
        cell_rect(c, cx, chy - MAIN_H, cw, MAIN_H, fill=TITLE_BG)
        draw_text(c, cx + cw / 2, chy - MAIN_H + 4, label,
                  ("Helvetica-Bold", 5.5), colors.white, align="center")

    hdr_col(*C_SPP,  "Species Code")
    hdr_col(*C_NAME, "Scientific / Common Name")
    hdr_col(C_T[0], C_T[1]+C_S[1]+C_G[1]+C_M[1],
            "Stratum  (T=10m · S=5m · G=1×1m · M=1×1m)")
    hdr_col(*C_COV,  "% Cover")
    hdr_col(*C_NE,   "N / E")
    hdr_col(C_OBL[0], C_OBL[1]+C_FACW[1]+C_FAC[1]+C_FACU[1]+C_UPL[1]+C_NL[1],
            "WI Status")
    hdr_col(*C_INV,  "Inv.")
    hdr_col(*C_NOX,  "Nox.")
    hdr_col(*C_NOT,  "Notes")

    # ── Sub-header row ────────────────────────────────────────────────────────
    shy = chy - MAIN_H
    cell_rect(c, MARGIN_L, shy - SUB_H, USABLE_W, SUB_H)

    def sub(cx, cw, label):
        draw_text(c, cx + cw / 2, shy - SUB_H + 3, label,
                  ("Helvetica", 4.5), align="center")

    sub(*C_T,    "T")
    sub(*C_S,    "S")
    sub(*C_G,    "G")
    sub(*C_M,    "M")
    sub(C_NE[0],      23, "N")
    sub(C_NE[0] + 23, 23, "E")
    sub(*C_OBL,  "OBL")
    sub(*C_FACW, "FACW")
    sub(*C_FAC,  "FAC")
    sub(*C_FACU, "FACU")
    sub(*C_UPL,  "UPL")
    sub(*C_NL,   "NL")
    sub(C_INV[0],      13, "Y")
    sub(C_INV[0] + 13, 13, "N")
    sub(C_NOX[0],      13, "Y")
    sub(C_NOX[0] + 13, 13, "N")

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

        for col, lbl in [(C_T, "T"), (C_S, "S"), (C_G, "G"), (C_M, "M")]:
            checkbox(c, f"strat_{lbl}_{rn}", col[0] + 4, ry + 4,
                     size=9, tooltip=f"Stratum {lbl} row {r+1}")

        text_field(c, f"pct_cover_{rn}", C_COV[0] + 1, ry + 2,
                   C_COV[1] - 2, ROW_H - 4, tooltip=f"% Cover row {r+1}")

        checkbox(c, f"native_{rn}", C_NE[0] + 4,  ry + 4, size=9, tooltip="Native")
        checkbox(c, f"exotic_{rn}", C_NE[0] + 27, ry + 4, size=9, tooltip="Exotic")

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
        checkbox(c, f"nox_y_{rn}", C_NOX[0] + 4,  ry + 4, size=9, tooltip="Noxious Yes")
        checkbox(c, f"nox_n_{rn}", C_NOX[0] + 17, ry + 4, size=9, tooltip="Noxious No")

        text_field(c, f"notes_{rn}", C_NOT[0] + 1, ry + 2,
                   C_NOT[1] - 2, ROW_H - 4, tooltip=f"Notes row {r+1}")

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
    draw_text(c, MARGIN_L + 2, vs_a + 10, "Species Count by WI Status:", FONT_LABEL)
    wx = MARGIN_L + 112
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

    # Row B — AWIDD dominance test
    vs_b = vs_a - VS_ROW
    cell_rect(c, MARGIN_L, vs_b, USABLE_W, VS_ROW, fill=colors.white)
    draw_text(c, MARGIN_L + 2, vs_b + 10,
              "Dominance Test (AWIDD §50/20 rule):  OBL+FACW+FAC dominant spp:",
              FONT_LABEL)
    text_field(c, "dom_obl_facw_fac", MARGIN_L + 240, vs_b + 2, 24, VS_ROW - 5,
               tooltip="Count of OBL+FACW+FAC dominant species")
    draw_text(c, MARGIN_L + 268, vs_b + 10, "of", FONT_LABEL)
    text_field(c, "dom_total_spp", MARGIN_L + 280, vs_b + 2, 24, VS_ROW - 5,
               tooltip="Total dominant species counted")
    draw_text(c, MARGIN_L + 308, vs_b + 10, "dominant   Criterion:", FONT_LABEL)
    checkbox(c, "dom_met",      MARGIN_L + 382, vs_b + 4, size=9, tooltip="Met")
    draw_text(c, MARGIN_L + 393, vs_b + 8, "Met", FONT_TINY)
    checkbox(c, "dom_not_met",  MARGIN_L + 410, vs_b + 4, size=9, tooltip="Not Met")
    draw_text(c, MARGIN_L + 421, vs_b + 8, "Not met", FONT_TINY)
    checkbox(c, "dom_marginal", MARGIN_L + 452, vs_b + 4, size=9, tooltip="Marginal")
    draw_text(c, MARGIN_L + 463, vs_b + 8, "Marginal", FONT_TINY)
    draw_text(c, MARGIN_L + 506, vs_b + 10,
              "(see AWIDD s.4.3 for FAC-neutral test if marginal)", FONT_TINY,
              colors.HexColor("#555555"))

    # ── Ecosite Classification ────────────────────────────────────────────────
    ECO_BAR = 13
    ECO_HDR = 12
    ECO_ROW = 16
    eco_top = vs_b - 2

    cell_rect(c, MARGIN_L, eco_top - ECO_BAR, USABLE_W, ECO_BAR, fill=TITLE_BG)
    draw_text(c, MARGIN_L + 4, eco_top - ECO_BAR + 4,
              "ECOSITE CLASSIFICATION  (Field Guide to Ecosite Classification of Northern Alberta)",
              ("Helvetica-Bold", 7), colors.white)

    ECO_COLS = [
        (0,   70,  "Ecosite"),
        (70,  110, "Nutrient / Moisture\nRegime"),
        (180, 110, "Tree Species\nModifier"),
        (290, 120, "Structural\nStage (1–7)"),
        (410, 130, "Wetland Indicator\nRegion"),
        (540, 216, "Notes"),
    ]

    eco_hdr_y = eco_top - ECO_BAR
    cell_rect(c, MARGIN_L, eco_hdr_y - ECO_HDR, USABLE_W, ECO_HDR, fill=TITLE_BG)
    for ox, cw, clabel in ECO_COLS:
        cx = MARGIN_L + ox
        lines = clabel.split("\n")
        if len(lines) == 2:
            draw_text(c, cx + cw / 2, eco_hdr_y - 4, lines[0],
                      ("Helvetica-Bold", 4.5), colors.white, align="center")
            draw_text(c, cx + cw / 2, eco_hdr_y - 9, lines[1],
                      ("Helvetica-Bold", 4.5), colors.white, align="center")
        else:
            draw_text(c, cx + cw / 2, eco_hdr_y - ECO_HDR + 4, clabel,
                      ("Helvetica-Bold", 4.5), colors.white, align="center")
        if ox > 0:
            c.saveState()
            c.setStrokeColor(GRID_COLOR)
            c.setLineWidth(0.3)
            c.line(cx, eco_hdr_y - ECO_HDR, cx, eco_top - ECO_BAR)
            c.restoreState()

    # Single data row
    eco_row_top = eco_hdr_y - ECO_HDR
    ery = eco_row_top - ECO_ROW
    cell_rect(c, MARGIN_L, ery, USABLE_W, ECO_ROW, fill=ROW_ALT)

    text_field(c, "ecosite_01",   MARGIN_L +   1, ery + 2,  68, ECO_ROW - 4,
               tooltip="Ecosite code (e.g. d1, w2b)")
    text_field(c, "nm_regime_01", MARGIN_L +  71, ery + 2, 108, ECO_ROW - 4,
               tooltip="Nutrient/Moisture Regime (e.g. C3, D5)")
    text_field(c, "tree_mod_01",  MARGIN_L + 181, ery + 2, 108, ECO_ROW - 4,
               tooltip="Tree Species Modifier (e.g. Aw, Sw, Pl)")

    sx = MARGIN_L + 291
    for stage in range(1, 8):
        checkbox(c, f"stage_{stage}_01", sx, ery + 4, size=8,
                 tooltip=f"Structural Stage {stage}")
        draw_text(c, sx + 9, ery + 9, str(stage), FONT_TINY)
        sx += 17

    rx = MARGIN_L + 411
    for lbl, nm, step in [
        ("AK",   "wi_reg_ak_01",   28),
        ("WMVC", "wi_reg_wmvc_01", 36),
        ("GP",   "wi_reg_gp_01",   26),
        ("NCNE", "wi_reg_ncne_01", 36),
    ]:
        checkbox(c, nm, rx, ery + 4, size=8, tooltip=f"WI Region {lbl}")
        draw_text(c, rx + 9, ery + 9, lbl, FONT_TINY)
        rx += step

    text_field(c, "eco_notes_01", MARGIN_L + 541, ery + 2, 213, ECO_ROW - 4,
               tooltip="Ecosite notes")

    # ── Hydrology Section ─────────────────────────────────────────────────────
    HY_BAR = 13
    HY_ROW = 16
    hy_top = ery - 2

    cell_rect(c, MARGIN_L, hy_top - HY_BAR, USABLE_W, HY_BAR, fill=TITLE_BG)
    draw_text(c, MARGIN_L + 4, hy_top - HY_BAR + 4, "HYDROLOGY",
              ("Helvetica-Bold", 7), colors.white)

    # Row A — water presence, depth, outlet
    ry_a = hy_top - HY_BAR - HY_ROW
    cell_rect(c, MARGIN_L, ry_a, USABLE_W, HY_ROW, fill=HEADER_BG)
    draw_text(c, MARGIN_L + 2, ry_a + 10, "Water at surface at time of survey:", FONT_LABEL)
    checkbox(c, "hydro_water_y", MARGIN_L + 140, ry_a + 4, size=8, tooltip="Water present Yes")
    draw_text(c, MARGIN_L + 150, ry_a + 8, "Y", FONT_TINY)
    checkbox(c, "hydro_water_n", MARGIN_L + 162, ry_a + 4, size=8, tooltip="Water present No")
    draw_text(c, MARGIN_L + 172, ry_a + 8, "N", FONT_TINY)
    draw_text(c, MARGIN_L + 186, ry_a + 10, "Water depth (cm):", FONT_LABEL)
    text_field(c, "hydro_depth_cm", MARGIN_L + 244, ry_a + 2, 34, HY_ROW - 4,
               tooltip="Water depth (cm)")
    draw_text(c, MARGIN_L + 284, ry_a + 10, "Outlet:", FONT_LABEL)
    ox = MARGIN_L + 308
    for lbl, nm, step in [
        ("None",       "none",       34),
        ("Surface",    "surface",    46),
        ("Subsurface", "subsurface", 58),
        ("Both",       "both",       34),
    ]:
        checkbox(c, f"outlet_{nm}", ox, ry_a + 4, size=8, tooltip=f"Outlet {lbl}")
        draw_text(c, ox + 10, ry_a + 8, lbl, FONT_TINY)
        ox += step

    # Row B — inundation / saturation indicators, two lines (merged from former Row B2)
    HY_ROW_B = 28
    ry_b = ry_a - HY_ROW_B
    cell_rect(c, MARGIN_L, ry_b, USABLE_W, HY_ROW_B, fill=colors.white)
    draw_text(c, MARGIN_L + 2, ry_b + 22, "Inundation / saturation indicators:", FONT_LABEL)
    # Line 1: standard AWIDD inundation/saturation indicators
    ix = MARGIN_L + 138
    for lbl, nm, step in [
        ("Watermarks / drift lines", "watermarks",    118),
        ("Water-stained leaves",     "water_stained",  94),
        ("Oxidized rhizospheres",    "oxidized_rhizo", 90),
        ("Saturation ≤30 cm",        "saturation",     72),
        ("Iron deposits",            "iron_deposits",  62),
        ("Algal mats",               "algal_mats",     50),
    ]:
        checkbox(c, f"ind_{nm}", ix, ry_b + 17, size=8, tooltip=lbl)
        draw_text(c, ix + 10, ry_b + 21, lbl, FONT_TINY)
        ix += step
    # Thin divider separating the two indicator lines
    c.saveState()
    c.setStrokeColor(GRID_COLOR)
    c.setLineWidth(0.3)
    c.line(MARGIN_L + 2, ry_b + 14, MARGIN_L + USABLE_W, ry_b + 14)
    c.restoreState()
    # Line 2: additional site indicators (saline / periglacial / stress)
    ix = MARGIN_L + 138
    for lbl, nm, step in [
        ("Salt crust",              "salt_crust",     72),
        ("Stunted/stressed plants", "stunted_plants", 106),
        ("Marl deposits",           "marl_deposits",   78),
        ("Surface soil cracks",     "soil_cracks",     90),
        ("Frost-heave hummocks",    "frost_hummocks",  88),
    ]:
        checkbox(c, f"ind_{nm}", ix, ry_b + 4, size=8, tooltip=lbl)
        draw_text(c, ix + 10, ry_b + 8, lbl, FONT_TINY)
        ix += step

    # Row C — water permanence class
    ry_c = ry_b - HY_ROW
    cell_rect(c, MARGIN_L, ry_c, USABLE_W, HY_ROW, fill=colors.white)
    draw_text(c, MARGIN_L + 2, ry_c + 10, "Permanence class (GWPWB):", FONT_LABEL)
    px = MARGIN_L + 114
    for lbl, nm, step in [
        ("Ephemeral (<2 mo)",      "ephemeral",   120),
        ("Intermittent (2–5 mo)",  "intermittent", 116),
        ("Semi-permanent (>5 mo)", "semi_perm",   128),
        ("Permanent (year-round)", "permanent",   122),
    ]:
        checkbox(c, f"perm_{nm}", px, ry_c + 4, size=8, tooltip=lbl)
        draw_text(c, px + 10, ry_c + 8, lbl, FONT_TINY)
        px += step

    # ── Remarks (combined hydrology notes + general remarks) ─────────────────
    rem_top = ry_c - 2
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

    page_title(c, "SOILS FIELD DATA FORM", "Alberta Wetland Assessment")

    # ── Header ────────────────────────────────────────────────────────────────
    hy = H - 50
    header1 = [
        ("Project ID", "s_project_id", 120),
        ("Site ID",    "s_site_id",    100),
        ("Plot ID",    "s_plot_id",     70),
        ("Observer",   "s_observer",   110),
    ]
    x = MARGIN_L
    for label, name, w in header1:
        cell_rect(c, x, hy - 12, w + 40, 18, fill=HEADER_BG)
        draw_text(c, x + 2, hy - 5, label + ":", FONT_LABEL)
        text_field(c, name, x + 2, hy - 12, w + 36, 14, tooltip=label)
        x += w + 44

    # Pit/Probe checkboxes
    cell_rect(c, x, hy - 12, 70, 18, fill=HEADER_BG)
    draw_text(c, x + 2, hy - 5, "Method:", FONT_LABEL)
    checkbox(c, "method_pit",   x + 2,  hy - 12, size=9, tooltip="Pit")
    draw_text(c, x + 13, hy - 8, "Pit",   FONT_TINY)
    checkbox(c, "method_probe", x + 36, hy - 12, size=9, tooltip="Probe")
    draw_text(c, x + 47, hy - 8, "Probe", FONT_TINY)
    x += 74

    # Depth to restrictive layer
    cell_rect(c, x, hy - 12, 100, 18, fill=HEADER_BG)
    draw_text(c, x + 2, hy - 5, "Depth to Restrict. Layer (cm):", FONT_LABEL)
    text_field(c, "depth_restrict", x + 2, hy - 12, 96, 14, tooltip="Depth to Restrictive Layer (cm)")

    # Row 2 of header
    hy2 = H - 74
    x = MARGIN_L
    date_items = [("Date (DD)", "s_date_dd", 30), ("MM", "s_date_mm", 30), ("YYYY", "s_date_yyyy", 42)]
    for label, name, w in date_items:
        cell_rect(c, x, hy2 - 12, w + 20, 18, fill=HEADER_BG)
        draw_text(c, x + 2, hy2 - 5, label + ":", FONT_LABEL)
        text_field(c, name, x + 2, hy2 - 12, w + 16, 14, tooltip=label)
        x += w + 24

    gps_items = [("GPS Easting", "s_gps_e", 80), ("GPS Northing", "s_gps_n", 80)]
    for label, name, w in gps_items:
        cell_rect(c, x, hy2 - 12, w + 40, 18, fill=HEADER_BG)
        draw_text(c, x + 2, hy2 - 5, label + ":", FONT_LABEL)
        text_field(c, name, x + 2, hy2 - 12, w + 36, 14, tooltip=label)
        x += w + 44

    # ── Column definitions ────────────────────────────────────────────────────
    # Each row represents one soil horizon
    # Columns must fit within USABLE_W (~756 pts)
    cols = [
        (MARGIN_L,       28,  "Horiz."),
        (MARGIN_L + 28,  28,  "Top\n(cm)"),
        (MARGIN_L + 56,  28,  "Bot.\n(cm)"),
        (MARGIN_L + 84,  34,  "Munsell\nHue"),
        (MARGIN_L + 118, 22,  "Val."),
        (MARGIN_L + 140, 22,  "Chr."),
        (MARGIN_L + 162, 132, "Texture"),
        (MARGIN_L + 294, 66,  "Structure"),
        (MARGIN_L + 360, 26,  "Von\nPost"),
        (MARGIN_L + 386, 72,  "Material"),
        (MARGIN_L + 458, 60,  "Mottles"),
        (MARGIN_L + 518, 60,  "Redox"),
        (MARGIN_L + 578, USABLE_W - 578, "Notes"),
    ]

    chy = H - 90
    ROW_H = 18

    for cx, cw, clabel in cols:
        cell_rect(c, cx, chy - 22, cw, 22, fill=TITLE_BG)
        lines = clabel.split("\n")
        for li, line in enumerate(lines):
            draw_text(c, cx + cw / 2, chy - 9 - li * 8, line,
                      ("Helvetica-Bold", 5), colors.white, align="center")

    # Sub-header labels
    shy = chy - 22
    sub_h = 12

    # Texture sub-labels  S LS SL L SiL Si SCL CL SiCL SC SiC C Muck Peat
    tex_labels = ["S", "LS", "SL", "L", "SiL", "Si", "SCL", "CL", "SiCL", "SC", "SiC", "C", "Muck", "Peat"]
    tx0 = cols[6][0]
    tw = cols[6][1] / len(tex_labels)
    for i, lbl in enumerate(tex_labels):
        draw_text(c, tx0 + i * tw + tw / 2, shy - 8, lbl, ("Helvetica", 4), align="center")

    # Structure sub-labels GR PL BK SBK PR MA
    str_labels = ["GR", "PL", "BK", "SBK", "PR", "MA"]
    sx0 = cols[7][0]
    sw = cols[7][1] / len(str_labels)
    for i, lbl in enumerate(str_labels):
        draw_text(c, sx0 + i * sw + sw / 2, shy - 8, lbl, ("Helvetica", 4), align="center")

    # Material  Min Peat Muck Marl
    mat_labels = ["Min", "Peat", "Muck", "Marl"]
    mx0 = cols[9][0]
    mw = cols[9][1] / len(mat_labels)
    for i, lbl in enumerate(mat_labels):
        draw_text(c, mx0 + i * mw + mw / 2, shy - 8, lbl, ("Helvetica", 4), align="center")

    # Mottles / Redox  None Few Com Many
    for ci in [10, 11]:
        cx0 = cols[ci][0]
        cw0 = cols[ci][1]
        for i, lbl in enumerate(["None", "Few", "Com", "Many"]):
            draw_text(c, cx0 + i * cw0 / 4 + cw0 / 8, shy - 8, lbl, ("Helvetica", 4), align="center")

    cell_rect(c, MARGIN_L, shy - sub_h, USABLE_W, sub_h)

    # ── Data rows ─────────────────────────────────────────────────────────────
    N_ROWS = 12
    row_top = shy - sub_h

    for r in range(N_ROWS):
        ry = row_top - (r + 1) * ROW_H
        fill = ROW_ALT if r % 2 == 0 else colors.white
        cell_rect(c, MARGIN_L, ry, USABLE_W, ROW_H, fill=fill)

        rn = f"{r+1:02d}"

        # Text fields
        for ci, fname, tip in [
            (0, f"horizon_{rn}",   "Horizon code"),
            (1, f"depth_top_{rn}", "Depth top (cm)"),
            (2, f"depth_bot_{rn}", "Depth bottom (cm)"),
            (3, f"munsell_hue_{rn}", "Munsell Hue"),
            (4, f"munsell_val_{rn}", "Munsell Value"),
            (5, f"munsell_chr_{rn}", "Munsell Chroma"),
            (8, f"von_post_{rn}",    "Von Post (H1-H10)"),
            (12, f"s_notes_{rn}",   "Notes"),
        ]:
            cx, cw, _ = cols[ci]
            text_field(c, fname, cx + 1, ry + 2, cw - 2, ROW_H - 4, tooltip=tip)

        # Texture checkboxes
        tx0 = cols[6][0]
        tw = cols[6][1] / len(tex_labels)
        for i, lbl in enumerate(tex_labels):
            checkbox(c, f"tex_{lbl.lower()}_{rn}", tx0 + i * tw + 1, ry + 4, size=9, tooltip=f"Texture {lbl}")

        # Structure checkboxes
        sx0 = cols[7][0]
        sw = cols[7][1] / len(str_labels)
        for i, lbl in enumerate(str_labels):
            checkbox(c, f"str_{lbl.lower()}_{rn}", sx0 + i * sw + 1, ry + 4, size=9, tooltip=f"Structure {lbl}")

        # Material checkboxes
        mx0 = cols[9][0]
        mw = cols[9][1] / len(mat_labels)
        for i, lbl in enumerate(mat_labels):
            checkbox(c, f"mat_{lbl.lower()}_{rn}", mx0 + i * mw + 1, ry + 4, size=9, tooltip=f"Material {lbl}")

        # Mottles checkboxes
        cx0, cw0 = cols[10][0], cols[10][1]
        for i, lbl in enumerate(["none", "few", "common", "many"]):
            checkbox(c, f"mot_{lbl}_{rn}", cx0 + i * cw0 / 4 + 1, ry + 4, size=9, tooltip=f"Mottles {lbl}")

        # Redox checkboxes
        cx0, cw0 = cols[11][0], cols[11][1]
        for i, lbl in enumerate(["none", "few", "common", "many"]):
            checkbox(c, f"rdx_{lbl}_{rn}", cx0 + i * cw0 / 4 + 1, ry + 4, size=9, tooltip=f"Redox {lbl}")

    # ── Footer ────────────────────────────────────────────────────────────────
    fy = row_top - N_ROWS * ROW_H - 4
    footer_h = 52

    cell_rect(c, MARGIN_L, fy - footer_h, USABLE_W, footer_h, fill=HEADER_BG)

    draw_text(c, MARGIN_L + 2, fy - 9, "Hydric Soil Indicators Present:", FONT_LABEL)
    checkbox(c, "hydric_ind_yes", MARGIN_L + 120, fy - 14, size=9, tooltip="Yes")
    draw_text(c, MARGIN_L + 131, fy - 10, "Yes", FONT_TINY)
    checkbox(c, "hydric_ind_no",  MARGIN_L + 148, fy - 14, size=9, tooltip="No")
    draw_text(c, MARGIN_L + 159, fy - 10, "No", FONT_TINY)

    draw_text(c, MARGIN_L + 182, fy - 9, "Hydric Soil Criterion Met:", FONT_LABEL)
    checkbox(c, "hydric_met_yes",      MARGIN_L + 290, fy - 14, size=9, tooltip="Yes")
    draw_text(c, MARGIN_L + 301, fy - 10, "Yes", FONT_TINY)
    checkbox(c, "hydric_met_no",       MARGIN_L + 316, fy - 14, size=9, tooltip="No")
    draw_text(c, MARGIN_L + 327, fy - 10, "No", FONT_TINY)
    checkbox(c, "hydric_met_marginal", MARGIN_L + 340, fy - 14, size=9, tooltip="Marginal")
    draw_text(c, MARGIN_L + 351, fy - 10, "Marginal", FONT_TINY)

    draw_text(c, MARGIN_L + 420, fy - 9, "Soil Great Group (field assessment):", FONT_LABEL)
    text_field(c, "great_group", MARGIN_L + 560, fy - 14, 188, 12, tooltip="Soil Great Group")

    draw_text(c, MARGIN_L + 2, fy - 22, "Additional Notes:", FONT_LABEL)
    text_field(c, "s_add_notes", MARGIN_L + 2, fy - footer_h + 14,
               USABLE_W - 4, 18, tooltip="Additional Notes", multiline=True)

    draw_text(c, MARGIN_L + 2, fy - footer_h + 10,
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
