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
#   Archetype  : two-panel categorical condition dot plot.
#   Encoding   : x = aligner; y = primary mapped-read rate; colour = platform;
#                panel = reference genome.
#   Integrity  : no coverage-breadth reuse, aggregation, connector, jitter,
#                smoothing, fitted trend, uncertainty interval, test or p-value.
#   Reuse      : inherit the Panel c palette, typography, centred titles,
#                categorical boundary guides, mark scale and export contract.
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

ALIGNER_CENTRES <- seq_along(ALIGNERS)
ALIGNER_BOUNDARIES <- seq(0.5, length(ALIGNERS) + 0.5, by = 1)
Y_LIMITS <- c(97.5, 100.10)

WIDTH_MM = 183
HEIGHT_MM = 52
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
if (any(plot_data$primary_mapped_pct < Y_LIMITS[1] |
        plot_data$primary_mapped_pct > Y_LIMITS[2])) {
  stop("At least one primary mapped-read value lies outside the y window")
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
  plotted_points = nrow(plot_data),
  transform_platform = "remove terminal _latest suffix",
  transform_primary_mapped = "100 x Primary mapped rate fraction",
  filter_rule = "Depth == 30x; one row per reference x aligner x platform",
  geometry = paste(
    "exact categorical points; reference panels and aligner x positions;",
    "no coverage reuse, connectors, jitter, aggregation or fitted trends"
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

percent_labels <- function(values) {
  paste0(formatC(values, format = "f", digits = 1), "%")
}

theme_condition_subpanel <- function(
    show_legend = FALSE,
    base_size = 6.7,
    base_family = BASE_FAMILY
) {
  theme_classic(base_size = base_size, base_family = base_family) +
    theme(
      axis.line = element_blank(),
      axis.ticks = element_blank(),
      axis.title.x = element_text(
        colour = "#171717", size = 6.8, face = "bold",
        margin = margin(t = 2.0)
      ),
      axis.title.y = element_text(
        colour = "#171717", size = 6.8, face = "bold",
        margin = margin(r = 2.0)
      ),
      axis.text.x = element_text(
        colour = "#292929", size = 6.2, margin = margin(t = 1.2)
      ),
      axis.text.y = element_text(
        colour = "#292929", size = 6.0, margin = margin(r = 1.0)
      ),
      plot.title = element_text(
        colour = "#111111", size = 7.2, face = "bold",
        hjust = 0.5, margin = margin(b = 2.2)
      ),
      panel.grid = element_blank(),
      legend.position = if (show_legend) "top" else "none",
      legend.direction = "horizontal",
      legend.title = element_text(
        colour = "#222222", size = 6.0, face = "bold"
      ),
      legend.text = element_text(colour = "#292929", size = 6.0),
      legend.key = element_blank(),
      legend.key.width = unit(4.6, "mm"),
      legend.key.height = unit(2.5, "mm"),
      legend.spacing.x = unit(2.2, "mm"),
      legend.spacing.y = unit(0, "mm"),
      legend.box.spacing = unit(0, "mm"),
      legend.margin = margin(0, 0, 0, 0, unit = "mm"),
      plot.margin = margin(1.4, 2.0, 1.2, 2.0, unit = "mm")
    )
}

make_condition_subpanel <- function(panel_index, show_legend = FALSE) {
  reference_name <- REFERENCES[panel_index]
  panel_data <- plot_data %>% filter(reference == reference_name)

  if (nrow(panel_data) != 6L) {
    stop("Each reference subpanel must contain exactly six primary-rate points")
  }

  y_title <- if (panel_index == 1L) {
    "Primary mapped-read rate"
  } else {
    "\u00A0"
  }

  ggplot(
    panel_data,
    aes(
      x = aligner_index,
      y = primary_mapped_pct,
      colour = platform
    )
  ) +
    geom_vline(
      data = data.frame(x_boundary = ALIGNER_BOUNDARIES),
      aes(xintercept = x_boundary),
      inherit.aes = FALSE,
      colour = "#D7D7D7",
      linewidth = 0.34
    ) +
    geom_point(size = 2.05, shape = 16) +
    scale_colour_manual(
      name = "Platform",
      values = PLATFORM_COLOURS,
      breaks = PLATFORMS,
      limits = PLATFORMS,
      drop = FALSE
    ) +
    scale_x_continuous(
      name = "Aligner",
      limits = range(ALIGNER_BOUNDARIES),
      breaks = ALIGNER_CENTRES,
      labels = ALIGNERS,
      expand = expansion(mult = 0)
    ) +
    scale_y_continuous(
      name = y_title,
      limits = Y_LIMITS,
      breaks = seq(97.5, 100.0, by = 0.5),
      labels = percent_labels,
      expand = expansion(mult = 0)
    ) +
    guides(
      colour = guide_legend(
        order = 1,
        nrow = 1,
        byrow = TRUE,
        override.aes = list(shape = 16, size = 2.0)
      )
    ) +
    labs(title = unname(PANEL_TITLES[reference_name])) +
    theme_condition_subpanel(show_legend = show_legend)
}

extract_legend <- function(plot_object) {
  plot_gtable <- ggplotGrob(plot_object)
  candidates <- which(grepl("^guide-box", plot_gtable$layout$name))
  for (candidate in candidates) {
    candidate_grob <- plot_gtable$grobs[[candidate]]
    if (!inherits(candidate_grob, "zeroGrob")) {
      return(candidate_grob)
    }
  }
  stop("Unable to extract the shared platform legend")
}

panel_plots <- lapply(
  seq_along(REFERENCES),
  function(panel_index) make_condition_subpanel(panel_index, FALSE)
)

# Build the shared legend on an explicit null device so non-interactive runs do
# not create an unintended Rplots.pdf before the publication devices open.
grDevices::pdf(NULL)
legend_grob <- extract_legend(make_condition_subpanel(1L, TRUE))
grDevices::dev.off()

draw_panel_d <- function() {
  grid.newpage()
  panel_layout <- grid.layout(
    nrow = 2,
    ncol = 2,
    heights = unit.c(unit(7.0, "mm"), unit(1, "null")),
    widths = unit(rep(1, 2), "null")
  )
  pushViewport(viewport(layout = panel_layout))

  pushViewport(viewport(layout.pos.row = 1, layout.pos.col = 1:2))
  grid.draw(legend_grob)
  popViewport()

  for (panel_index in seq_along(panel_plots)) {
    print(
      panel_plots[[panel_index]],
      newpage = FALSE,
      vp = viewport(layout.pos.row = 2, layout.pos.col = panel_index)
    )
  }
  popViewport()
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
  plotted_points = nrow(plot_data),
  plotted_references = length(REFERENCES),
  geometry = "reference-faceted categorical points; no connectors or fits",
  x_encoding = paste(
    "aligner categories at centres 1 and 2; pale guides at boundaries",
    "0.5, 1.5 and 2.5"
  ),
  y_window = "97.5-100.10%",
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
message("Plotted primary-rate points: ", nrow(plot_data), " / 12")
message("Coverage-breadth values reused: 0")
message("Connector segments: 0")
message("Font family: ", BASE_FAMILY)
