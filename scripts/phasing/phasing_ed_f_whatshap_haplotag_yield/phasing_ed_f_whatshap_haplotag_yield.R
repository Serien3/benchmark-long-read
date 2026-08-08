#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(scales)
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
DATA_FILE <- file.path(ROOT, "data", "phasing_haplotag_whatshap.csv")
OUTPUT_DIR <- file.path(ROOT, "figures", "phasing", "phasing_ed_f_whatshap_haplotag_yield")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

FIGURE_STEM <- "phasing_ed_f_whatshap_haplotag_yield"
WIDTH_MM <- 88
HEIGHT_MM <- 48
DPI <- 600

EXPECTED_PLATFORMS <- c("BGI", "ONT", "HiFi")
EXPECTED_MAPPERS <- c("minimap2", "winnowmap")
EXPECTED_DEPTHS <- c(10, 30, 50)

PLATFORM_COLORS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)

font_candidates <- c("Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans")
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

if (identical(BASE_FAMILY, "Nimbus Sans") &&
    !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  nimbus_metrics <- grDevices::pdfFonts("NimbusSan")[[1]]
  do.call(grDevices::pdfFonts, setNames(list(nimbus_metrics), BASE_FAMILY))
}

raw <- read_csv(
  DATA_FILE,
  show_col_types = FALSE,
  progress = FALSE,
  locale = locale(encoding = "UTF-8")
)

required <- c(
  "Dataset", "Reference", "Mapper", "Depth", "Alignments processed",
  "Tagged H1+H2", "Taggable rate", "H1", "H2", "H1 fraction", "H2 fraction",
  "H1/H2 ratio", "Non-H1/H2", "Phase sets", "Status"
)
missing_columns <- setdiff(required, names(raw))
if (length(missing_columns) > 0L) {
  stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
}
if (nrow(raw) != 18L) stop("Expected exactly 18 WhatsHap haplotag rows")

plot_data <- raw |>
  transmute(
    dataset = Dataset,
    platform = sub("_latest$", "", Dataset),
    reference = Reference,
    mapper = Mapper,
    depth = Depth,
    depth_x = as.numeric(sub("x$", "", Depth)),
    alignments_processed = as.numeric(`Alignments processed`),
    source_tagged_h1_h2 = as.numeric(`Tagged H1+H2`),
    source_taggable_rate = as.numeric(`Taggable rate`),
    h1_alignments = as.numeric(H1),
    h2_alignments = as.numeric(H2),
    source_h1_fraction = as.numeric(`H1 fraction`),
    source_h2_fraction = as.numeric(`H2 fraction`),
    source_h1_h2_ratio = as.numeric(`H1/H2 ratio`),
    non_h1_h2 = as.numeric(`Non-H1/H2`),
    phase_sets = as.numeric(`Phase sets`),
    status = Status
  ) |>
  mutate(
    tagged_h1_h2 = h1_alignments + h2_alignments,
    taggable_alignment_pct = 100 * tagged_h1_h2 / alignments_processed,
    h1_fraction = h1_alignments / tagged_h1_h2,
    h2_fraction = h2_alignments / tagged_h1_h2,
    h1_h2_ratio = h1_alignments / h2_alignments,
    platform = factor(platform, levels = EXPECTED_PLATFORMS),
    mapper = factor(mapper, levels = EXPECTED_MAPPERS),
    depth_index = match(depth_x, EXPECTED_DEPTHS)
  ) |>
  arrange(platform, mapper, depth_x)

numeric_fields <- c(
  "depth_x", "alignments_processed", "source_tagged_h1_h2", "h1_alignments",
  "h2_alignments", "tagged_h1_h2", "taggable_alignment_pct", "h1_fraction",
  "h2_fraction", "h1_h2_ratio", "non_h1_h2", "phase_sets"
)
if (any(!is.finite(unlist(plot_data[numeric_fields], use.names = FALSE)))) {
  stop("Depth, counts, rates and balance metrics must be finite")
}
if (any(plot_data$alignments_processed <= 0)) stop("Processed-alignment denominators must be positive")
if (any(plot_data$h1_alignments < 0) || any(plot_data$h2_alignments <= 0)) {
  stop("H1 counts must be non-negative and H2 counts must be positive")
}
if (any(plot_data$tagged_h1_h2 > plot_data$alignments_processed)) {
  stop("Tagged H1+H2 alignments cannot exceed alignments processed")
}
if (any(plot_data$source_tagged_h1_h2 != plot_data$tagged_h1_h2)) {
  stop("Stored Tagged H1+H2 does not equal H1 + H2")
}
if (any(plot_data$taggable_alignment_pct < 0 | plot_data$taggable_alignment_pct > 100)) {
  stop("Taggable-alignment percentages must lie in [0, 100]")
}
if (any(abs(plot_data$h1_fraction + plot_data$h2_fraction - 1) > 1e-12)) {
  stop("Recomputed H1 and H2 fractions must sum to one")
}
if (any(plot_data$reference != "GRCh38")) stop("All plotted rows must use GRCh38")
if (any(plot_data$status != "Complete")) stop("All plotted rows must be complete")

expected_keys <- expand.grid(
  platform = EXPECTED_PLATFORMS,
  mapper = EXPECTED_MAPPERS,
  depth_x = EXPECTED_DEPTHS,
  stringsAsFactors = FALSE
) |>
  transmute(key = paste(platform, mapper, depth_x, sep = "|"))
observed_keys <- plot_data |>
  transmute(key = paste(as.character(platform), as.character(mapper), depth_x, sep = "|"))
if (anyDuplicated(observed_keys$key) || !setequal(expected_keys$key, observed_keys$key)) {
  stop("The source is not the complete 3-platform x 2-mapper x 3-depth design")
}

observed_depth_order <- plot_data |>
  group_by(platform, mapper) |>
  summarise(depths = paste(depth_x, collapse = ","), .groups = "drop")
if (any(observed_depth_order$depths != paste(EXPECTED_DEPTHS, collapse = ","))) {
  stop("Every trajectory must contain ordered 10x, 30x and 50x observations")
}

taggable_rate_residual <- plot_data$taggable_alignment_pct / 100 - plot_data$source_taggable_rate
h1_fraction_residual <- plot_data$h1_fraction - plot_data$source_h1_fraction
h2_fraction_residual <- plot_data$h2_fraction - plot_data$source_h2_fraction
h1_h2_ratio_residual <- plot_data$h1_h2_ratio - plot_data$source_h1_h2_ratio

if (max(abs(taggable_rate_residual)) > 6e-5) {
  stop("Recomputed taggable rates disagree with the rounded source rates")
}
if (max(abs(h1_fraction_residual)) > 6e-5 || max(abs(h2_fraction_residual)) > 6e-5) {
  stop("Recomputed H1/H2 fractions disagree with the rounded source fractions")
}
if (max(abs(h1_h2_ratio_residual)) > 6e-4) {
  stop("Recomputed H1/H2 ratios disagree with the rounded source ratios")
}

write_csv(
  plot_data |>
    transmute(
      platform = as.character(platform), mapper = as.character(mapper),
      reference, depth, depth_x, depth_index,
      denominator_alignments_processed = alignments_processed,
      numerator_tagged_h1_h2_alignments = tagged_h1_h2,
      h1_alignments, h2_alignments,
      source_taggable_rate,
      plotted_taggable_alignments_pct = taggable_alignment_pct,
      h1_fraction, h2_fraction, h1_h2_ratio,
      source_h1_fraction, source_h2_fraction, source_h1_h2_ratio,
      non_h1_h2, phase_sets,
      transformation = "100 * (H1 + H2) / Alignments processed",
      unit_note = "alignments; not unique reads and not truth-validated assignments"
    ),
  file.path(OUTPUT_DIR, "source_data_plotted.csv"),
  na = ""
)

balance_audit <- data.frame(
  rows = nrow(plot_data),
  minimum_h1_h2_ratio = min(plot_data$h1_h2_ratio),
  maximum_h1_h2_ratio = max(plot_data$h1_h2_ratio),
  minimum_h1_fraction_pct = 100 * min(plot_data$h1_fraction),
  maximum_h1_fraction_pct = 100 * max(plot_data$h1_fraction),
  minimum_h2_fraction_pct = 100 * min(plot_data$h2_fraction),
  maximum_h2_fraction_pct = 100 * max(plot_data$h2_fraction),
  maximum_abs_h1_h2_sum_residual = max(abs(plot_data$h1_fraction + plot_data$h2_fraction - 1)),
  display_decision = "balance retained in Source Data and the haplotype-balance audit; no low-information 50/50 stacked chart",
  stringsAsFactors = FALSE
)
write_csv(balance_audit, file.path(OUTPUT_DIR, "haplotype_balance_audit.csv"), na = "")

audit <- data.frame(
  source_file = basename(DATA_FILE),
  source_rows = nrow(raw),
  selected_rows = nrow(plot_data),
  excluded_rows = nrow(raw) - nrow(plot_data),
  inclusion_rule = "all rows retained",
  exclusion_rule = "none",
  expected_design = "3 platforms x 2 mappers x 3 depths",
  observed_unique_trajectories = n_distinct(interaction(plot_data$platform, plot_data$mapper)),
  observed_points_per_trajectory = paste(
    sort(unique(table(interaction(plot_data$platform, plot_data$mapper)))),
    collapse = "|"
  ),
  minimum_taggable_pct = min(plot_data$taggable_alignment_pct),
  maximum_taggable_pct = max(plot_data$taggable_alignment_pct),
  maximum_stored_rate_residual = max(abs(taggable_rate_residual)),
  aggregation = "none",
  smoothing = "none",
  interpolation = "none; straight segments connect only adjacent measured depths",
  error_bars = "none; each point is one deterministic workflow output",
  mapper_as_replicate = FALSE,
  mapper_layout = "two independent side-by-side plotting regions; no positional offset",
  depth_coordinate_grammar = "10x, 30x and 50x at category centres 1, 2 and 3; guides at boundaries 0.5, 1.5, 2.5 and 3.5",
  reuse_level = "structural adaptation of the revised LongPhase depth panels",
  axis_note = "shared linear 45-70% display range; no value is clipped",
  stringsAsFactors = FALSE
)
write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"), na = "")

metric_definition <- data.frame(
  metric = "Taggable alignments",
  numerator = "Alignments assigned to haplotype 1 or haplotype 2 (H1 + H2)",
  denominator = "Alignments processed by WhatsHap haplotag",
  plotted_unit = "%",
  transformation = "100 * (H1 + H2) / Alignments processed",
  scale = "linear",
  interpretation = paste(
    "Fraction of processed alignments receiving an H1/H2 haplotype assignment;",
    "not a unique-read rate and not a truth-set phasing-accuracy metric."
  ),
  balance_note = paste(
    "H1/H2 ratio is reported in Source Data; observed range",
    sprintf("%.4f-%.4f", min(plot_data$h1_h2_ratio), max(plot_data$h1_h2_ratio))
  ),
  stringsAsFactors = FALSE
)
write_csv(metric_definition, file.path(OUTPUT_DIR, "metric_definitions.csv"), na = "")

DEPTH_CENTRES <- seq_along(EXPECTED_DEPTHS)
DEPTH_BOUNDARIES <- seq(0.5, length(EXPECTED_DEPTHS) + 0.5, by = 1)

theme_haplotag_subpanel <- function() {
  theme_classic(base_size = 6.7, base_family = BASE_FAMILY) +
    theme(
      axis.line = element_blank(), axis.ticks = element_blank(),
      axis.title.x = element_text(colour = "#171717", size = 6.8, face = "bold", margin = margin(t = 2.0)),
      axis.title.y = element_text(colour = "#171717", size = 6.8, face = "bold", margin = margin(r = 2.0)),
      axis.text.x = element_text(colour = "#292929", size = 6.2, margin = margin(t = 1.2)),
      axis.text.y = element_text(colour = "#292929", size = 6.0, margin = margin(r = 1.0)),
      panel.grid = element_blank(),
      plot.title = element_text(colour = "#111111", size = 7.2, face = "bold", hjust = 0.5, margin = margin(b = 2.2)),
      legend.position = "none",
      plot.margin = margin(4.0, 1.2, 1.2, 1.2, unit = "mm")
    )
}

make_haplotag_subpanel <- function(mapper_name, panel_index) {
  panel_data <- plot_data |> filter(as.character(mapper) == mapper_name)
  if (nrow(panel_data) != 9L) stop("Each mapper panel must contain exactly nine observations")
  ggplot(panel_data, aes(x = depth_index, y = taggable_alignment_pct, colour = platform, group = platform)) +
    geom_vline(data = data.frame(x_boundary = DEPTH_BOUNDARIES), aes(xintercept = x_boundary), inherit.aes = FALSE, colour = "#D7D7D7", linewidth = 0.34) +
    geom_line(linewidth = 0.72, lineend = "round", linejoin = "round") +
    geom_point(size = 2.05, shape = 16) +
    scale_colour_manual(values = PLATFORM_COLORS, breaks = EXPECTED_PLATFORMS, limits = EXPECTED_PLATFORMS, drop = FALSE, guide = "none") +
    scale_x_continuous(name = "Sequencing Depth", limits = range(DEPTH_BOUNDARIES), breaks = DEPTH_CENTRES, labels = paste0(EXPECTED_DEPTHS, "×"), expand = expansion(mult = 0)) +
    scale_y_continuous(name = if (panel_index == 1L) "Taggable alignments (%)" else "\u00A0", breaks = seq(45, 70, by = 5), labels = label_number(accuracy = 1), limits = c(45, 70), expand = expansion(mult = 0)) +
    labs(title = mapper_name) + theme_haplotag_subpanel()
}

panel_plots <- Map(make_haplotag_subpanel, EXPECTED_MAPPERS, seq_along(EXPECTED_MAPPERS))

draw_mapper_pair <- function() {
  grid::grid.newpage()
  panel_layout <- grid::grid.layout(nrow = 1, ncol = length(panel_plots), widths = grid::unit(rep(1, length(panel_plots)), "null"))
  grid::pushViewport(grid::viewport(layout = panel_layout))
  for (panel_index in seq_along(panel_plots)) print(panel_plots[[panel_index]], newpage = FALSE, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = panel_index))
  grid::popViewport()
}

save_one <- function(ext) {
  path <- file.path(OUTPUT_DIR, paste0(FIGURE_STEM, ".", ext))
  width_in <- WIDTH_MM / 25.4
  height_in <- HEIGHT_MM / 25.4

  if (ext == "svg") {
    svglite::svglite(
      path, width = width_in, height = height_in, bg = "white",
      system_fonts = list(sans = BASE_FAMILY)
    )
  } else if (ext == "pdf") {
    grDevices::cairo_pdf(
      path, width = width_in, height = height_in,
      family = BASE_FAMILY, bg = "white", onefile = TRUE
    )
  } else if (ext == "tiff") {
    ragg::agg_tiff(
      path, width = WIDTH_MM, height = HEIGHT_MM, units = "mm",
      res = DPI, background = "white", scaling = 1
    )
  } else if (ext == "png") {
    ragg::agg_png(
      path, width = WIDTH_MM, height = HEIGHT_MM, units = "mm",
      res = DPI, background = "white", scaling = 1
    )
  } else {
    stop("Unsupported extension: ", ext)
  }

  draw_mapper_pair()
  grDevices::dev.off()
  path
}

formats <- c("svg", "pdf", "tiff", "png")
outputs <- vapply(formats, save_one, character(1))
if (!all(file.exists(outputs)) || any(file.info(outputs)$size <= 0)) {
  stop("One or more figure exports are missing or empty")
}

manifest <- data.frame(
  file = basename(outputs),
  format = formats,
  width_mm = WIDTH_MM,
  height_mm = HEIGHT_MM,
  dpi = c(NA, NA, DPI, DPI),
  bytes = unname(file.info(outputs)$size),
  md5 = unname(tools::md5sum(outputs)),
  font_family = BASE_FAMILY,
  editable_text = c(TRUE, TRUE, FALSE, FALSE),
  plotted_points = nrow(plot_data),
  raw_trajectories = n_distinct(interaction(plot_data$platform, plot_data$mapper)),
  panel_layout = "1 x 2 independent axes: mapper",
  depth_coordinate_grammar = "centres 1,2,3; boundaries 0.5,1.5,2.5,3.5",
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
write_csv(manifest, file.path(OUTPUT_DIR, "render_manifest.csv"), na = "")

message("Rendered WhatsHap haplotag-yield trajectories to: ", OUTPUT_DIR)
