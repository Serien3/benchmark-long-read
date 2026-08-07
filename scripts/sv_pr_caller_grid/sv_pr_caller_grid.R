#!/usr/bin/env Rscript

# =============================================================================
# Platform-centred SV precision-recall caller grid
#
# One independent 2 x 2 figure per truth set. Caller is a robustness facet;
# platform remains the principal comparison. All four panels within a figure
# share one undistorted precision-recall coordinate system.
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

find_project_root <- function() {
  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  start <- if (length(script_arg) == 1L) {
    dirname(normalizePath(sub("^--file=", "", script_arg)))
  } else {
    normalizePath(getwd())
  }
  candidate <- start
  repeat {
    if (file.exists(file.path(candidate, "AGENTS.md"))) return(candidate)
    parent <- dirname(candidate)
    if (identical(parent, candidate)) stop("Cannot locate project root")
    candidate <- parent
  }
}

ROOT <- find_project_root()
DATA_DIR <- file.path(ROOT, "data")
OUTPUT_DIR <- file.path(ROOT, "figures", "codex_sv_pr_caller_grid")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# ---- Figure contract -------------------------------------------------------

# Claim: platform precision-recall differences can be evaluated for robustness
# across four callers without overlaying caller trajectories on one axis.
# Archetype: quantitative 2 x 2 grid, one independent figure per truth set.
# Evidence: 72 source observations per figure; no aggregation or uncertainty.
# Export: 183 x 174 mm, editable SVG/PDF, 320 dpi PNG, 600 dpi TIFF.

CALLERS <- c("cuteSV", "Sniffles2", "sawfish", "SVDSS")
PLATFORMS <- c("BGI", "ONT", "HiFi")
ALIGNERS <- c("minimap2", "winnowmap")
DEPTHS <- c("10x", "30x", "50x")

BENCHMARKS <- list(
  GIAB5 = list(
    file = "sv_benchmark_GIAB5.0q.csv",
    label = "GIAB v5.0q \u00b7 GRCh38"
  ),
  CMRG = list(
    file = "sv_benchmark_CMRG.csv",
    label = "GIAB CMRG \u00b7 GRCh38"
  )
)

# Identical visual encoding to the approved stand-alone SV PR figures.
PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)
ALIGNER_SHAPES <- c(minimap2 = 16, winnowmap = 18)
DEPTH_ALPHA <- c(`10x` = 0.18, `30x` = 0.58, `50x` = 1.00)

font_candidates <- c(
  "Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans"
)
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

# ---- Data integrity --------------------------------------------------------

read_benchmark <- function(spec, benchmark_key) {
  path <- file.path(DATA_DIR, spec$file)
  raw <- read_csv(path, show_col_types = FALSE, progress = FALSE)
  if (ncol(raw) < 9L) stop("Expected at least nine columns in ", spec$file)

  names(raw)[1:6] <- c(
    "aligner", "reference", "eval_mode", "caller", "platform", "depth"
  )

  selected <- raw %>%
    filter(
      reference == "GRCh38",
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

  expected <- expand_grid(
    caller = factor(CALLERS, levels = CALLERS),
    platform = factor(PLATFORMS, levels = PLATFORMS),
    aligner = factor(ALIGNERS, levels = ALIGNERS),
    depth = factor(DEPTHS, levels = DEPTHS)
  )
  missing_keys <- expected %>%
    anti_join(
      selected %>% select(caller, platform, aligner, depth),
      by = c("caller", "platform", "aligner", "depth")
    )
  duplicates <- selected %>%
    count(caller, platform, aligner, depth, name = "n") %>%
    filter(n != 1L)

  if (nrow(selected) != 72L || nrow(missing_keys) > 0L || nrow(duplicates) > 0L) {
    stop(benchmark_key, " lacks the complete symmetric 4 x 3 x 2 x 3 design")
  }
  if (any(!is.finite(selected$precision)) ||
      any(!is.finite(selected$recall)) || any(!is.finite(selected$F1))) {
    stop(benchmark_key, " contains non-finite PR values")
  }
  if (any(selected$precision < 0 | selected$precision > 1) ||
      any(selected$recall < 0 | selected$recall > 1)) {
    stop(benchmark_key, " contains PR values outside [0, 1]")
  }

  attr(selected, "audit") <- data.frame(
    benchmark = benchmark_key,
    source_file = spec$file,
    source_rows = nrow(raw),
    plotted_rows = nrow(selected),
    reference = "GRCh38",
    callers = paste(CALLERS, collapse = ";"),
    refine_used = FALSE
  )
  selected
}

# ---- Shared PR geometry ----------------------------------------------------

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
    recall = recall[keep], precision = precision[keep],
    f1 = rep(f1, sum(keep))
  )
}

shared_panel_window <- function(d) {
  # One window from all four callers. The same numerical limits, breaks, and
  # physical aspect ratio are used in every facet within the truth set.
  values <- c(d$recall, d$precision)
  data_low <- min(values)
  data_high <- max(values)
  data_span <- max(data_high - data_low, 0.05)
  lower_pad <- max(0.015, data_span * 0.04)
  common_low <- max(0, data_low - lower_pad)
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
    anchor$recall <- min(anchor$recall + x_pad, min(xlim[2], 1) - x_pad)
    anchor$precision <- max(anchor$precision + y_pad, ylim[1] + y_pad)
    anchor$hjust <- 0
    anchor$vjust <- -0.10
  }
  anchor
}

axis_breaks <- function(lim) {
  # As in the existing PR figures, the first labelled tick is inset from the
  # lower-left corner instead of coinciding with the panel intersection.
  for (step in c(0.20, 0.10, 0.05, 0.02, 0.01)) {
    from <- (floor(lim[1] / step) + 1) * step
    to <- floor(min(lim[2], 1) / step) * step
    if (to < from) next
    breaks <- round(seq(from, to, by = step), 8)
    breaks <- breaks[breaks > lim[1] + 1e-9 & breaks < lim[2] - 1e-9]
    if (length(breaks) >= 4L && length(breaks) <= 6L) return(breaks)
  }
  breaks <- pretty(lim, n = 5)
  breaks[breaks > lim[1] + 1e-9 & breaks < lim[2] - 1e-9]
}

fmt_f1 <- function(x) sub("0$", "", sprintf("%.2f", x))

# ---- Figure ----------------------------------------------------------------

theme_pr_grid <- function(base_family = BASE_FAMILY) {
  theme_bw(base_size = 7.2, base_family = base_family) +
    theme(
      panel.grid = element_blank(),
      panel.border = element_rect(
        colour = "#8F8F8F", fill = NA, linewidth = 0.27
      ),
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      plot.title = element_text(
        size = 9.2, face = "plain", colour = "#161616", hjust = 0.5,
        margin = margin(b = 1.2, unit = "mm")
      ),
      strip.background = element_blank(),
      strip.text = element_text(
        size = 8.8, face = "plain", colour = "#161616",
        margin = margin(t = 0.8, b = 1.2, unit = "mm")
      ),
      axis.title = element_text(size = 7.4, colour = "#1A1A1A"),
      axis.text = element_text(size = 6.2, colour = "#5B5B5B"),
      axis.ticks = element_line(colour = "#777777", linewidth = 0.25),
      axis.ticks.length = unit(1.5, "pt"),
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.direction = "horizontal",
      legend.title = element_text(size = 6.2, colour = "#303030"),
      legend.text = element_text(size = 5.8, colour = "#4D4D4D"),
      legend.key.width = unit(4.4, "mm"),
      legend.key.height = unit(3.0, "mm"),
      legend.spacing.x = unit(0.8, "mm"),
      legend.spacing.y = unit(0.2, "mm"),
      panel.spacing = unit(4.0, "mm"),
      plot.margin = margin(t = 2.5, r = 3.0, b = 1.5, l = 2.5, unit = "mm")
    )
}

make_caller_grid <- function(d, truth_label) {
  d <- d %>%
    arrange(caller, platform, aligner, depth_x) %>%
    mutate(trajectory = interaction(caller, platform, aligner, drop = TRUE))

  if (nrow(d) != 72L) stop(truth_label, ": expected 72 plotted points")

  segments <- d %>%
    group_by(trajectory) %>%
    arrange(depth_x, .by_group = TRUE) %>%
    mutate(
      recall_end = lead(recall),
      precision_end = lead(precision),
      segment_depth = lead(depth)
    ) %>%
    filter(!is.na(recall_end), !is.na(precision_end)) %>%
    ungroup()
  if (nrow(segments) != 48L) stop(truth_label, ": expected 48 depth segments")

  lim <- shared_panel_window(d)
  breaks <- axis_breaks(lim$x)
  f1_levels <- f1_levels_for_window(lim$x, lim$y)
  f1_list <- lapply(f1_levels, make_f1_curve, xlim = lim$x, ylim = lim$y)
  f1_curves <- bind_rows(f1_list)
  f1_labels <- bind_rows(lapply(
    f1_list, f1_label_anchor, xlim = lim$x, ylim = lim$y
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
      linewidth = 0.48, lineend = "round", show.legend = FALSE
    ) +
    geom_point(
      aes(colour = platform, shape = aligner, alpha = depth),
      size = 2.15, stroke = 0
    ) +
    scale_colour_manual(
      name = "Platform", values = PLATFORM_COLOURS,
      breaks = PLATFORMS, drop = FALSE
    ) +
    scale_shape_manual(
      name = "Aligner", values = ALIGNER_SHAPES,
      breaks = ALIGNERS, drop = FALSE
    ) +
    scale_alpha_manual(
      name = "Depth", values = DEPTH_ALPHA,
      breaks = DEPTHS, drop = FALSE
    ) +
    scale_x_continuous(
      breaks = breaks, labels = label_number(accuracy = 0.01),
      expand = expansion(mult = 0)
    ) +
    scale_y_continuous(
      breaks = breaks, labels = label_number(accuracy = 0.01),
      expand = expansion(mult = 0)
    ) +
    coord_fixed(
      ratio = 1, xlim = lim$x, ylim = lim$y,
      expand = FALSE, clip = "on"
    ) +
    facet_wrap(vars(caller), ncol = 2, scales = "fixed") +
    guides(
      colour = guide_legend(
        order = 1, title.position = "top", nrow = 1,
        override.aes = list(alpha = 1, shape = 16, size = 2.15)
      ),
      shape = guide_legend(
        order = 2, title.position = "top", nrow = 1,
        override.aes = list(alpha = 1, colour = "#555555", size = 2.15)
      ),
      alpha = guide_legend(
        order = 3, title.position = "top", nrow = 1,
        override.aes = list(colour = "#555555", shape = 16, size = 2.15)
      )
    ) +
    labs(title = truth_label, x = "Recall", y = "Precision") +
    theme_pr_grid()

  attr(p, "window") <- lim
  attr(p, "breaks") <- breaks
  attr(p, "f1_levels") <- f1_levels
  p
}

save_grid <- function(plot, stem, width_mm = 183, height_mm = 174,
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
}

# ---- Driver ----------------------------------------------------------------

all_data <- list()
audits <- list()
manifests <- list()

for (benchmark_key in names(BENCHMARKS)) {
  spec <- BENCHMARKS[[benchmark_key]]
  message("[", benchmark_key, "] reading ", spec$file)
  d <- read_benchmark(spec, benchmark_key)
  p <- make_caller_grid(d, spec$label)
  lim <- attr(p, "window")
  stem <- file.path(OUTPUT_DIR, paste0("sv_pr_callers_", benchmark_key))
  save_grid(p, stem)

  all_data[[benchmark_key]] <- d
  audits[[benchmark_key]] <- attr(d, "audit")
  manifests[[benchmark_key]] <- data.frame(
    benchmark = benchmark_key,
    truth_set = spec$label,
    plotted_points = nrow(d),
    caller_panels = length(CALLERS),
    trajectories = length(CALLERS) * length(PLATFORMS) * length(ALIGNERS),
    depth_segments = 48L,
    shared_x_min = lim$x[1], shared_x_max = lim$x[2],
    shared_y_min = lim$y[1], shared_y_max = lim$y[2],
    symmetric_axes = isTRUE(all.equal(lim$x, lim$y)),
    first_labelled_tick = attr(p, "breaks")[1],
    f1_contours = paste(fmt_f1(attr(p, "f1_levels")), collapse = ";"),
    output_stem = basename(stem)
  )
}

plotted_source <- bind_rows(all_data) %>%
  mutate(across(c(caller, platform, aligner, depth), as.character))
write_csv(plotted_source, file.path(OUTPUT_DIR, "source_data_plotted.csv"))
write_csv(bind_rows(audits), file.path(OUTPUT_DIR, "data_filter_audit.csv"))
write_csv(bind_rows(manifests), file.path(OUTPUT_DIR, "render_manifest.csv"))

message("Created two caller-grid PR figures in: ", OUTPUT_DIR)
