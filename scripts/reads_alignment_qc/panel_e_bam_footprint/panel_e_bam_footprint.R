#!/usr/bin/env Rscript

# =============================================================================
# Panel e: BAM output footprint across mapping conditions at matched 30x
#
# Scientific contract
#   Claim      : under the unified alignment/BAM workflow, the 30x output
#                footprint is strongly platform-dependent and also changes
#                consistently with aligner and reference genome.
#   Role       : operational complement to Panel d's read-retention result.
#   Evidence   : all 12 strict-30x platform x reference x aligner conditions.
#   Archetype  : compact 3 x 4 in-cell horizontal-bar matrix.
#   Encoding   : rows = platform; columns = reference x aligner; bar length =
#                BAM size on one common zero-based 0-115 GiB scale; bar colour
#                = platform; exact source value printed in every cell.
#   Integrity  : no aggregation, connector, point, jitter, fitted trend,
#                uncertainty interval, statistical test or p-value.
#   Reuse      : inherit Panel d's 89 x 54 mm matrix, typography, reference
#                headers, row/column order, platform palette and grey accents.
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
INPUT_FILE <- file.path(ROOT, "data", "alignment_qc.csv")
OUTPUT_DIR <- file.path(
  ROOT, "figures", "reads_alignment_qc", "panel_e_bam_footprint"
)
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

REFERENCES <- c("GRCh38", "T2T-CHM13")
ALIGNERS <- c("minimap2", "winnowmap")
PLATFORMS <- c("BGI", "ONT", "HiFi")

PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)

SCALE_LIMIT_GIB <- 115
CELL_WIDTH <- 0.88
CELL_HEIGHT <- 0.46

WIDTH_MM = 89
HEIGHT_MM = 54
PNG_DPI = 320
TIFF_DPI = 600
OUTPUT_STEM <- "bam_output_footprint_30x"

choose_font <- function() {
  candidates <- c(
    "Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans"
  )
  available <- unique(systemfonts::system_fonts()$family)
  selected <- candidates[candidates %in% available][1]
  if (is.na(selected)) "sans" else selected
}

BASE_FAMILY <- choose_font()

if (identical(BASE_FAMILY, "Nimbus Sans") &&
    !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  nimbus_metrics <- grDevices::pdfFonts("NimbusSan")[[1]]
  do.call(
    grDevices::pdfFonts,
    setNames(list(nimbus_metrics), BASE_FAMILY)
  )
}

assert_near <- function(observed, expected, label, tolerance = 1e-8) {
  if (length(observed) != 1L || !is.finite(observed) ||
      abs(observed - expected) > tolerance) {
    stop(label, " changed: expected ", expected, "; observed ", observed)
  }
}

# ---- Data contract ---------------------------------------------------------

required_columns <- c(
  "参考基因组", "Aligner", "Dataset", "Depth", "BAM size GiB"
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
if (n_source != 36L) {
  stop("Expected exactly 36 alignment-QC observations; found ", n_source)
}

plot_data <- raw %>%
  transmute(
    reference = factor(`参考基因组`, levels = REFERENCES),
    aligner = factor(Aligner, levels = ALIGNERS),
    source_dataset = Dataset,
    platform = factor(
      sub("_latest$", "", Dataset),
      levels = PLATFORMS
    ),
    depth_label = Depth,
    nominal_depth_x = as.numeric(sub("x$", "", Depth)),
    bam_size_gib = as.numeric(`BAM size GiB`)
  ) %>%
  filter(depth_label == "30x") %>%
  arrange(reference, aligner, platform)

if (nrow(plot_data) != 12L) {
  stop("Expected exactly 12 strict-30x observations; found ", nrow(plot_data))
}
if (any(is.na(plot_data$reference))) {
  stop("Unexpected reference label in the strict-30x alignment subset")
}
if (any(is.na(plot_data$aligner))) {
  stop("Unexpected aligner label in the strict-30x alignment subset")
}
if (any(is.na(plot_data$platform))) {
  stop("Unexpected platform label in the strict-30x alignment subset")
}
if (any(plot_data$nominal_depth_x != 30)) {
  stop("Panel e must contain only the prespecified nominal 30x observations")
}
if (any(!is.finite(plot_data$bam_size_gib)) ||
    any(plot_data$bam_size_gib < 0 |
        plot_data$bam_size_gib > SCALE_LIMIT_GIB)) {
  stop("BAM sizes must be finite and lie inside the declared 0-115 GiB scale")
}

duplicate_keys <- plot_data %>%
  count(reference, aligner, platform, name = "n") %>%
  filter(n != 1L)
if (nrow(duplicate_keys) > 0L) {
  stop("Reference x aligner x platform keys are not unique at 30x")
}

expected_keys <- expand.grid(
  reference = REFERENCES,
  aligner = ALIGNERS,
  platform = PLATFORMS,
  stringsAsFactors = FALSE
)
observed_keys <- plot_data %>%
  transmute(
    reference = as.character(reference),
    aligner = as.character(aligner),
    platform = as.character(platform)
  )
missing_keys <- anti_join(
  expected_keys,
  observed_keys,
  by = c("reference", "aligner", "platform")
)
unexpected_keys <- anti_join(
  observed_keys,
  expected_keys,
  by = c("reference", "aligner", "platform")
)
if (nrow(missing_keys) > 0L || nrow(unexpected_keys) > 0L) {
  stop("The 30x subset is not the complete symmetric 12-condition matrix")
}

# ---- Descriptive audits ----------------------------------------------------

minimap2_values <- plot_data %>%
  filter(aligner == "minimap2") %>%
  transmute(
    reference = as.character(reference),
    platform = as.character(platform),
    minimap2_bam_size_gib = bam_size_gib
  )
winnowmap_values <- plot_data %>%
  filter(aligner == "winnowmap") %>%
  transmute(
    reference = as.character(reference),
    platform = as.character(platform),
    winnowmap_bam_size_gib = bam_size_gib
  )

paired_values <- inner_join(
  minimap2_values,
  winnowmap_values,
  by = c("reference", "platform")
) %>%
  mutate(
    winnowmap_minus_minimap2_gib =
      winnowmap_bam_size_gib - minimap2_bam_size_gib,
    winnowmap_relative_change_pct =
      100 * winnowmap_minus_minimap2_gib / minimap2_bam_size_gib,
    winnowmap_reduction_pct = -winnowmap_relative_change_pct
  ) %>%
  arrange(
    factor(reference, levels = REFERENCES),
    factor(platform, levels = PLATFORMS)
  )

if (nrow(paired_values) != 6L) {
  stop("Expected six matched reference x platform aligner pairs")
}

platform_ranges <- plot_data %>%
  group_by(platform) %>%
  summarise(
    n_conditions = n(),
    minimum_gib = min(bam_size_gib),
    maximum_gib = max(bam_size_gib),
    range_gib = maximum_gib - minimum_gib,
    .groups = "drop"
  )

hifi_values <- plot_data %>%
  filter(platform == "HiFi") %>%
  transmute(
    reference = as.character(reference),
    aligner = as.character(aligner),
    hifi_bam_size_gib = bam_size_gib
  )

matched_platform_to_hifi <- plot_data %>%
  filter(platform != "HiFi") %>%
  transmute(
    reference = as.character(reference),
    aligner = as.character(aligner),
    platform = as.character(platform),
    platform_bam_size_gib = bam_size_gib
  ) %>%
  inner_join(hifi_values, by = c("reference", "aligner")) %>%
  mutate(
    platform_to_hifi_ratio =
      platform_bam_size_gib / hifi_bam_size_gib
  ) %>%
  arrange(
    factor(reference, levels = REFERENCES),
    factor(aligner, levels = ALIGNERS),
    factor(platform, levels = PLATFORMS)
  )

if (nrow(matched_platform_to_hifi) != 8L) {
  stop("Expected eight matched BGI/ONT-to-HiFi footprint ratios")
}

grch38_values <- plot_data %>%
  filter(reference == "GRCh38") %>%
  transmute(
    aligner = as.character(aligner),
    platform = as.character(platform),
    grch38_bam_size_gib = bam_size_gib
  )
t2t_values <- plot_data %>%
  filter(reference == "T2T-CHM13") %>%
  transmute(
    aligner = as.character(aligner),
    platform = as.character(platform),
    t2t_chm13_bam_size_gib = bam_size_gib
  )

paired_reference_values <- inner_join(
  grch38_values,
  t2t_values,
  by = c("aligner", "platform")
) %>%
  mutate(
    t2t_minus_grch38_gib =
      t2t_chm13_bam_size_gib - grch38_bam_size_gib,
    t2t_relative_change_pct =
      100 * t2t_minus_grch38_gib / grch38_bam_size_gib
  ) %>%
  arrange(
    factor(aligner, levels = ALIGNERS),
    factor(platform, levels = PLATFORMS)
  )

if (nrow(paired_reference_values) != 6L) {
  stop("Expected six matched platform x aligner reference pairs")
}

condition_order <- plot_data %>%
  arrange(reference, aligner, desc(bam_size_gib)) %>%
  group_by(reference, aligner) %>%
  summarise(
    platform_order = paste(as.character(platform), collapse = " > "),
    maximum_gib = max(bam_size_gib),
    minimum_gib = min(bam_size_gib),
    platform_spread_gib = maximum_gib - minimum_gib,
    .groups = "drop"
  )

if (any(condition_order$platform_order != "BGI > ONT > HiFi")) {
  stop("The BAM-footprint platform ordering changed in a mapping condition")
}
if (any(paired_values$winnowmap_minus_minimap2_gib >= 0)) {
  stop("Winnowmap is no longer smaller than minimap2 in every matched pair")
}
if (any(paired_reference_values$t2t_minus_grch38_gib >= 0)) {
  stop("T2T-CHM13 is no longer smaller than GRCh38 in every matched pair")
}

range_value <- function(platform_name, field) {
  platform_ranges[
    as.character(platform_ranges$platform) == platform_name,
    field,
    drop = TRUE
  ]
}

assert_near(range_value("BGI", "minimum_gib"), 90.51, "BGI minimum")
assert_near(range_value("BGI", "maximum_gib"), 109.30, "BGI maximum")
assert_near(range_value("ONT", "minimum_gib"), 81.35, "ONT minimum")
assert_near(range_value("ONT", "maximum_gib"), 102.88, "ONT maximum")
assert_near(range_value("HiFi", "minimum_gib"), 34.45, "HiFi minimum")
assert_near(range_value("HiFi", "maximum_gib"), 41.01, "HiFi maximum")
assert_near(
  min(paired_values$winnowmap_reduction_pct),
  6.638802488336,
  "Minimum winnowmap footprint reduction"
)
assert_near(
  max(paired_values$winnowmap_reduction_pct),
  11.479869423286,
  "Maximum winnowmap footprint reduction"
)
assert_near(
  min(matched_platform_to_hifi$platform_to_hifi_ratio),
  2.361393323657,
  "Minimum matched platform-to-HiFi ratio"
)
assert_near(
  max(matched_platform_to_hifi$platform_to_hifi_ratio),
  2.718875502008,
  "Maximum matched platform-to-HiFi ratio"
)

# ---- Matrix geometry -------------------------------------------------------

matrix_data <- plot_data %>%
  mutate(
    condition_x = case_when(
      reference == "GRCh38" & aligner == "minimap2" ~ 1.00,
      reference == "GRCh38" & aligner == "winnowmap" ~ 2.00,
      reference == "T2T-CHM13" & aligner == "minimap2" ~ 3.25,
      reference == "T2T-CHM13" & aligner == "winnowmap" ~ 4.25,
      TRUE ~ NA_real_
    ),
    platform_y = case_when(
      platform == "BGI" ~ 3,
      platform == "ONT" ~ 2,
      platform == "HiFi" ~ 1,
      TRUE ~ NA_real_
    ),
    track_xmin = condition_x - CELL_WIDTH / 2,
    track_xmax = condition_x + CELL_WIDTH / 2,
    track_ymin = platform_y - CELL_HEIGHT / 2,
    track_ymax = platform_y + CELL_HEIGHT / 2,
    bar_xmin = track_xmin,
    bar_xmax = track_xmin + CELL_WIDTH * bam_size_gib / SCALE_LIMIT_GIB,
    bar_fraction = bam_size_gib / SCALE_LIMIT_GIB,
    value_label = sprintf("%.2f", bam_size_gib),
    label_inside = bam_size_gib >= 65,
    label_x = if_else(label_inside, bar_xmax - 0.035, bar_xmax + 0.040),
    label_hjust = if_else(label_inside, 1, 0),
    bar_colour = unname(PLATFORM_COLOURS[as.character(platform)])
  )

if (any(!is.finite(matrix_data$condition_x)) ||
    any(!is.finite(matrix_data$platform_y))) {
  stop("Failed to map at least one matrix row or column position")
}
if (any(matrix_data$bar_xmax < matrix_data$track_xmin |
        matrix_data$bar_xmax > matrix_data$track_xmax)) {
  stop("At least one BAM bar lies outside its common 0-115 GiB track")
}
if (sum(matrix_data$label_inside) != 8L) {
  stop("Expected eight inside labels and four outside labels")
}

# ---- Traceable outputs -----------------------------------------------------

write_csv(
  plot_data %>%
    mutate(
      reference = as.character(reference),
      aligner = as.character(aligner),
      platform = as.character(platform),
      bam_size_gib = round(bam_size_gib, 4)
    ),
  file.path(OUTPUT_DIR, "source_data_plotted.csv"),
  na = ""
)
write_csv(
  matrix_data %>%
    transmute(
      reference = as.character(reference),
      aligner = as.character(aligner),
      platform = as.character(platform),
      bam_size_gib,
      scale_limit_gib = SCALE_LIMIT_GIB,
      bar_fraction,
      condition_x,
      platform_y,
      track_xmin,
      track_xmax,
      bar_xmin,
      bar_xmax,
      label_inside,
      label_x,
      label_hjust
    ) %>%
    mutate(across(where(is.numeric), ~ round(.x, 6))),
  file.path(OUTPUT_DIR, "matrix_cell_geometry_audit.csv"),
  na = ""
)
write_csv(
  paired_values %>% mutate(across(where(is.numeric), ~ round(.x, 6))),
  file.path(OUTPUT_DIR, "paired_aligner_differences.csv"),
  na = ""
)
write_csv(
  paired_reference_values %>%
    mutate(across(where(is.numeric), ~ round(.x, 6))),
  file.path(OUTPUT_DIR, "paired_reference_differences.csv"),
  na = ""
)
write_csv(
  platform_ranges %>%
    mutate(
      platform = as.character(platform),
      across(where(is.numeric), ~ round(.x, 6))
    ),
  file.path(OUTPUT_DIR, "platform_range_audit.csv"),
  na = ""
)
write_csv(
  matched_platform_to_hifi %>%
    mutate(across(where(is.numeric), ~ round(.x, 6))),
  file.path(OUTPUT_DIR, "matched_platform_to_hifi_ratios.csv"),
  na = ""
)
write_csv(
  condition_order %>%
    mutate(
      reference = as.character(reference),
      aligner = as.character(aligner),
      across(where(is.numeric), ~ round(.x, 6))
    ),
  file.path(OUTPUT_DIR, "condition_platform_order_audit.csv"),
  na = ""
)

data_audit <- data.frame(
  source_file = basename(INPUT_FILE),
  source_rows = n_source,
  selected_depth = "30x",
  selected_rows = nrow(plot_data),
  excluded_non_30x_rows = n_source - nrow(plot_data),
  expected_unique_keys = 12L,
  observed_unique_keys = nrow(distinct(
    plot_data, reference, aligner, platform
  )),
  plotted_cells = nrow(matrix_data),
  common_scale_gib = paste0("0-", SCALE_LIMIT_GIB),
  transform_platform = "remove terminal _latest suffix",
  transform_bam_size = "none; source values are already GiB",
  filter_rule = "Depth == 30x; one row per reference x aligner x platform",
  geometry = paste(
    "3 x 4 in-cell horizontal-bar matrix; common zero baseline;",
    "exact value in every cell; no points or connectors"
  ),
  replicate_statement = paste(
    "one HG002 30x technical subset per platform; mapping conditions are not",
    "biological replicates"
  ),
  stringsAsFactors = FALSE
)
write_csv(
  data_audit,
  file.path(OUTPUT_DIR, "data_filter_audit.csv"),
  na = ""
)

# ---- Figure ----------------------------------------------------------------

scale_key_start <- 2.195
scale_key_end <- scale_key_start + CELL_WIDTH
scale_key_breaks <- c(0, 60, 115)
scale_key_data <- data.frame(
  value = scale_key_breaks,
  x = scale_key_start +
    CELL_WIDTH * scale_key_breaks / SCALE_LIMIT_GIB,
  label = as.character(scale_key_breaks)
)

panel_e_plot <- ggplot(matrix_data) +
  geom_rect(
    aes(
      xmin = track_xmin,
      xmax = track_xmax,
      ymin = track_ymin,
      ymax = track_ymax
    ),
    fill = "#EEF1F2",
    colour = "#D7D7D7",
    linewidth = 0.24
  ) +
  geom_rect(
    aes(
      xmin = bar_xmin,
      xmax = bar_xmax,
      ymin = track_ymin,
      ymax = track_ymax,
      fill = bar_colour
    ),
    colour = NA
  ) +
  geom_text(
    aes(
      x = label_x,
      y = platform_y,
      label = value_label,
      hjust = label_hjust
    ),
    family = BASE_FAMILY,
    fontface = "bold",
    size = 1.96,
    colour = "#171717"
  ) +
  annotate(
    "text", x = 1.50, y = 3.78, label = "GRCh38 30×",
    family = BASE_FAMILY, fontface = "bold", size = 2.54,
    colour = "#111111"
  ) +
  annotate(
    "text", x = 3.75, y = 3.78, label = "T2T-CHM13 30×",
    family = BASE_FAMILY, fontface = "bold", size = 2.54,
    colour = "#111111"
  ) +
  annotate(
    "segment", x = 0.56, xend = 2.44, y = 3.49, yend = 3.49,
    colour = "#D7D7D7", linewidth = 0.34
  ) +
  annotate(
    "segment", x = 2.81, xend = 4.69, y = 3.49, yend = 3.49,
    colour = "#D7D7D7", linewidth = 0.34
  ) +
  annotate(
    "text",
    x = c(1.00, 2.00, 3.25, 4.25),
    y = 0.50,
    label = c("minimap2", "winnowmap", "minimap2", "winnowmap"),
    family = BASE_FAMILY,
    size = 2.12,
    colour = "#292929"
  ) +
  annotate(
    "text", x = mean(c(scale_key_start, scale_key_end)), y = 0.12,
    label = "BAM output footprint (GiB)",
    family = BASE_FAMILY, fontface = "bold", size = 2.26,
    colour = "#222222"
  ) +
  annotate(
    "segment",
    x = scale_key_start, xend = scale_key_end,
    y = -0.08, yend = -0.08,
    colour = "#D4D8DA", linewidth = 2.20, lineend = "butt"
  ) +
  geom_segment(
    data = scale_key_data,
    aes(x = x, xend = x, y = -0.15, yend = -0.01),
    inherit.aes = FALSE,
    colour = "#FFFFFF",
    linewidth = 0.30
  ) +
  geom_text(
    data = scale_key_data,
    aes(x = x, y = -0.31, label = label),
    inherit.aes = FALSE,
    family = BASE_FAMILY,
    size = 1.98,
    colour = "#292929"
  ) +
  scale_fill_identity() +
  scale_x_continuous(
    limits = c(0.08, 4.72),
    expand = expansion(mult = 0)
  ) +
  scale_y_continuous(
    breaks = c(3, 2, 1),
    labels = PLATFORMS,
    limits = c(-0.48, 3.94),
    expand = expansion(mult = 0)
  ) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = NULL) +
  theme_void(base_size = 6.7, base_family = BASE_FAMILY) +
  theme(
    axis.text.y = element_text(
      colour = "#171717", size = 6.4, face = "bold",
      margin = margin(r = 4.0)
    ),
    plot.margin = margin(1.5, 2.0, 1.0, 2.0, unit = "mm")
  )

draw_panel_e <- function() {
  print(panel_e_plot)
}

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
draw_panel_e()
grDevices::dev.off()

grDevices::cairo_pdf(
  pdf_path,
  width = width_in,
  height = height_in,
  family = BASE_FAMILY,
  bg = "white",
  onefile = TRUE
)
draw_panel_e()
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
draw_panel_e()
grDevices::dev.off()

ragg::agg_png(
  png_path,
  width = WIDTH_MM,
  height = HEIGHT_MM,
  units = "mm",
  res = PNG_DPI,
  background = "white"
)
draw_panel_e()
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
  selected_rows = nrow(plot_data),
  plotted_cells = nrow(matrix_data),
  plotted_references = length(REFERENCES),
  geometry = paste(
    "3 x 4 in-cell horizontal-bar matrix; exact values;",
    "one common zero-based 0-115 GiB scale"
  ),
  row_encoding = "platform: BGI, ONT, HiFi; fixed platform-coloured bars",
  column_encoding = paste(
    "GRCh38 minimap2, GRCh38 winnowmap, T2T-CHM13 minimap2,",
    "T2T-CHM13 winnowmap"
  ),
  point_geometries = 0L,
  connector_geometries = 0L,
  bytes = as.numeric(file.info(rendered_paths)$size),
  md5 = unname(tools::md5sum(rendered_paths)),
  stringsAsFactors = FALSE
)
write_csv(
  render_manifest,
  file.path(OUTPUT_DIR, "render_manifest.csv"),
  na = ""
)

message("Rendered revised Panel e to: ", OUTPUT_DIR)
message("Plotted BAM-footprint cells: ", nrow(matrix_data), " / 12")
message("Point geometries: 0")
message("Connector segments: 0")
message("Font family: ", BASE_FAMILY)
