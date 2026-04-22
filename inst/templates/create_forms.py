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
# VEGETATION FORM
# ─────────────────────────────────────────────────────────────────────────────

def build_veg_form(path):
    c = canvas.Canvas(path, pagesize=landscape(letter))
    c.setTitle("Vegetation Field Form — Wetland Assessment")

    page_title(c, "VEGETATION FIELD DATA FORM", "Alberta Wetland Assessment")

    # ── Header fields ─────────────────────────────────────────────────────────
    hy = H - 50
    header_fields = [
        ("Project ID",          "project_id",      120),
        ("Site ID",             "site_id",         100),
        ("Plot ID",             "plot_id",         70),
        ("Observer",            "observer",        110),
        ("Weather",             "weather",         90),
    ]
    x = MARGIN_L
    for label, name, w in header_fields:
        cell_rect(c, x, hy - 12, w + 40, 18, fill=HEADER_BG)
        draw_text(c, x + 2, hy - 5, label + ":", FONT_LABEL)
        text_field(c, name, x + 2, hy - 12, w + 36, 14, tooltip=label)
        x += w + 44

    # Date row
    hy2 = H - 74
    x = MARGIN_L
    date_items = [
        ("Date (DD)", "date_dd", 30),
        ("MM",        "date_mm", 30),
        ("YYYY",      "date_yyyy", 42),
    ]
    for label, name, w in date_items:
        cell_rect(c, x, hy2 - 12, w + 20, 18, fill=HEADER_BG)
        draw_text(c, x + 2, hy2 - 5, label + ":", FONT_LABEL)
        text_field(c, name, x + 2, hy2 - 12, w + 16, 14, tooltip=label)
        x += w + 24

    # GPS
    gps_items = [("GPS Easting", "gps_e", 80), ("GPS Northing", "gps_n", 80)]
    for label, name, w in gps_items:
        cell_rect(c, x, hy2 - 12, w + 40, 18, fill=HEADER_BG)
        draw_text(c, x + 2, hy2 - 5, label + ":", FONT_LABEL)
        text_field(c, name, x + 2, hy2 - 12, w + 36, 14, tooltip=label)
        x += w + 44

    # Datum checkboxes
    cell_rect(c, x, hy2 - 12, 80, 18, fill=HEADER_BG)
    draw_text(c, x + 2, hy2 - 5, "Datum:", FONT_LABEL)
    checkbox(c, "datum_nad83", x + 2, hy2 - 12, size=9, tooltip="NAD83")
    draw_text(c, x + 13, hy2 - 8, "NAD83", FONT_TINY)
    checkbox(c, "datum_wgs84", x + 40, hy2 - 12, size=9, tooltip="WGS84")
    draw_text(c, x + 51, hy2 - 8, "WGS84", FONT_TINY)
    x += 84

    # Dominant wetland class
    cell_rect(c, x, hy2 - 12, 140, 18, fill=HEADER_BG)
    draw_text(c, x + 2, hy2 - 5, "Dominant Wetland Class (obs.):", FONT_LABEL)
    text_field(c, "wetland_class_obs", x + 2, hy2 - 12, 136, 14, tooltip="Dominant Wetland Class Observed")

    # ── Column definitions ────────────────────────────────────────────────────
    # x_start, width, header label
    cols = [
        (MARGIN_L,       55,  "Species Code"),
        (MARGIN_L + 55,  90,  "Common Name"),
        (MARGIN_L + 145, 74,  "Stratum"),
        (MARGIN_L + 219, 60,  "Cover Class (BB)"),
        (MARGIN_L + 279, 22,  "N/E"),
        (MARGIN_L + 301, 106, "WI Status"),
        (MARGIN_L + 407, 22,  "Inv."),
        (MARGIN_L + 429, 22,  "Nox."),
        (MARGIN_L + 451, USABLE_W - 451, "Notes"),
    ]

    # Column headers
    chy = H - 90
    ROW_H = 16
    for cx, cw, clabel in cols:
        cell_rect(c, cx, chy - 14, cw, 14, fill=TITLE_BG)
        draw_text(c, cx + cw / 2, chy - 10, clabel,
                  ("Helvetica-Bold", 5.5), colors.white, align="center")

    # Sub-headers
    shy = chy - 14
    sub_h = 11

    # Stratum sub-labels
    sx = cols[2][0]
    for i, lbl in enumerate(["T", "S", "H", "G", "M"]):
        bx = sx + 2 + i * 14
        draw_text(c, bx + 4, shy - 7, lbl, FONT_TINY, align="center")

    # Cover class sub-labels
    cx0 = cols[3][0]
    for i, lbl in enumerate(["+", "1", "2", "3", "4", "5"]):
        bx = cx0 + 2 + i * 9
        draw_text(c, bx + 4, shy - 7, lbl, FONT_TINY, align="center")

    # N/E
    cx0 = cols[4][0]
    draw_text(c, cx0 + 2,  shy - 7, "N", FONT_TINY)
    draw_text(c, cx0 + 12, shy - 7, "E", FONT_TINY)

    # WI Status sub-labels
    cx0 = cols[5][0]
    for i, lbl in enumerate(["OBL", "FACW", "FAC", "FACU", "UPL", "NL"]):
        bx = cx0 + 1 + i * 17
        draw_text(c, bx + 4, shy - 7, lbl, ("Helvetica", 4.5), align="center")

    # Inv / Nox
    for ci in [6, 7]:
        cx0 = cols[ci][0]
        draw_text(c, cx0 + 1,  shy - 7, "Y", FONT_TINY)
        draw_text(c, cx0 + 11, shy - 7, "N", FONT_TINY)

    # Draw sub-header row border
    cell_rect(c, MARGIN_L, shy - sub_h, USABLE_W, sub_h)

    # ── Data rows ─────────────────────────────────────────────────────────────
    N_ROWS = 20
    row_top = shy - sub_h

    for r in range(N_ROWS):
        ry = row_top - (r + 1) * ROW_H
        fill = ROW_ALT if r % 2 == 0 else colors.white
        cell_rect(c, MARGIN_L, ry, USABLE_W, ROW_H, fill=fill)

        rn = f"{r+1:02d}"

        # Species code
        text_field(c, f"spp_code_{rn}", cols[0][0] + 1, ry + 2,
                   cols[0][1] - 2, ROW_H - 4, tooltip=f"Species Code row {r+1}")

        # Common name
        text_field(c, f"common_name_{rn}", cols[1][0] + 1, ry + 2,
                   cols[1][1] - 2, ROW_H - 4, tooltip=f"Common Name row {r+1}")

        # Stratum checkboxes T S H G M
        for i, lbl in enumerate(["T", "S", "H", "G", "M"]):
            bx = cols[2][0] + 2 + i * 14
            checkbox(c, f"stratum_{lbl}_{rn}", bx, ry + 3, size=9, tooltip=f"Stratum {lbl}")

        # Cover class + 1 2 3 4 5
        for i, lbl in enumerate(["plus", "1", "2", "3", "4", "5"]):
            bx = cols[3][0] + 1 + i * 9
            checkbox(c, f"cover_{lbl}_{rn}", bx, ry + 3, size=9, tooltip=f"Cover {lbl}")

        # Native/Exotic
        cx0 = cols[4][0]
        checkbox(c, f"native_{rn}", cx0 + 1,  ry + 3, size=9, tooltip="Native")
        checkbox(c, f"exotic_{rn}", cx0 + 11, ry + 3, size=9, tooltip="Exotic")

        # WI Status OBL FACW FAC FACU UPL NL
        cx0 = cols[5][0]
        for i, lbl in enumerate(["OBL", "FACW", "FAC", "FACU", "UPL", "NL"]):
            bx = cx0 + 1 + i * 17
            checkbox(c, f"wi_{lbl}_{rn}", bx, ry + 3, size=9, tooltip=f"WI Status {lbl}")

        # Invasive
        cx0 = cols[6][0]
        checkbox(c, f"inv_y_{rn}", cx0 + 1,  ry + 3, size=9, tooltip="Invasive Yes")
        checkbox(c, f"inv_n_{rn}", cx0 + 11, ry + 3, size=9, tooltip="Invasive No")

        # Noxious
        cx0 = cols[7][0]
        checkbox(c, f"nox_y_{rn}", cx0 + 1,  ry + 3, size=9, tooltip="Noxious Yes")
        checkbox(c, f"nox_n_{rn}", cx0 + 11, ry + 3, size=9, tooltip="Noxious No")

        # Notes
        text_field(c, f"notes_{rn}", cols[8][0] + 1, ry + 2,
                   cols[8][1] - 2, ROW_H - 4, tooltip=f"Notes row {r+1}")

    # ── Footer ────────────────────────────────────────────────────────────────
    fy = row_top - N_ROWS * ROW_H - 4
    footer_h = 44

    cell_rect(c, MARGIN_L, fy - footer_h, USABLE_W, footer_h, fill=HEADER_BG)
    draw_text(c, MARGIN_L + 2, fy - 9, "Total Species Count:", FONT_LABEL)
    text_field(c, "total_spp", MARGIN_L + 80, fy - 14, 40, 12, tooltip="Total Species Count")

    draw_text(c, MARGIN_L + 130, fy - 9, "Hydrophytic Vegetation Criterion Met:", FONT_LABEL)
    checkbox(c, "hydro_yes",      MARGIN_L + 270, fy - 14, size=9, tooltip="Yes")
    draw_text(c, MARGIN_L + 281, fy - 10, "Yes", FONT_TINY)
    checkbox(c, "hydro_no",       MARGIN_L + 300, fy - 14, size=9, tooltip="No")
    draw_text(c, MARGIN_L + 311, fy - 10, "No",  FONT_TINY)
    checkbox(c, "hydro_marginal", MARGIN_L + 324, fy - 14, size=9, tooltip="Marginal")
    draw_text(c, MARGIN_L + 335, fy - 10, "Marginal", FONT_TINY)

    draw_text(c, MARGIN_L + 2, fy - 22, "Additional Notes:", FONT_LABEL)
    text_field(c, "add_notes", MARGIN_L + 2, fy - footer_h + 2,
               USABLE_W - 4, 20, tooltip="Additional Notes", multiline=True)

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
    veg_path   = os.path.join(OUT_DIR, "vegetation_field_form.pdf")
    soils_path = os.path.join(OUT_DIR, "soils_field_form.pdf")
    build_veg_form(veg_path)
    build_soils_form(soils_path)
    print("Done.")
