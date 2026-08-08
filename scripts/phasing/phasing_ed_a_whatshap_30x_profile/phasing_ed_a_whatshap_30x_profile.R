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
BLOCK_FILE <- file.path(ROOT, "data", "phasing_block_stats_whatshap.csv")
ACCURACY_FILE <- file.path(ROOT, "data", "phasing_accuracy_whatshap.csv")
OUTPUT_DIR <- file.path(ROOT, "figures", "phasing", "phasing_ed_a_whatshap_30x_profile")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

FIGURE_STEM <- "phasing_ed_a_whatshap_30x_profile"
WIDTH_MM <- 183
HEIGHT_MM <- 52
DPI <- 600
TARGET_DEPTH <- "30x"
EXPECTED_PLATFORMS <- c("BGI", "ONT", "HiFi")
EXPECTED_MAPPERS <- c("minimap2", "winnowmap")

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

read_source <- function(path) {
  read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    locale = locale(encoding = "UTF-8")
  )
}

block_raw <- read_source(BLOCK_FILE)
accuracy_raw <- read_source(ACCURACY_FILE)

required_block <- c(
  "Dataset", "Reference", "Mapper", "Depth", "Het SNVs", "Phased SNVs",
  "Phased SNV rate", "WhatsHap block NG50", "Status", "Tool"
)
required_accuracy <- c(
  "Dataset", "Reference", "Mapper", "Depth", "Covered variants", "Assessed pairs",
  "Switch errors", "Switch error rate", "Blockwise Hamming", "Hamming rate", "Truth het SNVs", "Status"
)

missing_block <- setdiff(required_block, names(block_raw))
missing_accuracy <- setdiff(required_accuracy, names(accuracy_raw))
if (length(missing_block) > 0L) {
  stop("Missing WhatsHap block-stat columns: ", paste(missing_block, collapse = ", "))
}
if (length(missing_accuracy) > 0L) {
  stop("Missing WhatsHap accuracy columns: ", paste(missing_accuracy, collapse = ", "))
}
if (nrow(block_raw) != 18L || nrow(accuracy_raw) != 18L) {
  stop("Expected 18 rows in each WhatsHap source table")
}

key_columns <- c("Dataset", "Reference", "Mapper", "Depth")
block_30x <- block_raw |>
  filter(Depth == TARGET_DEPTH) |>
  select(all_of(required_block))
accuracy_30x <- accuracy_raw |>
  filter(Depth == TARGET_DEPTH) |>
  select(all_of(required_accuracy))

if (nrow(block_30x) != 6L || nrow(accuracy_30x) != 6L) {
  stop("Expected six 30x rows in each WhatsHap source table")
}
if (anyDuplicated(block_30x[key_columns]) || anyDuplicated(accuracy_30x[key_columns])) {
  stop("Duplicated platform-reference-mapper-depth key in 30x records")
}

wide <- inner_join(
  block_30x,
  accuracy_30x,
  by = key_columns,
  suffix = c(".block", ".accuracy")
) |>
  mutate(
    Platform = sub("_latest$", "", Dataset),
    phased_heterozygous_snvs_pct = 100 * `Phased SNVs` / `Het SNVs`,
    phase_block_NG50_Mb = as.numeric(`WhatsHap block NG50`),
    switch_errors_per_10000 = 10000 * `Switch errors` / `Assessed pairs`,
    blockwise_hamming_error_pct = 100 * `Blockwise Hamming` / `Covered variants`
  )

if (nrow(wide) != 6L) stop("The 30x WhatsHap block and accuracy tables did not join one-to-one")
if (!setequal(wide$Platform, EXPECTED_PLATFORMS)) stop("Unexpected platform set")
if (!setequal(wide$Mapper, EXPECTED_MAPPERS)) stop("Unexpected mapper set")
if (any(wide$Reference != "GRCh38")) stop("All plotted rows must use GRCh38")
if (any(wide$Status.block != "Complete") || any(wide$Status.accuracy != "Complete")) {
  stop("All plotted rows must have Complete status")
}
if (any(wide$Tool != "WhatsHap 2.8")) stop("Unexpected phasing tool")

expected_keys <- expand.grid(
  Platform = EXPECTED_PLATFORMS,
  Mapper = EXPECTED_MAPPERS,
  stringsAsFactors = FALSE
) |>
  transmute(key = paste(Platform, Mapper, sep = "|"))
observed_keys <- wide |>
  transmute(key = paste(Platform, Mapper, sep = "|"))
if (!setequal(expected_keys$key, observed_keys$key)) {
  stop("The plotted 30x design is not the complete 3-platform x 2-mapper matrix")
}

if (any(wide$`Het SNVs` <= 0) || any(wide$`Assessed pairs` <= 0) || any(wide$`Covered variants` <= 0)) {
  stop("All rate denominators must be positive")
}
if (any(wide$`Phased SNVs` < 0 | wide$`Phased SNVs` > wide$`Het SNVs`)) {
  stop("Phased SNV counts must lie within the heterozygous SNV denominator")
}
if (max(abs(wide$`Phased SNV rate` - wide$phased_heterozygous_snvs_pct / 100)) > 6e-5) {
  stop("Stored phased SNV rates disagree with recomputed rates")
}
if (max(abs(wide$`Switch error rate` - wide$switch_errors_per_10000 / 10000)) > 6e-7) {
  stop("Stored switch error rates disagree with recomputed rates")
}
if (max(abs(wide$`Hamming rate` - wide$blockwise_hamming_error_pct / 100)) > 6e-5) {
  stop("Stored Hamming rates disagree with recomputed rates")
}
if (any(!is.finite(wide$phase_block_NG50_Mb)) || any(wide$phase_block_NG50_Mb <= 0)) {
  stop("WhatsHap block NG50 values must be finite positive Mb values")
}

metric_spec <- data.frame(
  metric_key = c(
    "phased_heterozygous_snvs_pct", "phase_block_NG50_Mb",
    "switch_errors_per_10000", "blockwise_hamming_error_pct"
  ),
  metric_label = c(
    "Phased heterozygous\nSNVs (%)",
    "Phase-block\nNG50 (Mb)",
    "Switch errors per 10,000\nassessed pairs",
    "Blockwise Hamming\nerror (%)"
  ),
  unit = c("%", "Mb", "errors per 10,000 assessed pairs", "%"),
  numerator_field = c("Phased SNVs", NA, "Switch errors", "Blockwise Hamming"),
  denominator_field = c("Het SNVs", NA, "Assessed pairs", "Covered variants"),
  transformation = c(
    "100 * Phased SNVs / Het SNVs",
    "none; WhatsHap block NG50 is recorded in Mb",
    "10000 * Switch errors / Assessed pairs",
    "100 * Blockwise Hamming / Covered variants"
  ),
  stringsAsFactors = FALSE
)

long <- wide |>
  select(
    Dataset, Reference, Mapper, Depth, Platform,
    `Het SNVs`, `Phased SNVs`, `Phased SNV rate`, `WhatsHap block NG50`,
    `Assessed pairs`, `Switch errors`, `Switch error rate`,
    `Covered variants`, `Blockwise Hamming`, `Hamming rate`, `Truth het SNVs`,
    all_of(metric_spec$metric_key)
  ) |>
  pivot_longer(
    cols = all_of(metric_spec$metric_key),
    names_to = "metric_key",
    values_to = "display_value"
  ) |>
  left_join(metric_spec, by = "metric_key") |>
  mutate(
    Platform = factor(Platform, levels = rev(EXPECTED_PLATFORMS)),
    Mapper = factor(Mapper, levels = EXPECTED_MAPPERS),
    metric_label = factor(metric_label, levels = metric_spec$metric_label)
  ) |>
  arrange(metric_label, Platform, Mapper)

if (nrow(long) != 24L || any(!is.finite(long$display_value))) {
  stop("Expected 24 finite plotted values")
}

source_data <- long |>
  mutate(
    numerator = case_when(
      metric_key == "phased_heterozygous_snvs_pct" ~ as.numeric(`Phased SNVs`),
      metric_key == "switch_errors_per_10000" ~ as.numeric(`Switch errors`),
      metric_key == "blockwise_hamming_error_pct" ~ as.numeric(`Blockwise Hamming`),
      TRUE ~ NA_real_
    ),
    denominator = case_when(
      metric_key == "phased_heterozygous_snvs_pct" ~ as.numeric(`Het SNVs`),
      metric_key == "switch_errors_per_10000" ~ as.numeric(`Assessed pairs`),
      metric_key == "blockwise_hamming_error_pct" ~ as.numeric(`Covered variants`),
      TRUE ~ NA_real_
    ),
    source_value = case_when(
      metric_key == "phase_block_NG50_Mb" ~ as.numeric(`WhatsHap block NG50`),
      metric_key == "phased_heterozygous_snvs_pct" ~ as.numeric(`Phased SNV rate`),
      metric_key == "switch_errors_per_10000" ~ as.numeric(`Switch error rate`),
      metric_key == "blockwise_hamming_error_pct" ~ as.numeric(`Hamming rate`)
    ),
    source_value_unit = if_else(metric_key == "phase_block_NG50_Mb", "Mb", "fraction")
  ) |>
  transmute(
    platform = as.character(Platform), mapper = as.character(Mapper),
    reference = Reference, depth = Depth,
    metric = as.character(metric_label), display_value, display_unit = unit,
    numerator, denominator, source_value, source_value_unit,
    truth_het_snvs = `Truth het SNVs`, transformation
  )

write_csv(source_data, file.path(OUTPUT_DIR, "source_data_plotted.csv"), na = "")
write_csv(metric_spec, file.path(OUTPUT_DIR, "metric_definitions.csv"), na = "")

audit <- data.frame(
  source_file = c(basename(BLOCK_FILE), basename(ACCURACY_FILE)),
  source_rows = c(nrow(block_raw), nrow(accuracy_raw)),
  selected_rows = c(nrow(block_30x), nrow(accuracy_30x)),
  excluded_rows = c(nrow(block_raw) - nrow(block_30x), nrow(accuracy_raw) - nrow(accuracy_30x)),
  inclusion_rule = "Depth == 30x; all three platforms and both mappers retained",
  exclusion_reason = "10x and 50x belong to separately specified WhatsHap depth-response panels",
  aggregation = "none",
  averaging = "none",
  error_bars = "none; each bar is one deterministic workflow output",
  mapper_as_replicate = FALSE,
  cross_phaser_pooling = FALSE,
  scope_note = "WhatsHap counts and block statistics are not pooled with LongPhase results",
  chart_archetype = "four independent grouped-bar panels; mapper groups x platform bars",
  reuse_level = "structural adaptation of the LongPhase 30x grouped-bar profile",
  stringsAsFactors = FALSE
)
write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"), na = "")

axis_spec <- tibble::tibble(
  metric_key = metric_spec$metric_key,
  panel_title = c(
    "Phased heterozygous SNVs",
    "Phase-block NG50",
    "Switch-error burden",
    "Blockwise Hamming error"
  ),
  y_title = c(
    "Phased heterozygous SNVs (%)",
    "Phase-block NG50 (Mb)",
    "Errors per 10,000 pairs",
    "Blockwise Hamming error (%)"
  ),
  y_min = c(94.0, 0.0, 0.0, 0.0),
  y_max = c(100.0, 3.0, 9.0, 8.0),
  y_breaks = list(
    c(94, 96, 98, 100),
    c(0.0, 1.0, 2.0, 3.0),
    c(0, 2, 4, 6, 8),
    c(0, 2, 4, 6, 8)
  ),
  label_accuracy = c(1.0, 1.0, 1.0, 1.0),
  baseline_policy = c(
    "truncated 94-100% window; explicit ticks; comparisons are within-panel only",
    "zero baseline",
    "zero baseline",
    "zero baseline"
  )
)

axis_spec <- axis_spec |>
  left_join(
    long |>
      group_by(metric_key) |>
      summarise(
        observed_min = min(display_value),
        observed_max = max(display_value),
        .groups = "drop"
      ),
    by = "metric_key"
  ) |>
  mutate(values_within_window = observed_min >= y_min & observed_max <= y_max)

if (any(!axis_spec$values_within_window)) {
  stop("At least one metric value lies outside its declared display window")
}

write_csv(
  axis_spec |>
    transmute(
      metric_key, panel_title, y_title, y_min, y_max,
      y_breaks = vapply(y_breaks, paste, collapse = "|", character(1)),
      label_accuracy, baseline_policy, observed_min, observed_max,
      values_within_window
    ),
  file.path(OUTPUT_DIR, "axis_window_audit.csv"),
  na = ""
)

plot_data <- long |>
  mutate(
    Platform = factor(as.character(Platform), levels = EXPECTED_PLATFORMS),
    Mapper = factor(as.character(Mapper), levels = EXPECTED_MAPPERS),
    mapper_index = match(as.character(Mapper), EXPECTED_MAPPERS),
    platform_offset = recode(
      as.character(Platform),
      BGI = -0.250, ONT = 0.000, HiFi = 0.250,
      .default = NA_real_
    ),
    bar_x = mapper_index + platform_offset
  ) |>
  arrange(metric_label, Mapper, Platform)

BAR_WIDTH <- 0.200

if (any(!is.finite(plot_data$mapper_index)) ||
    any(!is.finite(plot_data$platform_offset)) ||
    any(!is.finite(plot_data$bar_x))) {
  stop("Failed to assign mapper or platform bar positions")
}

MAPPER_CENTRES <- seq_along(EXPECTED_MAPPERS)
MAPPER_BOUNDARIES <- seq(0.5, length(EXPECTED_MAPPERS) + 0.5, by = 1)

bar_left <- plot_data$bar_x - BAR_WIDTH / 2
bar_right <- plot_data$bar_x + BAR_WIDTH / 2
mapper_left <- plot_data$mapper_index - 0.5
mapper_right <- plot_data$mapper_index + 0.5
if (any(bar_left <= mapper_left) || any(bar_right >= mapper_right)) {
  stop("At least one bar extends beyond its mapper-group boundaries")
}

theme_bar_subpanel <- function() {
  theme_classic(base_size = 6.7, base_family = BASE_FAMILY) +
    theme(
      axis.line = element_blank(),
      axis.ticks = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y = element_text(
        colour = "#171717", size = 6.4, face = "bold",
        margin = margin(r = 1.8)
      ),
      axis.text.x = element_text(
        colour = "#292929", size = 5.9, margin = margin(t = 1.2)
      ),
      axis.text.y = element_text(
        colour = "#292929", size = 5.8, margin = margin(r = 0.9)
      ),
      panel.grid = element_blank(),
      plot.title = element_text(
        colour = "#111111", size = 7.0, face = "bold",
        hjust = 0.5, margin = margin(b = 2.0)
      ),
      legend.position = "none",
      plot.margin = margin(t = 1.2, r = 1.4, b = 1.2, l = 1.4, unit = "mm")
    )
}

make_bar_panel <- function(metric_name) {
  panel_data <- plot_data |> filter(metric_key == metric_name)
  spec <- axis_spec |> filter(metric_key == metric_name)
  if (nrow(panel_data) != 6L || nrow(spec) != 1L) {
    stop("Each metric panel must contain six observations and one axis specification")
  }

  ggplot(panel_data, aes(x = bar_x, y = display_value, fill = Platform)) +
    geom_vline(
      data = data.frame(x_boundary = MAPPER_BOUNDARIES),
      aes(xintercept = x_boundary),
      inherit.aes = FALSE,
      colour = "#E1E1E1",
      linewidth = 0.34
    ) +
    geom_col(width = BAR_WIDTH, colour = NA) +
    scale_fill_manual(
      values = PLATFORM_COLORS,
      breaks = EXPECTED_PLATFORMS,
      limits = EXPECTED_PLATFORMS,
      drop = FALSE,
      guide = "none"
    ) +
    scale_x_continuous(
      limits = range(MAPPER_BOUNDARIES),
      breaks = MAPPER_CENTRES,
      labels = EXPECTED_MAPPERS,
      expand = expansion(mult = 0)
    ) +
    scale_y_continuous(
      name = spec$y_title,
      breaks = spec$y_breaks[[1]],
      labels = label_number(accuracy = spec$label_accuracy, trim = FALSE),
      expand = expansion(mult = 0)
    ) +
    coord_cartesian(
      ylim = c(spec$y_min, spec$y_max),
      expand = FALSE,
      clip = "on"
    ) +
    labs(title = spec$panel_title) +
    theme_bar_subpanel()
}

panel_plots <- lapply(metric_spec$metric_key, make_bar_panel)

draw_header <- function() {
  grid::grid.text(
    "a", x = grid::unit(1.5, "mm"), y = grid::unit(0.56, "npc"),
    just = c("left", "centre"),
    gp = grid::gpar(
      fontfamily = BASE_FAMILY, fontsize = 8.0, fontface = "bold",
      col = "#202124"
    )
  )
  grid::grid.text(
    "WhatsHap  ·  HG002  ·  GRCh38  ·  matched 30×",
    x = grid::unit(7.5, "mm"), y = grid::unit(0.56, "npc"),
    just = c("left", "centre"),
    gp = grid::gpar(
      fontfamily = BASE_FAMILY, fontsize = 6.2, col = "#5F6368"
    )
  )

  grid::grid.text(
    "Platform", x = grid::unit(0.665, "npc"), y = grid::unit(0.56, "npc"),
    just = c("right", "centre"),
    gp = grid::gpar(
      fontfamily = BASE_FAMILY, fontsize = 6.0, fontface = "bold",
      col = "#343434"
    )
  )
  legend_x <- c(0.700, 0.800, 0.900)
  for (i in seq_along(EXPECTED_PLATFORMS)) {
    grid::grid.rect(
      x = grid::unit(legend_x[i], "npc"), y = grid::unit(0.56, "npc"),
      width = grid::unit(2.2, "mm"), height = grid::unit(2.2, "mm"),
      gp = grid::gpar(fill = PLATFORM_COLORS[EXPECTED_PLATFORMS[i]], col = NA)
    )
    grid::grid.text(
      EXPECTED_PLATFORMS[i],
      x = grid::unit(legend_x[i] + 0.015, "npc"),
      y = grid::unit(0.56, "npc"),
      just = c("left", "centre"),
      gp = grid::gpar(
        fontfamily = BASE_FAMILY, fontsize = 5.9, col = "#343434"
      )
    )
  }
}

draw_profile <- function() {
  grid::grid.newpage()
  page_layout <- grid::grid.layout(
    nrow = 2, ncol = length(panel_plots),
    heights = grid::unit.c(grid::unit(6.5, "mm"), grid::unit(1, "null")),
    widths = grid::unit(rep(1, length(panel_plots)), "null")
  )
  grid::pushViewport(grid::viewport(layout = page_layout))

  grid::pushViewport(grid::viewport(layout.pos.row = 1, layout.pos.col = 1:4))
  draw_header()
  grid::popViewport()

  for (panel_index in seq_along(panel_plots)) {
    print(
      panel_plots[[panel_index]], newpage = FALSE,
      vp = grid::viewport(layout.pos.row = 2, layout.pos.col = panel_index)
    )
  }
  grid::popViewport()
}

save_one <- function(ext) {
  path <- file.path(OUTPUT_DIR, paste0(FIGURE_STEM, ".", ext))
  width_in <- WIDTH_MM / 25.4
  height_in <- HEIGHT_MM / 25.4

  if (ext == "svg") {
    svglite::svglite(path, width = width_in, height = height_in, bg = "white",
                     system_fonts = list(sans = BASE_FAMILY))
  } else if (ext == "pdf") {
    grDevices::cairo_pdf(path, width = width_in, height = height_in,
                         family = BASE_FAMILY, bg = "white", onefile = TRUE)
  } else if (ext == "tiff") {
    ragg::agg_tiff(path, width = WIDTH_MM, height = HEIGHT_MM, units = "mm",
                   res = DPI, background = "white", scaling = 1)
  } else if (ext == "png") {
    ragg::agg_png(path, width = WIDTH_MM, height = HEIGHT_MM, units = "mm",
                  res = DPI, background = "white", scaling = 1)
  } else {
    stop("Unsupported extension: ", ext)
  }

  draw_profile()
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
  plotted_bars = nrow(long),
  unique_workflow_outputs = nrow(wide),
  panel_layout = "1 x 4 independent grouped-bar panels",
  mapper_layout = "two x-axis groups per panel; three platform bars per group",
  bar_geometry = "width 0.200; platform offsets -0.250,0,+0.250; within-group gap 0.050",
  platform_legend = "single shared header legend",
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
write_csv(manifest, file.path(OUTPUT_DIR, "render_manifest.csv"), na = "")

message("Rendered WhatsHap 30x profile to: ", OUTPUT_DIR)
