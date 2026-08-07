#!/usr/bin/env Rscript

# Reusable radar-chart geometry and visual contract for the SV benchmark.
# This file contains no experimental or simulated values.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(grid)
  library(scales)
  library(svglite)
  library(ragg)
})

RADAR_PLATFORM_ORDER <- c("BGI", "ONT", "HiFi")
RADAR_ALIGNER_ORDER <- c("minimap2", "winnowmap")
RADAR_DEPTH_ORDER <- c("10x", "30x", "50x")
RADAR_AXIS_ORDER <- as.vector(t(outer(
  RADAR_DEPTH_ORDER, RADAR_ALIGNER_ORDER, paste, sep = "|"
)))
RADAR_AXIS_LABELS <- c(
  "10\u00d7-MM2", "10\u00d7-WM",
  "30\u00d7-MM2", "30\u00d7-WM",
  "50\u00d7-MM2", "50\u00d7-WM"
)

# Identical platform mapping to the established SV precision-recall figures.
RADAR_PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)

radar_font_family <- function() {
  candidates <- c("Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans")
  available <- unique(systemfonts::system_fonts()$family)
  selected <- candidates[candidates %in% available][1]
  if (is.na(selected)) "sans" else selected
}

RADAR_BASE_FAMILY <- radar_font_family()

validate_radar_data <- function(data, axis_order = RADAR_AXIS_ORDER) {
  required <- c("depth", "platform", "aligner", "value")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop("Radar data are missing columns: ", paste(missing, collapse = ", "))
  }

  checked <- data %>%
    transmute(
      depth = as.character(depth),
      platform = as.character(platform),
      aligner = as.character(aligner),
      value = as.numeric(value)
    ) %>%
    mutate(axis = paste(depth, aligner, sep = "|"))

  if (anyNA(checked) || any(!is.finite(checked$value))) {
    stop("Radar data contain missing or non-finite values")
  }
  if (any(checked$value < 0 | checked$value > 1)) {
    stop("Radar values must be untransformed proportions in [0, 1]")
  }
  if (!setequal(unique(checked$axis), axis_order)) {
    stop("Every platform must contain 10x, 30x, and 50x for both aligners")
  }
  if (!setequal(unique(checked$platform), RADAR_PLATFORM_ORDER)) {
    stop("Platforms must be exactly: ", paste(RADAR_PLATFORM_ORDER, collapse = ", "))
  }
  if (!setequal(unique(checked$aligner), RADAR_ALIGNER_ORDER)) {
    stop("Aligners must be exactly: ", paste(RADAR_ALIGNER_ORDER, collapse = ", "))
  }

  duplicates <- checked %>%
    count(platform, aligner, depth, name = "n") %>%
    filter(n != 1L)
  if (nrow(duplicates) > 0L) {
    stop("Each platform must have one value per depth-by-aligner combination")
  }

  expected_n <- length(RADAR_PLATFORM_ORDER) * length(axis_order)
  if (nrow(checked) != expected_n) {
    stop("Expected ", expected_n, " rows, found ", nrow(checked))
  }

  checked %>%
    mutate(
      axis = factor(axis, levels = axis_order),
      depth = factor(depth, levels = RADAR_DEPTH_ORDER),
      platform = factor(platform, levels = RADAR_PLATFORM_ORDER),
      aligner = factor(aligner, levels = RADAR_ALIGNER_ORDER),
      series = platform,
      axis_id = as.integer(axis)
    ) %>%
    arrange(platform, aligner, axis_id)
}

radar_grid_data <- function(n_axes, levels, radii) {
  if (length(levels) != length(radii)) stop("Grid levels and radii must match")
  bind_rows(Map(function(level, radius) {
    data.frame(
      axis_id = c(seq_len(n_axes), n_axes + 1L),
      radius = radius,
      level = level
    )
  }, levels, radii))
}

adaptive_radar_scale <- function(values) {
  values <- as.numeric(values)
  if (any(!is.finite(values)) || any(values < 0 | values > 1)) {
    stop("Adaptive radar scaling requires finite values in [0, 1]")
  }

  span <- diff(range(values))
  padding <- max(0.025, span * 0.10)
  lower <- max(0, floor((min(values) - padding) / 0.05) * 0.05)
  upper <- min(1, ceiling((max(values) + padding) / 0.05) * 0.05)

  if (upper - lower < 0.15) {
    extra <- (0.15 - (upper - lower)) / 2
    lower <- max(0, floor((lower - extra) / 0.05) * 0.05)
    upper <- min(1, ceiling((upper + extra) / 0.05) * 0.05)
  }

  width <- upper - lower
  step <- if (width <= 0.30 + 1e-9) 0.05 else 0.10
  n_steps <- ceiling(width / step - 1e-9)
  upper <- min(1, lower + n_steps * step)
  if (upper < max(values) + padding && upper < 1) upper <- min(1, upper + step)

  list(
    limits = c(lower, upper),
    breaks = round(seq(lower, upper, by = step), 10),
    step = step
  )
}

radar_xy <- function(axis_id, radius, n_axes) {
  angle <- pi / 2 - 2 * pi * (axis_id - 1) / n_axes
  data.frame(
    x = radius * cos(angle),
    y = radius * sin(angle)
  )
}

close_radar_paths <- function(data, n_axes) {
  first_points <- data %>%
    group_by(series) %>%
    slice_min(axis_id, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    mutate(axis_id = n_axes + 1L)
  bind_rows(data, first_points) %>%
    arrange(series, axis_id)
}

make_sv_radar <- function(data, title, subtitle = NULL,
                          axis_order = RADAR_AXIS_ORDER,
                          axis_labels = RADAR_AXIS_LABELS,
                          radial_limits = c(0, 1),
                          radial_breaks = NULL,
                          line_halo = FALSE) {
  d <- validate_radar_data(data, axis_order)
  n_axes <- length(axis_order)
  radial_limits <- as.numeric(radial_limits)
  if (length(radial_limits) != 2L ||
      any(!is.finite(radial_limits)) ||
      radial_limits[1] >= radial_limits[2]) {
    stop("radial_limits must be two increasing finite values")
  }
  if (min(d$value) < radial_limits[1] - 1e-9 ||
      max(d$value) > radial_limits[2] + 1e-9) {
    stop("radial_limits do not contain every plotted value")
  }
  if (is.null(radial_breaks)) {
    radial_breaks <- seq(radial_limits[1], radial_limits[2], length.out = 6L)
  }
  radial_breaks <- sort(unique(as.numeric(radial_breaks)))
  if (radial_breaks[1] < radial_limits[1] - 1e-9 ||
      tail(radial_breaks, 1) > radial_limits[2] + 1e-9) {
    stop("radial_breaks must lie within radial_limits")
  }

  to_radius <- function(x) {
    (x - radial_limits[1]) / diff(radial_limits)
  }
  d <- d %>% mutate(radius = to_radius(value))
  closed <- close_radar_paths(d, n_axes)
  closed <- bind_cols(
    closed,
    radar_xy(closed$axis_id, closed$radius, n_axes)
  )
  grid_data <- radar_grid_data(
    n_axes, radial_breaks, to_radius(radial_breaks)
  )
  grid_data <- bind_cols(
    grid_data,
    radar_xy(grid_data$axis_id, grid_data$radius, n_axes)
  )
  point_xy <- radar_xy(d$axis_id, d$radius, n_axes)
  d <- bind_cols(d, point_xy)

  spoke_ends <- radar_xy(seq_len(n_axes), rep(1, n_axes), n_axes)
  spokes <- data.frame(
    x = 0, y = 0,
    xend = spoke_ends$x, yend = spoke_ends$y
  )

  label_radii <- c(1.12, 1.10, 1.10, 1.12, 1.10, 1.10)
  label_xy <- radar_xy(seq_len(n_axes), label_radii, n_axes)
  axis_labels <- data.frame(
    axis_id = seq_len(n_axes),
    x = label_xy$x,
    y = label_xy$y,
    label = axis_labels,
    hjust = c(0.5, 0, 0, 0.5, 1, 1),
    vjust = c(0, 0.5, 0.5, 1, 0.5, 0.5)
  )
  radial_labels <- data.frame(
    x = rep(-0.035, length(radial_breaks)),
    y = to_radius(radial_breaks),
    label = percent(radial_breaks, accuracy = 1)
  )

  inner_grid <- grid_data %>% filter(level < max(radial_breaks))
  outer_grid <- grid_data %>% filter(level == max(radial_breaks))

  p <- ggplot() +
    geom_path(
      data = inner_grid,
      aes(x, y, group = level),
      colour = "#D5D5D5", linewidth = 0.23, linejoin = "round"
    ) +
    geom_path(
      data = outer_grid,
      aes(x, y, group = level),
      colour = "#BEBEBE", linewidth = 0.27, linejoin = "round"
    ) +
    geom_segment(
      data = spokes,
      aes(x = x, xend = xend, y = y, yend = yend),
      colour = "#D0D0D0", linewidth = 0.23
    ) +
    scale_colour_manual(
      name = "Platform", values = RADAR_PLATFORM_COLOURS,
      breaks = RADAR_PLATFORM_ORDER, drop = FALSE
    )

  if (isTRUE(line_halo)) {
    for (platform_name in RADAR_PLATFORM_ORDER) {
      platform_path <- closed %>% filter(platform == platform_name)
      p <- p +
        geom_path(
          data = platform_path,
          aes(x = x, y = y, group = series),
          colour = "white", linewidth = 1.02,
          lineend = "round", linejoin = "round",
          show.legend = FALSE
        ) +
        geom_path(
          data = platform_path,
          aes(x = x, y = y, group = series, colour = platform),
          linewidth = 0.52, alpha = 0.92,
          lineend = "round", linejoin = "round"
        )
    }
  } else {
    p <- p + geom_path(
      data = closed,
      aes(x = x, y = y, group = series, colour = platform),
      linewidth = 0.52, alpha = 0.86,
      lineend = "round", linejoin = "round"
    )
  }

  p +
    geom_text(
      data = axis_labels,
      aes(x, y, label = label, hjust = hjust, vjust = vjust),
      family = RADAR_BASE_FAMILY, size = 2.25, colour = "#4F4F4F"
    ) +
    geom_text(
      data = radial_labels,
      aes(x, y, label = label),
      family = RADAR_BASE_FAMILY, size = 1.85,
      hjust = 1.08, vjust = -0.15, colour = "#707070"
    ) +
    coord_equal(
      xlim = c(-1.25, 1.25), ylim = c(-1.18, 1.20),
      expand = FALSE, clip = "off"
    ) +
    guides(
      colour = guide_legend(
        order = 1, title.position = "top", nrow = 1,
        override.aes = list(linetype = "solid", shape = NA, linewidth = 0.65)
      )
    ) +
    labs(title = title, subtitle = subtitle) +
    theme_void(base_size = 7.2, base_family = RADAR_BASE_FAMILY) +
    theme(
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      plot.title = element_text(
        size = 8.8, face = "plain", colour = "#161616", hjust = 0.5,
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

save_sv_radar <- function(plot, stem, width_mm = 89, height_mm = 93,
                          preview_res = 320, print_res = 600) {
  dir.create(dirname(stem), recursive = TRUE, showWarnings = FALSE)
  width_in <- width_mm / 25.4
  height_in <- height_mm / 25.4

  ragg::agg_png(
    paste0(stem, ".png"), width = width_mm, height = height_mm,
    units = "mm", res = preview_res, background = "white", scaling = 1
  )
  print(plot)
  dev.off()

  svglite::svglite(
    paste0(stem, ".svg"), width = width_in, height = height_in,
    bg = "white", system_fonts = list(sans = RADAR_BASE_FAMILY)
  )
  print(plot)
  dev.off()

  grDevices::cairo_pdf(
    paste0(stem, ".pdf"), width = width_in, height = height_in,
    family = RADAR_BASE_FAMILY, bg = "white"
  )
  print(plot)
  dev.off()

  ragg::agg_tiff(
    paste0(stem, ".tiff"), width = width_mm, height = height_mm,
    units = "mm", res = print_res, background = "white",
    compression = "lzw", scaling = 1
  )
  print(plot)
  dev.off()

  invisible(stem)
}
