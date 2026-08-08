#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(grid)
  library(svglite)
  library(ragg)
  library(systemfonts)
})

find_root <- function() {
  arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(arg) == 1L) {
    script_path <- normalizePath(sub("^--file=", "", arg))
    return(dirname(dirname(dirname(script_path))))
  }
  normalizePath(getwd())
}

ROOT <- find_root()
OUTPUT_DIR <- file.path(ROOT, "figures", "phasing_main_a_experimental_logic")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

FIGURE_STEM <- "phasing_main_a_experimental_logic"
WIDTH_MM <- 183
HEIGHT_MM <- 31
DPI <- 600

font_candidates <- c("Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans")
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

if (identical(BASE_FAMILY, "Nimbus Sans") &&
    !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  nimbus_metrics <- grDevices::pdfFonts("NimbusSan")[[1]]
  do.call(grDevices::pdfFonts, setNames(list(nimbus_metrics), BASE_FAMILY))
}

COL <- c(
  ink = "#202124",
  muted = "#62676D",
  hairline = "#AEB4BA",
  scaffold = "#E3E6E8",
  card = "#F7F8F8",
  primary_fill = "#EAF2F8",
  primary_edge = "#4D7895",
  secondary_fill = "#F2F4F5",
  secondary_edge = "#7D878E",
  bgi = "#FFB000",
  ont = "#13A4A6",
  hifi = "#9400D3"
)

workflow_nodes <- data.frame(
  lane = c(
    "design", "design", "design", "design",
    "primary", "primary", "primary", "primary", "primary", "primary",
    "validation", "validation", "validation"
  ),
  stage = c(
    "sample", "platforms", "mappers", "depths",
    "input", "input", "input", "phaser", "output", "output",
    "input", "phaser", "output"
  ),
  label = c(
    "HG002 genomic DNA", "BGI | ONT | HiFi", "minimap2 | winnowmap",
    "10x | 30x | 50x",
    "alignment BAM", "Clair3 heterozygous biallelic SNPs",
    "Sniffles2 SVs with read names", "LongPhase 2.0.2 joint SNP + SV phasing",
    "phased SNP VCF: coverage, NG50, GIAB switch/Hamming errors",
    "phased SV VCF: phased fraction, T2T-Q100 Truvari F1",
    "alignment BAM + Clair3 SNP VCF", "WhatsHap 2.8 SNP phasing",
    "coverage, NG50, GIAB errors, haplotag yield"
  ),
  quantitative_observation = FALSE,
  stringsAsFactors = FALSE
)

stopifnot(
  identical(c("BGI", "ONT", "HiFi"), strsplit(workflow_nodes$label[2], " \\| ")[[1]]),
  identical(c("minimap2", "winnowmap"), strsplit(workflow_nodes$label[3], " \\| ")[[1]]),
  identical(c("10x", "30x", "50x"), strsplit(workflow_nodes$label[4], " \\| ")[[1]])
)

write.csv(
  workflow_nodes,
  file.path(OUTPUT_DIR, "source_data_plotted.csv"),
  row.names = FALSE,
  na = ""
)

audit <- data.frame(
  source_scope = "Experimental design and completed phasing workflows",
  source_rows = nrow(workflow_nodes),
  plotted_rows = nrow(workflow_nodes),
  excluded_rows = 0L,
  exclusion_rule = "none",
  aggregation = "none",
  interpolation = "none",
  quantitative_values_plotted = FALSE,
  note = "This panel is a workflow schematic; no experimental result values are encoded.",
  stringsAsFactors = FALSE
)
write.csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"), row.names = FALSE)

metric_definitions <- data.frame(
  display_term = c(
    "SNP coverage", "NG50", "Switch error", "Hamming error",
    "SV phased fraction", "SV benchmark F1", "Haplotag yield"
  ),
  definition = c(
    "Phased benchmark SNPs divided by benchmark SNPs for LongPhase; phased heterozygous SNVs divided by heterozygous SNVs for WhatsHap.",
    "Phase-block length at which cumulative block span reaches 50% of the GRCh38 chr1-22 genome length.",
    "Switch errors divided by assessed adjacent variant pairs; switch errors equal switch events plus twice the flip events.",
    "Blockwise Hamming errors divided by covered truth variants after block orientation correction.",
    "Phased heterozygous SV genotypes divided by all heterozygous SV genotypes; phased means that the GT separator is '|'.",
    "Harmonic mean of precision and recall from Truvari comparison of the SV call set with T2T-Q100; not a truth test of phase orientation.",
    "H1 plus H2 tagged alignments divided by all processed alignments; not unique reads and not truth-validated assignments."
  ),
  transformation_in_later_panels = c(
    "fraction x 100 for percent display",
    "kb / 1000 for Mb display where needed",
    "rate x 10000 for errors per 10,000 assessed pairs",
    "rate x 100 for percent display; logarithmic axis only where specified",
    "fraction x 100 for percent display",
    "none",
    "fraction x 100 for percent display"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  metric_definitions,
  file.path(OUTPUT_DIR, "metric_definitions.csv"),
  row.names = FALSE
)

mm_x <- function(x) unit(x / WIDTH_MM, "npc")
mm_y <- function(y) unit(y / HEIGHT_MM, "npc")

txt <- function(label, x, y, size = 6.5, colour = COL[["ink"]],
                face = "plain", hjust = 0.5, vjust = 0.5) {
  grid.text(
    label,
    x = mm_x(x), y = mm_y(y),
    just = c(hjust, vjust),
    gp = gpar(
      fontfamily = BASE_FAMILY,
      fontsize = size,
      fontface = face,
      col = colour,
      lineheight = 0.94
    )
  )
}

rounded_box <- function(x, y, w, h, fill = COL[["card"]],
                        edge = COL[["hairline"]], radius = 1.1,
                        linewidth = 0.55) {
  grid.roundrect(
    x = mm_x(x), y = mm_y(y), width = mm_x(w), height = mm_y(h),
    r = unit(radius, "mm"),
    gp = gpar(fill = fill, col = edge, lwd = linewidth)
  )
}

arrow_line <- function(x0, y0, x1, y1, colour = COL[["hairline"]],
                       linewidth = 0.65) {
  grid.lines(
    x = mm_x(c(x0, x1)), y = mm_y(c(y0, y1)),
    arrow = arrow(type = "closed", length = unit(1.35, "mm")),
    gp = gpar(col = colour, lwd = linewidth, lineend = "round")
  )
}

draw_design_card <- function() {
  rounded_box(24.5, 15.2, 37.0, 24.0, fill = "white", edge = COL[["scaffold"]])
  txt("Matched HG002 design", 8.0, 25.0, size = 7.1, face = "bold", hjust = 0)
  txt("genomic DNA  |  GRCh38", 8.0, 21.8, size = 5.8, colour = COL[["muted"]], hjust = 0)

  grid.points(
    x = mm_x(c(9.0, 20.3, 30.5)), y = mm_y(rep(17.7, 3)),
    pch = 21, size = unit(2.15, "mm"),
    gp = gpar(col = "white", lwd = 0.45),
    vp = NULL
  )
  grid.points(mm_x(9.0), mm_y(17.7), pch = 21, size = unit(2.15, "mm"),
              gp = gpar(fill = COL[["bgi"]], col = "white", lwd = 0.45))
  grid.points(mm_x(20.3), mm_y(17.7), pch = 21, size = unit(2.15, "mm"),
              gp = gpar(fill = COL[["ont"]], col = "white", lwd = 0.45))
  grid.points(mm_x(30.5), mm_y(17.7), pch = 21, size = unit(2.15, "mm"),
              gp = gpar(fill = COL[["hifi"]], col = "white", lwd = 0.45))
  txt("BGI", 10.8, 17.7, size = 5.7, hjust = 0)
  txt("ONT", 22.1, 17.7, size = 5.7, hjust = 0)
  txt("HiFi", 32.3, 17.7, size = 5.7, hjust = 0)

  grid.lines(mm_x(c(8.0, 12.5)), mm_y(c(13.7, 13.7)),
             gp = gpar(col = COL[["ink"]], lwd = 1.05))
  txt("minimap2", 14.0, 13.7, size = 5.6, hjust = 0)
  grid.lines(mm_x(c(26.0, 30.5)), mm_y(c(13.7, 13.7)),
             gp = gpar(col = COL[["ink"]], lwd = 1.05, lty = 22))
  txt("winnowmap", 32.0, 13.7, size = 5.6, hjust = 0)

  txt("10×     30×     50×", 8.0, 9.8, size = 6.0, hjust = 0)
  txt("18 matched combinations", 8.0, 5.6,
      size = 5.2, colour = COL[["muted"]], hjust = 0)
}

draw_main_lane <- function() {
  txt("PRIMARY  |  JOINT SNP + SV PHASING", 45.8, 28.1, size = 5.2,
      colour = COL[["primary_edge"]], face = "bold", hjust = 0)

  rounded_box(61.5, 22.0, 30.0, 9.2)
  txt("Alignment BAM", 48.2, 24.8, size = 5.7, face = "bold", hjust = 0)
  txt("Clair3 het biallelic SNPs", 48.2, 21.9, size = 5.2, hjust = 0)
  txt("Sniffles2 SVs + read names", 48.2, 19.1, size = 5.2, hjust = 0)

  rounded_box(97.0, 22.0, 25.5, 9.2,
              fill = COL[["primary_fill"]], edge = COL[["primary_edge"]], linewidth = 0.8)
  txt("LongPhase 2.0.2", 97.0, 23.6, size = 6.6, face = "bold")
  txt("joint SNP + SV phasing", 97.0, 20.5, size = 5.4, colour = COL[["muted"]])

  rounded_box(146.4, 24.7, 65.6, 4.5, fill = "white", edge = COL[["scaffold"]], radius = 0.8)
  txt("Phased SNP VCF", 115.0, 24.7, size = 5.6, face = "bold", hjust = 0)
  txt("coverage  |  NG50  |  GIAB switch + Hamming errors", 135.5, 24.7,
      size = 5.0, hjust = 0)

  rounded_box(146.4, 19.3, 65.6, 4.5, fill = "white", edge = COL[["scaffold"]], radius = 0.8)
  txt("Phased SV VCF", 115.0, 19.3, size = 5.6, face = "bold", hjust = 0)
  txt("phased fraction  |  T2T-Q100 Truvari F1", 135.5, 19.3,
      size = 5.0, hjust = 0)

  arrow_line(42.9, 22.0, 46.2, 22.0)
  arrow_line(76.8, 22.0, 82.7, 22.0, colour = COL[["primary_edge"]])
  grid.lines(mm_x(c(109.8, 112.0, 112.0)), mm_y(c(22.0, 22.0, 24.7)),
             gp = gpar(col = COL[["primary_edge"]], lwd = 0.65, lineend = "round"))
  grid.lines(mm_x(c(112.0, 112.0)), mm_y(c(22.0, 19.3)),
             gp = gpar(col = COL[["primary_edge"]], lwd = 0.65, lineend = "round"))
  arrow_line(112.0, 24.7, 113.0, 24.7, colour = COL[["primary_edge"]])
  arrow_line(112.0, 19.3, 113.0, 19.3, colour = COL[["primary_edge"]])
}

draw_validation_lane <- function() {
  txt("INDEPENDENT VALIDATION  |  SNP PHASING + HAPLOTAG", 45.8, 13.1, size = 5.2,
      colour = COL[["secondary_edge"]], face = "bold", hjust = 0)

  rounded_box(61.5, 7.2, 30.0, 7.2)
  txt("Alignment BAM", 48.2, 8.6, size = 5.6, face = "bold", hjust = 0)
  txt("Clair3 SNP VCF", 48.2, 5.9, size = 5.2, hjust = 0)

  rounded_box(97.0, 7.2, 25.5, 7.2,
              fill = COL[["secondary_fill"]], edge = COL[["secondary_edge"]], linewidth = 0.75)
  txt("WhatsHap 2.8", 97.0, 8.4, size = 6.4, face = "bold")
  txt("SNP phasing", 97.0, 5.7, size = 5.3, colour = COL[["muted"]])

  rounded_box(146.9, 7.2, 66.6, 7.2, fill = "white", edge = COL[["scaffold"]])
  txt("Phased SNP outputs", 115.0, 8.6, size = 5.7, face = "bold", hjust = 0)
  txt("coverage  |  NG50  |  GIAB errors  |  haplotag yield", 115.0, 5.8,
      size = 5.2, hjust = 0)

  arrow_line(42.9, 7.2, 46.2, 7.2)
  arrow_line(76.8, 7.2, 82.7, 7.2, colour = COL[["secondary_edge"]])
  arrow_line(109.8, 7.2, 113.2, 7.2, colour = COL[["secondary_edge"]])
}

draw_figure <- function() {
  grid.newpage()
  pushViewport(viewport(xscale = c(0, 1), yscale = c(0, 1), clip = "off"))
  grid.rect(gp = gpar(fill = "white", col = NA))
  txt("a", 1.2, 29.6, size = 8.0, face = "bold", hjust = 0)
  draw_design_card()
  draw_main_lane()
  draw_validation_lane()
  popViewport()
}

open_svg <- function(path) {
  svglite::svglite(path, width = WIDTH_MM / 25.4, height = HEIGHT_MM / 25.4,
                   bg = "white", system_fonts = list(sans = BASE_FAMILY))
}

open_pdf <- function(path) {
  grDevices::cairo_pdf(path, width = WIDTH_MM / 25.4, height = HEIGHT_MM / 25.4,
                       family = BASE_FAMILY, bg = "white", onefile = TRUE)
}

open_tiff <- function(path) {
  ragg::agg_tiff(path, width = WIDTH_MM, height = HEIGHT_MM, units = "mm",
                 res = DPI, background = "white", scaling = 1)
}

open_png <- function(path) {
  ragg::agg_png(path, width = WIDTH_MM, height = HEIGHT_MM, units = "mm",
                res = DPI, background = "white", scaling = 1)
}

devices <- list(svg = open_svg, pdf = open_pdf, tiff = open_tiff, png = open_png)
for (ext in names(devices)) {
  out <- file.path(OUTPUT_DIR, paste0(FIGURE_STEM, ".", ext))
  devices[[ext]](out)
  draw_figure()
  grDevices::dev.off()
}

outputs <- file.path(OUTPUT_DIR, paste0(FIGURE_STEM, ".", names(devices)))
if (!all(file.exists(outputs)) || any(file.info(outputs)$size <= 0)) {
  stop("One or more figure exports are missing or empty")
}

manifest <- data.frame(
  file = basename(outputs),
  format = names(devices),
  width_mm = WIDTH_MM,
  height_mm = HEIGHT_MM,
  dpi = c(NA, NA, DPI, DPI),
  bytes = unname(file.info(outputs)$size),
  md5 = unname(tools::md5sum(outputs)),
  font_family = BASE_FAMILY,
  editable_text = c(TRUE, TRUE, FALSE, FALSE),
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
write.csv(manifest, file.path(OUTPUT_DIR, "render_manifest.csv"), row.names = FALSE, na = "")

message("Rendered phasing workflow panel to: ", OUTPUT_DIR)
