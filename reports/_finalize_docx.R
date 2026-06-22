# Post-render docx finalizer for the peat report. Run on the rendered .docx by
# run_report.R. Two OOXML touch-ups Quarto/Pandoc can't express directly:
#
#  1. Clean figures. Quarto wraps each cross-referenceable (#fig-) figure in a
#     single-cell table so the image stays with its numbered caption. Those
#     wrapper tables inherit the banded "Table" style, putting a green band
#     behind figures. We strip the table style from any table that contains an
#     image, so banding stays on the real data tables only.
#
#  2. Landscape appendices. Appendix A (wide cross-section figures) and
#     Appendix B (the wide per-hole field table) are switched to landscape with
#     narrow margins to maximise space. We clone the document's real final
#     section properties (which carry the header/footer references — logo and
#     page numbers) and only change orientation/margins, so the branding is
#     preserved across sections.
#
# The leading underscore keeps Quarto from treating this as a renderable input.

library(xml2)

finalize_report_docx <- function(path,
                                 landscape_from = "Appendix A",
                                 landscape_to   = "Appendix C",
                                 cover = NULL,
                                 cover_source = NULL) {
  W <- "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  R <- "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  nsdecl <- sprintf('xmlns:w="%s" xmlns:r="%s"', W, R)

  path <- normalizePath(path, mustWork = TRUE)   # absolute: we setwd() before re-zipping
  tmp <- file.path(tempdir(), paste0("docx_", as.integer(runif(1, 1, 1e9))))
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  utils::unzip(path, exdir = tmp)
  doc_path <- file.path(tmp, "word", "document.xml")
  doc <- read_xml(doc_path)
  ns  <- xml_ns(doc)

  ## 1. Strip the table style from figure-wrapper and signature tables ---------
  # Figures: the single-cell wrapper tables inherit the banded style. Signature
  # block: the closure "Report prepared by" table should be plain, not banded.
  n_fig <- 0
  for (tbl in xml_find_all(doc, ".//w:tbl", ns)) {
    is_fig <- length(xml_find_all(tbl, ".//w:drawing", ns)) > 0
    is_sig <- grepl("Report prepared by",
                    paste(xml_text(xml_find_all(tbl, ".//w:t", ns)), collapse = " "))
    if (is_fig || is_sig) {
      sty <- xml_find_first(tbl, "./w:tblPr/w:tblStyle", ns)
      if (!is.na(sty)) { xml_remove(sty); n_fig <- n_fig + 1 }
    }
  }

  ## 1b. Retarget table captions so the List of Tables can find them -----------
  # Pandoc styles every caption "Image Caption", so the List of Tables (which
  # collects "Table Caption") comes up empty and tables leak into the List of
  # Figures. Relabel the "Table N:" captions to the Table Caption style.
  n_cap <- 0
  for (p in xml_find_all(doc, ".//w:p", ns)) {
    sty <- xml_find_first(p, "./w:pPr/w:pStyle", ns)
    if (!is.na(sty) && identical(xml_attr(sty, "val"), "ImageCaption")) {
      txt <- paste(xml_text(xml_find_all(p, ".//w:t", ns)), collapse = "")
      if (startsWith(txt, "Table")) {   # caption-styled paras only; safe prefix
        xml_set_attr(sty, "w:val", "TableCaption"); n_cap <- n_cap + 1
      }
    }
  }

  ## 1c. Keep each figure image with its caption ------------------------------
  # The cross-section figures are plain image paragraphs (not in a table); add
  # keepNext so the image and its following caption are not split across a page.
  for (p in xml_find_all(doc, ".//w:p[.//w:drawing]", ns)) {
    if (!is.na(xml_find_first(p, "ancestor::w:tbl", ns))) next   # skip in-table figs
    ppr <- xml_find_first(p, "./w:pPr", ns)
    if (is.na(ppr)) ppr <- xml_add_child(p, read_xml(sprintf('<w:pPr %s/>', nsdecl)), .where = 0)
    if (is.na(xml_find_first(ppr, "./w:keepNext", ns)))
      xml_add_child(ppr, read_xml(sprintf('<w:keepNext %s/>', nsdecl)), .where = 0)
  }

  ## 1d. Column widths for the per-hole field table (landscape) ----------------
  # Give pH a usable width (values fit on one line) and let the long bryophyte
  # names wrap, by switching the table to a fixed layout with explicit widths
  # keyed on the header text (robust to column reordering).
  col_w <- c("Test Hole" = 1000, "Wetland Class" = 1500, "Dominant Bryophyte" = 2500,
             "Depth to Mineral" = 1500, "Depth to Water Table" = 1700, "pH" = 900,
             "EC" = 1300, "Professional" = 2000, "Retail" = 1900)
  width_for <- function(h) {
    hit <- which(vapply(names(col_w), function(k) startsWith(h, k), logical(1)))
    if (length(hit)) col_w[[hit[1]]] else 1400L
  }
  set_tblW <- function(tt, w) {   # set a table's overall width
    tp <- xml_find_first(tt, "./w:tblPr", ns)
    old <- xml_find_first(tp, "./w:tblW", ns); if (!is.na(old)) xml_remove(old)
    xml_add_child(tp, read_xml(sprintf('<w:tblW %s w:w="%d" w:type="dxa"/>', nsdecl, as.integer(w))))
    ol <- xml_find_first(tp, "./w:tblLayout", ns); if (!is.na(ol)) xml_remove(ol)
    xml_add_child(tp, read_xml(sprintf('<w:tblLayout %s w:type="fixed"/>', nsdecl)))
  }
  set_grid <- function(tt, widths) {   # replace a table's grid columns
    g <- xml_find_first(tt, "./w:tblGrid", ns)
    repeat { gc <- xml_find_first(g, "./w:gridCol", ns); if (is.na(gc)) break; xml_remove(gc) }
    for (w in widths) xml_add_child(g, read_xml(sprintf('<w:gridCol %s w:w="%d"/>', nsdecl, as.integer(w))))
  }
  set_cells <- function(rows, widths) {   # set per-cell widths row by row
    for (r in rows) {
      cells <- xml_find_all(r, "./w:tc", ns)
      for (j in seq_along(cells)) {
        tcpr <- xml_find_first(cells[[j]], "./w:tcPr", ns)
        if (is.na(tcpr)) tcpr <- xml_add_child(cells[[j]], read_xml(sprintf('<w:tcPr %s/>', nsdecl)), .where = 0)
        tcw <- xml_find_first(tcpr, "./w:tcW", ns); if (!is.na(tcw)) xml_remove(tcw)
        xml_add_child(tcpr, read_xml(sprintf('<w:tcW %s w:w="%d" w:type="dxa"/>',
                                             nsdecl, as.integer(widths[min(j, length(widths))]))), .where = 0)
      }
    }
  }
  for (tbl in xml_find_all(doc, ".//w:tbl", ns)) {
    rows <- xml_find_all(tbl, "./w:tr", ns)
    if (!length(rows)) next
    hdr <- vapply(xml_find_all(rows[[1]], "./w:tc", ns),
                  function(c) paste(xml_text(xml_find_all(c, ".//w:t", ns)), collapse = ""), "")
    if (!any(startsWith(hdr, "Test Hole"))) next      # the per-hole field table only
    ws    <- vapply(hdr, width_for, numeric(1))
    total <- as.integer(sum(ws))
    # The data table is nested inside a single-cell caption-wrapper table fixed at
    # portrait width; widen that wrapper too, or the columns stay squeezed.
    wrap <- xml_find_first(tbl, "ancestor::w:tbl", ns)
    if (!is.na(wrap)) {
      set_tblW(wrap, total); set_grid(wrap, total)
      set_cells(xml_find_all(wrap, "./w:tr", ns), total)
    }
    set_tblW(tbl, total); set_grid(tbl, ws); set_cells(rows, ws)
  }

  ## 2. Landscape section for the appendix range -------------------------------
  body  <- xml_find_first(doc, ".//w:body", ns)
  final <- xml_find_first(body, "./w:sectPr", ns)   # governs the last section

  # Heading paragraph whose text starts with `label`.
  find_heading <- function(label) {
    for (p in xml_find_all(body, "./w:p", ns)) {
      txt <- paste(xml_text(xml_find_all(p, ".//w:t", ns)), collapse = "")
      if (startsWith(trimws(txt), label)) return(p)
    }
    NULL
  }
  paraA <- find_heading(landscape_from)
  paraC <- find_heading(landscape_to)

  # Serialised copy of the real final sectPr (a node, so no <?xml?> declaration).
  final_str <- as.character(final)
  # Parse a sectPr string into an editable node (namespace-wrapped so the w:
  # prefix always resolves), returning the <w:sectPr> node.
  parse_sect <- function(s) {
    d <- read_xml(sprintf('<root %s>%s</root>', nsdecl, s))
    xml_find_first(d, ".//w:sectPr", xml_ns(d))
  }
  # Section-break paragraph carrying a given sectPr string.
  break_para <- function(sect_str) {
    xml_find_first(
      read_xml(sprintf('<w:p %s><w:pPr>%s</w:pPr></w:p>', nsdecl, sect_str)),
      "/w:p")
  }

  # Landscape variant: rotate the page and shrink margins to 0.5"; keep the
  # cloned header/footer references so the branding carries across sections.
  land_sect <- parse_sect(final_str)
  lns  <- xml_ns(land_sect)
  pgsz <- xml_find_first(land_sect, ".//w:pgSz", lns)
  xml_set_attr(pgsz, "w:w", "15840"); xml_set_attr(pgsz, "w:h", "12240")
  xml_set_attr(pgsz, "w:orient", "landscape")
  pgmar <- xml_find_first(land_sect, ".//w:pgMar", lns)
  for (a in c("w:top", "w:right", "w:bottom", "w:left")) xml_set_attr(pgmar, a, "720")

  n_land <- 0
  if (!is.null(paraA) && !is.null(paraC)) {
    # Section semantics: a sectPr in a paragraph ends the section AT that paragraph.
    # Break before Appendix A ends the PORTRAIT body; break before Appendix C ends
    # the LANDSCAPE appendix range; the doc-final (portrait) sectPr governs App C.
    xml_add_sibling(paraA, break_para(final_str),            .where = "before")
    xml_add_sibling(paraC, break_para(as.character(land_sect)), .where = "before")
    n_land <- 1
  } else {
    warning("Landscape headings not both found ('", landscape_from, "' / '",
            landscape_to, "'); appendix orientation left unchanged.")
  }

  ## 2b. Branded cover page + front-matter pagination --------------------------
  # Pandoc keeps only the styles from the reference doc, not its cover page, so we
  # rebuild the cover here from report_style.docx (the design source of truth) and
  # put the title block, table of contents and figure/table lists each on their
  # own page. `cover` is a list(client, location, project_number, client_address);
  # title/subtitle/date are taken from the rendered title block.
  if (!is.null(cover) && !is.null(cover_source) && file.exists(cover_source)) {
    add_pbb <- function(p) {   # page-break-before on a paragraph
      ppr <- xml_find_first(p, "./w:pPr", ns)
      if (is.na(ppr)) ppr <- xml_add_child(p, read_xml(sprintf('<w:pPr %s/>', nsdecl)),
                                           .where = 0)
      xml_add_child(ppr, read_xml(sprintf('<w:pageBreakBefore %s/>', nsdecl)), .where = 0)
    }
    set_text <- function(p, txt) {   # replace a paragraph's text, honouring \n
      rs <- xml_find_all(p, ".//w:r", ns)
      if (length(rs) == 0) return(invisible())
      r1 <- rs[[1]]
      if (length(rs) > 1) for (k in 2:length(rs)) xml_remove(rs[[k]])
      for (ch in xml_children(r1)) if (xml_name(ch) != "rPr") xml_remove(ch)
      parts <- strsplit(txt, "\n", fixed = TRUE)[[1]]
      if (!length(parts)) parts <- ""
      for (i in seq_along(parts)) {
        if (i > 1) xml_add_child(r1, read_xml(sprintf('<w:br %s/>', nsdecl)))
        tn <- xml_add_child(r1, read_xml(sprintf('<w:t %s xml:space="preserve"></w:t>', nsdecl)))
        xml_set_text(tn, parts[i])
      }
    }
    para_text <- function(p) paste(xml_text(xml_find_all(p, ".//w:t", ns)), collapse = "")

    # Title / subtitle / date come from Pandoc's title block (first paras); capture
    # then remove it (the cover carries them).
    top <- xml_find_all(body, "./w:p", ns)
    title <- para_text(top[[1]]); subtitle <- para_text(top[[2]]); date <- para_text(top[[3]])
    for (p in top) {
      sty <- xml_attr(xml_find_first(p, "./w:pPr/w:pStyle", ns), "val")
      if (!is.na(sty) && sty %in% c("Title", "Subtitle", "Date")) xml_remove(p)
    }

    # Pull the cover paragraphs (through the green-plan.com line) from the source.
    ctmp <- file.path(tempdir(), paste0("cover_", as.integer(runif(1, 1, 1e9))))
    on.exit(unlink(ctmp, recursive = TRUE), add = TRUE)
    utils::unzip(cover_source, exdir = ctmp)
    cdoc <- read_xml(file.path(ctmp, "word", "document.xml")); cns <- xml_ns(cdoc)
    cps  <- xml_find_all(cdoc, ".//w:body/w:p", cns)
    last <- which(grepl("green-plan.com", vapply(cps, para_text, "")))[1]
    cover_paras <- cps[seq_len(last)]

    # Substitute the placeholder fields (positions are stable in the template).
    set_text(cover_paras[[1]],  title)
    set_text(cover_paras[[2]],  subtitle)
    set_text(cover_paras[[4]],  cover$location)
    set_text(cover_paras[[5]],  cover$project_number)
    set_text(cover_paras[[7]],  date)
    set_text(cover_paras[[12]], paste("Prepared For:", cover$client))
    set_text(cover_paras[[14]], cover$client_address)

    # Copy EVERY relationship the cover references (logo image, the green-plan.com
    # hyperlink, ...) into the rendered document with fresh ids, remapping each
    # reference, so the inserted cover leaves no dangling relationship (which is
    # what makes Word refuse to open the file).
    RELNS <- "http://schemas.openxmlformats.org/package/2006/relationships"
    crels <- read_xml(file.path(ctmp, "word", "_rels", "document.xml.rels"))
    drels <- read_xml(file.path(tmp,  "word", "_rels", "document.xml.rels"))
    next_n <- max(as.integer(sub("rId", "", xml_attr(xml_find_all(drels, "//*[@Id]"), "Id"))),
                  na.rm = TRUE)
    idmap <- new.env()
    for (p in cover_paras) {
      for (aname in c("embed", "id", "link")) {
        for (nd in xml_find_all(p, sprintf(".//*[@r:%s]", aname), cns)) {
          old <- xml_attr(nd, aname)
          if (is.na(old)) next
          if (is.null(idmap[[old]])) {
            rel <- xml_find_first(crels, sprintf("//*[@Id='%s']", old))
            if (is.na(rel)) next
            next_n <- next_n + 1
            newid  <- paste0("rId", next_n)
            typ <- xml_attr(rel, "Type"); tgt <- xml_attr(rel, "Target")
            mode <- xml_attr(rel, "TargetMode")
            if (grepl("/image$", typ)) {           # internal image: copy the media file
              dir.create(file.path(tmp, "word", "media"), showWarnings = FALSE, recursive = TRUE)
              tgt2 <- paste0("media/cover_", basename(tgt))
              file.copy(file.path(ctmp, "word", tgt), file.path(tmp, "word", tgt2),
                        overwrite = TRUE)
              tgt <- tgt2
            }
            at <- sprintf('Id="%s" Type="%s" Target="%s"', newid, typ, tgt)
            if (!is.na(mode)) at <- paste0(at, sprintf(' TargetMode="%s"', mode))
            xml_add_child(xml_root(drels),
                          read_xml(sprintf('<Relationship xmlns="%s" %s/>', RELNS, at)))
            assign(old, newid, envir = idmap)
          }
          xml_set_attr(nd, paste0("r:", aname), get(old, envir = idmap))
        }
      }
    }
    write_xml(drels, file.path(tmp, "word", "_rels", "document.xml.rels"))

    # Prepend the cover as the first children of the body, in order.
    for (i in seq_along(cover_paras)) xml_add_child(body, cover_paras[[i]], .where = i - 1)

    # Page breaks: cover | TOC | List of Figures + List of Tables | body.
    body_started <- FALSE
    for (p in xml_find_all(body, ".//w:p", ns)) {
      sty <- xml_attr(xml_find_first(p, "./w:pPr/w:pStyle", ns), "val")
      t   <- para_text(p)
      if (t %in% c("Table of contents", "List of Figures")) {
        add_pbb(p)
      } else if (!body_started && !is.na(sty) && sty == "Heading1") {
        add_pbb(p); body_started <- TRUE      # first body heading onto its own page
      }
    }

    # Ensure PNG is a declared content type for the logo.
    ct_path <- file.path(tmp, "[Content_Types].xml")
    ct <- read_xml(ct_path)
    if (is.na(xml_find_first(ct, "//*[@Extension='png']"))) {
      xml_add_child(xml_root(ct), read_xml(sprintf(
        '<Default xmlns="%s" Extension="png" ContentType="image/png"/>',
        "http://schemas.openxmlformats.org/package/2006/content-types")))
      write_xml(ct, ct_path)
    }
  }

  ## 3. Force Word to refresh fields on open -----------------------------------
  # The TOC, List of Figures and List of Tables are field codes that render empty
  # until updated. Setting updateFields makes Word rebuild them when the document
  # is opened (it prompts once), so they populate without a manual F9.
  set_path <- file.path(tmp, "word", "settings.xml")
  if (file.exists(set_path)) {
    settings <- read_xml(set_path)
    sns <- xml_ns(settings)
    if (is.na(xml_find_first(settings, ".//w:updateFields", sns))) {
      uf <- read_xml(sprintf('<w:updateFields %s w:val="true"/>', nsdecl))
      xml_add_child(settings, uf, .where = 0)   # must precede most settings
      write_xml(settings, set_path)
    }
  }

  ## Write back ----------------------------------------------------------------
  write_xml(doc, doc_path)
  # mode = "mirror" keeps the relative paths (word/document.xml, _rels/, ...)
  # that a .docx requires; "cherry-pick" would flatten them. all.files = TRUE is
  # essential: the package master relationship _rels/.rels is a dotfile and would
  # otherwise be dropped, which makes Word refuse to open the document.
  zip::zip(zipfile = path, files = list.files(tmp, recursive = TRUE, all.files = TRUE),
           root = tmp, mode = "mirror")

  message(sprintf("  finalize_docx: cleaned %d figure tables; landscape appendices: %s",
                  n_fig, if (n_land) "applied" else "skipped"))
  invisible(path)
}
