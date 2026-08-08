#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
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
DATA_FILE <- file.path(ROOT, "data", "phasing_block_stats_whatshap.csv")
OUTPUT_DIR <- file.path(ROOT, "figures", "phasing", "phasing_ed_d_whatshap_phased_snv_depth")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

FIGURE_STEM <- "phasing_ed_d_whatshap_phased_snv_depth"
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
  "Dataset", "Reference", "Mapper", "Depth", "Het SNVs", "Phased SNVs",
  "Phased SNV rate", "Status", "Tool"
)
missing_columns <- setdiff(required, names(raw))
if (length(missing_columns) > 0L) {
  stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
}
if (nrow(raw) != 18L) stop("Expected exactly 18 WhatsHap block-stat rows")

plot_data <- raw |>
  transmute(
    dataset = Dataset,
    platform = sub("_latest$", "", Dataset),
    reference = Reference,
    mapper = Mapper,
    depth = Depth,
    depth_x = as.numeric(sub("x$", "", Depth)),
    het_snvs = as.numeric(`Het SNVs`),
    phased_snvs = as.numeric(`Phased SNVs`),
    source_phased_snv_rate = as.numeric(`Phased SNV rate`),
    phased_snv_pct = 100 * as.numeric(`Phased SNVs`) / as.numeric(`Het SNVs`),
    status = Status,
    tool = Tool
  ) |>
  mutate(
    platform = factor(platform, levels = EXPECTED_PLATFORMS),
    mapper = factor(mapper, levels = EXPECTED_MAPPERS),
    depth_index = match(depth_x, EXPECTED_DEPTHS)
  ) |>
  arrange(platform, mapper, depth_x)

numeric_fields <- c("depth_x", "het_snvs", "phased_snvs", "phased_snv_pct")
if (any(!is.finite(unlist(plot_data[numeric_fields], use.names = FALSE)))) {
  stop("Depth, counts and phased-SNV values must be finite")
}
if (any(plot_data$het_snvs <= 0)) stop("Heterozygous-SNV denominators must be positive")
if (any(plot_data$phased_snvs < 0) || any(plot_data$phased_snvs > plot_data$het_snvs)) {
  stop("Phased-SNV counts must lie between zero and the heterozygous-SNV denominator")
}
if (any(plot_data$phased_snv_pct < 0) || any(plot_data$phased_snv_pct > 100)) {
  stop("Phased-SNV percentages must lie in [0, 100]")
}
if (any(plot_data$reference != "GRCh38")) stop("All plotted rows must use GRCh38")
if (any(plot_data$status != "Complete")) stop("All plotted rows must be complete")
if (any(plot_data$tool != "WhatsHap 2.8")) stop("Unexpected phasing tool or version")

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

rate_residual <- plot_data$phased_snv_pct / 100 - plot_data$source_phased_snv_rate
if (max(abs(rate_residual)) > 6e-5) {
  stop("Recomputed phased-SNV rates disagree with the rounded source rates")
}

paired_data <- plot_data |>
  select(platform, depth, depth_x, mapper, phased_snv_pct) |>
  pivot_wider(names_from = mapper, values_from = phased_snv_pct) |>
  mutate(
    connector_ymin = pmin(minimap2, winnowmap),
    connector_ymax = pmax(minimap2, winnowmap),
    mapper_delta_percentage_points = winnowmap - minimap2
  ) |>
  arrange(platform, depth_x)

if (nrow(paired_data) != 9L || any(!is.finite(paired_data$mapper_delta_percentage_points))) {
  stop("Expected nine complete within-platform, within-depth mapper pairs")
}

write_csv(
  plot_data |>
    transmute(
      platform = as.character(platform), mapper = as.character(mapper),
      reference, depth, depth_x, depth_index,
      numerator_phased_snvs = phased_snvs,
      denominator_heterozygous_snvs = het_snvs,
      source_phased_snv_rate,
      plotted_phased_heterozygous_snv_pct = phased_snv_pct,
      transformation = "100 * Phased SNVs / Het SNVs"
    ),
  file.path(OUTPUT_DIR, "source_data_plotted.csv"),
  na = ""
)

write_csv(
  paired_data |>
    transmute(
      platform = as.character(platform), depth, depth_x,
      minimap2_phased_snv_pct = minimap2,
      winnowmap_phased_snv_pct = winnowmap,
      mapper_delta_percentage_points,
      connector_ymin, connector_ymax,
      connector_definition = "winnowmap minus minimap2 within the same platform and depth"
    ),
  file.path(OUTPUT_DIR, "paired_mapper_differences.csv"),
  na = ""
)

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
  observed_mapper_pairs = nrow(paired_data),
  minimum_phased_snv_pct = min(plot_data$phased_snv_pct),
  maximum_phased_snv_pct = max(plot_data$phased_snv_pct),
  minimum_mapper_delta_pp = min(paired_data$mapper_delta_percentage_points),
  maximum_mapper_delta_pp = max(paired_data$mapper_delta_percentage_points),
  maximum_stored_rate_residual = max(abs(rate_residual)),
  aggregation = "none",
  averaging = "none",
  smoothing = "none",
  interpolation = "none; straight segments connect only adjacent measured depths",
  connectors = "none in the figure; paired mapper differences remain exported in paired_mapper_differences.csv",
  error_bars = "none; each point is one deterministic workflow output",
  mapper_as_replicate = FALSE,
  cross_phaser_pooling = FALSE,
  axis_note = "shared linear 94-100% display range across both mapper regions; no value is clipped",
  mapper_layout = "two independent side-by-side plotting regions; no positional offset",
  depth_coordinate_grammar = "10x, 30x and 50x at category centres 1, 2 and 3; guides at boundaries 0.5, 1.5, 2.5 and 3.5",
  reuse_level = "structural adaptation of the revised LongPhase depth panels",
  stringsAsFactors = FALSE
)
write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"), na = "")

metric_definition <- data.frame(
  metric = "Phased heterozygous SNV fraction",
  numerator = "Phased SNVs",
  denominator = "Heterozygous SNVs in the WhatsHap SNP call set",
  plotted_unit = "%",
  transformation = "100 * Phased SNVs / Het SNVs",
  scale = "linear; shared across mapper regions",
  axis_range = "94-100%",
  interpretation = paste(
    "Fraction of heterozygous SNVs assigned to a phase block by WhatsHap;",
    "this is phasing yield, not truth-validated phasing accuracy."
  ),
  stringsAsFactors = FALSE
)
write_csv(metric_definition, file.path(OUTPUT_DIR, "metric_definitions.csv"), na = "")

DEPTH_CENTRES <- seq_along(EXPECTED_DEPTHS)
DEPTH_BOUNDARIES <- seq(0.5, length(EXPECTED_DEPTHS) + 0.5, by = 1)

theme_phased_snv_subpanel <- function() {
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

make_phased_snv_subpanel <- function(mapper_name, panel_index) {
  panel_data <- plot_data |> filter(as.character(mapper) == mapper_name)
  if (nrow(panel_data) != 9L) stop("Each mapper panel must contain exactly nine observations")
  ggplot(panel_data, aes(x = depth_index, y = phased_snv_pct, colour = platform, group = platform)) +
    geom_vline(data = data.frame(x_boundary = DEPTH_BOUNDARIES), aes(xintercept = x_boundary), inherit.aes = FALSE, colour = "#D7D7D7", linewidth = 0.34) +
    geom_line(linewidth = 0.72, lineend = "round", linejoin = "round") +
    geom_point(size = 2.05, shape = 16) +
    scale_colour_manual(values = PLATFORM_COLORS, breaks = EXPECTED_PLATFORMS, limits = EXPECTED_PLATFORMS, drop = FALSE, guide = "none") +
    scale_x_continuous(name = "Sequencing Depth", limits = range(DEPTH_BOUNDARIES), breaks = DEPTH_CENTRES, labels = paste0(EXPECTED_DEPTHS, "×"), expand = expansion(mult = 0)) +
    scale_y_continuous(name = if (panel_index == 1L) "Phased heterozygous SNVs (%)" else "\u00A0", breaks = seq(94, 100, by = 2), labels = label_number(accuracy = 1, suffix = "%"), limits = c(94, 100), expand = expansion(mult = 0)) +
    labs(title = mapper_name) + theme_phased_snv_subpanel()
}

panel_plots <- Map(make_phased_snv_subpanel, EXPECTED_MAPPERS, seq_along(EXPECTED_MAPPERS))

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
  paired_comparisons_exported = nrow(paired_data),
  panel_layout = "1 x 2 independent axes: mapper",
  depth_coordinate_grammar = "centres 1,2,3; boundaries 0.5,1.5,2.5,3.5",
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
write_csv(manifest, file.path(OUTPUT_DIR, "render_manifest.csv"), na = "")

message("Rendered WhatsHap phased-SNV depth trajectories to: ", OUTPUT_DIR)
