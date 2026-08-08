#!/usr/bin/env Rscript

# =============================================================================
# Panel a: nested input-depth rulers for HG002 read subsets
#
# Scientific contract
#   Claim      : the 10x and 30x inputs are depth matched across platforms;
#                BGI and HiFi also reach 50x, whereas the ONT nominal-50x
#                subset contains 47.768x of available sequence yield.
#   Role       : experimental-design evidence, not a platform ranking panel.
#   Evidence   : all nine platform x target-depth observations.
#   Archetype  : compact nested-depth ruler.
#   Encoding   : one horizontal platform-coloured ruler per platform; internal
#                boundaries = achieved 10x and 30x subsets; endpoint = achieved
#                highest-depth subset; grey guides = 10x, 30x and 50x targets.
#   Integrity  : all nine observed depths are encoded and directly labelled;
#                no aggregation, overlap, jitter, smoothing or inference.
#   Reuse      : build the geometry anew; inherit the project palette,
#                Panel c typography, pale-guide styling and export contract.
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
  ROOT, "figures", "reads_alignment_qc", "panel_a_input_depth"
)
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

PLATFORMS <- c("BGI", "ONT", "HiFi")
TARGET_DEPTHS <- c(10, 30, 50)
PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)

WIDTH_MM = 60
HEIGHT_MM = 34
PNG_DPI = 320
TIFF_DPI = 600
OUTPUT_STEM <- "approximate_input_depth"

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
  "Approx coverage", "Status"
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

plot_data <- raw %>%
  transmute(
    source_dataset = Dataset,
    platform = sub("_latest$", "", Dataset),
    depth_label = Depth,
    target_input_depth_x = as.numeric(sub("x$", "", Depth)),
    approximate_input_depth_x = as.numeric(`Approx coverage`),
    delta_from_target_x = round(
      approximate_input_depth_x - target_input_depth_x,
      digits = 3
    ),
    reads = as.numeric(Reads),
    total_bases = as.numeric(`Total bases`),
    yield_gb = as.numeric(`Yield (Gb)`),
    status = Status
  ) %>%
  mutate(
    platform = factor(platform, levels = PLATFORMS),
    depth_label = factor(
      depth_label,
      levels = paste0(TARGET_DEPTHS, "x")
    )
  ) %>%
  arrange(platform, target_input_depth_x)

if (any(is.na(plot_data$platform))) {
  stop("Unexpected platform label in reads QC")
}
if (!setequal(plot_data$target_input_depth_x, TARGET_DEPTHS)) {
  stop("Unexpected target-depth levels in reads QC")
}
if (any(!is.finite(plot_data$approximate_input_depth_x)) ||
    any(plot_data$approximate_input_depth_x <= 0)) {
  stop("Approximate input depths must be finite and positive")
}
if (any(plot_data$status != "OK")) {
  stop("At least one reads-QC row is not marked OK")
}

duplicate_keys <- plot_data %>%
  count(platform, target_input_depth_x, name = "n") %>%
  filter(n != 1L)
if (nrow(duplicate_keys) > 0L) {
  stop("Platform x target-depth keys are not unique")
}

expected_keys <- expand.grid(
  platform = PLATFORMS,
  target_input_depth_x = TARGET_DEPTHS,
  stringsAsFactors = FALSE
)
observed_keys <- plot_data %>%
  transmute(
    platform = as.character(platform),
    target_input_depth_x = target_input_depth_x
  )
missing_keys <- anti_join(
  expected_keys,
  observed_keys,
  by = c("platform", "target_input_depth_x")
)
if (nrow(missing_keys) > 0L) {
  stop("Incomplete symmetric 3-platform x 3-depth input matrix")
}

ont_50 <- plot_data %>%
  filter(platform == "ONT", target_input_depth_x == 50)
if (nrow(ont_50) != 1L ||
    !isTRUE(all.equal(ont_50$approximate_input_depth_x, 47.768))) {
  stop("ONT nominal-50x observation is missing or has changed")
}

write_csv(
  plot_data %>% mutate(platform = as.character(platform)),
  file.path(OUTPUT_DIR, "source_data_plotted.csv"),
  na = ""
)

audit <- data.frame(
  source_file = basename(INPUT_FILE),
  source_rows = n_source,
  plotted_rows = nrow(plot_data),
  excluded_rows = n_source - nrow(plot_data),
  expected_unique_keys = 9L,
  observed_unique_keys = nrow(distinct(plot_data, platform, target_input_depth_x)),
  transform_platform = "remove terminal _latest suffix",
  transform_depth = "remove terminal x suffix and parse numeric",
  transform_delta = "approximate_input_depth_x - target_input_depth_x",
  filter_rule = "none; all nine reads-QC observations plotted",
  archetype = "three-row nested-depth ruler",
  plotted_segments = 9L,
  platform_rows = 3L,
  replicate_statement = "nested technical depth subsets; not independent replicates",
  stringsAsFactors = FALSE
)
write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"), na = "")

# ---- Nested-ruler mapping --------------------------------------------------

PLATFORM_Y <- c(BGI = 3, ONT = 2, HiFi = 1)
PLATFORM_LABEL_COLOURS <- c(
  BGI = "#1C1C1C",
  ONT = "#10282A",
  HiFi = "#FFFFFF"
)

nested_summary <- plot_data %>%
  group_by(platform) %>%
  summarise(
    depth_10x = approximate_input_depth_x[target_input_depth_x == 10],
    depth_30x = approximate_input_depth_x[target_input_depth_x == 30],
    depth_highest = approximate_input_depth_x[target_input_depth_x == 50],
    .groups = "drop"
  ) %>%
  mutate(platform_y = unname(PLATFORM_Y[as.character(platform)]))

if (nrow(nested_summary) != 3L ||
    any(!is.finite(nested_summary$platform_y))) {
  stop("Expected one complete nested-depth ruler per platform")
}
if (any(nested_summary$depth_10x >= nested_summary$depth_30x) ||
    any(nested_summary$depth_30x >= nested_summary$depth_highest)) {
  stop("Nested input-depth boundaries must be strictly increasing")
}

segment_data <- bind_rows(
  nested_summary %>%
    transmute(
      platform, platform_y,
      target_depth_x = 10,
      segment_start_x = 0,
      segment_end_x = depth_10x
    ),
  nested_summary %>%
    transmute(
      platform, platform_y,
      target_depth_x = 30,
      segment_start_x = depth_10x,
      segment_end_x = depth_30x
    ),
  nested_summary %>%
    transmute(
      platform, platform_y,
      target_depth_x = 50,
      segment_start_x = depth_30x,
      segment_end_x = depth_highest
    )
) %>%
  mutate(
    achieved_depth_x = segment_end_x,
    incremental_depth_x = segment_end_x - segment_start_x,
    delta_from_target_x = achieved_depth_x - target_depth_x,
    target_attainment_pct = 100 * achieved_depth_x / target_depth_x,
    value_label = sprintf("%.3f×", achieved_depth_x),
    value_label_x = segment_end_x - 0.45,
    value_label_colour = unname(
      PLATFORM_LABEL_COLOURS[as.character(platform)]
    )
  ) %>%
  arrange(platform, target_depth_x)

if (nrow(segment_data) != 9L ||
    any(segment_data$incremental_depth_x <= 0)) {
  stop("Expected nine positive nested ruler segments")
}

write_csv(
  segment_data %>%
    mutate(
      platform = as.character(platform),
      across(where(is.numeric), ~ round(.x, 6))
    ),
  file.path(OUTPUT_DIR, "nested_depth_ruler_audit.csv"),
  na = ""
)

# ---- Figure ---------------------------------------------------------------

track_data <- nested_summary %>%
  transmute(
    platform,
    platform_y,
    track_start_x = 0,
    track_end_x = 50
  )

separator_data <- segment_data %>%
  filter(target_depth_x %in% c(10, 30)) %>%
  transmute(
    platform,
    platform_y,
    boundary_x = achieved_depth_x
  )

target_guides <- data.frame(
  target_depth_x = c(10, 30, 50),
  target_label = c("10×", "30×", "50×"),
  label_hjust = c(0.5, 0.5, 1.0)
)

p <- ggplot() +
  geom_segment(
    data = target_guides,
    aes(
      x = target_depth_x,
      xend = target_depth_x,
      y = 0.62,
      yend = 3.38
    ),
    inherit.aes = FALSE,
    colour = "#D7D7D7",
    linewidth = 0.34
  ) +
  geom_rect(
    data = track_data,
    aes(
      xmin = track_start_x,
      xmax = track_end_x,
      ymin = platform_y - 0.29,
      ymax = platform_y + 0.29
    ),
    inherit.aes = FALSE,
    fill = "#F1F1F1",
    colour = "#D2D2D2",
    linewidth = 0.25
  ) +
  geom_rect(
    data = segment_data,
    aes(
      xmin = segment_start_x,
      xmax = segment_end_x,
      ymin = platform_y - 0.28,
      ymax = platform_y + 0.28,
      fill = platform
    ),
    inherit.aes = FALSE,
    colour = NA
  ) +
  geom_segment(
    data = separator_data,
    aes(
      x = boundary_x,
      xend = boundary_x,
      y = platform_y - 0.28,
      yend = platform_y + 0.28
    ),
    inherit.aes = FALSE,
    colour = "#FFFFFF",
    linewidth = 0.52
  ) +
  geom_text(
    data = segment_data,
    aes(
      x = value_label_x,
      y = platform_y,
      label = value_label,
      colour = value_label_colour
    ),
    inherit.aes = FALSE,
    hjust = 1,
    vjust = 0.5,
    family = BASE_FAMILY,
    fontface = "bold",
    size = 1.80,
    show.legend = FALSE
  ) +
  geom_text(
    data = target_guides,
    aes(
      x = target_depth_x,
      y = 3.53,
      label = target_label,
      hjust = label_hjust
    ),
    inherit.aes = FALSE,
    vjust = 0,
    family = BASE_FAMILY,
    size = 1.98,
    colour = "#333333"
  ) +
  annotate(
    "text",
    x = 25,
    y = 3.98,
    label = "Target input depth",
    family = BASE_FAMILY,
    fontface = "bold",
    size = 2.26,
    colour = "#171717"
  ) +
  scale_fill_manual(
    values = PLATFORM_COLOURS,
    breaks = PLATFORMS,
    limits = PLATFORMS,
    drop = FALSE,
    guide = "none"
  ) +
  scale_colour_identity() +
  scale_x_continuous(
    limits = c(0, 50.25),
    expand = expansion(mult = 0)
  ) +
  scale_y_continuous(
    breaks = c(3, 2, 1),
    labels = PLATFORMS,
    limits = c(0.50, 4.12),
    expand = expansion(mult = 0)
  ) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = NULL) +
  theme_void(base_size = 6.4, base_family = BASE_FAMILY) +
  theme(
    axis.text.y = element_text(
      colour = "#171717",
      size = 6.2,
      face = "bold",
      margin = margin(r = 2.2)
    ),
    plot.margin = margin(1.0, 1.5, 0.7, 1.3, unit = "mm")
  )

# ---- Export ---------------------------------------------------------------

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
  plotted_rows = nrow(plot_data),
  plotted_segments = nrow(segment_data),
  platform_rulers = nrow(nested_summary),
  direct_value_labels = nrow(segment_data),
  geometry = paste(
    "nested-depth rulers; internal 10x and 30x achieved boundaries;",
    "highest-depth achieved endpoint; target guides at 10x, 30x and 50x"
  ),
  overlap = "none; one spatially independent ruler per platform",
  bytes = as.numeric(file.info(rendered_paths)$size),
  md5 = unname(tools::md5sum(rendered_paths)),
  stringsAsFactors = FALSE
)
write_csv(
  render_manifest,
  file.path(OUTPUT_DIR, "render_manifest.csv"),
  na = ""
)

message("Rendered Panel a to: ", OUTPUT_DIR)
message("Plotted rows: ", nrow(plot_data), " / ", n_source)
message("Nested ruler segments: ", nrow(segment_data), " / 9")
message("Overplotted platform trajectories: 0")
message("Font family: ", BASE_FAMILY)
