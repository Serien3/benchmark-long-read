#!/usr/bin/env Rscript

# =============================================================================
# SV precision-recall figures: GIAB v5.0q and CMRG
#
# One independent figure per caller and truth set.
#   colour : sequencing platform (BGI / ONT / HiFi)
#   shape  : aligner (minimap2 = circle / winnowmap = diamond)
#   alpha  : matched sequencing depth (10x < 30x < 50x)
#   path   : depth trajectory, strictly ordered 10x -> 30x -> 50x
#
# The source tables are never modified. The driver exports the exact plotted
# rows and a render manifest beside the figures for auditability.
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
OUTPUT_DIR <- file.path(ROOT, "figures", "codex_sv_pr")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# ---- Figure contract -------------------------------------------------------

# Claim: within each caller and truth set, the six platform-by-aligner
# trajectories reveal how precision-recall performance changes from 10x to 50x.
# Archetype: stand-alone quantitative comparison panel.
# Evidence: 18 observations per panel; no aggregation and no uncertainty model.
# Output: 74 x 74 mm; editable SVG/PDF, 600 dpi TIFF, 320 dpi PNG preview.

CALLERS <- c("cuteSV", "Sniffles2", "sawfish", "SVDSS")
PLATFORMS <- c("BGI", "ONT", "HiFi")
ALIGNERS <- c("minimap2", "winnowmap")
DEPTHS <- c("10x", "30x", "50x")

BENCHMARKS <- list(
  GIAB5 = list(
    file = "sv_benchmark_GIAB5.0q.csv",
    label = "GIAB v5.0q"
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

ALIGNER_SHAPES <- c(
  minimap2 = 16,
  winnowmap = 18
)

DEPTH_ALPHA <- c(
  `10x` = 0.18,
  `30x` = 0.58,
  `50x` = 1.00
)

# Use an Arial/Helvetica-compatible family without requiring a proprietary
# font installation. Nimbus Sans is the available metric-compatible fallback.
preferred_family <- "Arial"
font_candidates <- c(preferred_family, "Helvetica", "Nimbus Sans",
                     "Liberation Sans", "sans")
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

# ---- Data contract and integrity checks -----------------------------------

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

  # Both source tables use the same first-six-column schema. Renaming by
  # position avoids locale-dependent matching of the Chinese headers.
  names(raw)[1:6] <- c(
    "aligner", "reference", "eval_mode", "caller", "platform", "depth"
  )

  n_source <- nrow(raw)
  grch38 <- raw %>% filter(reference == "GRCh38")
  n_grch38 <- nrow(grch38)

  plotted <- grch38 %>%
    filter(
      caller %in% CALLERS,
      platform %in% PLATFORMS,
      aligner %in% ALIGNERS,
      depth %in% DEPTHS
    ) %>%
    transmute(
      benchmark = benchmark_key,
      truth_set = spec$label,
      reference = reference,
      eval_mode = eval_mode,
      caller = factor(caller, levels = CALLERS),
      platform = factor(platform, levels = PLATFORMS),
      aligner = factor(aligner, levels = ALIGNERS),
      depth = factor(depth, levels = DEPTHS),
      depth_x = as.integer(sub("x$", "", as.character(depth))),
      precision = as.numeric(precision),
      recall = as.numeric(recall),
      F1 = as.numeric(F1)
    ) %>%
    arrange(caller, platform, aligner, depth_x)

  n_plotted <- nrow(plotted)

  if (any(!is.finite(plotted$precision)) || any(!is.finite(plotted$recall))) {
    stop(benchmark_key, " contains non-finite precision or recall values")
  }
  if (any(plotted$precision < 0 | plotted$precision > 1) ||
      any(plotted$recall < 0 | plotted$recall > 1)) {
    stop(benchmark_key, " contains precision or recall values outside [0, 1]")
  }

  duplicate_keys <- plotted %>%
    count(caller, platform, aligner, depth, name = "n") %>%
    filter(n != 1L)
  if (nrow(duplicate_keys) > 0L) {
    stop(benchmark_key, " has missing or duplicated caller/platform/aligner/depth keys")
  }

  expected <- tidyr::expand_grid(
    caller = factor(CALLERS, levels = CALLERS),
    platform = factor(PLATFORMS, levels = PLATFORMS),
    aligner = factor(ALIGNERS, levels = ALIGNERS),
    depth = factor(DEPTHS, levels = DEPTHS)
  )
  missing_keys <- expected %>%
    anti_join(
      plotted %>% select(caller, platform, aligner, depth),
      by = c("caller", "platform", "aligner", "depth")
    )
  if (nrow(missing_keys) > 0L) {
    stop(benchmark_key, " is incomplete for the symmetric 4 x 3 x 2 x 3 design")
  }

  expected_rows <- length(CALLERS) * length(PLATFORMS) *
    length(ALIGNERS) * length(DEPTHS)
  if (n_plotted != expected_rows) {
    stop(benchmark_key, ": expected ", expected_rows,
         " plotted rows but found ", n_plotted)
  }

  attr(plotted, "audit") <- data.frame(
    benchmark = benchmark_key,
    source_rows = n_source,
    grch38_rows = n_grch38,
    plotted_rows = n_plotted,
    excluded_non_grch38 = n_source - n_grch38,
    excluded_nonshared_callers = n_grch38 - n_plotted
  )
  plotted
}

# ---- F1 backdrop -----------------------------------------------------------

f1_value <- function(precision, recall) {
  ifelse(precision + recall > 0,
         2 * precision * recall / (precision + recall), NA_real_)
}

make_f1_curve <- function(f1, xlim, ylim, n = 700L) {
  recall <- seq(max(xlim[1], f1 / 2 + 1e-4), min(xlim[2], 1), length.out = n)
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
  # Compute one tight window from the union of precision and recall values.
  # Using the same window on both axes preserves an undistorted square PR
  # space while giving each caller a targeted, data-aware magnification.
  values <- c(d$recall, d$precision)
  data_low <- min(values)
  data_high <- max(values)
  data_span <- max(data_high - data_low, 0.05)
  lower_pad <- max(0.015, data_span * 0.06)
  common_low <- max(0, data_low - lower_pad)

  # A small headroom above the hard 1.0 boundary keeps the 1.00 tick and any
  # point at precision=1 fully inside the thin grey panel frame.
  list(x = c(common_low, 1.005), y = c(common_low, 1.005))
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
    # Curves that leave through the lower boundary are labelled immediately
    # above the exit point, matching the supplied PR-panel reference.
    anchor$recall <- min(anchor$recall + x_pad, min(xlim[2], 1) - x_pad)
    anchor$precision <- max(anchor$precision + y_pad, ylim[1] + y_pad)
    anchor$hjust <- 0
    anchor$vjust <- -0.10
  }
  anchor
}

axis_breaks <- function(lim) {
  # The first labelled tick is deliberately inset from the panel corner, as in
  # the supplied reference and the approved style reconstruction.
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

# ---- Plot ------------------------------------------------------------------

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
        size = 8.8, face = "plain", colour = "#161616", hjust = 0.5,
        margin = margin(b = 2.0)
      ),
      axis.title = element_text(size = 7.4, colour = "#1A1A1A"),
      axis.text = element_text(size = 6.2, colour = "#5B5B5B"),
      axis.ticks = element_line(colour = "#777777", linewidth = 0.25),
      axis.ticks.length = unit(1.5, "pt"),
      plot.margin = margin(t = 2.4, r = 3.0, b = 2.0, l = 2.5, unit = "mm")
    )
}

make_pr_plot <- function(d, caller_name, truth_label) {
  d <- d %>%
    filter(caller == caller_name) %>%
    arrange(platform, aligner, depth_x) %>%
    mutate(trajectory = interaction(platform, aligner, drop = TRUE))

  if (nrow(d) != 18L) {
    stop(caller_name, " / ", truth_label, ": expected 18 points, found ", nrow(d))
  }

  # Build two explicit depth segments per trajectory. Segment opacity is keyed
  # to the destination depth: 10x->30x is medium and 30x->50x is strongest.
  # This reproduces the weak-to-strong line progression in the reference plot.
  segments <- d %>%
    group_by(trajectory) %>%
    arrange(depth_x, .by_group = TRUE) %>%
    mutate(
      recall_end = lead(recall),
      precision_end = lead(precision),
      segment_depth = lead(depth)
    ) %>%
    filter(!is.na(recall_end), !is.na(precision_end), !is.na(segment_depth)) %>%
    ungroup()

  if (nrow(segments) != 12L) {
    stop(caller_name, " / ", truth_label,
         ": expected 12 depth segments, found ", nrow(segments))
  }

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
      colour = "#A8A8A8", linewidth = 0.28, linetype = "44",
      lineend = "butt"
    ) +
    geom_text(
      data = f1_labels,
      aes(
        x = recall, y = precision,
        label = paste0("F1=", fmt_f1(f1)),
        hjust = hjust, vjust = vjust
      ),
      inherit.aes = FALSE,
      family = BASE_FAMILY, fontface = "bold",
      size = 2.15, colour = "#202020"
    ) +
    geom_segment(
      data = segments,
      aes(
        x = recall, y = precision,
        xend = recall_end, yend = precision_end,
        colour = platform, alpha = segment_depth
      ),
      inherit.aes = FALSE,
      linewidth = 0.48, lineend = "round",
      show.legend = FALSE
    ) +
    geom_point(
      aes(colour = platform, shape = aligner, alpha = depth),
      size = 2.15, stroke = 0, show.legend = FALSE
    ) +
    scale_colour_manual(
      name = "Platform", values = PLATFORM_COLOURS,
      breaks = PLATFORMS, drop = FALSE, guide = "none"
    ) +
    scale_shape_manual(
      name = "Aligner", values = ALIGNER_SHAPES,
      breaks = ALIGNERS, drop = FALSE, guide = "none"
    ) +
    scale_alpha_manual(
      name = "Depth", values = DEPTH_ALPHA,
      breaks = DEPTHS, drop = FALSE, guide = "none"
    ) +
    scale_x_continuous(
      breaks = axis_breaks(lim$x), labels = label_number(accuracy = 0.01),
      expand = expansion(mult = 0)
    ) +
    scale_y_continuous(
      breaks = axis_breaks(lim$y), labels = label_number(accuracy = 0.01),
      expand = expansion(mult = 0)
    ) +
    coord_fixed(
      ratio = 1, xlim = lim$x, ylim = lim$y,
      expand = FALSE, clip = "on"
    ) +
    labs(
      title = caller_name,
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
    paste0(stem, ".png"), width = width_mm, height = height_mm,
    units = "mm", res = preview_res, background = "white", scaling = 1
  )
  print(plot)
  dev.off()

  svglite::svglite(
    paste0(stem, ".svg"), width = width_in, height = height_in,
    bg = "white", system_fonts = list(sans = BASE_FAMILY)
  )
  print(plot)
  dev.off()

  grDevices::cairo_pdf(
    paste0(stem, ".pdf"), width = width_in, height = height_in,
    family = BASE_FAMILY, bg = "white"
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

# ---- Driver ----------------------------------------------------------------

all_data <- list()
audit_rows <- list()
render_rows <- list()

for (benchmark_key in names(BENCHMARKS)) {
  spec <- BENCHMARKS[[benchmark_key]]
  message("[", benchmark_key, "] reading ", spec$file)
  benchmark_data <- read_benchmark(spec, benchmark_key)

  audit_rows[[benchmark_key]] <- attr(benchmark_data, "audit")
  all_data[[benchmark_key]] <- benchmark_data

  for (caller_name in CALLERS) {
    plot <- make_pr_plot(benchmark_data, caller_name, spec$label)
    lim <- attr(plot, "window")
    f1_levels <- attr(plot, "f1_levels")
    stem <- file.path(
      OUTPUT_DIR,
      sprintf("sv_pr_%s_%s", caller_name, benchmark_key)
    )

    save_figure(plot, stem)

    render_rows[[paste(benchmark_key, caller_name, sep = "_")]] <- data.frame(
      benchmark = benchmark_key,
      truth_set = spec$label,
      caller = caller_name,
      plotted_points = 18L,
      trajectories = 6L,
      x_min = lim$x[1],
      x_max = lim$x[2],
      y_min = lim$y[1],
      y_max = lim$y[2],
      first_labelled_tick = axis_breaks(lim$x)[1],
      symmetric_axes = isTRUE(all.equal(lim$x, lim$y)),
      legend_shown = FALSE,
      f1_contours = paste(fmt_f1(f1_levels), collapse = ";"),
      output_stem = basename(stem)
    )

    message(
      sprintf(
        "  %-10s 18 points / 6 trajectories; x=[%.3f, %.3f], y=[%.3f, %.3f]",
        caller_name, lim$x[1], lim$x[2], lim$y[1], lim$y[2]
      )
    )
  }
}

plotted_source <- bind_rows(all_data) %>%
  mutate(across(c(caller, platform, aligner, depth), as.character))
write_csv(plotted_source, file.path(OUTPUT_DIR, "source_data_plotted.csv"))
write_csv(bind_rows(audit_rows), file.path(OUTPUT_DIR, "data_filter_audit.csv"))
write_csv(bind_rows(render_rows), file.path(OUTPUT_DIR, "render_manifest.csv"))

message("Created eight independent PR figures in: ", OUTPUT_DIR)
