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
OUTPUT_DIR <- file.path(ROOT, "figures", "codex_mosaic_sv_dual_track")
OUTPUT_STEM <- "mosaic_sv_candidate_dual_track"
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

FIGURE_WIDTH_MM <- 183
FIGURE_HEIGHT_MM <- 112
PNG_DPI <- 320
TIFF_DPI <- 600

PLATFORM_LEVELS <- c("BGI", "ONT", "HiFi")
ALIGNER_LEVELS <- c("minimap2", "winnowmap")
SV_TYPES <- c("DEL", "INS", "DUP", "INV", "BND")
VAF_BINS <- c("VAF 5–10%", "VAF 10–20%")
X_POSITIONS <- c(1, 2, 4, 5, 7, 8)
PLATFORM_CENTERS <- c(BGI = 1.5, ONT = 4.5, HiFi = 7.5)

# Fixed platform mapping used throughout the manuscript SV figures.
PLATFORM_COLORS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)

# Muted categorical family retained from the established manuscript figures.
SV_TYPE_COLORS <- c(
  DEL = "#A8B0BE",
  INS = "#A98970",
  DUP = "#6F9FA0",
  INV = "#765B96",
  BND = "#C2A55F"
)

# Purple-grey pies follow the visual character of the provided reference while
# remaining distinct from the five SV-type fills.
VAF_COLORS <- c(
  `VAF 5–10%` = "#625A70",
  `VAF 10–20%` = "#AAA3B3"
)

FILL_COLORS <- c(SV_TYPE_COLORS, VAF_COLORS)
TEXT_COLOR <- "#171717"
SECONDARY_TEXT <- "#555555"

# The pie centers lie above the quantitative panel. Their common size and
# position are decorative/summary geometry, not additional quantitative axes.
BAR_Y_MAX <- 4300
PIE_CENTER_Y <- 4860
PIE_RADIUS_X <- 0.190
PIE_RADIUS_Y <- 255
PIE_POINTS_PER_SLICE <- 90L

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
    arrange(platform, aligner) |>
    mutate(
      x = X_POSITIONS,
      total_label = scales::comma(total_calls)
    )

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

  numeric_fields <- c(
    "total_calls", SV_TYPES, "vaf_5_10", "vaf_10_20",
    "mean_vaf", "median_vaf", "median_support"
  )
  numeric_values <- unlist(wide[numeric_fields], use.names = FALSE)
  if (any(!is.finite(numeric_values)) || any(numeric_values < 0)) {
    stop("All plotted numeric values must be finite and non-negative")
  }
  if (any(wide$sv_type_residual != 0)) {
    stop("Total calls does not equal DEL + INS + DUP + INV + BND")
  }
  if (any(wide$vaf_bin_residual != 0)) {
    stop("Total calls does not equal the two VAF-bin counts")
  }
  if (any(wide$mean_vaf < 0.05 | wide$mean_vaf > 0.20) ||
      any(wide$median_vaf < 0.05 | wide$median_vaf > 0.20)) {
    stop("Mean and median VAF must remain within the configured 5–20% interval")
  }
  if (any(wide$median_support <= 0)) {
    stop("Median support must be positive")
  }

  sv <- wide |>
    select(
      dataset, platform, aligner, depth, caller, x, total_calls,
      mean_vaf, median_vaf, median_support, all_of(SV_TYPES)
    ) |>
    pivot_longer(
      cols = all_of(SV_TYPES),
      names_to = "category",
      values_to = "count"
    ) |>
    mutate(
      category = factor(category, levels = SV_TYPES),
      proportion = count / total_calls,
      segment_label = if_else(
        proportion >= 0.065,
        scales::percent(proportion, accuracy = 1),
        ""
      )
    )

  vaf <- wide |>
    select(
      dataset, platform, aligner, depth, caller, x, total_calls,
      mean_vaf, median_vaf, median_support, vaf_5_10, vaf_10_20
    ) |>
    pivot_longer(
      cols = c(vaf_5_10, vaf_10_20),
      names_to = "category_key",
      values_to = "count"
    ) |>
    mutate(
      category = recode(
        category_key,
        vaf_5_10 = "VAF 5–10%",
        vaf_10_20 = "VAF 10–20%"
      ),
      category = factor(category, levels = VAF_BINS),
      proportion = count / total_calls
    ) |>
    group_by(dataset, platform, aligner, x, total_calls) |>
    arrange(category, .by_group = TRUE) |>
    mutate(
      end_prop = cumsum(proportion),
      start_prop = lag(end_prop, default = 0),
      angle_start = pi / 2 - 2 * pi * start_prop,
      angle_end = pi / 2 - 2 * pi * end_prop,
      angle_mid = pi / 2 - 2 * pi * ((start_prop + end_prop) / 2),
      pie_label = scales::percent(proportion, accuracy = 1),
      pie_label_colour = if_else(
        as.character(category) == "VAF 5–10%", "white", TEXT_COLOR
      )
    ) |>
    ungroup()

  pie_arc <- vaf |>
    select(
      dataset, platform, aligner, x, category,
      angle_start, angle_end
    ) |>
    tidyr::uncount(PIE_POINTS_PER_SLICE, .id = "arc_point") |>
    mutate(
      angle = angle_start +
        (arc_point - 1) / (PIE_POINTS_PER_SLICE - 1) *
        (angle_end - angle_start),
      pie_x = x + PIE_RADIUS_X * cos(angle),
      pie_y = PIE_CENTER_Y + PIE_RADIUS_Y * sin(angle),
      polygon_order = arc_point
    )

  pie_polygons <- bind_rows(
    vaf |>
      transmute(
        dataset, platform, aligner, x, category,
        pie_x = x, pie_y = PIE_CENTER_Y,
        polygon_order = 0L
      ),
    pie_arc |>
      select(
        dataset, platform, aligner, x, category,
        pie_x, pie_y, polygon_order
      ),
    vaf |>
      transmute(
        dataset, platform, aligner, x, category,
        pie_x = x, pie_y = PIE_CENTER_Y,
        polygon_order = PIE_POINTS_PER_SLICE + 1L
      )
  ) |>
    mutate(
      pie_group = interaction(dataset, aligner, category, drop = TRUE)
    ) |>
    arrange(pie_group, polygon_order)

  pie_labels <- vaf |>
    transmute(
      dataset,
      platform,
      aligner,
      x = x + 0.57 * PIE_RADIUS_X * cos(angle_mid),
      y = PIE_CENTER_Y + 0.57 * PIE_RADIUS_Y * sin(angle_mid),
      category,
      label = pie_label,
      label_colour = pie_label_colour
    )

  list(
    raw = raw,
    wide = wide,
    sv = sv,
    vaf = vaf,
    pie_polygons = pie_polygons,
    pie_labels = pie_labels
  )
}

make_plot <- function(data_objects) {
  wide <- data_objects$wide
  sv <- data_objects$sv
  pie_polygons <- data_objects$pie_polygons
  pie_labels <- data_objects$pie_labels

  platform_labels <- tibble::tibble(
    platform = factor(PLATFORM_LEVELS, levels = PLATFORM_LEVELS),
    x = unname(PLATFORM_CENTERS),
    y = -455
  )
  platform_rules <- platform_labels |>
    transmute(
      platform,
      x_start = x - 0.57,
      x_end = x + 0.57,
      y = -245,
      yend = -245
    )
  separators <- tibble::tibble(x = c(3, 6))

  ggplot() +
    geom_segment(
      data = separators,
      aes(x = x, xend = x, y = 0, yend = 4200),
      colour = "#171717",
      linewidth = 0.32,
      linetype = "22"
    ) +
    geom_col(
      data = sv,
      aes(x = x, y = count, fill = category),
      width = 0.62,
      colour = "white",
      linewidth = 0.24,
      position = position_stack(reverse = TRUE)
    ) +
    geom_text(
      data = sv |> filter(segment_label != ""),
      aes(x = x, y = count, label = segment_label),
      family = BASE_FAMILY,
      size = 1.70,
      colour = TEXT_COLOR,
      position = position_stack(vjust = 0.5, reverse = TRUE)
    ) +
    geom_text(
      data = wide,
      aes(x = x, y = total_calls + 105, label = total_label),
      family = BASE_FAMILY,
      size = 1.74,
      colour = TEXT_COLOR
    ) +
    geom_polygon(
      data = pie_polygons,
      aes(x = pie_x, y = pie_y, group = pie_group, fill = category),
      colour = "white",
      linewidth = 0.34,
      linejoin = "round"
    ) +
    geom_text(
      data = pie_labels,
      aes(x = x, y = y, label = label, colour = label_colour),
      family = BASE_FAMILY,
      fontface = "plain",
      size = 1.42,
      show.legend = FALSE
    ) +
    geom_segment(
      data = platform_rules,
      aes(x = x_start, xend = x_end, y = y, yend = yend, colour = platform),
      linewidth = 0.75,
      lineend = "butt",
      show.legend = FALSE
    ) +
    geom_text(
      data = platform_labels,
      aes(x = x, y = y, label = platform, colour = platform),
      family = BASE_FAMILY,
      fontface = "bold",
      size = 2.05,
      show.legend = FALSE
    ) +
    scale_fill_manual(
      values = FILL_COLORS,
      breaks = c(SV_TYPES, VAF_BINS),
      labels = c(SV_TYPES, VAF_BINS),
      drop = FALSE
    ) +
    scale_colour_manual(
      values = c(PLATFORM_COLORS, white = "white", `#171717` = "#171717"),
      guide = "none"
    ) +
    scale_x_continuous(
      breaks = X_POSITIONS,
      labels = rep(ALIGNER_LEVELS, times = 3),
      expand = expansion(mult = c(0, 0))
    ) +
    scale_y_continuous(
      breaks = seq(0, 4000, by = 1000),
      labels = scales::label_comma(),
      expand = expansion(mult = c(0, 0))
    ) +
    coord_cartesian(
      xlim = c(0.35, 8.65),
      ylim = c(0, BAR_Y_MAX),
      clip = "off"
    ) +
    labs(
      title = "Low-VAF SV candidate landscape",
      subtitle = "HG002 · GRCh38 · 30× · Sniffles2 mosaic mode · VAF 5–20%",
      x = NULL,
      y = "Low-VAF SV candidates",
      fill = NULL
    ) +
    guides(
      fill = guide_legend(
        nrow = 1,
        byrow = TRUE,
        keywidth = unit(3.8, "mm"),
        keyheight = unit(2.8, "mm"),
        override.aes = list(colour = "white", linewidth = 0.20)
      )
    ) +
    theme_classic(base_size = 6.4, base_family = BASE_FAMILY) +
    theme(
      axis.line = element_line(colour = "#111111", linewidth = 0.34),
      axis.ticks = element_line(colour = "#111111", linewidth = 0.30),
      axis.ticks.length = unit(1.6, "pt"),
      axis.title.y = element_text(
        size = 6.9,
        face = "bold",
        colour = TEXT_COLOR,
        margin = margin(r = 3.0)
      ),
      axis.text.y = element_text(size = 5.8, colour = TEXT_COLOR),
      axis.text.x = element_text(
        size = 5.7,
        colour = TEXT_COLOR,
        margin = margin(t = 1.5)
      ),
      plot.title = element_text(
        size = 8.2,
        face = "bold",
        colour = TEXT_COLOR,
        hjust = 0.5,
        margin = margin(b = 0.3, unit = "mm")
      ),
      plot.subtitle = element_text(
        size = 6.3,
        colour = SECONDARY_TEXT,
        hjust = 0.5,
        margin = margin(b = 16.5, unit = "mm")
      ),
      panel.grid = element_blank(),
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.text = element_text(size = 5.7, colour = TEXT_COLOR),
      legend.spacing.x = unit(1.1, "mm"),
      legend.margin = margin(t = 7.0, unit = "mm"),
      legend.background = element_rect(fill = NA, colour = NA),
      legend.box.background = element_blank(),
      plot.margin = margin(t = 2.0, r = 3.0, b = 9.0, l = 3.0, unit = "mm")
    )
}

save_plot_bundle <- function(plot_object) {
  width_in <- FIGURE_WIDTH_MM / 25.4
  height_in <- FIGURE_HEIGHT_MM / 25.4

  ggsave(
    file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".png")),
    plot_object,
    device = ragg::agg_png,
    width = width_in,
    height = height_in,
    units = "in",
    dpi = PNG_DPI,
    background = "white"
  )
  ggsave(
    file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".tiff")),
    plot_object,
    device = ragg::agg_tiff,
    width = width_in,
    height = height_in,
    units = "in",
    dpi = TIFF_DPI,
    compression = "lzw",
    background = "white"
  )
  svglite::svglite(
    file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".svg")),
    width = width_in,
    height = height_in,
    bg = "white",
    system_fonts = list(sans = BASE_FAMILY)
  )
  print(plot_object)
  grDevices::dev.off()

  grDevices::cairo_pdf(
    file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".pdf")),
    width = width_in,
    height = height_in,
    family = BASE_FAMILY,
    bg = "white"
  )
  print(plot_object)
  grDevices::dev.off()
}

write_provenance <- function(data_objects) {
  source_data <- bind_rows(
    data_objects$sv |>
      transmute(
        dataset,
        platform = as.character(platform),
        aligner = as.character(aligner),
        depth,
        caller,
        mark = "stacked bar",
        category = as.character(category),
        count,
        proportion,
        total_calls,
        mean_vaf,
        median_vaf,
        median_support
      ),
    data_objects$vaf |>
      transmute(
        dataset,
        platform = as.character(platform),
        aligner = as.character(aligner),
        depth,
        caller,
        mark = "pie",
        category = as.character(category),
        count,
        proportion,
        total_calls,
        mean_vaf,
        median_vaf,
        median_support
      )
  )
  write_csv(source_data, file.path(OUTPUT_DIR, "source_data_plotted.csv"))

  audit <- tibble::tibble(
    source_file = basename(DATA_FILE),
    source_rows = nrow(data_objects$raw),
    selected_rows = nrow(data_objects$wide),
    excluded_rows = nrow(data_objects$raw) - nrow(data_objects$wide),
    workflows_plotted = nrow(data_objects$wide),
    stacked_bar_segments = nrow(data_objects$sv),
    pie_slices = nrow(data_objects$vaf),
    platform_levels = paste(PLATFORM_LEVELS, collapse = "|"),
    aligner_levels = paste(ALIGNER_LEVELS, collapse = "|"),
    common_depth = "30x",
    common_caller = "Sniffles2 mosaic mode",
    max_sv_type_sum_residual = max(abs(data_objects$wide$sv_type_residual)),
    max_vaf_bin_sum_residual = max(abs(data_objects$wide$vaf_bin_residual)),
    bars_start_at_zero = TRUE,
    common_bar_axis = TRUE,
    pie_size_constant = TRUE,
    pie_position_quantitative = FALSE,
    cross_classification_implied = FALSE,
    aggregation_used = FALSE,
    smoothing_used = FALSE,
    uncertainty_available = FALSE,
    inferential_statistics_used = FALSE,
    interpretation_boundary = "candidate burden and marginal composition; no truth-based performance claim"
  )
  write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"))

  manifest <- tibble::tibble(
    output_stem = OUTPUT_STEM,
    figure_width_mm = FIGURE_WIDTH_MM,
    figure_height_mm = FIGURE_HEIGHT_MM,
    role = "absolute SV-type candidate counts with VAF-bin pie summaries",
    source_file = basename(DATA_FILE),
    source_rows = nrow(data_objects$raw),
    workflows_plotted = nrow(data_objects$wide),
    stacked_segments = nrow(data_objects$sv),
    pie_slices = nrow(data_objects$vaf),
    bar_y_axis = "absolute candidate count from zero",
    pie_encoding = "equal-area pies; wedge angle encodes within-workflow VAF proportion",
    sv_type_order = paste(SV_TYPES, collapse = "|"),
    vaf_bin_order = paste(VAF_BINS, collapse = "|"),
    platform_colors = paste(
      paste(names(PLATFORM_COLORS), PLATFORM_COLORS, sep = "="),
      collapse = "|"
    ),
    sv_type_colors = paste(
      paste(names(SV_TYPE_COLORS), SV_TYPE_COLORS, sep = "="),
      collapse = "|"
    ),
    vaf_colors = paste(
      paste(names(VAF_COLORS), VAF_COLORS, sep = "="),
      collapse = "|"
    ),
    base_font_family = BASE_FAMILY,
    png_dpi = PNG_DPI,
    tiff_dpi = TIFF_DPI,
    vector_outputs = "SVG|PDF",
    raster_outputs = "PNG|TIFF"
  )
  write_csv(manifest, file.path(OUTPUT_DIR, "render_manifest.csv"))
}

data_objects <- read_mosaic_data()
plot_object <- make_plot(data_objects)
save_plot_bundle(plot_object)
write_provenance(data_objects)

message("Wrote stacked-bar plus VAF-pie mosaic-SV figure to: ", OUTPUT_DIR)
