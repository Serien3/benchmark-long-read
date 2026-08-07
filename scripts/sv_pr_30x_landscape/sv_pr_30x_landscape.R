#!/usr/bin/env Rscript

# =============================================================================
# Panel c: 30x SV precision-recall landscape
#
# Scientific contract
#   Claim      : at matched 30x depth, platform performance reflects distinct
#                precision-recall trade-offs that depend on caller, aligner,
#                and benchmark context.
#   Evidence   : 24 unaggregated observations per truth set (48 total).
#   Archetype  : two independent quantitative PR landscapes.
#   Encoding   : colour = platform; shape = caller; solid/hollow = aligner.
#   Integrity  : raw precision and recall only; no jitter, smoothing,
#                aggregation, uncertainty model, or depth opacity.
#   Style      : typography, palette, F1 contours, frame, and export devices
#                inherit the approved scripts/sv_pr_figures visual language.
# =============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
  library(grid)
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
DATA_DIR <- file.path(ROOT, "data")
OUTPUT_DIR <- file.path(ROOT, "figures", "sv_pr_30x_landscape")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

CALLERS <- c("cuteSV", "Sniffles2", "sawfish", "SVDSS")
PLATFORMS <- c("BGI", "ONT", "HiFi")
ALIGNERS <- c("minimap2", "winnowmap")
TARGET_DEPTH <- "30x"

BENCHMARKS <- list(
  T2TQ100 = list(
    file = "sv_benchmark_T2TQ100.csv",
    label = "T2T-Q100 v1.1"
  ),
  CMRG = list(
    file = "sv_benchmark_CMRG.csv",
    label = "GIAB CMRG"
  )
)

PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)

# Shapes 21-24 support an independently controlled outline and fill. This
# allows platform colour and caller shape to remain visible while aligner is
# represented redundantly by a solid versus hollow interior.
CALLER_SHAPES <- c(
  cuteSV = 21,
  Sniffles2 = 24,
  sawfish = 22,
  SVDSS = 23
)

PLATFORM_ALIGNER_LEVELS <- c(
  "BGI__minimap2", "ONT__minimap2", "HiFi__minimap2",
  "BGI__winnowmap", "ONT__winnowmap", "HiFi__winnowmap"
)

PLATFORM_ALIGNER_LABELS <- c(
  "BGI · minimap2", "ONT · minimap2", "HiFi · minimap2",
  "BGI · winnowmap", "ONT · winnowmap", "HiFi · winnowmap"
)

PLATFORM_ALIGNER_FILLS <- c(
  BGI__minimap2 = PLATFORM_COLOURS[["BGI"]],
  ONT__minimap2 = PLATFORM_COLOURS[["ONT"]],
  HiFi__minimap2 = PLATFORM_COLOURS[["HiFi"]],
  BGI__winnowmap = "#FFFFFF",
  ONT__winnowmap = "#FFFFFF",
  HiFi__winnowmap = "#FFFFFF"
)

PLATFORM_ALIGNER_OUTLINES <- c(
  PLATFORM_COLOURS[["BGI"]], PLATFORM_COLOURS[["ONT"]],
  PLATFORM_COLOURS[["HiFi"]], PLATFORM_COLOURS[["BGI"]],
  PLATFORM_COLOURS[["ONT"]], PLATFORM_COLOURS[["HiFi"]]
)

font_candidates <- c(
  "Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans"
)
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

# Grid consults the PostScript font database while measuring text for Cairo
# PDF output. Register the system-font family name as an alias to the bundled
# Nimbus Sans metrics so vector rendering is warning-free and dimensionally
# consistent with the raster/SVG devices.
if (identical(BASE_FAMILY, "Nimbus Sans") &&
    !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  nimbus_metrics <- grDevices::pdfFonts("NimbusSan")[[1]]
  do.call(
    grDevices::pdfFonts,
    setNames(list(nimbus_metrics), BASE_FAMILY)
  )
}

# ---- Data contract ---------------------------------------------------------

read_benchmark <- function(spec, benchmark_key) {
  path <- file.path(DATA_DIR, spec$file)
  raw <- read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    locale = locale(encoding = "UTF-8")
  )

  if (ncol(raw) < 9L) {
    stop("Expected at least nine columns in ", spec$file)
  }

  names(raw)[1:6] <- c(
    "aligner", "reference", "eval_mode", "caller", "platform", "depth"
  )

  n_source <- nrow(raw)
  grch38 <- raw %>% filter(reference == "GRCh38")
  core_all_depths <- grch38 %>%
    filter(
      caller %in% CALLERS,
      platform %in% PLATFORMS,
      aligner %in% ALIGNERS,
      depth %in% c("10x", "30x", "50x")
    )

  plotted <- core_all_depths %>%
    filter(depth == TARGET_DEPTH) %>%
    transmute(
      benchmark = benchmark_key,
      truth_set = spec$label,
      reference = reference,
      eval_mode = eval_mode,
      caller = factor(caller, levels = CALLERS),
      platform = factor(platform, levels = PLATFORMS),
      aligner = factor(aligner, levels = ALIGNERS),
      depth = depth,
      precision = as.numeric(precision),
      recall = as.numeric(recall),
      F1 = as.numeric(F1),
      platform_aligner = factor(
        paste(as.character(platform), as.character(aligner), sep = "__"),
        levels = PLATFORM_ALIGNER_LEVELS
      )
    ) %>%
    arrange(aligner, caller, platform)

  if (any(!is.finite(plotted$precision)) ||
      any(!is.finite(plotted$recall)) ||
      any(!is.finite(plotted$F1))) {
    stop(benchmark_key, " contains non-finite raw performance values")
  }

  if (any(plotted$precision < 0 | plotted$precision > 1) ||
      any(plotted$recall < 0 | plotted$recall > 1) ||
      any(plotted$F1 < 0 | plotted$F1 > 1)) {
    stop(benchmark_key, " contains performance values outside [0, 1]")
  }

  duplicate_keys <- plotted %>%
    count(caller, platform, aligner, depth, name = "n") %>%
    filter(n != 1L)
  if (nrow(duplicate_keys) > 0L) {
    stop(benchmark_key, " has duplicated 30x caller/platform/aligner keys")
  }

  expected <- tidyr::expand_grid(
    caller = factor(CALLERS, levels = CALLERS),
    platform = factor(PLATFORMS, levels = PLATFORMS),
    aligner = factor(ALIGNERS, levels = ALIGNERS)
  )
  missing_keys <- expected %>%
    anti_join(
      plotted %>% select(caller, platform, aligner),
      by = c("caller", "platform", "aligner")
    )
  if (nrow(missing_keys) > 0L || nrow(plotted) != 24L) {
    stop(benchmark_key, " is incomplete for the symmetric 4 x 3 x 2 design")
  }

  attr(plotted, "audit") <- data.frame(
    benchmark = benchmark_key,
    truth_set = spec$label,
    source_file = spec$file,
    source_rows = n_source,
    grch38_rows = nrow(grch38),
    core_rows_all_depths = nrow(core_all_depths),
    plotted_rows_30x = nrow(plotted),
    excluded_non_grch38 = n_source - nrow(grch38),
    excluded_noncore_callers = nrow(grch38) - nrow(core_all_depths),
    excluded_other_depths_from_core = nrow(core_all_depths) - nrow(plotted),
    filter_rule = paste0(
      "reference=GRCh38; callers=cuteSV|Sniffles2|sawfish|SVDSS; ",
      "platforms=BGI|ONT|HiFi; aligners=minimap2|winnowmap; ",
      "depth=30x; metrics=raw precision|recall|F1"
    )
  )

  plotted
}

# ---- F1 contours and data-aware square windows ----------------------------

f1_value <- function(precision, recall) {
  ifelse(
    precision + recall > 0,
    2 * precision * recall / (precision + recall),
    NA_real_
  )
}

make_f1_curve <- function(f1, xlim, ylim, n = 700L) {
  recall <- seq(
    max(xlim[1], f1 / 2 + 1e-4),
    min(xlim[2], 1),
    length.out = n
  )
  precision <- f1 * recall / (2 * recall - f1)
  keep <- is.finite(precision) &
    precision >= ylim[1] & precision <= min(ylim[2], 1)
  data.frame(
    recall = recall[keep],
    precision = precision[keep],
    f1 = rep(f1, sum(keep))
  )
}

panel_window <- function(d) {
  values <- c(d$recall, d$precision)
  data_low <- min(values)
  data_high <- max(values)
  data_span <- max(data_high - data_low, 0.05)
  lower_pad <- max(0.015, data_span * 0.06)
  common_low <- max(0, data_low - lower_pad)
  upper_pad <- max(0.005, data_span * 0.02)
  common_high <- 1 + upper_pad
  list(x = c(common_low, common_high), y = c(common_low, common_high))
}

f1_levels_for_window <- function(xlim, ylim) {
  lower_corner_f1 <- f1_value(ylim[1], xlim[1])
  candidates <- if (!is.finite(lower_corner_f1) || lower_corner_f1 < 0.35) {
    c(0.10, 0.30, 0.50, 0.70, 0.90)
  } else {
    c(0.50, 0.60, 0.70, 0.80, 0.90)
  }
  candidates[vapply(
    candidates,
    function(z) nrow(make_f1_curve(z, xlim, ylim)) >= 2L,
    logical(1)
  )]
}

f1_label_anchor <- function(curve, xlim, ylim) {
  if (nrow(curve) < 2L) return(NULL)

  anchor <- curve[which.max(curve$recall), , drop = FALSE]
  x_pad <- diff(xlim) * 0.012
  y_pad <- diff(ylim) * 0.010

  if (anchor$recall >= min(xlim[2], 1) - diff(xlim) * 0.02) {
    anchor$recall <- min(xlim[2], 1) - x_pad
    anchor$precision <- anchor$f1 * anchor$recall /
      (2 * anchor$recall - anchor$f1)
    anchor$hjust <- 1
    anchor$vjust <- -0.30
  } else {
    anchor$recall <- min(anchor$recall + x_pad, min(xlim[2], 1) - x_pad)
    anchor$precision <- max(anchor$precision + y_pad, ylim[1] + y_pad)
    anchor$hjust <- 0
    anchor$vjust <- -0.10
  }
  anchor
}

axis_breaks <- function(lim) {
  for (step in c(0.20, 0.10, 0.05, 0.02, 0.01)) {
    from <- (floor(lim[1] / step) + 1) * step
    to <- floor(min(lim[2], 1) / step) * step
    if (to < from) next
    breaks <- round(seq(from, to, by = step), 8)
    breaks <- breaks[
      breaks > lim[1] + 1e-9 & breaks < lim[2] - 1e-9
    ]
    if (length(breaks) >= 4L && length(breaks) <= 6L) return(breaks)
  }

  breaks <- pretty(lim, n = 5)
  breaks[breaks > lim[1] + 1e-9 & breaks < lim[2] - 1e-9]
}

fmt_f1 <- function(x) sub("0$", "", sprintf("%.2f", x))

# ---- Visual language -------------------------------------------------------

theme_reference_pr <- function(base_family = BASE_FAMILY) {
  theme_bw(base_size = 7.2, base_family = base_family) +
    theme(
      panel.grid = element_blank(),
      panel.border = element_rect(
        colour = "#8F8F8F", fill = NA, linewidth = 0.27
      ),
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      plot.title = element_text(
        size = 8.6, face = "plain", colour = "#161616", hjust = 0.5,
        margin = margin(b = 0.8)
      ),
      plot.subtitle = element_text(
        size = 6.8, face = "plain", colour = "#666666", hjust = 0.5,
        margin = margin(b = 1.8)
      ),
      axis.title = element_text(size = 7.4, colour = "#1A1A1A"),
      axis.text = element_text(size = 6.2, colour = "#5B5B5B"),
      axis.ticks = element_line(colour = "#777777", linewidth = 0.25),
      axis.ticks.length = unit(1.5, "pt"),
      legend.position = "none",
      plot.margin = margin(t = 1.6, r = 2.5, b = 1.8, l = 2.5, unit = "mm")
    )
}

shared_scales <- function() {
  list(
    scale_colour_manual(
      values = PLATFORM_COLOURS,
      breaks = PLATFORMS,
      drop = FALSE,
      guide = "none"
    ),
    scale_fill_manual(
      name = "Platform · aligner",
      values = PLATFORM_ALIGNER_FILLS,
      breaks = PLATFORM_ALIGNER_LEVELS,
      labels = PLATFORM_ALIGNER_LABELS,
      drop = FALSE,
      guide = guide_legend(
        order = 1,
        nrow = 2,
        byrow = TRUE,
        override.aes = list(
          shape = 21,
          colour = PLATFORM_ALIGNER_OUTLINES,
          size = 2.2,
          stroke = 0.65,
          alpha = 1
        )
      )
    ),
    scale_shape_manual(
      name = "SV caller",
      values = CALLER_SHAPES,
      breaks = CALLERS,
      drop = FALSE,
      guide = guide_legend(
        order = 2,
        nrow = 1,
        override.aes = list(
          colour = "#4A4A4A",
          fill = "#B8B8B8",
          size = 2.2,
          stroke = 0.65,
          alpha = 1
        )
      )
    )
  )
}

make_pr_plot <- function(d) {
  lim <- panel_window(d)
  f1_levels <- f1_levels_for_window(lim$x, lim$y)
  f1_list <- lapply(f1_levels, make_f1_curve, xlim = lim$x, ylim = lim$y)
  f1_curves <- bind_rows(f1_list)
  f1_labels <- bind_rows(lapply(
    f1_list,
    f1_label_anchor,
    xlim = lim$x,
    ylim = lim$y
  ))

  p <- ggplot(d, aes(x = recall, y = precision)) +
    geom_path(
      data = f1_curves,
      aes(x = recall, y = precision, group = f1),
      inherit.aes = FALSE,
      colour = "#A8A8A8",
      linewidth = 0.28,
      linetype = "44",
      lineend = "butt"
    ) +
    geom_text(
      data = f1_labels,
      aes(
        x = recall,
        y = precision,
        label = paste0("F1=", fmt_f1(f1)),
        hjust = hjust,
        vjust = vjust
      ),
      inherit.aes = FALSE,
      family = BASE_FAMILY,
      fontface = "bold",
      size = 2.20,
      colour = "#202020"
    ) +
    geom_point(
      aes(
        colour = platform,
        fill = platform_aligner,
        shape = caller
      ),
      size = 2.25,
      stroke = 0.65,
      alpha = 1,
      show.legend = FALSE
    ) +
    shared_scales() +
    scale_x_continuous(
      breaks = axis_breaks(lim$x),
      labels = label_number(accuracy = 0.01),
      expand = expansion(mult = 0)
    ) +
    scale_y_continuous(
      breaks = axis_breaks(lim$y),
      labels = label_number(accuracy = 0.01),
      expand = expansion(mult = 0)
    ) +
    coord_fixed(
      ratio = 1,
      xlim = lim$x,
      ylim = lim$y,
      expand = FALSE,
      clip = "on"
    ) +
    labs(
      title = unique(d$truth_set),
      subtitle = "GRCh38 · 30×",
      x = "Recall",
      y = "Precision"
    ) +
    theme_reference_pr()

  attr(p, "window") <- lim
  attr(p, "f1_levels") <- f1_levels
  p
}

# ---- Export ----------------------------------------------------------------

save_figure <- function(plot, stem, width_mm = 74, height_mm = 74,
                        preview_res = 320, print_res = 600) {
  width_in <- width_mm / 25.4
  height_in <- height_mm / 25.4

  ragg::agg_png(
    paste0(stem, ".png"),
    width = width_mm,
    height = height_mm,
    units = "mm",
    res = preview_res,
    background = "white",
    scaling = 1
  )
  print(plot)
  dev.off()

  svglite::svglite(
    paste0(stem, ".svg"),
    width = width_in,
    height = height_in,
    bg = "white",
    system_fonts = list(sans = BASE_FAMILY)
  )
  print(plot)
  dev.off()

  grDevices::cairo_pdf(
    paste0(stem, ".pdf"),
    width = width_in,
    height = height_in,
    family = BASE_FAMILY,
    bg = "white"
  )
  print(plot)
  dev.off()

  ragg::agg_tiff(
    paste0(stem, ".tiff"),
    width = width_mm,
    height = height_mm,
    units = "mm",
    res = print_res,
    background = "white",
    compression = "lzw",
    scaling = 1
  )
  print(plot)
  dev.off()
}

# ---- Driver ----------------------------------------------------------------

all_data <- list()
audits <- list()
render_rows <- list()

for (benchmark_key in names(BENCHMARKS)) {
  spec <- BENCHMARKS[[benchmark_key]]
  message("[", benchmark_key, "] reading ", spec$file)
  d <- read_benchmark(spec, benchmark_key)
  all_data[[benchmark_key]] <- d
  audits[[benchmark_key]] <- attr(d, "audit")
}

for (benchmark_key in names(all_data)) {
  p <- make_pr_plot(all_data[[benchmark_key]])
  lim <- attr(p, "window")
  f1_levels <- attr(p, "f1_levels")
  stem <- file.path(
    OUTPUT_DIR,
    paste0("sv_pr_30x_", benchmark_key)
  )

  save_figure(p, stem)

  render_rows[[benchmark_key]] <- data.frame(
    benchmark = benchmark_key,
    truth_set = unique(all_data[[benchmark_key]]$truth_set),
    depth = TARGET_DEPTH,
    plotted_points = nrow(all_data[[benchmark_key]]),
    x_metric = "recall",
    y_metric = "precision",
    x_min = lim$x[1],
    x_max = lim$x[2],
    y_min = lim$y[1],
    y_max = lim$y[2],
    symmetric_within_panel = isTRUE(all.equal(lim$x, lim$y)),
    f1_contours = paste(fmt_f1(f1_levels), collapse = ";"),
    depth_alpha_used = FALSE,
    jitter_used = FALSE,
    aggregation_used = FALSE,
    legend_shown = FALSE,
    output_stem = basename(stem)
  )
}

source_data <- bind_rows(all_data) %>%
  mutate(across(c(caller, platform, aligner, platform_aligner), as.character))

write_csv(source_data, file.path(OUTPUT_DIR, "source_data_plotted.csv"))
write_csv(bind_rows(audits), file.path(OUTPUT_DIR, "data_filter_audit.csv"))
write_csv(bind_rows(render_rows), file.path(OUTPUT_DIR, "render_manifest.csv"))

message("Created 30x SV PR landscape in: ", OUTPUT_DIR)
