#!/usr/bin/env Rscript

# =============================================================================
# Panel a: approximate input depth across nested HG002 read subsets
#
# Scientific contract
#   Claim      : the 10x and 30x inputs are depth matched across platforms;
#                BGI and HiFi also reach 50x, whereas the ONT nominal-50x
#                subset contains 47.768x of available sequence yield.
#   Role       : experimental-design evidence, not a platform ranking panel.
#   Evidence   : all nine platform x target-depth observations.
#   Archetype  : compact identity-reference line plot.
#   Encoding   : colour = platform; grey dashed line = exact target matching.
#   Integrity  : no aggregation, jitter, smoothing, uncertainty, or inference.
#   Reuse      : build anew; style-only inheritance from the project palette,
#                typography, vector export, and audit conventions.
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
HEIGHT_MM = 52
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
  replicate_statement = "nested technical depth subsets; not independent replicates",
  stringsAsFactors = FALSE
)
write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"), na = "")

# ---- Figure ---------------------------------------------------------------

theme_input_depth <- function(base_size = 6.4, base_family = BASE_FAMILY) {
  theme_classic(base_size = base_size, base_family = base_family) +
    theme(
      axis.line = element_line(colour = "#252525", linewidth = 0.28),
      axis.ticks = element_line(colour = "#252525", linewidth = 0.28),
      axis.ticks.length = unit(1.15, "mm"),
      axis.title = element_text(
        colour = "#202020", size = 6.4, margin = margin(t = 2.0, r = 2.0)
      ),
      axis.text = element_text(colour = "#4D4D4D", size = 5.8),
      legend.position = "top",
      legend.justification = "center",
      legend.direction = "horizontal",
      legend.title = element_blank(),
      legend.text = element_text(colour = "#333333", size = 5.8),
      legend.key = element_blank(),
      legend.key.width = unit(7.0, "mm"),
      legend.key.height = unit(2.4, "mm"),
      legend.spacing.x = unit(0.8, "mm"),
      legend.margin = margin(0, 0, 1.0, 0, unit = "mm"),
      panel.grid = element_blank(),
      plot.margin = margin(1.2, 2.2, 1.5, 1.5, unit = "mm")
    )
}

p <- ggplot(
  plot_data,
  aes(
    x = target_input_depth_x,
    y = approximate_input_depth_x,
    colour = platform,
    group = platform
  )
) +
  geom_abline(
    slope = 1,
    intercept = 0,
    colour = "#A7A7A7",
    linewidth = 0.27,
    linetype = "22"
  ) +
  geom_line(linewidth = 0.42, lineend = "round") +
  geom_point(colour = "white", size = 2.65, show.legend = FALSE) +
  geom_point(size = 1.95) +
  annotate(
    "segment",
    x = 50,
    xend = 50,
    y = 47.2,
    yend = 45.7,
    colour = "#6B6B6B",
    linewidth = 0.22
  ) +
  annotate(
    "text",
    x = 49.6,
    y = 44.7,
    label = "47.77×",
    hjust = 1,
    vjust = 1,
    family = BASE_FAMILY,
    size = 2.0,
    colour = "#343434"
  ) +
  scale_colour_manual(
    values = PLATFORM_COLOURS,
    breaks = PLATFORMS,
    limits = PLATFORMS,
    drop = FALSE
  ) +
  scale_x_continuous(
    name = "Target input depth (×)",
    breaks = c(0, 10, 30, 50),
    limits = c(0, 52),
    expand = expansion(mult = 0)
  ) +
  scale_y_continuous(
    name = "Approximate input depth (×)",
    breaks = c(0, 10, 30, 50),
    limits = c(0, 52),
    expand = expansion(mult = 0)
  ) +
  coord_fixed(ratio = 1, clip = "off") +
  guides(
    colour = guide_legend(
      nrow = 1,
      byrow = TRUE,
      override.aes = list(linewidth = 0.42, size = 1.9)
    )
  ) +
  theme_input_depth()

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
message("Font family: ", BASE_FAMILY)
