#!/usr/bin/env Rscript

# =============================================================================
# SV detection and genotype F1 across caller, aligner, platform, and depth
#
# Figure contract
#   Claim      : platform differences in SV detection and genotype agreement
#                depend on depth and the caller-aligner workflow.
#   Evidence   : all 144 original F1 and GT-F1 observations per truth set; no
#                aggregation.
#   Archetype  : stand-alone quantitative trajectory chart.
#   Encoding   : x = four callers under minimap2 followed by the same four
#                callers under winnowmap; each caller contains three ordered
#                depth columns shared by all platforms; colour = platform;
#                opacity redundantly encodes depth; point shape and line type
#                redundantly encode F1 versus GT-F1.
#   Integrity  : original F1 and gt-F1 only (never refine F1); deterministic
#                within-category offsets are visual separation, not data jitter.
#   Export     : editable SVG/PDF, 600 dpi TIFF, and PNG preview.
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
OUTPUT_DIR <- file.path(
  ROOT, "figures", "SV_benchmark", "sv_f1_caller_aligner"
)
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

CALLERS <- c("cuteSV", "Sniffles2", "sawfish", "SVDSS")
ALIGNERS <- c("minimap2", "winnowmap")
PLATFORMS <- c("BGI", "ONT", "HiFi")
DEPTHS <- c("10x", "30x", "50x")
METRICS <- c("F1", "GT-F1")

BENCHMARKS <- list(
  GIAB5 = list(
    file = "sv_benchmark_GIAB5.0q.csv",
    label = "GIAB v5.0q",
    reference = "GRCh38"
  ),
  CMRG = list(
    file = "sv_benchmark_CMRG.csv",
    label = "GIAB CMRG",
    reference = "GRCh38"
  )
)

# Exact visual encoding used by scripts/codex/sv_pr_figures.
PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)

DEPTH_ALPHA <- c(
  `10x` = 0.30,
  `30x` = 0.60,
  `50x` = 1.00
)

# Deterministic layout offsets. F1 is never changed. Each caller has three
# shared depth columns; BGI, ONT, and HiFi observations at the same depth use
# exactly the same x coordinate.
DEPTH_OFFSET <- c(`10x` = -0.20, `30x` = 0, `50x` = 0.20)

METRIC_SHAPES <- c(F1 = 16, `GT-F1` = 2)
METRIC_LINETYPES <- c(F1 = "solid", `GT-F1` = "22")

font_candidates <- c("Arial", "Helvetica", "Nimbus Sans",
                     "Liberation Sans", "sans")
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

read_benchmark <- function(spec, benchmark_key) {
  path <- file.path(DATA_DIR, spec$file)
  raw <- read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    locale = locale(encoding = "UTF-8")
  )

  if (ncol(raw) < 9L) stop("Expected at least nine columns in ", spec$file)
  names(raw)[1:6] <- c(
    "aligner", "reference", "eval_mode", "caller", "platform", "depth"
  )

  n_source <- nrow(raw)
  filtered <- raw %>%
    filter(
      reference == spec$reference,
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
      aligner = factor(aligner, levels = ALIGNERS),
      platform = factor(platform, levels = PLATFORMS),
      depth = factor(depth, levels = DEPTHS),
      depth_numeric = as.integer(sub("x$", "", as.character(depth))),
      F1 = as.numeric(F1),
      `GT-F1` = as.numeric(.data[["gt-F1"]])
    ) %>%
    pivot_longer(
      cols = all_of(METRICS),
      names_to = "metric",
      values_to = "score"
    ) %>%
    mutate(
      metric = factor(metric, levels = METRICS)
    ) %>%
    arrange(aligner, caller, platform, metric, depth_numeric)

  if (any(!is.finite(filtered$score))) {
    stop(benchmark_key, " contains non-finite F1 or GT-F1 values")
  }
  if (any(filtered$score < 0 | filtered$score > 1)) {
    stop(benchmark_key, " contains F1 or GT-F1 values outside [0, 1]")
  }

  key_counts <- filtered %>%
    count(aligner, caller, platform, depth, metric, name = "n")
  if (nrow(key_counts) != 144L || any(key_counts$n != 1L)) {
    stop(benchmark_key, " is not a complete unique 2 x 4 x 3 x 3 x 2 design")
  }

  expected <- expand_grid(
    aligner = factor(ALIGNERS, levels = ALIGNERS),
    caller = factor(CALLERS, levels = CALLERS),
    platform = factor(PLATFORMS, levels = PLATFORMS),
    depth = factor(DEPTHS, levels = DEPTHS),
    metric = factor(METRICS, levels = METRICS)
  )
  missing_keys <- expected %>%
    anti_join(
      filtered %>% select(aligner, caller, platform, depth, metric),
      by = c("aligner", "caller", "platform", "depth", "metric")
    )
  if (nrow(missing_keys) > 0L) {
    stop(benchmark_key, " has missing caller-aligner-platform-depth keys")
  }

  attr(filtered, "audit") <- data.frame(
    benchmark = benchmark_key,
    truth_set = spec$label,
    source_rows = n_source,
    plotted_rows = nrow(filtered) / length(METRICS),
    plotted_metric_points = nrow(filtered),
    excluded_rows = n_source - nrow(filtered) / length(METRICS),
    filter_rule = paste0(
      "reference=", spec$reference,
      "; callers=cuteSV|Sniffles2|sawfish|SVDSS",
      "; aligners=minimap2|winnowmap; platforms=BGI|ONT|HiFi",
      "; depths=10x|30x|50x; metrics=original F1|gt-F1"
    )
  )
  filtered
}

add_layout <- function(d) {
  d %>%
    mutate(
      caller_index = as.integer(caller),
      aligner_index = as.integer(aligner),
      # A 0.65-unit inter-aligner gap separates the two workflow blocks.
      category_x = caller_index + if_else(aligner == "winnowmap", 4.65, 0),
      x = category_x + unname(DEPTH_OFFSET[as.character(depth)]),
      trajectory = interaction(
        aligner, caller, platform, metric, drop = TRUE
      )
    )
}

make_segments <- function(d) {
  segments <- d %>%
    group_by(trajectory) %>%
    arrange(depth_numeric, .by_group = TRUE) %>%
    mutate(
      xend = lead(x),
      yend = lead(score),
      segment_depth = lead(depth)
    ) %>%
    filter(!is.na(xend), !is.na(yend), !is.na(segment_depth)) %>%
    ungroup()

  if (nrow(segments) != 96L) {
    stop("Expected 96 depth segments but found ", nrow(segments))
  }
  segments
}

f1_limits <- function(x) {
  span <- diff(range(x))
  pad_low <- max(0.025, span * 0.08)
  pad_high <- max(0.020, span * 0.06)
  # Keep the panel boundary slightly below the first labelled tick, matching
  # the inset-axis treatment of the PR figures. The tiny upper headroom likewise
  # keeps the final tick away from the frame without changing the F1 scale.
  lower <- max(0, min(x) - pad_low)
  upper_tick <- min(1, ceiling((max(x) + pad_high) / 0.05) * 0.05)
  upper <- min(1.005, upper_tick + 0.005)
  c(lower, upper)
}

f1_breaks <- function(lim) {
  step <- if (diff(lim) <= 0.30) 0.05 else 0.10
  first <- ceiling((lim[1] + 1e-9) / step) * step
  last <- floor((min(lim[2], 1) + 1e-9) / step) * step
  round(seq(first, last, by = step), 8)
}

theme_reference_f1 <- function(base_family = BASE_FAMILY) {
  theme_bw(base_size = 7.2, base_family = base_family) +
    theme(
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.border = element_blank(),
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      plot.title = element_text(
        size = 9.0, face = "plain", colour = "#161616", hjust = 0.5,
        margin = margin(b = 1.0)
      ),
      plot.subtitle = element_text(
        size = 6.3, face = "plain", colour = "#626262", hjust = 0.5,
        margin = margin(b = 2.4)
      ),
      axis.title = element_text(size = 7.4, colour = "#1A1A1A"),
      axis.text = element_text(size = 6.2, colour = "#5B5B5B"),
      axis.text.x = element_text(margin = margin(t = 1.6)),
      axis.ticks = element_line(colour = "#777777", linewidth = 0.25),
      axis.ticks.length = unit(1.5, "pt"),
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.box.just = "center",
      legend.title = element_text(size = 6.2, colour = "#292929"),
      legend.text = element_text(size = 5.9, colour = "#4E4E4E"),
      legend.key.width = unit(4.5, "mm"),
      legend.key.height = unit(3.2, "mm"),
      legend.spacing = unit(3.5, "mm"),
      legend.spacing.x = unit(1.4, "mm"),
      legend.margin = margin(t = -1.0, r = 0, b = -1.2, l = 0, unit = "mm"),
      plot.margin = margin(t = 2.4, r = 3.0, b = 1.4, l = 2.5, unit = "mm")
    )
}

make_plot <- function(d, truth_label) {
  d <- add_layout(d)
  segments <- make_segments(d)
  ylim <- f1_limits(d$score)
  ybreaks <- f1_breaks(ylim)
  grid_breaks <- ybreaks
  xlim <- c(0.52, 9.13)

  category_centres <- c(1:4, 1:4 + 4.65)
  category_labels <- rep(CALLERS, 2)
  block_centres <- c(mean(1:4), mean(1:4 + 4.65))
  block_divider <- mean(c(max(1:4), min(1:4 + 4.65)))
  block_y <- ylim[2] - diff(ylim) * 0.025

  p <- ggplot(d, aes(x = x, y = score)) +
    geom_hline(
      yintercept = grid_breaks,
      colour = "#D0D0D0", linewidth = 0.27, linetype = "44"
    ) +
    # Retain the PR-style frame on three sides while intentionally omitting
    # only its top solid edge.
    annotate(
      "segment", x = xlim[1], xend = xlim[2],
      y = ylim[1], yend = ylim[1],
      colour = "#8F8F8F", linewidth = 0.27
    ) +
    annotate(
      "segment", x = xlim[1], xend = xlim[1],
      y = ylim[1], yend = ylim[2],
      colour = "#8F8F8F", linewidth = 0.27
    ) +
    annotate(
      "segment", x = xlim[2], xend = xlim[2],
      y = ylim[1], yend = ylim[2],
      colour = "#8F8F8F", linewidth = 0.27
    ) +
    geom_vline(
      xintercept = block_divider,
      colour = "#B1B1B1", linewidth = 0.28, linetype = "44"
    ) +
    geom_segment(
      data = segments,
      aes(
        x = x, y = score, xend = xend, yend = yend,
        colour = platform, alpha = segment_depth, linetype = metric
      ),
      inherit.aes = FALSE,
      linewidth = 0.45, lineend = "round", show.legend = FALSE
    ) +
    geom_point(
      aes(colour = platform, alpha = depth, shape = metric),
      size = 2.05, stroke = 0.55
    ) +
    annotate(
      "text", x = block_centres, y = block_y,
      label = ALIGNERS, family = BASE_FAMILY,
      size = 2.25, fontface = "plain", colour = "#333333", vjust = 1
    ) +
    scale_colour_manual(
      name = "Platform", values = PLATFORM_COLOURS,
      breaks = PLATFORMS, drop = FALSE
    ) +
    scale_alpha_manual(
      name = "Depth", values = DEPTH_ALPHA,
      breaks = DEPTHS, drop = FALSE
    ) +
    scale_shape_manual(
      name = "Metric", values = METRIC_SHAPES,
      breaks = METRICS, drop = FALSE
    ) +
    scale_linetype_manual(
      values = METRIC_LINETYPES,
      breaks = METRICS, drop = FALSE,
      guide = "none"
    ) +
    scale_x_continuous(
      breaks = category_centres,
      labels = category_labels,
      limits = xlim,
      expand = expansion(mult = 0)
    ) +
    scale_y_continuous(
      breaks = ybreaks,
      labels = label_number(accuracy = 0.01),
      limits = ylim,
      expand = expansion(mult = 0)
    ) +
    coord_cartesian(clip = "on") +
    guides(
      colour = guide_legend(
        order = 1, nrow = 1,
        override.aes = list(alpha = 1, size = 1.90)
      ),
      alpha = guide_legend(
        order = 2, nrow = 1,
        override.aes = list(colour = "#575757", size = 1.90)
      ),
      shape = guide_legend(
        order = 3, nrow = 1,
        override.aes = list(colour = "#575757", alpha = 1, size = 2.05)
      )
    ) +
    labs(
      title = paste0("SV benchmark · ", truth_label),
      subtitle = "GRCh38 · detection F1 and GT-F1",
      x = "SV caller",
      y = "F1 score"
    ) +
    theme_reference_f1()

  attr(p, "ylim") <- ylim
  attr(p, "segments") <- nrow(segments)
  p
}

save_figure <- function(plot, stem, width_mm = 183, height_mm = 105,
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

all_source <- list()
audits <- list()
manifests <- list()

for (benchmark_key in names(BENCHMARKS)) {
  spec <- BENCHMARKS[[benchmark_key]]
  message("[", benchmark_key, "] reading ", spec$file)
  d <- read_benchmark(spec, benchmark_key)
  p <- make_plot(d, spec$label)
  stem <- file.path(OUTPUT_DIR, paste0("sv_detection_f1_", benchmark_key))
  save_figure(p, stem)

  layout_source <- add_layout(d) %>%
    mutate(
      caller = as.character(caller),
      aligner = as.character(aligner),
      platform = as.character(platform),
      depth = as.character(depth),
      metric = as.character(metric),
      trajectory = as.character(trajectory)
    )
  coincident_groups <- layout_source %>%
    count(aligner, caller, depth, metric, x, score, name = "n_platforms") %>%
    filter(n_platforms > 1L)
  all_source[[benchmark_key]] <- layout_source
  audits[[benchmark_key]] <- attr(d, "audit")
  manifests[[benchmark_key]] <- data.frame(
    benchmark = benchmark_key,
    truth_set = spec$label,
    plotted_points = nrow(d),
    depth_trajectories = 48L,
    plotted_segments = attr(p, "segments"),
    depth_position_order = "10x<30x<50x",
    platforms_share_depth_x = TRUE,
    coincident_platform_groups = nrow(coincident_groups),
    coincident_extra_points = sum(coincident_groups$n_platforms - 1L),
    platform_offset = "BGI=0;ONT=0;HiFi=0",
    depth_offset = "10x=-0.20;30x=0;50x=0.20",
    depth_alpha = "10x=0.30;30x=0.60;50x=1.00",
    metric = "F1|GT-F1",
    refine_used = FALSE,
    gt_metric_used = TRUE,
    y_min = attr(p, "ylim")[1],
    y_max = attr(p, "ylim")[2],
    width_mm = 183,
    height_mm = 105,
    output_stem = basename(stem)
  )

  message(
    sprintf(
      "  144 points / 48 trajectories / 96 segments; score axis [%.2f, %.2f]",
      attr(p, "ylim")[1], attr(p, "ylim")[2]
    )
  )
}

write_csv(bind_rows(all_source), file.path(OUTPUT_DIR, "source_data_plotted.csv"))
write_csv(bind_rows(audits), file.path(OUTPUT_DIR, "data_filter_audit.csv"))
write_csv(bind_rows(manifests), file.path(OUTPUT_DIR, "render_manifest.csv"))

message("Created two SV F1 and GT-F1 figures in: ", OUTPUT_DIR)
