#!/usr/bin/env Rscript

# =============================================================================
# Panel e: BAM output footprint at the matched 30x condition
#
# Scientific contract
#   Claim      : under the current unified alignment and BAM-output workflow,
#                30x BAM storage footprint differs substantially by platform
#                and modestly but consistently by aligner.
#   Role       : operational evidence, defaulting to Extended Data and retained
#                as a possible main-figure replacement panel.
#   Evidence   : all 12 strict-30x platform x reference x aligner conditions.
#   Archetype  : two-facet matched-condition dot plot.
#   Encoding   : row and colour = platform; point shape = aligner; neutral
#                segment = matched aligner pair within platform and reference.
#   Integrity  : no aggregation, jitter, smoothing, uncertainty, test or
#                p-value; BAM size is reported on a zero-based GiB axis.
#   Reuse      : structural adaptation of the confirmed Panel d matched-condition
#                geometry, with metric-specific data guards and axis contract.
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
PLATFORM_Y_LEVELS <- rev(PLATFORMS)

PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)
ALIGNER_SHAPES <- c(
  minimap2 = 16,
  winnowmap = 5
)

WIDTH_MM = 183
HEIGHT_MM = 38
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

assert_near <- function(observed, expected, label, tolerance = 1e-8) {
  if (length(observed) != 1L || !is.finite(observed) ||
      abs(observed - expected) > tolerance) {
    stop(
      label, " changed: expected ", expected, "; observed ", observed
    )
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
      levels = PLATFORM_Y_LEVELS
    ),
    depth_label = Depth,
    nominal_depth_x = as.numeric(sub("x$", "", Depth)),
    bam_size_gib = as.numeric(`BAM size GiB`)
  ) %>%
  filter(depth_label == "30x") %>%
  arrange(reference, desc(as.integer(platform)), aligner)

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
        plot_data$bam_size_gib > 115)) {
  stop("BAM sizes must be finite and lie inside the declared 0-115 GiB axis")
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

# ---- Matched-pair and operational audits ----------------------------------

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
    reference = factor(reference, levels = REFERENCES),
    platform = factor(platform, levels = PLATFORM_Y_LEVELS),
    winnowmap_minus_minimap2_gib =
      winnowmap_bam_size_gib - minimap2_bam_size_gib,
    winnowmap_relative_change_pct =
      100 * winnowmap_minus_minimap2_gib / minimap2_bam_size_gib,
    winnowmap_reduction_pct = -winnowmap_relative_change_pct
  ) %>%
  arrange(reference, desc(as.integer(platform)))

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
  ) %>%
  arrange(desc(as.integer(platform)))

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
  arrange(reference, platform, aligner)

if (nrow(matched_platform_to_hifi) != 8L) {
  stop("Expected eight matched BGI/ONT-to-HiFi footprint ratios")
}

range_value <- function(platform_name, field) {
  platform_ranges[
    as.character(platform_ranges$platform) == platform_name,
    field,
    drop = TRUE
  ]
}

# Guards link the plotted matrix to the confirmed operational summary.
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
  paired_values %>%
    mutate(
      reference = as.character(reference),
      platform = as.character(platform),
      across(where(is.numeric), ~ round(.x, 6))
    ),
  file.path(OUTPUT_DIR, "paired_aligner_differences.csv"),
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
  matched_aligner_pairs = nrow(paired_values),
  transform_platform = "remove terminal _latest suffix",
  transform_bam_size = "none; source values are already GiB",
  filter_rule = "Depth == 30x; one row per reference x aligner x platform",
  exclusion_reason = paste(
    "Panel e is the prespecified matched 30x footprint comparison;",
    "full depth response is reserved for Extended Data 2"
  ),
  replicate_statement = paste(
    "one HG002 30x technical subset per platform; conditions are not",
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

theme_bam_footprint <- function(
    base_size = 6.3,
    base_family = BASE_FAMILY
) {
  theme_classic(base_size = base_size, base_family = base_family) +
    theme(
      axis.line.x = element_line(colour = "#252525", linewidth = 0.30),
      axis.line.y = element_blank(),
      axis.ticks.x = element_line(colour = "#252525", linewidth = 0.30),
      axis.ticks.y = element_blank(),
      axis.ticks.length.x = unit(1.0, "mm"),
      axis.title.x = element_text(
        colour = "#202020", size = 6.3, margin = margin(t = 1.5)
      ),
      axis.title.y = element_blank(),
      axis.text.x = element_text(
        colour = "#4D4D4D", size = 5.7, margin = margin(t = 0.8)
      ),
      axis.text.y = element_text(
        colour = "#252525", size = 6.2, face = "bold",
        margin = margin(r = 1.4)
      ),
      strip.background = element_blank(),
      strip.text = element_text(
        colour = "#202020", size = 6.5, face = "bold",
        margin = margin(b = 1.3)
      ),
      panel.grid.major.x = element_line(
        colour = "#E9E9E9", linewidth = 0.25
      ),
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      panel.spacing.x = unit(7.0, "mm"),
      legend.position = "top",
      legend.justification = "center",
      legend.direction = "horizontal",
      legend.title = element_text(
        colour = "#252525", size = 5.8, face = "bold"
      ),
      legend.text = element_text(colour = "#333333", size = 5.7),
      legend.key = element_blank(),
      legend.key.width = unit(5.0, "mm"),
      legend.key.height = unit(2.6, "mm"),
      legend.spacing.x = unit(0.8, "mm"),
      legend.margin = margin(0, 0, 0.8, 0, unit = "mm"),
      plot.margin = margin(1.2, 2.0, 1.2, 1.8, unit = "mm")
    )
}

p <- ggplot(
  plot_data,
  aes(
    x = bam_size_gib,
    y = platform,
    colour = platform,
    shape = aligner
  )
) +
  geom_segment(
    data = paired_values,
    aes(
      x = minimap2_bam_size_gib,
      xend = winnowmap_bam_size_gib,
      y = platform,
      yend = platform
    ),
    inherit.aes = FALSE,
    colour = "#B8B8B8",
    linewidth = 0.42,
    lineend = "round"
  ) +
  geom_point(
    colour = "#3D3D3D",
    size = 2.25,
    stroke = 0.58,
    show.legend = FALSE
  ) +
  geom_point(size = 1.75, stroke = 0.44) +
  facet_grid(cols = vars(reference)) +
  scale_colour_manual(
    values = PLATFORM_COLOURS,
    breaks = PLATFORMS,
    limits = PLATFORMS,
    drop = FALSE,
    guide = "none"
  ) +
  scale_shape_manual(
    name = "Aligner",
    values = ALIGNER_SHAPES,
    breaks = ALIGNERS,
    limits = ALIGNERS,
    drop = FALSE
  ) +
  scale_x_continuous(
    name = "BAM output footprint (GiB)",
    limits = c(0, 115),
    breaks = seq(0, 100, by = 20),
    expand = expansion(mult = 0)
  ) +
  scale_y_discrete(
    limits = PLATFORM_Y_LEVELS,
    drop = FALSE,
    expand = expansion(add = 0.42)
  ) +
  guides(
    shape = guide_legend(
      nrow = 1,
      byrow = TRUE,
      override.aes = list(
        colour = "#333333",
        size = 1.9,
        stroke = 0.5
      )
    )
  ) +
  theme_bam_footprint()

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
  selected_rows = nrow(plot_data),
  matched_pairs = nrow(paired_values),
  bytes = as.numeric(file.info(rendered_paths)$size),
  md5 = unname(tools::md5sum(rendered_paths)),
  stringsAsFactors = FALSE
)
write_csv(
  render_manifest,
  file.path(OUTPUT_DIR, "render_manifest.csv"),
  na = ""
)

message("Rendered Panel e to: ", OUTPUT_DIR)
message("Selected rows: ", nrow(plot_data), " / ", n_source)
message("Matched aligner pairs: ", nrow(paired_values))
message("Font family: ", BASE_FAMILY)
