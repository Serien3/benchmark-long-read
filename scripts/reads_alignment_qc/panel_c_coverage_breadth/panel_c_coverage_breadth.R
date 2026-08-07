#!/usr/bin/env Rscript

# =============================================================================
# Panel c: reference-base coverage breadth across nominal depth
#
# Scientific contract
#   Claim      : reference-base coverage breadth rises mainly before 30x,
#                approaches convergence among platforms on GRCh38, remains
#                more platform-separated on T2T-CHM13, and is broadly similar
#                between minimap2 and winnowmap within matched conditions.
#   Role       : hero evidence in the reads/alignment QC opening figure.
#   Evidence   : all 36 platform x depth x reference x aligner conditions.
#   Archetype  : one-row, four-panel depth-response small multiple.
#   Encoding   : panel = reference x aligner; colour = platform;
#                x = nominal nested depth; y = reference bases covered >=1x.
#   Integrity  : no filtering, aggregation, jitter, smoothing, model fit,
#                uncertainty interval, test or p-value.
#   Reuse      : structural adaptation of the author-supplied cuteHap example:
#                four independent narrow plots, bold centred titles, depth
#                points centred between vertical category-boundary guides,
#                repeated x-axis titles and filled circular markers. Insets
#                are omitted because no local region requires a second scale.
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
  ROOT, "figures", "reads_alignment_qc", "panel_c_coverage_breadth"
)
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

REFERENCES <- c("GRCh38", "T2T-CHM13")
ALIGNERS <- c("minimap2", "winnowmap")
PLATFORMS <- c("BGI", "ONT", "HiFi")
DEPTHS <- c(10, 30, 50)
PANEL_LEVELS <- c(
  "GRCh38 · minimap2",
  "GRCh38 · winnowmap",
  "T2T-CHM13 · minimap2",
  "T2T-CHM13 · winnowmap"
)
PANEL_TITLES <- c(
  "GRCh38 minimap2",
  "GRCh38 winnowmap",
  "T2T-CHM13 minimap2",
  "T2T-CHM13 winnowmap"
)

PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)

# The two reference-specific windows have the same 2.5-percentage-point span.
# This preserves geometric comparability of slopes and gaps while avoiding a
# visually compressed 92-100% global axis. Absolute levels remain explicit in
# the percentage tick labels on every small multiple.
REFERENCE_Y_MIN <- c(GRCh38 = 92.0, `T2T-CHM13` = 97.5)
REFERENCE_Y_MAX <- c(GRCh38 = 94.5, `T2T-CHM13` = 100.0)

WIDTH_MM = 183
HEIGHT_MM = 59.5
PNG_DPI = 320
TIFF_DPI = 600
OUTPUT_STEM <- "reference_base_coverage_breadth"

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
  "参考基因组", "Aligner", "Dataset", "Depth", "Coverage rate"
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
    platform = factor(sub("_latest$", "", Dataset), levels = PLATFORMS),
    depth_label = Depth,
    nominal_depth_x = as.numeric(sub("x$", "", Depth)),
    depth_index = match(nominal_depth_x, DEPTHS),
    coverage_fraction = as.numeric(`Coverage rate`),
    coverage_pct = 100 * coverage_fraction
  ) %>%
  mutate(
    panel = factor(
      paste(as.character(reference), as.character(aligner), sep = " · "),
      levels = PANEL_LEVELS
    )
  ) %>%
  arrange(panel, platform, nominal_depth_x)

if (any(is.na(plot_data$reference))) {
  stop("Unexpected reference label in alignment QC")
}
if (any(is.na(plot_data$aligner))) {
  stop("Unexpected aligner label in alignment QC")
}
if (any(is.na(plot_data$platform))) {
  stop("Unexpected platform label in alignment QC")
}
if (any(is.na(plot_data$panel))) {
  stop("Unexpected reference x aligner panel label in alignment QC")
}
if (any(!is.finite(plot_data$nominal_depth_x)) ||
    !setequal(plot_data$nominal_depth_x, DEPTHS)) {
  stop("Nominal depth must contain exactly 10x, 30x and 50x")
}
if (any(is.na(plot_data$depth_index)) ||
    !setequal(plot_data$depth_index, seq_along(DEPTHS))) {
  stop("Depth centres must map exactly to category positions 1, 2 and 3")
}
if (any(!is.finite(plot_data$coverage_fraction)) ||
    any(plot_data$coverage_fraction < 0 |
        plot_data$coverage_fraction > 1)) {
  stop("Coverage fractions must be finite and lie in [0, 1]")
}
row_y_min <- unname(REFERENCE_Y_MIN[as.character(plot_data$reference)])
row_y_max <- unname(REFERENCE_Y_MAX[as.character(plot_data$reference)])
if (any(plot_data$coverage_pct < row_y_min |
        plot_data$coverage_pct > row_y_max)) {
  stop("At least one observation lies outside its declared reference window")
}

duplicate_keys <- plot_data %>%
  count(reference, aligner, platform, nominal_depth_x, name = "n") %>%
  filter(n != 1L)
if (nrow(duplicate_keys) > 0L) {
  stop("Reference x aligner x platform x depth keys are not unique")
}

expected_keys <- expand.grid(
  reference = REFERENCES,
  aligner = ALIGNERS,
  platform = PLATFORMS,
  nominal_depth_x = DEPTHS,
  stringsAsFactors = FALSE
)
observed_keys <- plot_data %>%
  transmute(
    reference = as.character(reference),
    aligner = as.character(aligner),
    platform = as.character(platform),
    nominal_depth_x
  )
missing_keys <- anti_join(
  expected_keys,
  observed_keys,
  by = c("reference", "aligner", "platform", "nominal_depth_x")
)
unexpected_keys <- anti_join(
  observed_keys,
  expected_keys,
  by = c("reference", "aligner", "platform", "nominal_depth_x")
)
if (nrow(missing_keys) > 0L || nrow(unexpected_keys) > 0L) {
  stop("Alignment-QC input is not the complete symmetric 36-condition matrix")
}

# ---- Derived checks supporting the result narrative -----------------------

minimap2_values <- plot_data %>%
  filter(aligner == "minimap2") %>%
  transmute(
    reference = as.character(reference),
    platform = as.character(platform),
    nominal_depth_x,
    minimap2_coverage_pct = coverage_pct
  )
winnowmap_values <- plot_data %>%
  filter(aligner == "winnowmap") %>%
  transmute(
    reference = as.character(reference),
    platform = as.character(platform),
    nominal_depth_x,
    winnowmap_coverage_pct = coverage_pct
  )

aligner_differences <- inner_join(
  minimap2_values,
  winnowmap_values,
  by = c("reference", "platform", "nominal_depth_x")
) %>%
  mutate(
    winnowmap_minus_minimap2_pp =
      winnowmap_coverage_pct - minimap2_coverage_pct,
    absolute_difference_pp = abs(winnowmap_minus_minimap2_pp)
  ) %>%
  arrange(reference, platform, nominal_depth_x)

if (nrow(aligner_differences) != 18L) {
  stop("Expected 18 matched aligner comparisons")
}

depth_10 <- plot_data %>%
  filter(nominal_depth_x == 10) %>%
  transmute(
    reference = as.character(reference),
    aligner = as.character(aligner),
    platform = as.character(platform),
    coverage_10x_pct = coverage_pct
  )
depth_30 <- plot_data %>%
  filter(nominal_depth_x == 30) %>%
  transmute(
    reference = as.character(reference),
    aligner = as.character(aligner),
    platform = as.character(platform),
    coverage_30x_pct = coverage_pct
  )
depth_50 <- plot_data %>%
  filter(nominal_depth_x == 50) %>%
  transmute(
    reference = as.character(reference),
    aligner = as.character(aligner),
    platform = as.character(platform),
    coverage_50x_pct = coverage_pct
  )

depth_gains <- depth_10 %>%
  inner_join(
    depth_30,
    by = c("reference", "aligner", "platform")
  ) %>%
  inner_join(
    depth_50,
    by = c("reference", "aligner", "platform")
  ) %>%
  mutate(
    gain_10x_to_30x_pp = coverage_30x_pct - coverage_10x_pct,
    gain_30x_to_50x_pp = coverage_50x_pct - coverage_30x_pct
  ) %>%
  arrange(reference, platform, aligner)

if (nrow(depth_gains) != 12L) {
  stop("Expected 12 matched depth-response series")
}

coverage_30x_summary <- plot_data %>%
  filter(nominal_depth_x == 30) %>%
  group_by(reference) %>%
  summarise(
    n_conditions = n(),
    minimum_pct = min(coverage_pct),
    maximum_pct = max(coverage_pct),
    range_pp = maximum_pct - minimum_pct,
    .groups = "drop"
  )

aligner_summary <- data.frame(
  metric = c(
    "signed median: winnowmap - minimap2",
    "median absolute aligner difference",
    "maximum absolute aligner difference"
  ),
  scope = "all matched platform x depth x reference conditions",
  n_conditions = 18L,
  value = c(
    median(aligner_differences$winnowmap_minus_minimap2_pp),
    median(aligner_differences$absolute_difference_pp),
    max(aligner_differences$absolute_difference_pp)
  ),
  unit = "percentage points",
  stringsAsFactors = FALSE
)

depth_summary <- bind_rows(
  data.frame(
    metric = c("minimum depth gain", "median depth gain", "maximum depth gain"),
    scope = "10x to 30x",
    n_conditions = 12L,
    value = c(
      min(depth_gains$gain_10x_to_30x_pp),
      median(depth_gains$gain_10x_to_30x_pp),
      max(depth_gains$gain_10x_to_30x_pp)
    ),
    unit = "percentage points"
  ),
  data.frame(
    metric = c("minimum depth gain", "median depth gain", "maximum depth gain"),
    scope = "30x to 50x",
    n_conditions = 12L,
    value = c(
      min(depth_gains$gain_30x_to_50x_pp),
      median(depth_gains$gain_30x_to_50x_pp),
      max(depth_gains$gain_30x_to_50x_pp)
    ),
    unit = "percentage points"
  )
)

coverage_summary_long <- bind_rows(
  coverage_30x_summary %>%
    transmute(
      metric = "minimum coverage breadth",
      scope = paste0(as.character(reference), ", 30x"),
      n_conditions,
      value = minimum_pct,
      unit = "%"
    ),
  coverage_30x_summary %>%
    transmute(
      metric = "maximum coverage breadth",
      scope = paste0(as.character(reference), ", 30x"),
      n_conditions,
      value = maximum_pct,
      unit = "%"
    ),
  coverage_30x_summary %>%
    transmute(
      metric = "platform-aligner range",
      scope = paste0(as.character(reference), ", 30x"),
      n_conditions,
      value = range_pp,
      unit = "percentage points"
    )
)

summary_audit <- bind_rows(
  coverage_summary_long,
  aligner_summary,
  depth_summary
) %>%
  mutate(value = round(value, 6))

# Guards link the current plotted matrix to the confirmed narrative values.
assert_near(
  coverage_30x_summary$minimum_pct[
    coverage_30x_summary$reference == "GRCh38"
  ],
  92.94,
  "GRCh38 30x minimum"
)
assert_near(
  coverage_30x_summary$maximum_pct[
    coverage_30x_summary$reference == "GRCh38"
  ],
  93.33,
  "GRCh38 30x maximum"
)
assert_near(
  coverage_30x_summary$minimum_pct[
    coverage_30x_summary$reference == "T2T-CHM13"
  ],
  98.31,
  "T2T-CHM13 30x minimum"
)
assert_near(
  coverage_30x_summary$maximum_pct[
    coverage_30x_summary$reference == "T2T-CHM13"
  ],
  99.43,
  "T2T-CHM13 30x maximum"
)
assert_near(aligner_summary$value[1], -0.025, "signed aligner median")
assert_near(aligner_summary$value[2], 0.05, "absolute aligner median")
assert_near(aligner_summary$value[3], 0.21, "maximum aligner difference")
assert_near(depth_summary$value[2], 0.65, "10x-to-30x median gain")
assert_near(depth_summary$value[5], 0.185, "30x-to-50x median gain")

write_csv(
  plot_data %>%
    mutate(
      reference = as.character(reference),
      aligner = as.character(aligner),
      platform = as.character(platform),
      coverage_pct = round(coverage_pct, 4)
    ),
  file.path(OUTPUT_DIR, "source_data_plotted.csv"),
  na = ""
)
write_csv(
  aligner_differences %>%
    mutate(across(where(is.numeric), ~ round(.x, 6))),
  file.path(OUTPUT_DIR, "paired_aligner_differences.csv"),
  na = ""
)
write_csv(
  depth_gains %>%
    mutate(across(where(is.numeric), ~ round(.x, 6))),
  file.path(OUTPUT_DIR, "depth_gain_audit.csv"),
  na = ""
)
write_csv(
  summary_audit,
  file.path(OUTPUT_DIR, "derived_summary_audit.csv"),
  na = ""
)

data_audit <- data.frame(
  source_file = basename(INPUT_FILE),
  source_rows = n_source,
  plotted_rows = nrow(plot_data),
  excluded_rows = n_source - nrow(plot_data),
  expected_unique_keys = 36L,
  observed_unique_keys = nrow(distinct(
    plot_data, reference, aligner, platform, nominal_depth_x
  )),
  transform_platform = "remove terminal _latest suffix",
  transform_depth = "remove terminal x suffix and parse numeric",
  transform_coverage = "100 x Coverage rate fraction",
  filter_rule = "none; all 36 alignment-QC conditions plotted",
  replicate_statement = paste(
    "nested technical depth subsets from one HG002 dataset per platform;",
    "conditions are not biological replicates"
  ),
  stringsAsFactors = FALSE
)
write_csv(
  data_audit,
  file.path(OUTPUT_DIR, "data_filter_audit.csv"),
  na = ""
)

# ---- Figure ----------------------------------------------------------------

# The supplied visual reference uses vertical guides as categorical boundaries,
# not as tick-centred grid lines. With three depths at x = 1, 2 and 3, the four
# guides therefore sit at x = 0.5, 1.5, 2.5 and 3.5.
DEPTH_CENTRES <- seq_along(DEPTHS)
DEPTH_BOUNDARIES <- seq(0.5, length(DEPTHS) + 0.5, by = 1)

coverage_axis_labels <- function(values) {
  paste0(formatC(values, format = "f", digits = 0), "%")
}

theme_coverage_subpanel <- function(
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
      legend.position = "none",
      plot.margin = margin(4.0, 1.6, 1.2, 1.6, unit = "mm")
    )
}

make_coverage_subpanel <- function(panel_index) {
  panel_name <- PANEL_LEVELS[panel_index]
  panel_title <- PANEL_TITLES[panel_index]
  panel_data <- plot_data %>% filter(panel == panel_name)

  if (nrow(panel_data) != 9L) {
    stop("Each reference x aligner subpanel must contain exactly nine points")
  }

  reference_name <- as.character(panel_data$reference[1])
  y_limits <- c(
    unname(REFERENCE_Y_MIN[reference_name]),
    unname(REFERENCE_Y_MAX[reference_name])
  )
  y_breaks <- if (identical(reference_name, "GRCh38")) {
    c(92, 93, 94)
  } else {
    c(98, 99, 100)
  }
  y_title <- if (panel_index == 1L) {
    "Reference bases covered ≥1×"
  } else {
    "\u00A0"
  }

  ggplot(
    panel_data,
    aes(
      x = depth_index,
      y = coverage_pct,
      colour = platform,
      group = platform
    )
  ) +
    geom_vline(
      data = data.frame(x_boundary = DEPTH_BOUNDARIES),
      aes(xintercept = x_boundary),
      inherit.aes = FALSE,
      colour = "#D7D7D7",
      linewidth = 0.34
    ) +
    geom_line(linewidth = 0.72, lineend = "round", linejoin = "round") +
    geom_point(size = 2.05, shape = 16) +
    scale_colour_manual(
      values = PLATFORM_COLOURS,
      breaks = PLATFORMS,
      limits = PLATFORMS,
      drop = FALSE,
      guide = "none"
    ) +
    scale_x_continuous(
      name = "Sequencing Depth",
      limits = range(DEPTH_BOUNDARIES),
      breaks = DEPTH_CENTRES,
      labels = paste0(DEPTHS, "×"),
      expand = expansion(mult = 0)
    ) +
    scale_y_continuous(
      name = y_title,
      limits = y_limits,
      breaks = y_breaks,
      labels = coverage_axis_labels,
      expand = expansion(mult = 0)
    ) +
    labs(title = panel_title) +
    theme_coverage_subpanel()
}

panel_plots <- lapply(seq_along(PANEL_LEVELS), make_coverage_subpanel)

draw_panel_c <- function() {
  grid.newpage()
  panel_layout <- grid.layout(
    nrow = 1,
    ncol = length(panel_plots),
    widths = unit(rep(1, length(panel_plots)), "null")
  )
  pushViewport(viewport(layout = panel_layout))
  for (panel_index in seq_along(panel_plots)) {
    print(
      panel_plots[[panel_index]],
      newpage = FALSE,
      vp = viewport(layout.pos.row = 1, layout.pos.col = panel_index)
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
draw_panel_c()
grDevices::dev.off()

grDevices::cairo_pdf(
  pdf_path,
  width = width_in,
  height = height_in,
  family = BASE_FAMILY,
  bg = "white",
  onefile = TRUE
)
draw_panel_c()
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
draw_panel_c()
grDevices::dev.off()

ragg::agg_png(
  png_path,
  width = WIDTH_MM,
  height = HEIGHT_MM,
  units = "mm",
  res = PNG_DPI,
  background = "white"
)
draw_panel_c()
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
  plotted_series = nrow(distinct(plot_data, reference, platform, aligner)),
  panel_layout = "1 x 4 independent axes: reference x aligner",
  depth_coordinate_grammar = paste(
    "centres 1,2,3 for 10x,30x,50x;",
    "vertical boundaries 0.5,1.5,2.5,3.5"
  ),
  axis_windows = paste(
    "GRCh38 92.0-94.5%; T2T-CHM13 97.5-100.0%;",
    "equal 2.5-percentage-point span"
  ),
  bytes = as.numeric(file.info(rendered_paths)$size),
  md5 = unname(tools::md5sum(rendered_paths)),
  stringsAsFactors = FALSE
)
write_csv(
  render_manifest,
  file.path(OUTPUT_DIR, "render_manifest.csv"),
  na = ""
)

message("Rendered Panel c to: ", OUTPUT_DIR)
message("Plotted rows: ", nrow(plot_data), " / ", n_source)
message("Plotted reference-specific series: ", render_manifest$plotted_series[1])
message("Font family: ", BASE_FAMILY)
