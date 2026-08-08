#!/usr/bin/env Rscript

# =============================================================================
# Supporting figures for cuteSV and Sniffles2 parameter tuning
#
# Claim discipline: these figures report the measured parameter-response data;
# they do not rank runs, add best-run badges, or encode a preferred conclusion.
# Source: CSVs extracted directly from 最新数据评测.xlsx by the companion Python
# script, with workbook sheet and row retained for every observation.
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
DATA_DIR <- file.path(ROOT, "data", "caller_tuning_xlsx")
OUTPUT_DIR <- file.path(ROOT, "figures", "SV_benchmark", "caller_tuning")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

font_candidates <- c("Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans")
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"
if (identical(BASE_FAMILY, "Nimbus Sans") && !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  do.call(grDevices::pdfFonts, setNames(list(grDevices::pdfFonts("NimbusSan")[[1]]), BASE_FAMILY))
}

COL_DARK <- "#25364F"
COL_TEAL <- "#2A8F91"
COL_RUST <- "#B46A4D"
COL_GREY <- "#8A9299"
COL_GRID <- "#D9DEE2"
COL_HEAT_LOW <- "#F3F5F6"
COL_HEAT_MID <- "#91A8B5"
COL_HEAT_HIGH <- "#29465B"

theme_paper <- function(base_size = 7) {
  theme_classic(base_size = base_size, base_family = BASE_FAMILY) +
    theme(
      axis.line = element_line(colour = "#222222", linewidth = 0.30),
      axis.ticks = element_line(colour = "#222222", linewidth = 0.28),
      axis.ticks.length = unit(1.5, "pt"),
      axis.title = element_text(size = 7.2, colour = "#111111"),
      axis.text = element_text(size = 6.2, colour = "#222222"),
      plot.title = element_text(size = 9.0, face = "bold", colour = "#111111", margin = margin(b = 1.5)),
      plot.subtitle = element_text(size = 6.4, colour = "#555555", margin = margin(b = 4.0)),
      plot.caption = element_text(size = 5.5, colour = "#666666", hjust = 0, margin = margin(t = 3.0)),
      legend.title = element_text(size = 6.5),
      legend.text = element_text(size = 6.1),
      legend.key.size = unit(3.8, "mm"),
      plot.margin = margin(5, 6, 5, 6, unit = "mm")
    )
}

export_plot <- function(plot, stem, width_mm, height_mm, source_file, plotted_rows, note = "") {
  out_base <- file.path(OUTPUT_DIR, stem)
  width_in <- width_mm / 25.4
  height_in <- height_mm / 25.4

  svglite::svglite(paste0(out_base, ".svg"), width = width_in, height = height_in)
  print(plot); dev.off()
  grDevices::cairo_pdf(paste0(out_base, ".pdf"), width = width_in, height = height_in, family = BASE_FAMILY)
  print(plot); dev.off()
  ragg::agg_tiff(paste0(out_base, ".tiff"), width = width_in, height = height_in, units = "in", res = 600, compression = "lzw")
  print(plot); dev.off()
  ragg::agg_png(paste0(out_base, ".png"), width = width_in, height = height_in, units = "in", res = 300)
  print(plot); dev.off()

  tibble(
    figure = stem, source_file = source_file, source_workbook = "最新数据评测.xlsx",
    plotted_rows = plotted_rows, width_mm = width_mm, height_mm = height_mm,
    smoothing = FALSE, interpolation = FALSE, aggregation = FALSE,
    missing_data = note, exports = "SVG|PDF|TIFF600|PNG300"
  )
}

read_checked <- function(filename, expected_rows) {
  path <- file.path(DATA_DIR, filename)
  d <- read_csv(path, show_col_types = FALSE, progress = FALSE, locale = locale(encoding = "UTF-8"))
  if (nrow(d) != expected_rows) stop(filename, ": expected ", expected_rows, " rows; found ", nrow(d))
  if (!all(c("source_workbook", "source_sheet", "source_row") %in% names(d))) stop(filename, ": provenance columns missing")
  d
}

manifests <- list()

# ---- cuteSV complete first-round factorial space ----------------------------
cutesv_r1 <- read_checked("cutesv_round1_fullfactor.csv", 162) %>%
  mutate(
    mapq = factor(mapq, levels = c(10, 20)),
    ins_bias_f = factor(ins_bias, levels = c(100, 500, 1000)),
    ins_ratio_f = factor(ins_ratio, levels = c(0.3, 0.5, 0.9)),
    del_bias_f = factor(del_bias, levels = c(100, 500, 1000)),
    del_ratio_f = factor(del_ratio, levels = c(0.3, 0.5, 0.9))
  )

if (nrow(distinct(cutesv_r1, mapq, ins_bias, ins_ratio, del_bias, del_ratio)) != 162L) {
  stop("cuteSV round-1 parameter keys are duplicated or incomplete")
}

raw_limits <- range(cutesv_r1$raw_f1)
refine_limits <- range(cutesv_r1$refine_f1)

make_cutesv_atlas <- function(mapq_value, metric, evaluation_label, limits) {
  score_col <- if (metric == "raw") "raw_f1" else "refine_f1"
  d <- cutesv_r1 %>%
    filter(as.character(mapq) == as.character(mapq_value)) %>%
    mutate(
      score = .data[[score_col]],
      score_label = sprintf("%.3f", score),
      label_colour = if_else(rescale(score, to = c(0, 1), from = limits) > 0.58, "white", "#17212B")
    )
  if (nrow(d) != 81L) stop("cuteSV atlas must contain exactly 81 cells")

  ggplot(d, aes(x = del_ratio_f, y = del_bias_f, fill = score)) +
    geom_tile(colour = "white", linewidth = 0.42) +
    geom_text(aes(label = score_label, colour = label_colour), size = 1.72, family = BASE_FAMILY, show.legend = FALSE) +
    scale_colour_identity() +
    scale_fill_gradient2(
      low = COL_HEAT_LOW, mid = COL_HEAT_MID, high = COL_HEAT_HIGH,
      midpoint = mean(limits), limits = limits, name = "F1",
      labels = label_number(accuracy = 0.01)
    ) +
    facet_grid(
      rows = vars(ins_bias_f), cols = vars(ins_ratio_f),
      labeller = labeller(
        ins_bias_f = function(x) paste0("INS bias ", x, " bp"),
        ins_ratio_f = function(x) paste0("INS ratio ", x)
      )
    ) +
    labs(
      title = paste0("cuteSV parameter space · MAPQ ", mapq_value, " · ", evaluation_label),
      subtitle = "BGI 50× · GRCh38/minimap2 · min support 10 · all 81 parameter combinations",
      x = "DEL clustering ratio", y = "DEL clustering bias (bp)"
    ) +
    coord_equal() +
    theme_paper(6.8) +
    theme(
      axis.line = element_blank(), axis.ticks = element_blank(),
      panel.spacing = unit(1.4, "mm"),
      strip.background = element_rect(fill = "#EEF1F3", colour = NA),
      strip.text = element_text(size = 6.0, colour = "#222222", margin = margin(2.2, 2.2, 2.2, 2.2)),
      legend.position = "right", legend.key.height = unit(18, "mm")
    )
}

atlas_specs <- tribble(
  ~mapq, ~metric, ~eval_label, ~stem,
  10, "raw", "raw", "cutesv_round1_mapq10_raw_f1_atlas",
  20, "raw", "raw", "cutesv_round1_mapq20_raw_f1_atlas",
  10, "refine", "refined", "cutesv_round1_mapq10_refine_f1_atlas",
  20, "refine", "refined", "cutesv_round1_mapq20_refine_f1_atlas"
)
for (i in seq_len(nrow(atlas_specs))) {
  spec <- atlas_specs[i, ]
  limits <- if (spec$metric == "raw") raw_limits else refine_limits
  p <- make_cutesv_atlas(spec$mapq, spec$metric, spec$eval_label, limits)
  manifests[[length(manifests) + 1L]] <- export_plot(p, spec$stem, 183, 139, "cutesv_round1_fullfactor.csv", 81)
}

# ---- cuteSV targeted second round, kept in experimental order ---------------
cutesv_r2 <- read_checked("cutesv_round2_targeted.csv", 14) %>%
  arrange(order) %>%
  mutate(
    concise_label = sprintf(
      "%02d  %s · s%d q%d · INS %g/%g · DEL %g/%g",
      order, gsub("_", " ", parameter_group), min_support, mapq,
      ins_bias, ins_ratio, del_bias, del_ratio
    ),
    concise_label = factor(concise_label, levels = rev(concise_label))
  )
cutesv_r2_long <- cutesv_r2 %>%
  select(order, concise_label, parameter_group, raw_f1, refine_f1) %>%
  pivot_longer(c(raw_f1, refine_f1), names_to = "evaluation", values_to = "f1") %>%
  mutate(
    evaluation = recode(evaluation, raw_f1 = "Raw", refine_f1 = "Refined"),
    evaluation = factor(evaluation, levels = c("Raw", "Refined")),
    label = sprintf("%.3f", f1)
  )

p_r2 <- ggplot(cutesv_r2_long, aes(y = concise_label)) +
  geom_line(aes(x = f1, group = order), orientation = "y", colour = COL_GRID, linewidth = 0.55) +
  geom_point(aes(x = f1, colour = evaluation, shape = evaluation), size = 2.0, stroke = 0.35) +
  geom_text(
    aes(x = f1, label = label, colour = evaluation),
    hjust = ifelse(cutesv_r2_long$evaluation == "Raw", 1.16, -0.16),
    size = 1.8, family = BASE_FAMILY, show.legend = FALSE
  ) +
  scale_colour_manual(values = c(Raw = COL_DARK, Refined = COL_RUST)) +
  scale_shape_manual(values = c(Raw = 16, Refined = 17)) +
  scale_x_continuous(limits = c(0.795, 0.918), breaks = seq(0.80, 0.90, 0.02), labels = label_number(accuracy = 0.01), expand = expansion(mult = c(0, 0))) +
  labs(
    title = "cuteSV targeted parameter refinement",
    subtitle = "BGI 50× · GRCh38/minimap2 · all 14 runs shown in experimental order",
    x = "F1", y = NULL, colour = NULL, shape = NULL
  ) +
  theme_paper(6.8) +
  theme(
    panel.grid.major.x = element_line(colour = "#E4E7E9", linewidth = 0.25),
    legend.position = "top", legend.justification = "left",
    axis.text.y = element_text(size = 5.5), axis.ticks.y = element_blank()
  )
manifests[[length(manifests) + 1L]] <- export_plot(p_r2, "cutesv_round2_targeted_f1", 183, 128, "cutesv_round2_targeted.csv", 28)

# ---- cuteSV HiFi parameter sensitivity --------------------------------------
cutesv_hifi <- read_checked("cutesv_hifi_wholegenome.csv", 6) %>%
  mutate(
    parameter_set = factor(parameter_set, levels = c("Previous", "HiFi-specific")),
    depth = factor(paste0(depth_x, "x"), levels = c("10x", "30x", "50x"))
  )

hifi_f1_value <- function(precision, recall) {
  ifelse(precision + recall > 0, 2 * precision * recall / (precision + recall), NA_real_)
}

hifi_f1_curve <- function(f1, xlim, ylim, n = 700L) {
  recall <- seq(max(xlim[1], f1 / 2 + 1e-4), min(xlim[2], 1), length.out = n)
  precision <- f1 * recall / (2 * recall - f1)
  keep <- is.finite(precision) & precision >= ylim[1] & precision <= min(ylim[2], 1)
  data.frame(recall = recall[keep], precision = precision[keep], f1 = rep(f1, sum(keep)))
}

hifi_panel_window <- function(d) {
  joint_range <- range(c(d$recall, d$precision))
  joint_pad <- max(0.008, diff(joint_range) * 0.025)
  common_lim <- pmax(0, pmin(1, joint_range + c(-joint_pad, joint_pad)))
  list(x = common_lim, y = common_lim)
}

hifi_f1_levels <- function(d, xlim, ylim) {
  centre <- round(median(d$f1) / 0.04) * 0.04
  candidates <- centre + c(-0.04, 0, 0.04)
  candidates[vapply(
    candidates,
    function(z) nrow(hifi_f1_curve(z, xlim, ylim)) >= 2L,
    logical(1)
  )]
}

hifi_f1_label_anchor <- function(curve, xlim, ylim) {
  anchor <- curve[which.max(curve$recall), , drop = FALSE]
  x_pad <- diff(xlim) * 0.012
  y_pad <- diff(ylim) * 0.010
  if (anchor$recall >= min(xlim[2], 1) - diff(xlim) * 0.02) {
    anchor$recall <- min(xlim[2], 1) - x_pad
    anchor$precision <- anchor$f1 * anchor$recall / (2 * anchor$recall - anchor$f1)
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

hifi_axis_breaks <- function(lim) {
  breaks <- pretty(lim, n = 4)
  breaks[breaks >= lim[1] - 1e-9 & breaks <= lim[2] + 1e-9]
}

hifi_theme_reference_pr <- function() {
  theme_bw(base_size = 7.2, base_family = BASE_FAMILY) +
    theme(
      panel.grid = element_blank(),
      panel.border = element_rect(colour = "#8F8F8F", fill = NA, linewidth = 0.27),
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      plot.title = element_text(size = 8.8, face = "plain", colour = "#161616", hjust = 0.5, margin = margin(b = 2.0)),
      axis.title = element_text(size = 7.4, colour = "#1A1A1A"),
      axis.text = element_text(size = 6.2, colour = "#5B5B5B"),
      axis.ticks = element_line(colour = "#777777", linewidth = 0.25),
      axis.ticks.length = unit(1.5, "pt"),
      legend.position = "none",
      plot.margin = margin(t = 2.4, r = 3.0, b = 2.0, l = 2.5, unit = "mm")
    )
}

hifi_segments <- cutesv_hifi %>%
  group_by(parameter_set) %>%
  arrange(depth_x, .by_group = TRUE) %>%
  mutate(
    recall_end = lead(recall),
    precision_end = lead(precision),
    segment_depth = lead(depth)
  ) %>%
  filter(!is.na(recall_end), !is.na(precision_end), !is.na(segment_depth)) %>%
  ungroup()
if (nrow(hifi_segments) != 4L) stop("cuteSV HiFi PR plot requires four depth segments")

hifi_lim <- hifi_panel_window(cutesv_hifi)
hifi_levels <- hifi_f1_levels(cutesv_hifi, hifi_lim$x, hifi_lim$y)
hifi_curve_list <- lapply(hifi_levels, hifi_f1_curve, xlim = hifi_lim$x, ylim = hifi_lim$y)
hifi_curves <- bind_rows(hifi_curve_list)
hifi_labels <- bind_rows(lapply(hifi_curve_list, hifi_f1_label_anchor, xlim = hifi_lim$x, ylim = hifi_lim$y))

p_hifi_pr <- ggplot(cutesv_hifi, aes(x = recall, y = precision)) +
  geom_path(
    data = hifi_curves,
    aes(x = recall, y = precision, group = f1),
    inherit.aes = FALSE, colour = "#A8A8A8", linewidth = 0.28,
    linetype = "44", lineend = "butt"
  ) +
  geom_text(
    data = hifi_labels,
    aes(
      x = recall, y = precision,
      label = paste0("F1=", sub("0$", "", sprintf("%.2f", f1))),
      hjust = hjust, vjust = vjust
    ),
    inherit.aes = FALSE, family = BASE_FAMILY, fontface = "bold",
    size = 2.15, colour = "#202020"
  ) +
  geom_segment(
    data = hifi_segments,
    aes(
      x = recall, y = precision, xend = recall_end, yend = precision_end,
      colour = parameter_set, alpha = segment_depth
    ),
    inherit.aes = FALSE, linewidth = 0.48, lineend = "round",
    show.legend = FALSE
  ) +
  geom_point(
    aes(colour = parameter_set, shape = parameter_set, alpha = depth),
    size = 2.15, stroke = 0, show.legend = FALSE
  ) +
  scale_colour_manual(values = c(Previous = "#FFB000", `HiFi-specific` = "#9400D3")) +
  scale_shape_manual(values = c(Previous = 16, `HiFi-specific` = 18)) +
  scale_alpha_manual(values = c(`10x` = 0.18, `30x` = 0.58, `50x` = 1.00)) +
  scale_x_continuous(
    breaks = hifi_axis_breaks(hifi_lim$x), labels = label_number(accuracy = 0.01),
    expand = expansion(mult = 0)
  ) +
  scale_y_continuous(
    breaks = hifi_axis_breaks(hifi_lim$y), labels = label_number(accuracy = 0.01),
    expand = expansion(mult = 0)
  ) +
  coord_fixed(ratio = 1, xlim = hifi_lim$x, ylim = hifi_lim$y, expand = FALSE, clip = "on") +
  labs(title = "cuteSV", x = "Recall", y = "Precision") +
  hifi_theme_reference_pr()
manifests[[length(manifests) + 1L]] <- export_plot(
  p_hifi_pr, "cutesv_hifi_parameter_pr", 74, 74,
  "cutesv_hifi_wholegenome.csv", 6,
  "none in plotted table; workbook benchmark label requires provenance confirmation"
)

cutesv_counts <- read_checked("cutesv_hifi_callcount.csv", 6) %>%
  mutate(parameter_set = factor(parameter_set, levels = c("Previous", "HiFi-specific")))
p_hifi_counts <- ggplot(cutesv_counts, aes(x = depth_x, y = total_calls, colour = parameter_set, group = parameter_set)) +
  geom_line(linewidth = 0.65) +
  geom_point(aes(shape = parameter_set), size = 2.0, stroke = 0.4) +
  scale_colour_manual(values = c(Previous = COL_DARK, `HiFi-specific` = COL_RUST)) +
  scale_shape_manual(values = c(Previous = 16, `HiFi-specific` = 17)) +
  scale_x_continuous(breaks = c(10, 30, 50), labels = function(x) paste0(x, "×")) +
  scale_y_continuous(labels = label_number(big.mark = ","), breaks = seq(20000, 30000, 2500)) +
  labs(
    title = "cuteSV call yield by parameter set",
    subtitle = "GRCh38/minimap2 · direct VCF call counts",
    x = "Sequencing depth", y = "SV calls", colour = NULL, shape = NULL
  ) +
  theme_paper(7.0) +
  theme(panel.grid.major.y = element_line(colour = "#E5E8EA", linewidth = 0.25), legend.position = "top")
manifests[[length(manifests) + 1L]] <- export_plot(p_hifi_counts, "cutesv_hifi_parameter_callcount", 89, 76, "cutesv_hifi_callcount.csv", 6)

# ---- Sniffles2 full 3 × 3 matrix --------------------------------------------
sniffles_matrix <- read_checked("sniffles2_matrix_50x.csv", 9) %>%
  mutate(
    auto_multiplier_f = factor(auto_multiplier, levels = c(0.05, 0.10, 0.15)),
    mapq_f = factor(mapq, levels = c(10, 20, 30))
  )
if (nrow(distinct(sniffles_matrix, auto_multiplier, mapq)) != 9L) stop("Sniffles2 matrix keys are incomplete")

make_sniffles_heatmap <- function(score_col, title, stem) {
  d <- sniffles_matrix %>%
    mutate(score = .data[[score_col]], score_label = sprintf("%.4f", score))
  limits <- range(d$score)
  d <- d %>% mutate(label_colour = if_else(rescale(score, to = c(0, 1), from = limits) > 0.58, "white", "#17212B"))
  p <- ggplot(d, aes(x = mapq_f, y = auto_multiplier_f, fill = score)) +
    geom_tile(colour = "white", linewidth = 0.7) +
    geom_text(aes(label = score_label, colour = label_colour), size = 2.25, family = BASE_FAMILY, show.legend = FALSE) +
    scale_colour_identity() +
    scale_fill_gradient2(low = COL_HEAT_LOW, mid = COL_HEAT_MID, high = COL_HEAT_HIGH, midpoint = mean(limits), limits = limits, name = "F1", labels = label_number(accuracy = 0.0001)) +
    coord_equal() +
    labs(
      title = title,
      subtitle = "BGI 50× · GRCh38/minimap2 · min support auto",
      x = "Minimum mapping quality", y = "Auto-support multiplier"
    ) +
    theme_paper(7.0) +
    theme(axis.line = element_blank(), axis.ticks = element_blank(), legend.key.height = unit(17, "mm"))
  manifests[[length(manifests) + 1L]] <<- export_plot(p, stem, 89, 74, "sniffles2_matrix_50x.csv", 9)
}

make_sniffles_heatmap("raw_f1", "Sniffles2 raw whole-genome F1", "sniffles2_matrix_50x_raw_f1")
make_sniffles_heatmap("refine_f1", "Sniffles2 refined whole-genome F1", "sniffles2_matrix_50x_refine_f1")
make_sniffles_heatmap("cmrg_f1", "Sniffles2 CMRG F1", "sniffles2_matrix_50x_cmrg_f1")

# ---- Sniffles2 cross-depth validation: measured values, not deltas -----------
sniffles_depth <- read_checked("sniffles2_cross_depth.csv", 6)
sniffles_depth_long <- sniffles_depth %>%
  select(depth_x, mapq, raw_f1, refine_f1, cmrg_f1) %>%
  pivot_longer(c(raw_f1, refine_f1, cmrg_f1), names_to = "evaluation", values_to = "f1") %>%
  mutate(
    evaluation = recode(evaluation, raw_f1 = "Raw whole genome", refine_f1 = "Refined whole genome", cmrg_f1 = "CMRG"),
    evaluation = factor(evaluation, levels = c("Raw whole genome", "Refined whole genome", "CMRG")),
    mapq = factor(mapq, levels = c(10, 20), labels = c("MAPQ 10", "MAPQ 20"))
  )

p_sniffles_depth <- ggplot(sniffles_depth_long, aes(x = depth_x, y = f1, colour = evaluation, linetype = mapq, shape = mapq, group = interaction(evaluation, mapq))) +
  geom_line(linewidth = 0.65) +
  geom_point(size = 1.9, stroke = 0.4) +
  scale_colour_manual(values = c(`Raw whole genome` = COL_DARK, `Refined whole genome` = COL_TEAL, CMRG = COL_RUST)) +
  scale_linetype_manual(values = c(`MAPQ 10` = "solid", `MAPQ 20` = "22")) +
  scale_shape_manual(values = c(`MAPQ 10` = 16, `MAPQ 20` = 1)) +
  scale_x_continuous(breaks = c(10, 30, 50), labels = function(x) paste0(x, "×")) +
  scale_y_continuous(limits = c(0.70, 0.92), breaks = seq(0.70, 0.90, 0.05), labels = label_number(accuracy = 0.01)) +
  labs(
    title = "Sniffles2 parameter response across depth",
    subtitle = "BGI · GRCh38/minimap2 · auto-support multiplier 0.10",
    x = "Sequencing depth", y = "F1", colour = NULL, linetype = NULL, shape = NULL
  ) +
  theme_paper(7.0) +
  theme(
    panel.grid.major.y = element_line(colour = "#E5E8EA", linewidth = 0.25),
    legend.position = "top", legend.box = "vertical", legend.spacing.y = unit(0, "mm")
  )
manifests[[length(manifests) + 1L]] <- export_plot(p_sniffles_depth, "sniffles2_cross_depth_f1", 120, 84, "sniffles2_cross_depth.csv", 18)

bind_rows(manifests) %>% write_csv(file.path(OUTPUT_DIR, "render_manifest.csv"))

source_files <- c(
  "cutesv_round1_fullfactor.csv", "cutesv_round2_targeted.csv",
  "cutesv_hifi_wholegenome.csv", "cutesv_hifi_callcount.csv",
  "sniffles2_matrix_50x.csv", "sniffles2_cross_depth.csv"
)
bind_rows(lapply(source_files, function(filename) {
  read_csv(file.path(DATA_DIR, filename), show_col_types = FALSE, progress = FALSE) %>% mutate(source_table = filename, .before = 1)
})) %>% write_csv(file.path(OUTPUT_DIR, "source_data_plotted.csv"))

tribble(
  ~source_table, ~source_rows, ~plotted_rows, ~status, ~reason,
  "cutesv_round1_fullfactor.csv", 162, 162, "complete", "All factorial observations shown; raw and refined F1 use separate atlases",
  "cutesv_round2_targeted.csv", 14, 14, "complete", "All targeted runs shown in workbook order",
  "cutesv_hifi_wholegenome.csv", 6, 6, "complete", "All precision-recall observations shown",
  "cutesv_hifi_callcount.csv", 6, 6, "complete", "All direct call counts shown",
  "cutesv_hifi_refine_incomplete.csv", 5, 0, "not plotted", "HiFi-specific 50x refined F1 is absent in workbook; no partial trajectory drawn",
  "cutesv_hifi_cmrg_incomplete.csv", 4, 0, "not plotted", "Only 10x and 30x are recorded; retained as extracted source data for a later dedicated view",
  "sniffles2_matrix_50x.csv", 9, 9, "complete", "All 3 x 3 parameter combinations shown in each evaluation heatmap",
  "sniffles2_cross_depth.csv", 6, 6, "complete", "All depth-MAPQ combinations and all three recorded F1 evaluations shown"
) %>% write_csv(file.path(OUTPUT_DIR, "data_filter_audit.csv"))

cat("Rendered", nrow(bind_rows(manifests)), "stand-alone caller-tuning figures to", OUTPUT_DIR, "\n")
