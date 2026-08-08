#!/usr/bin/env Rscript

# =============================================================================
# Panel d: primary mapped-read rate across mapping conditions at 30x
#
# Scientific contract
#   Claim      : read-level primary mapping retention remains platform-specific
#                across both reference genomes and both aligners at matched 30x.
#   Role       : add a read-level mapping outcome after Panel c reports the
#                position-level coverage-breadth response.
#   Evidence   : all 12 strict-30x platform x reference x aligner conditions.
#   Archetype  : compact 3 x 4 annotated heatmap.
#   Encoding   : rows = platform; columns = reference x aligner; sequential
#                fill and exact cell labels = primary mapped-read rate.
#   Integrity  : no coverage-breadth reuse, aggregation, connector, ranking
#                badge, uncertainty interval, test or p-value.
#   Reuse      : inherit the Panel c palette accents, typography, title weight,
#                white background and export contract.
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
  ROOT, "figures", "reads_alignment_qc", "panel_d_primary_mapped_rate"
)
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

REFERENCES <- c("GRCh38", "T2T-CHM13")
ALIGNERS <- c("minimap2", "winnowmap")
PLATFORMS <- c("BGI", "ONT", "HiFi")
PANEL_TITLES <- c(
  GRCh38 = "GRCh38 30×",
  `T2T-CHM13` = "T2T-CHM13 30×"
)

PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)

FILL_LIMITS <- c(97.9, 100.0)

WIDTH_MM = 89
HEIGHT_MM = 54
PNG_DPI = 320
TIFF_DPI = 600
OUTPUT_STEM <- "primary_mapped_read_rate_30x"

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
  "参考基因组", "Aligner", "Dataset", "Depth", "Primary mapped rate"
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
    primary_mapped_fraction = as.numeric(`Primary mapped rate`),
    primary_mapped_pct = 100 * primary_mapped_fraction,
    aligner_index = as.numeric(aligner)
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
  stop("Panel d must contain only the prespecified nominal 30x observations")
}
if (any(!is.finite(plot_data$primary_mapped_fraction)) ||
    any(plot_data$primary_mapped_fraction < 0 |
        plot_data$primary_mapped_fraction > 1)) {
  stop("Primary mapped-read fractions must be finite and lie in [0, 1]")
}
if (any(plot_data$primary_mapped_pct < FILL_LIMITS[1] |
        plot_data$primary_mapped_pct > FILL_LIMITS[2])) {
  stop("At least one primary mapped-read value lies outside the fill scale")
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

# ---- Transformation and descriptive audits --------------------------------

minimap2_values <- plot_data %>%
  filter(aligner == "minimap2") %>%
  transmute(
    reference = as.character(reference),
    platform = as.character(platform),
    minimap2_primary_mapped_pct = primary_mapped_pct
  )
winnowmap_values <- plot_data %>%
  filter(aligner == "winnowmap") %>%
  transmute(
    reference = as.character(reference),
    platform = as.character(platform),
    winnowmap_primary_mapped_pct = primary_mapped_pct
  )

paired_values <- inner_join(
  minimap2_values,
  winnowmap_values,
  by = c("reference", "platform")
) %>%
  mutate(
    winnowmap_minus_minimap2_pp =
      winnowmap_primary_mapped_pct - minimap2_primary_mapped_pct,
    absolute_aligner_difference_pp = abs(winnowmap_minus_minimap2_pp)
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
    minimum_primary_mapped_pct = min(primary_mapped_pct),
    maximum_primary_mapped_pct = max(primary_mapped_pct),
    primary_mapped_range_pp =
      maximum_primary_mapped_pct - minimum_primary_mapped_pct,
    .groups = "drop"
  )

reference_ranges <- plot_data %>%
  group_by(reference) %>%
  summarise(
    n_conditions = n(),
    minimum_primary_mapped_pct = min(primary_mapped_pct),
    maximum_primary_mapped_pct = max(primary_mapped_pct),
    primary_mapped_range_pp =
      maximum_primary_mapped_pct - minimum_primary_mapped_pct,
    .groups = "drop"
  )

condition_order <- plot_data %>%
  arrange(reference, aligner, desc(primary_mapped_pct)) %>%
  group_by(reference, aligner) %>%
  summarise(
    platform_order = paste(as.character(platform), collapse = " > "),
    highest_primary_mapped_pct = max(primary_mapped_pct),
    lowest_primary_mapped_pct = min(primary_mapped_pct),
    platform_spread_pp =
      highest_primary_mapped_pct - lowest_primary_mapped_pct,
    .groups = "drop"
  )

if (any(condition_order$platform_order != "HiFi > BGI > ONT")) {
  stop("The platform ordering changed in at least one mapping condition")
}

# Guards tie the plot to the confirmed 30x experimental matrix.
assert_near(
  platform_ranges$minimum_primary_mapped_pct[
    platform_ranges$platform == "BGI"
  ],
  99.02,
  "BGI minimum primary mapped-read rate"
)
assert_near(
  platform_ranges$maximum_primary_mapped_pct[
    platform_ranges$platform == "BGI"
  ],
  99.69,
  "BGI maximum primary mapped-read rate"
)
assert_near(
  platform_ranges$minimum_primary_mapped_pct[
    platform_ranges$platform == "ONT"
  ],
  97.94,
  "ONT minimum primary mapped-read rate"
)
assert_near(
  platform_ranges$maximum_primary_mapped_pct[
    platform_ranges$platform == "ONT"
  ],
  98.34,
  "ONT maximum primary mapped-read rate"
)
assert_near(
  platform_ranges$minimum_primary_mapped_pct[
    platform_ranges$platform == "HiFi"
  ],
  99.92,
  "HiFi minimum primary mapped-read rate"
)
assert_near(
  platform_ranges$maximum_primary_mapped_pct[
    platform_ranges$platform == "HiFi"
  ],
  100.00,
  "HiFi maximum primary mapped-read rate"
)
assert_near(
  max(paired_values$absolute_aligner_difference_pp),
  0.36,
  "Maximum matched aligner difference"
)

write_csv(
  plot_data %>%
    mutate(
      reference = as.character(reference),
      aligner = as.character(aligner),
      platform = as.character(platform),
      primary_mapped_pct = round(primary_mapped_pct, 4)
    ),
  file.path(OUTPUT_DIR, "source_data_plotted.csv"),
  na = ""
)
write_csv(
  paired_values %>% mutate(across(where(is.numeric), ~ round(.x, 6))),
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
  reference_ranges %>%
    mutate(
      reference = as.character(reference),
      across(where(is.numeric), ~ round(.x, 6))
    ),
  file.path(OUTPUT_DIR, "reference_range_audit.csv"),
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
  plotted_cells = nrow(plot_data),
  transform_platform = "remove terminal _latest suffix",
  transform_primary_mapped = "100 x Primary mapped rate fraction",
  filter_rule = "Depth == 30x; one row per reference x aligner x platform",
  geometry = paste(
    "3 x 4 annotated heatmap; exact cell values;",
    "no coverage reuse, connectors, aggregation or fitted trends"
  ),
  exclusion_reason = paste(
    "Panel d is the prespecified matched-30x primary-retention view;",
    "depth response and coverage breadth are reported in Panel c"
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

heatmap_data <- plot_data %>%
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
    value_label = sprintf("%.2f%%", primary_mapped_pct),
    label_colour = if_else(
      primary_mapped_pct >= 99.15, "#FFFFFF", "#182126"
    )
  )

if (any(!is.finite(heatmap_data$condition_x)) ||
    any(!is.finite(heatmap_data$platform_y))) {
  stop("Failed to map at least one heatmap row or column position")
}

platform_markers <- heatmap_data %>%
  distinct(platform, platform_y) %>%
  mutate(marker_colour = unname(PLATFORM_COLOURS[as.character(platform)]))

panel_d_plot <- ggplot(
  heatmap_data,
  aes(x = condition_x, y = platform_y)
) +
  geom_tile(
    aes(fill = primary_mapped_pct),
    width = 0.88,
    height = 0.82,
    colour = "#FFFFFF",
    linewidth = 0.48
  ) +
  geom_text(
    aes(label = value_label, colour = label_colour),
    family = BASE_FAMILY,
    fontface = "bold",
    size = 2.02,
    show.legend = FALSE
  ) +
  geom_point(
    data = platform_markers,
    aes(x = 0.28, y = platform_y, colour = marker_colour),
    inherit.aes = FALSE,
    size = 1.70,
    shape = 16,
    show.legend = FALSE
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
  scale_x_continuous(
    breaks = c(1.00, 2.00, 3.25, 4.25),
    labels = c("minimap2", "winnowmap", "minimap2", "winnowmap"),
    limits = c(0.08, 4.72),
    expand = expansion(mult = 0)
  ) +
  scale_y_continuous(
    breaks = c(3, 2, 1),
    labels = PLATFORMS,
    limits = c(0.52, 3.94),
    expand = expansion(mult = 0)
  ) +
  scale_fill_gradientn(
    name = "Primary mapped-read rate",
    colours = c("#F0F3F4", "#C4D2D7", "#7596A1", "#294F5B"),
    values = scales::rescale(c(97.9, 98.5, 99.3, 100.0)),
    limits = FILL_LIMITS,
    breaks = c(98, 99, 100),
    labels = c("98%", "99%", "100%"),
    oob = scales::squish,
    guide = guide_colourbar(
      title.position = "top",
      title.hjust = 0.5,
      barwidth = unit(34, "mm"),
      barheight = unit(2.2, "mm"),
      ticks = FALSE,
      frame.colour = NA
    )
  ) +
  scale_colour_identity() +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = NULL) +
  theme_void(base_size = 6.7, base_family = BASE_FAMILY) +
  theme(
    axis.text.x = element_text(
      colour = "#292929", size = 6.0, margin = margin(t = 1.5)
    ),
    axis.text.y = element_text(
      colour = "#171717", size = 6.4, face = "bold",
      margin = margin(r = 4.0)
    ),
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title = element_text(
      colour = "#222222", size = 6.4, face = "bold",
      margin = margin(b = 1.0)
    ),
    legend.text = element_text(colour = "#292929", size = 5.8),
    legend.margin = margin(1.0, 0, 0, 0, unit = "mm"),
    legend.box.spacing = unit(0.5, "mm"),
    plot.margin = margin(1.5, 2.0, 1.0, 2.0, unit = "mm")
  )

draw_panel_d <- function() {
  print(panel_d_plot)
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
draw_panel_d()
grDevices::dev.off()

grDevices::cairo_pdf(
  pdf_path,
  width = width_in,
  height = height_in,
  family = BASE_FAMILY,
  bg = "white",
  onefile = TRUE
)
draw_panel_d()
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
draw_panel_d()
grDevices::dev.off()

ragg::agg_png(
  png_path,
  width = WIDTH_MM,
  height = HEIGHT_MM,
  units = "mm",
  res = PNG_DPI,
  background = "white"
)
draw_panel_d()
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
  plotted_cells = nrow(plot_data),
  plotted_references = length(REFERENCES),
  geometry = "3 x 4 annotated heatmap; exact values in every cell",
  row_encoding = "platform: BGI, ONT, HiFi with fixed colour markers",
  column_encoding = paste(
    "GRCh38 minimap2, GRCh38 winnowmap, T2T-CHM13 minimap2,",
    "T2T-CHM13 winnowmap"
  ),
  fill_scale = "primary mapped-read rate; 97.9-100.0%; sequential blue-grey",
  bytes = as.numeric(file.info(rendered_paths)$size),
  md5 = unname(tools::md5sum(rendered_paths)),
  stringsAsFactors = FALSE
)
write_csv(
  render_manifest,
  file.path(OUTPUT_DIR, "render_manifest.csv"),
  na = ""
)

message("Rendered revised Panel d to: ", OUTPUT_DIR)
message("Plotted primary-rate cells: ", nrow(plot_data), " / 12")
message("Coverage-breadth values reused: 0")
message("Connector segments: 0")
message("Font family: ", BASE_FAMILY)
