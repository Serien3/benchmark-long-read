#!/usr/bin/env Rscript

# =============================================================================
# Panel b: integrated 30x read profile
#
# Scientific contract
#   Claim      : under the matched 30x input condition, the three platforms
#                retain distinct read-length, reported read-Q and high-quality
#                read-composition profiles.
#   Role       : descriptive read-level evidence; this panel does not rank an
#                overall winner or infer downstream benchmark performance.
#   Evidence   : the three strict-30x reads-QC observations, shown without
#                aggregation or artificial displacement.
#   Archetype  : aligned, faceted dot matrix with one shared platform axis.
#   Encoding   : row = platform; colour = platform; shape = summary statistic;
#                x position = observed value in each metric domain.
#   Integrity  : no jitter, smoothing, uncertainty interval, test or p-value.
#   Reuse      : build anew; style-only inheritance from the project palette,
#                typography, vector export and audit conventions.
# =============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(grid)
  library(svglite)
  library(ragg)
  library(systemfonts)
})

find_root <- function() {
  arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(arg) == 1L) {
    script_path <- normalizePath(sub("^--file=", "", arg))
    return(dirname(dirname(dirname(dirname(script_path)))))
  }
  normalizePath(getwd())
}

ROOT <- find_root()
INPUT_FILE <- file.path(ROOT, "data", "reads_qc_nanoplot_q20.csv")
OUTPUT_DIR <- file.path(
  ROOT, "figures", "reads_alignment_qc", "panel_b_read_profile"
)
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

PLATFORMS <- c("BGI", "ONT", "HiFi")
# ggplot draws the last discrete level at the top of a vertical axis.
PLATFORM_Y_LEVELS <- rev(PLATFORMS)
FACETS <- c(
  "Read length (kb)",
  "Reported read Q",
  "Mean-Q>20 composition (%)"
)
STATISTICS <- c(
  "Mean", "Median", "N50", "Read fraction", "Base share"
)
PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)
STATISTIC_SHAPES <- c(
  Mean = 16,
  Median = 17,
  N50 = 18,
  `Read fraction` = 1,
  `Base share` = 0
)

WIDTH_MM = 120
HEIGHT_MM = 52
PNG_DPI = 320
TIFF_DPI = 600
OUTPUT_STEM <- "integrated_read_profile_30x"

choose_font <- function() {
  candidates <- c(
    "Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans"
  )
  available <- unique(systemfonts::system_fonts()$family)
  selected <- candidates[candidates %in% available][1]
  if (is.na(selected)) "sans" else selected
}

BASE_FAMILY <- choose_font()

# Cairo consults the PDF font database while measuring text. Register the
# available Helvetica-compatible Nimbus metrics under the system family name.
if (identical(BASE_FAMILY, "Nimbus Sans") &&
    !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  nimbus_metrics <- grDevices::pdfFonts("NimbusSan")[[1]]
  do.call(
    grDevices::pdfFonts,
    setNames(list(nimbus_metrics), BASE_FAMILY)
  )
}

# ---- Data contract ---------------------------------------------------------

required_columns <- c(
  "Dataset", "Depth", "Reads", "Total bases", "Yield (Gb)",
  "Approx coverage", "Mean length", "Median length", "Read N50",
  "Mean Q", "Median Q", "Reads with mean Q>20 (%) (NanoPlot)",
  "Mean-Q>20 read yield (Gb)", "Status"
)

raw <- read_csv(
  INPUT_FILE,
  show_col_types = FALSE,
  progress = FALSE,
  locale = locale(encoding = "UTF-8")
)

missing_columns <- setdiff(required_columns, names(raw))
if (length(missing_columns) > 0L) {
  stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
}

n_source <- nrow(raw)
if (n_source != 9L) {
  stop("Expected exactly nine reads-QC observations; found ", n_source)
}

input_30x <- raw %>%
  transmute(
    source_dataset = Dataset,
    platform = sub("_latest$", "", Dataset),
    depth = Depth,
    reads = as.numeric(Reads),
    total_bases = as.numeric(`Total bases`),
    total_yield_gb = as.numeric(`Yield (Gb)`),
    approximate_input_depth_x = as.numeric(`Approx coverage`),
    mean_length_kb = as.numeric(`Mean length`) / 1000,
    median_length_kb = as.numeric(`Median length`) / 1000,
    read_n50_kb = as.numeric(`Read N50`) / 1000,
    mean_reported_q = as.numeric(`Mean Q`),
    median_reported_q = as.numeric(`Median Q`),
    q20_read_fraction = as.numeric(
      `Reads with mean Q>20 (%) (NanoPlot)`
    ),
    q20_read_fraction_pct = 100 * q20_read_fraction,
    q20_read_yield_gb = as.numeric(`Mean-Q>20 read yield (Gb)`),
    q20_read_base_share_pct = 100 * q20_read_yield_gb / total_yield_gb,
    status = Status
  ) %>%
  filter(depth == "30x") %>%
  mutate(
    platform = factor(platform, levels = PLATFORMS)
  ) %>%
  arrange(platform)

if (nrow(input_30x) != 3L) {
  stop("Expected exactly three strict-30x observations; found ", nrow(input_30x))
}
if (any(is.na(input_30x$platform)) ||
    !setequal(as.character(input_30x$platform), PLATFORMS)) {
  stop("The strict-30x subset must contain BGI, ONT and HiFi exactly once")
}
if (nrow(distinct(input_30x, platform)) != 3L) {
  stop("Platform keys are not unique in the strict-30x subset")
}
if (any(input_30x$status != "OK")) {
  stop("At least one strict-30x reads-QC row is not marked OK")
}

numeric_fields <- input_30x %>%
  select(
    mean_length_kb, median_length_kb, read_n50_kb,
    mean_reported_q, median_reported_q,
    q20_read_fraction, q20_read_fraction_pct,
    q20_read_yield_gb, q20_read_base_share_pct,
    total_yield_gb
  )
if (any(!is.finite(as.matrix(numeric_fields)))) {
  stop("All plotted and derived strict-30x values must be finite")
}
if (any(input_30x$q20_read_fraction < 0 |
        input_30x$q20_read_fraction > 1)) {
  stop("Q>20 read fractions must lie in [0, 1]")
}
if (any(input_30x$q20_read_yield_gb < 0 |
        input_30x$q20_read_yield_gb > input_30x$total_yield_gb)) {
  stop("Mean-Q>20 read yield must lie within total yield")
}
if (any(input_30x$q20_read_base_share_pct < 0 |
        input_30x$q20_read_base_share_pct > 100)) {
  stop("Derived Q20-read base shares must lie in [0, 100]")
}

make_long <- function(data, facet, statistic, value, unit, source_field,
                      transformation) {
  data %>%
    transmute(
      source_dataset,
      depth,
      platform,
      facet = facet,
      statistic = statistic,
      value = {{ value }},
      unit = unit,
      source_field = source_field,
      transformation = transformation,
      total_yield_gb,
      q20_read_yield_gb
    )
}

plot_data <- bind_rows(
  make_long(
    input_30x, FACETS[1], "Mean", mean_length_kb, "kb",
    "Mean length", "source bp / 1000"
  ),
  make_long(
    input_30x, FACETS[1], "Median", median_length_kb, "kb",
    "Median length", "source bp / 1000"
  ),
  make_long(
    input_30x, FACETS[1], "N50", read_n50_kb, "kb",
    "Read N50", "source bp / 1000"
  ),
  make_long(
    input_30x, FACETS[2], "Mean", mean_reported_q, "Q score",
    "Mean Q", "identity"
  ),
  make_long(
    input_30x, FACETS[2], "Median", median_reported_q, "Q score",
    "Median Q", "identity"
  ),
  make_long(
    input_30x, FACETS[3], "Read fraction", q20_read_fraction_pct, "%",
    "Reads with mean Q>20 (%) (NanoPlot)", "source fraction x 100"
  ),
  make_long(
    input_30x, FACETS[3], "Base share", q20_read_base_share_pct, "%",
    "Mean-Q>20 read yield (Gb) / Yield (Gb)",
    "100 x Q20-read yield / total yield"
  )
) %>%
  mutate(
    platform = factor(platform, levels = PLATFORM_Y_LEVELS),
    facet = factor(facet, levels = FACETS),
    statistic = factor(statistic, levels = STATISTICS)
  ) %>%
  arrange(facet, desc(as.integer(platform)), statistic)

if (nrow(plot_data) != 21L) {
  stop("Expected 21 plotted marks; found ", nrow(plot_data))
}
if (any(!is.finite(plot_data$value))) {
  stop("All plotted values must be finite")
}
duplicate_marks <- plot_data %>%
  count(platform, facet, statistic, name = "n") %>%
  filter(n != 1L)
if (nrow(duplicate_marks) > 0L) {
  stop("Platform x facet x statistic plotting keys are not unique")
}

composition_segments <- input_30x %>%
  transmute(
    platform = factor(platform, levels = PLATFORM_Y_LEVELS),
    facet = factor(FACETS[3], levels = FACETS),
    x = q20_read_fraction_pct,
    xend = q20_read_base_share_pct
  )

axis_anchors <- bind_rows(
  data.frame(facet = FACETS[1], value = c(0, 32)),
  data.frame(facet = FACETS[2], value = c(0, 35)),
  data.frame(facet = FACETS[3], value = c(0, 100))
) %>%
  mutate(
    facet = factor(facet, levels = FACETS),
    platform = factor("ONT", levels = PLATFORM_Y_LEVELS)
  )

write_csv(
  input_30x %>%
    mutate(
      platform = as.character(platform),
      q20_read_base_share_pct = round(q20_read_base_share_pct, 4)
    ),
  file.path(OUTPUT_DIR, "source_data_input_30x.csv"),
  na = ""
)
write_csv(
  plot_data %>%
    mutate(
      platform = as.character(platform),
      facet = as.character(facet),
      statistic = as.character(statistic),
      value = round(value, 4)
    ),
  file.path(OUTPUT_DIR, "source_data_plotted.csv"),
  na = ""
)

audit <- data.frame(
  source_file = basename(INPUT_FILE),
  source_rows = n_source,
  selected_depth = "30x",
  selected_input_rows = nrow(input_30x),
  excluded_non_30x_rows = n_source - nrow(input_30x),
  plotted_marks = nrow(plot_data),
  expected_plotted_marks = 21L,
  transform_platform = "remove terminal _latest suffix",
  transform_length = "source bp / 1000",
  transform_q20_read_fraction = "source fraction x 100",
  transform_q20_base_share = "100 x Q20-read yield (Gb) / total yield (Gb)",
  filter_rule = "Depth == 30x; one observation retained per platform",
  replicate_statement = paste(
    "one HG002 30x technical subset per platform; no biological replicates"
  ),
  stringsAsFactors = FALSE
)
write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"), na = "")

# ---- Figure ----------------------------------------------------------------

panel_breaks <- function(limits) {
  if (max(limits, na.rm = TRUE) > 70) {
    c(0, 25, 50, 75, 100)
  } else {
    c(0, 10, 20, 30)
  }
}

theme_read_profile <- function(base_size = 6.2, base_family = BASE_FAMILY) {
  theme_classic(base_size = base_size, base_family = base_family) +
    theme(
      axis.line.x = element_line(colour = "#252525", linewidth = 0.28),
      axis.line.y = element_blank(),
      axis.ticks.x = element_line(colour = "#252525", linewidth = 0.28),
      axis.ticks.y = element_blank(),
      axis.ticks.length.x = unit(1.0, "mm"),
      axis.title = element_blank(),
      axis.text.x = element_text(
        colour = "#4D4D4D", size = 5.7, margin = margin(t = 1.0)
      ),
      axis.text.y = element_text(
        colour = "#252525", size = 6.2, face = "bold",
        margin = margin(r = 1.2)
      ),
      strip.background = element_blank(),
      strip.text = element_text(
        colour = "#202020", size = 6.4, face = "bold",
        margin = margin(b = 1.7)
      ),
      panel.grid = element_blank(),
      panel.spacing.x = unit(3.0, "mm"),
      legend.position = "bottom",
      legend.justification = "center",
      legend.direction = "horizontal",
      legend.title = element_blank(),
      legend.text = element_text(colour = "#333333", size = 5.5),
      legend.key = element_blank(),
      legend.key.width = unit(4.0, "mm"),
      legend.key.height = unit(2.5, "mm"),
      legend.spacing.x = unit(0.7, "mm"),
      legend.margin = margin(1.2, 0, 0, 0, unit = "mm"),
      plot.margin = margin(1.5, 1.8, 1.2, 1.5, unit = "mm")
    )
}

p <- ggplot(
  plot_data,
  aes(x = value, y = platform, colour = platform, shape = statistic)
) +
  geom_hline(
    yintercept = seq_along(PLATFORM_Y_LEVELS),
    colour = "#E8E8E8",
    linewidth = 0.28
  ) +
  geom_blank(
    data = axis_anchors,
    aes(x = value, y = platform),
    inherit.aes = FALSE
  ) +
  geom_segment(
    data = composition_segments,
    aes(x = x, xend = xend, y = platform, yend = platform),
    inherit.aes = FALSE,
    colour = "#B8B8B8",
    linewidth = 0.38,
    lineend = "round"
  ) +
  geom_point(size = 2.0, stroke = 0.48) +
  facet_wrap(
    vars(facet),
    nrow = 1,
    scales = "free_x"
  ) +
  scale_colour_manual(
    values = PLATFORM_COLOURS,
    breaks = PLATFORMS,
    limits = PLATFORMS,
    drop = FALSE,
    guide = "none"
  ) +
  scale_shape_manual(
    values = STATISTIC_SHAPES,
    breaks = STATISTICS,
    limits = STATISTICS,
    drop = FALSE
  ) +
  scale_x_continuous(
    breaks = panel_breaks,
    expand = expansion(mult = c(0.015, 0.035))
  ) +
  scale_y_discrete(
    limits = PLATFORM_Y_LEVELS,
    drop = FALSE
  ) +
  guides(
    shape = guide_legend(
      nrow = 1,
      byrow = TRUE,
      override.aes = list(
        colour = "#333333",
        size = 1.85,
        stroke = 0.45
      )
    )
  ) +
  theme_read_profile()

# ---- Export ----------------------------------------------------------------

width_in <- WIDTH_MM / 25.4
height_in <- HEIGHT_MM / 25.4

svg_path <- file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".svg"))
pdf_path <- file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".pdf"))
tiff_path <- file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".tiff"))
png_path <- file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".png"))

svglite::svglite(
  svg_path,
  width = width_in,
  height = height_in,
  bg = "white",
  fix_text_size = FALSE
)
print(p)
grDevices::dev.off()

grDevices::cairo_pdf(
  pdf_path,
  width = width_in,
  height = height_in,
  family = BASE_FAMILY,
  bg = "white",
  onefile = TRUE
)
print(p)
grDevices::dev.off()

ragg::agg_tiff(
  tiff_path,
  width = WIDTH_MM,
  height = HEIGHT_MM,
  units = "mm",
  res = TIFF_DPI,
  compression = "lzw",
  background = "white"
)
print(p)
grDevices::dev.off()

ragg::agg_png(
  png_path,
  width = WIDTH_MM,
  height = HEIGHT_MM,
  units = "mm",
  res = PNG_DPI,
  background = "white"
)
print(p)
grDevices::dev.off()

rendered_paths <- c(svg_path, pdf_path, tiff_path, png_path)
render_manifest <- data.frame(
  file = basename(rendered_paths),
  format = c("SVG", "PDF", "TIFF", "PNG"),
  width_mm = WIDTH_MM,
  height_mm = HEIGHT_MM,
  dpi = c(NA, NA, TIFF_DPI, PNG_DPI),
  editable_text = c(TRUE, TRUE, FALSE, FALSE),
  base_family = BASE_FAMILY,
  selected_input_rows = nrow(input_30x),
  plotted_marks = nrow(plot_data),
  bytes = as.numeric(file.info(rendered_paths)$size),
  md5 = unname(tools::md5sum(rendered_paths)),
  stringsAsFactors = FALSE
)
write_csv(
  render_manifest,
  file.path(OUTPUT_DIR, "render_manifest.csv"),
  na = ""
)

message("Rendered Panel b to: ", OUTPUT_DIR)
message("Selected input rows: ", nrow(input_30x), " / ", n_source)
message("Plotted marks: ", nrow(plot_data))
message("Font family: ", BASE_FAMILY)
