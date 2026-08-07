suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(grid)
  library(systemfonts)
  library(svglite)
  library(ragg)
})

find_root <- function() {
  arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(arg) == 1L) {
    script_path <- normalizePath(sub("^--file=", "", arg))
    return(dirname(dirname(dirname(script_path))))
  }
  normalizePath(getwd())
}

ROOT <- find_root()
DATA_FILE <- file.path(ROOT, "data", "mosaic_sv_pilot.csv")
OUTPUT_DIR <- file.path(ROOT, "figures", "codex_mosaic_sv_pilot")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

fig_width_mm = 89
fig_height_mm = 93
vaf_width_mm <- 105
vaf_height_mm <- 75

PLATFORM_LEVELS <- c("BGI", "ONT", "HiFi")
ALIGNER_LEVELS <- c("minimap2", "winnowmap")
SV_TYPES <- c("DEL", "INS", "DUP", "INV", "BND")
VAF_BINS <- c("VAF 5–10%", "VAF 10–20%")

# Fixed platform mapping inherited from the existing SV figures.
PLATFORM_COLORS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)
PLATFORM_SHAPES <- c(BGI = 16, ONT = 17, HiFi = 15)

# Muted count-composition palette inherited from the MEI figure family.
VAF_COLORS <- c(
  `VAF 5–10%` = "#A8B0BE",
  `VAF 10–20%` = "#A98970"
)

TEXT_COLOR <- "#171717"
SECONDARY_TEXT <- "#555555"
GRID_COLOR <- "#D5D7DA"
SEGMENT_EDGE <- "#777D84"

font_candidates <- c("Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans")
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

if (identical(BASE_FAMILY, "Nimbus Sans") &&
    !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  nimbus_metrics <- grDevices::pdfFonts("NimbusSan")[[1]]
  do.call(grDevices::pdfFonts, setNames(list(nimbus_metrics), BASE_FAMILY))
}

read_mosaic_data <- function() {
  raw <- read_csv(
    DATA_FILE,
    show_col_types = FALSE,
    progress = FALSE,
    locale = locale(encoding = "UTF-8")
  )

  required <- c(
    "Dataset", "Aligner", "Depth", "Caller", "Total calls",
    "DEL", "INS", "DUP", "INV", "BND",
    "VAF 5%-10%", "VAF 10%-20%",
    "Mean VAF", "Median VAF", "Median support"
  )
  missing_columns <- setdiff(required, names(raw))
  if (length(missing_columns) > 0L) {
    stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
  }

  wide <- raw |>
    transmute(
      dataset = as.character(Dataset),
      platform = sub("_latest$", "", as.character(Dataset)),
      aligner = as.character(Aligner),
      depth = as.character(Depth),
      caller = as.character(Caller),
      total_calls = as.numeric(`Total calls`),
      DEL = as.numeric(DEL),
      INS = as.numeric(INS),
      DUP = as.numeric(DUP),
      INV = as.numeric(INV),
      BND = as.numeric(BND),
      vaf_5_10 = as.numeric(`VAF 5%-10%`),
      vaf_10_20 = as.numeric(`VAF 10%-20%`),
      mean_vaf = as.numeric(`Mean VAF`),
      median_vaf = as.numeric(`Median VAF`),
      median_support = as.numeric(`Median support`)
    ) |>
    mutate(
      platform = factor(platform, levels = PLATFORM_LEVELS),
      aligner = factor(aligner, levels = ALIGNER_LEVELS),
      sv_type_sum = DEL + INS + DUP + INV + BND,
      vaf_bin_sum = vaf_5_10 + vaf_10_20,
      sv_type_residual = total_calls - sv_type_sum,
      vaf_bin_residual = total_calls - vaf_bin_sum
    ) |>
    arrange(aligner, platform)

  if (nrow(wide) != 6L) stop("Expected 6 platform-aligner observations")
  if (any(is.na(wide$platform)) || any(is.na(wide$aligner))) {
    stop("Unexpected platform or aligner label")
  }
  key_counts <- wide |> count(platform, aligner, name = "n")
  if (nrow(key_counts) != 6L || any(key_counts$n != 1L)) {
    stop("Platform-aligner design contains missing or duplicated keys")
  }
  if (any(wide$depth != "30x") || any(wide$caller != "Sniffles2")) {
    stop("Rows do not share the declared 30x Sniffles2 mosaic design")
  }
  numeric_values <- unlist(
    wide[c("total_calls", SV_TYPES, "vaf_5_10", "vaf_10_20")],
    use.names = FALSE
  )
  if (any(!is.finite(numeric_values)) || any(numeric_values < 0)) {
    stop("Candidate counts must be finite and non-negative")
  }
  if (any(wide$sv_type_residual != 0)) {
    stop("Total calls does not equal DEL + INS + DUP + INV + BND")
  }
  if (any(wide$vaf_bin_residual != 0)) {
    stop("Total calls does not equal the two VAF-bin counts")
  }
  if (any(!is.finite(wide$mean_vaf)) || any(!is.finite(wide$median_vaf)) ||
      any(wide$mean_vaf < 0.05 | wide$mean_vaf > 0.20) ||
      any(wide$median_vaf < 0.05 | wide$median_vaf > 0.20)) {
    stop("Mean and median VAF must be finite and within the configured 5–20% interval")
  }
  if (any(wide$median_support <= 0)) {
    stop("Median support must be positive")
  }

  radar <- wide |>
    pivot_longer(
      cols = all_of(SV_TYPES),
      names_to = "sv_type",
      values_to = "count"
    ) |>
    mutate(
      sv_type = factor(sv_type, levels = SV_TYPES),
      axis = as.numeric(sv_type),
      proportion = count / total_calls,
      platform = factor(platform, levels = PLATFORM_LEVELS)
    )

  radar_check <- radar |>
    group_by(platform, aligner) |>
    summarise(proportion_sum = sum(proportion), .groups = "drop")
  if (max(abs(radar_check$proportion_sum - 1)) > 1e-12) {
    stop("SV-type proportions do not sum to one")
  }

  vaf <- wide |>
    select(
      dataset, platform, aligner, depth, caller, total_calls,
      vaf_5_10, vaf_10_20, mean_vaf, median_vaf, median_support
    ) |>
    pivot_longer(
      cols = c(vaf_5_10, vaf_10_20),
      names_to = "vaf_bin_key",
      values_to = "count"
    ) |>
    mutate(
      vaf_bin = recode(
        vaf_bin_key,
        vaf_5_10 = "VAF 5–10%",
        vaf_10_20 = "VAF 10–20%"
      ),
      vaf_bin = factor(vaf_bin, levels = VAF_BINS),
      proportion = count / total_calls,
      segment_label = sprintf("%.1f%%", 100 * proportion)
    )

  list(raw = raw, wide = wide, radar = radar, vaf = vaf)
}

theme_radar <- function() {
  theme_void(base_size = 7.2, base_family = BASE_FAMILY) +
    theme(
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      plot.title = element_text(
        size = 8.6, face = "bold", colour = "#161616", hjust = 0.5,
        margin = margin(b = 0.2, unit = "mm")
      ),
      plot.subtitle = element_text(
        size = 6.3, face = "plain", colour = "#666666", hjust = 0.5,
        margin = margin(b = 0.8, unit = "mm")
      ),
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.box.just = "center",
      legend.direction = "horizontal",
      legend.title = element_text(size = 6.2, colour = "#303030"),
      legend.text = element_text(size = 5.8, colour = "#4D4D4D"),
      legend.key.width = unit(5.0, "mm"),
      legend.key.height = unit(3.0, "mm"),
      legend.spacing.x = unit(0.8, "mm"),
      legend.spacing.y = unit(0.2, "mm"),
      plot.margin = margin(t = 2.5, r = 5.5, b = 1.5, l = 5.5, unit = "mm")
    )
}

make_radar_plot <- function(radar_data, wide_data, aligner_name) {
  d <- radar_data |>
    filter(as.character(aligner) == aligner_name) |>
    arrange(platform, sv_type)

  # Match the established radar template: custom polygonal grid, unfilled
  # platform profiles, no vertex markers, and radial labels along the top axis.
  # A single square-root transform is applied to every spoke. Tick labels remain
  # the true proportions, so rare SV classes gain legibility without per-axis
  # normalization or a change of denominator.
  outer_limit <- 0.60
  ring_levels <- c(0, 0.01, 0.05, 0.10, 0.30, 0.60)
  to_radius <- function(proportion) sqrt(proportion / outer_limit)
  axis_geometry <- tibble::tibble(
    axis = seq_along(SV_TYPES),
    sv_type = factor(SV_TYPES, levels = SV_TYPES),
    angle = pi / 2 - 2 * pi * (seq_along(SV_TYPES) - 1) / length(SV_TYPES)
  ) |>
    mutate(unit_x = cos(angle), unit_y = sin(angle))

  d <- d |>
    left_join(axis_geometry |> select(axis, angle, unit_x, unit_y), by = "axis") |>
    mutate(
      radius = to_radius(proportion),
      x = radius * unit_x,
      y = radius * unit_y
    )

  d_closed <- d |>
    group_by(platform) |>
    arrange(axis, .by_group = TRUE) |>
    group_modify(~ bind_rows(.x, slice(.x, 1L))) |>
    ungroup()

  ring_data <- tidyr::expand_grid(
    level = ring_levels,
    axis = seq_along(SV_TYPES)
  ) |>
    left_join(axis_geometry, by = "axis") |>
    mutate(
      radius = to_radius(level),
      x = radius * unit_x,
      y = radius * unit_y
    ) |>
    group_by(level) |>
    arrange(axis, .by_group = TRUE) |>
    group_modify(~ bind_rows(.x, slice(.x, 1L))) |>
    ungroup()

  spoke_data <- axis_geometry |>
    transmute(x = 0, y = 0, xend = unit_x, yend = unit_y)

  axis_labels <- axis_geometry |>
    mutate(
      x = 1.12 * unit_x,
      y = 1.12 * unit_y,
      hjust = case_when(unit_x > 0.15 ~ 0, unit_x < -0.15 ~ 1, TRUE ~ 0.5),
      vjust = case_when(unit_y > 0.80 ~ 0.25, unit_y < -0.50 ~ 1, TRUE ~ 0.5)
    )

  ring_labels <- tibble::tibble(level = ring_levels) |>
    mutate(
      x = -0.035,
      y = to_radius(level),
      label = scales::percent(level, accuracy = 1)
    )

  inner_grid <- ring_data |> filter(level < max(ring_levels))
  outer_grid <- ring_data |> filter(level == max(ring_levels))

  ggplot() +
    geom_path(
      data = inner_grid,
      aes(x = x, y = y, group = factor(level)),
      colour = "#D9D9D9",
      linewidth = 0.22,
      linejoin = "round"
    ) +
    geom_path(
      data = outer_grid,
      aes(x = x, y = y, group = factor(level)),
      colour = "#D0D0D0",
      linewidth = 0.25,
      linejoin = "round"
    ) +
    geom_segment(
      data = spoke_data,
      aes(x = x, y = y, xend = xend, yend = yend),
      colour = "#D9D9D9",
      linewidth = 0.22
    ) +
    geom_path(
      data = d_closed,
      aes(x = x, y = y, group = platform, colour = platform),
      linewidth = 0.50,
      alpha = 0.92,
      lineend = "round",
      linejoin = "round"
    ) +
    geom_point(
      data = d,
      aes(x = x, y = y, colour = platform),
      shape = 16,
      size = 1.20,
      alpha = 0.95,
      stroke = 0,
      show.legend = FALSE
    ) +
    geom_text(
      data = axis_labels,
      aes(x = x, y = y, label = sv_type, hjust = hjust, vjust = vjust),
      family = BASE_FAMILY,
      size = 2.25,
      colour = "#242424"
    ) +
    geom_text(
      data = ring_labels,
      aes(x = x, y = y, label = label),
      family = BASE_FAMILY,
      size = 1.85,
      colour = "#555555",
      hjust = 1.08,
      vjust = -0.15
    ) +
    scale_colour_manual(
      values = PLATFORM_COLORS,
      breaks = PLATFORM_LEVELS,
      drop = FALSE
    ) +
    coord_equal(
      xlim = c(-1.23, 1.23),
      ylim = c(-1.18, 1.20),
      expand = FALSE,
      clip = "off"
    ) +
    labs(
      title = aligner_name,
      subtitle = "SV-type composition · square-root radial scale",
      colour = "Platform"
    ) +
    guides(
      colour = guide_legend(
        order = 1,
        title.position = "top",
        nrow = 1,
        byrow = TRUE,
        override.aes = list(linetype = "solid", linewidth = 0.65)
      )
    ) +
    theme_radar()
}

theme_vaf <- function() {
  theme_classic(base_size = 6.5, base_family = BASE_FAMILY) +
    theme(
      axis.line = element_line(colour = "#111111", linewidth = 0.28),
      axis.ticks = element_line(colour = "#111111", linewidth = 0.25),
      axis.ticks.length = unit(1.5, "pt"),
      axis.title.y = element_text(
        size = 6.8, colour = TEXT_COLOR, margin = margin(r = 3.0)
      ),
      axis.title.x = element_blank(),
      axis.text.y = element_text(size = 5.7, colour = TEXT_COLOR),
      axis.text.x = element_text(
        size = 5.5, colour = TEXT_COLOR, margin = margin(t = 1.2)
      ),
      panel.grid = element_blank(),
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.title = element_blank(),
      legend.text = element_text(size = 5.7, colour = TEXT_COLOR),
      legend.key.width = unit(4.2, "mm"),
      legend.key.height = unit(3.1, "mm"),
      legend.spacing.x = unit(1.5, "mm"),
      legend.margin = margin(t = 4.5, unit = "mm"),
      legend.background = element_rect(fill = NA, colour = NA),
      legend.box.background = element_blank(),
      plot.margin = margin(t = 2.2, r = 2.5, b = 2.0, l = 2.0, unit = "mm")
    )
}

make_vaf_plot <- function(vaf_data, wide_data) {
  x_positions <- c(1, 2, 4, 5, 7, 8)
  platform_centers <- c(BGI = 1.5, ONT = 4.5, HiFi = 7.5)

  position_key <- wide_data |>
    arrange(platform, aligner) |>
    transmute(platform, aligner, x = x_positions)

  d <- vaf_data |>
    left_join(position_key, by = c("platform", "aligner")) |>
    arrange(platform, aligner, vaf_bin)

  totals <- wide_data |>
    arrange(platform, aligner) |>
    left_join(position_key, by = c("platform", "aligner")) |>
    mutate(total_label = scales::comma(total_calls))

  group_labels <- tibble::tibble(
    platform = names(platform_centers),
    x = unname(platform_centers),
    y = -430
  )

  ggplot(d, aes(x = x, y = count, fill = vaf_bin)) +
    geom_col(
      width = 0.58,
      colour = SEGMENT_EDGE,
      linewidth = 0.16,
      position = position_stack(reverse = TRUE)
    ) +
    geom_text(
      aes(label = segment_label),
      position = position_stack(vjust = 0.5, reverse = TRUE),
      size = 1.72,
      family = BASE_FAMILY,
      colour = TEXT_COLOR
    ) +
    geom_text(
      data = totals,
      aes(x = x, y = total_calls + 155, label = total_label),
      inherit.aes = FALSE,
      size = 1.72,
      family = BASE_FAMILY,
      colour = TEXT_COLOR
    ) +
    geom_text(
      data = group_labels,
      aes(x = x, y = y, label = platform),
      inherit.aes = FALSE,
      size = 1.95,
      family = BASE_FAMILY,
      colour = TEXT_COLOR
    ) +
    scale_fill_manual(
      values = VAF_COLORS,
      breaks = VAF_BINS,
      drop = FALSE
    ) +
    scale_x_continuous(
      limits = c(0.4, 8.6),
      breaks = x_positions,
      labels = rep(ALIGNER_LEVELS, times = 3),
      expand = expansion(mult = c(0, 0))
    ) +
    scale_y_continuous(
      breaks = seq(0, 4000, by = 1000),
      labels = scales::label_comma(),
      expand = expansion(mult = c(0, 0))
    ) +
    coord_cartesian(ylim = c(0, 4450), clip = "off") +
    labs(
      x = NULL,
      y = "Low-VAF SV candidates",
      fill = NULL
    ) +
    guides(fill = guide_legend(nrow = 1, byrow = TRUE)) +
    theme_vaf()
}

save_plot_bundle <- function(plot_object, stem, width_mm, height_mm) {
  width_in <- width_mm / 25.4
  height_in <- height_mm / 25.4

  ggsave(
    file.path(OUTPUT_DIR, paste0(stem, ".png")),
    plot_object,
    device = ragg::agg_png,
    width = width_in,
    height = height_in,
    units = "in",
    dpi = 320,
    background = "white"
  )
  ggsave(
    file.path(OUTPUT_DIR, paste0(stem, ".tiff")),
    plot_object,
    device = ragg::agg_tiff,
    width = width_in,
    height = height_in,
    units = "in",
    dpi = 600,
    compression = "lzw",
    background = "white"
  )
  svglite::svglite(
    file.path(OUTPUT_DIR, paste0(stem, ".svg")),
    width = width_in,
    height = height_in,
    bg = "white"
  )
  print(plot_object)
  grDevices::dev.off()

  grDevices::cairo_pdf(
    file.path(OUTPUT_DIR, paste0(stem, ".pdf")),
    width = width_in,
    height = height_in,
    family = BASE_FAMILY,
    bg = "white"
  )
  print(plot_object)
  grDevices::dev.off()
}

write_provenance <- function(data_objects) {
  write_csv(
    data_objects$radar |>
      transmute(
        dataset, platform = as.character(platform),
        aligner = as.character(aligner), depth, caller,
        sv_type = as.character(sv_type), count, total_calls, proportion
      ),
    file.path(OUTPUT_DIR, "source_data_sv_type_radar.csv")
  )
  write_csv(
    data_objects$vaf |>
      transmute(
        dataset, platform = as.character(platform),
        aligner = as.character(aligner), depth, caller,
        vaf_bin = as.character(vaf_bin), count, total_calls, proportion,
        mean_vaf, median_vaf, median_support
      ),
    file.path(OUTPUT_DIR, "source_data_vaf_stacked.csv")
  )

  audit <- tibble::tibble(
    source_file = basename(DATA_FILE),
    source_rows = nrow(data_objects$raw),
    selected_rows = nrow(data_objects$wide),
    excluded_rows = nrow(data_objects$raw) - nrow(data_objects$wide),
    selected_platforms = paste(PLATFORM_LEVELS, collapse = "|"),
    selected_aligners = paste(ALIGNER_LEVELS, collapse = "|"),
    common_depth = "30x",
    common_caller = "Sniffles2 mosaic mode",
    max_sv_type_sum_residual = max(abs(data_objects$wide$sv_type_residual)),
    max_vaf_bin_sum_residual = max(abs(data_objects$wide$vaf_bin_residual)),
    radar_denominator = "Total calls within each platform-aligner workflow",
    radar_common_scale = "0-60% on every spoke and both aligners",
    radar_radial_transform = "sqrt(proportion / 0.60); tick labels remain true proportions",
    per_spoke_normalization = FALSE,
    vaf_bar_measure = "absolute candidate counts",
    vaf_bar_total_labels = TRUE,
    uncertainty_available = FALSE,
    inferential_statistics_used = FALSE,
    aggregation_used = FALSE,
    smoothing_used = FALSE,
    interpolation_used = FALSE,
    interpretation_boundary = "candidate burden and composition; no truth-based accuracy claim"
  )
  write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"))

  manifest <- tibble::tibble(
    output_stem = c(
      "mosaic_sv_type_radar_minimap2",
      "mosaic_sv_type_radar_winnowmap",
      "mosaic_sv_vaf_stacked_counts"
    ),
    figure_width_mm = c(fig_width_mm, fig_width_mm, vaf_width_mm),
    figure_height_mm = c(fig_height_mm, fig_height_mm, vaf_height_mm),
    role = c(
      "SV-type composition under minimap2",
      "SV-type composition under winnowmap",
      "absolute candidate burden and VAF-bin composition"
    ),
    source_file = basename(DATA_FILE),
    base_font_family = BASE_FAMILY,
    png_dpi = 320,
    tiff_dpi = 600
  )
  write_csv(manifest, file.path(OUTPUT_DIR, "render_manifest.csv"))
}

data_objects <- read_mosaic_data()

radar_minimap2 <- make_radar_plot(
  data_objects$radar,
  data_objects$wide,
  "minimap2"
)
radar_winnowmap <- make_radar_plot(
  data_objects$radar,
  data_objects$wide,
  "winnowmap"
)
vaf_stacked <- make_vaf_plot(data_objects$vaf, data_objects$wide)

write_provenance(data_objects)
save_plot_bundle(
  radar_minimap2,
  "mosaic_sv_type_radar_minimap2",
  fig_width_mm,
  fig_height_mm
)
save_plot_bundle(
  radar_winnowmap,
  "mosaic_sv_type_radar_winnowmap",
  fig_width_mm,
  fig_height_mm
)
save_plot_bundle(
  vaf_stacked,
  "mosaic_sv_vaf_stacked_counts",
  vaf_width_mm,
  vaf_height_mm
)

message("Wrote mosaic-SV pilot figures and provenance files to: ", OUTPUT_DIR)
