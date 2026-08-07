#!/usr/bin/env Rscript

# =============================================================================
# Platform-centred SV genotyping depth-response grid
#
# One independent 4 x 2 figure per truth set:
#   rows    = SV caller
#   columns = aligner
#   x       = matched sequencing depth
#   y       = original genotype F1
#   colour  = sequencing platform
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
OUTPUT_DIR <- file.path(ROOT, "figures", "codex_sv_gt_depth_workflow_grid")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# ---- Figure contract -------------------------------------------------------

# Claim: platform genotype-F1 differences and depth responses are evaluated
# simultaneously across matched caller-by-aligner workflows.
# Archetype: quantitative 4 x 2 interaction grid, one figure per truth set.
# Evidence: 72 point estimates per figure; no aggregation or uncertainty model.
# Export: 183 x 165 mm, editable SVG/PDF, 320 dpi PNG, 600 dpi TIFF.

CALLERS <- c("cuteSV", "Sniffles2", "sawfish", "SVDSS")
PLATFORMS <- c("BGI", "ONT", "HiFi")
ALIGNERS <- c("minimap2", "winnowmap")
DEPTHS <- c("10x", "30x", "50x")

BENCHMARKS <- list(
  GIAB5 = list(
    file = "sv_benchmark_GIAB5.0q.csv",
    label = "GIAB v5.0q \u00b7 GRCh38",
    y_limits = c(0.48, 0.75),
    y_breaks = seq(0.50, 0.75, by = 0.05)
  ),
  CMRG = list(
    file = "sv_benchmark_CMRG.csv",
    label = "GIAB CMRG \u00b7 GRCh38",
    y_limits = c(0.15, 0.90),
    y_breaks = seq(0.20, 0.80, by = 0.20)
  )
)

PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)

font_candidates <- c(
  "Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans"
)
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

# ---- Data contract ---------------------------------------------------------

read_benchmark <- function(spec, benchmark_key) {
  path <- file.path(DATA_DIR, spec$file)
  raw <- read_csv(path, show_col_types = FALSE, progress = FALSE)
  if (ncol(raw) < 13L || !"gt-F1" %in% names(raw)) {
    stop(spec$file, " does not contain the required gt-F1 column")
  }

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
      aligner = factor(aligner, levels = ALIGNERS),
      platform = factor(platform, levels = PLATFORMS),
      depth = factor(depth, levels = DEPTHS),
      genotype_F1 = as.numeric(`gt-F1`)
    ) %>%
    arrange(caller, aligner, platform, depth)

  expected <- expand_grid(
    caller = factor(CALLERS, levels = CALLERS),
    aligner = factor(ALIGNERS, levels = ALIGNERS),
    platform = factor(PLATFORMS, levels = PLATFORMS),
    depth = factor(DEPTHS, levels = DEPTHS)
  )
  missing_keys <- expected %>%
    anti_join(
      selected %>% select(caller, aligner, platform, depth),
      by = c("caller", "aligner", "platform", "depth")
    )
  duplicates <- selected %>%
    count(caller, aligner, platform, depth, name = "n") %>%
    filter(n != 1L)

  if (nrow(selected) != 72L || nrow(missing_keys) > 0L || nrow(duplicates) > 0L) {
    stop(benchmark_key, " lacks the complete symmetric 4 x 2 x 3 x 3 design")
  }
  if (any(!is.finite(selected$genotype_F1)) ||
      any(selected$genotype_F1 < 0 | selected$genotype_F1 > 1)) {
    stop(benchmark_key, " contains invalid genotype-F1 values")
  }
  if (min(selected$genotype_F1) < spec$y_limits[1] ||
      max(selected$genotype_F1) > spec$y_limits[2]) {
    stop(benchmark_key, " y limits do not contain every plotted observation")
  }

  attr(selected, "audit") <- data.frame(
    benchmark = benchmark_key,
    source_file = spec$file,
    source_rows = nrow(raw),
    plotted_rows = nrow(selected),
    metric_source_column = "gt-F1",
    refine_used = FALSE,
    reference = "GRCh38"
  )
  selected
}

# ---- Plot ------------------------------------------------------------------

theme_depth_grid <- function(base_family = BASE_FAMILY) {
  theme_bw(base_size = 7.2, base_family = base_family) +
    theme(
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_line(
        colour = "#E2E2E2", linewidth = 0.22
      ),
      panel.border = element_rect(
        colour = "#8F8F8F", fill = NA, linewidth = 0.27
      ),
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      plot.title = element_text(
        size = 9.2, face = "plain", colour = "#161616", hjust = 0.5,
        margin = margin(b = 0.2, unit = "mm")
      ),
      plot.subtitle = element_text(
        size = 6.5, face = "plain", colour = "#666666", hjust = 0.5,
        margin = margin(b = 1.2, unit = "mm")
      ),
      strip.background = element_blank(),
      strip.text.x = element_text(
        size = 7.8, face = "plain", colour = "#161616",
        margin = margin(t = 0.6, b = 0.8, unit = "mm")
      ),
      strip.text.y = element_text(
        size = 7.2, face = "plain", colour = "#161616", angle = 0,
        margin = margin(l = 1.0, r = 1.0, unit = "mm")
      ),
      axis.title = element_text(size = 7.4, colour = "#1A1A1A"),
      axis.text = element_text(size = 6.2, colour = "#5B5B5B"),
      axis.ticks = element_line(colour = "#777777", linewidth = 0.25),
      axis.ticks.length = unit(1.5, "pt"),
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.title = element_text(size = 6.2, colour = "#303030"),
      legend.text = element_text(size = 5.8, colour = "#4D4D4D"),
      legend.key.width = unit(6.0, "mm"),
      legend.key.height = unit(3.0, "mm"),
      legend.spacing.x = unit(1.0, "mm"),
      panel.spacing.x = unit(3.2, "mm"),
      panel.spacing.y = unit(2.8, "mm"),
      plot.margin = margin(t = 2.5, r = 2.5, b = 1.5, l = 2.5, unit = "mm")
    )
}

make_depth_grid <- function(d, spec) {
  if (nrow(d) != 72L) stop(spec$label, ": expected 72 observations")

  ggplot(
    d,
    aes(
      x = depth, y = genotype_F1,
      colour = platform, group = platform
    )
  ) +
    geom_line(
      linewidth = 0.48, alpha = 0.88,
      lineend = "round", linejoin = "round"
    ) +
    geom_point(size = 1.65, stroke = 0, alpha = 0.98) +
    facet_grid(
      rows = vars(caller), cols = vars(aligner),
      scales = "fixed", drop = FALSE
    ) +
    scale_colour_manual(
      name = "Platform", values = PLATFORM_COLOURS,
      breaks = PLATFORMS, drop = FALSE
    ) +
    scale_x_discrete(
      breaks = DEPTHS,
      labels = c(`10x` = "10\u00d7", `30x` = "30\u00d7", `50x` = "50\u00d7"),
      drop = FALSE,
      expand = expansion(add = 0.18)
    ) +
    scale_y_continuous(
      limits = spec$y_limits,
      breaks = spec$y_breaks,
      labels = label_number(accuracy = 0.01),
      expand = expansion(mult = 0)
    ) +
    guides(
      colour = guide_legend(
        title.position = "top", nrow = 1,
        override.aes = list(alpha = 1, linewidth = 0.55, size = 1.65)
      )
    ) +
    labs(
      title = spec$label,
      subtitle = "Genotype F1 across sequencing depth and SV analysis workflows",
      x = "Sequencing depth",
      y = "Genotype F1"
    ) +
    theme_depth_grid()
}

save_grid <- function(plot, stem, width_mm = 183, height_mm = 165,
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
  p <- make_depth_grid(d, spec)
  stem <- file.path(
    OUTPUT_DIR, paste0("sv_gt_depth_workflows_", benchmark_key)
  )
  save_grid(p, stem)

  all_data[[benchmark_key]] <- d
  audits[[benchmark_key]] <- attr(d, "audit")
  manifests[[benchmark_key]] <- data.frame(
    benchmark = benchmark_key,
    truth_set = spec$label,
    plotted_points = nrow(d),
    caller_rows = length(CALLERS),
    aligner_columns = length(ALIGNERS),
    platform_trajectories = length(CALLERS) * length(ALIGNERS) * length(PLATFORMS),
    y_min = spec$y_limits[1],
    y_max = spec$y_limits[2],
    first_labelled_tick = spec$y_breaks[1],
    last_labelled_tick = tail(spec$y_breaks, 1),
    metric_source_column = "gt-F1",
    refine_used = FALSE,
    output_stem = basename(stem)
  )
}

plotted_source <- bind_rows(all_data) %>%
  mutate(across(c(caller, aligner, platform, depth), as.character))
write_csv(plotted_source, file.path(OUTPUT_DIR, "source_data_plotted.csv"))
write_csv(bind_rows(audits), file.path(OUTPUT_DIR, "data_filter_audit.csv"))
write_csv(bind_rows(manifests), file.path(OUTPUT_DIR, "render_manifest.csv"))

message("Created two GT depth-workflow figures in: ", OUTPUT_DIR)
