suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
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
DATA_FILE <- file.path(ROOT, "data", "sv_depth_gradient_bgi.csv")
OUTPUT_DIR <- file.path(ROOT, "figures", "codex_sv_depth_gradient_bgi")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

CALLERS <- c("cuteSV", "Sniffles2")
EXPECTED_DEPTHS <- seq(5, 70, by = 5)

# Style-only adaptation of the supplied reference figure.
BAR_FILL <- "#A8B0BE"
BAR_EDGE <- "#7E858E"
LINE_GREY <- "#7E7E7E"
DIAMOND_FILL <- "#A98970"
DIAMOND_EDGE <- "#7F7F7F"

font_candidates <- c("Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans")
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

if (identical(BASE_FAMILY, "Nimbus Sans") &&
    !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  nimbus_metrics <- grDevices::pdfFonts("NimbusSan")[[1]]
  do.call(grDevices::pdfFonts, setNames(list(nimbus_metrics), BASE_FAMILY))
}

read_depth_gradient <- function() {
  raw <- read_csv(
    DATA_FILE,
    show_col_types = FALSE,
    progress = FALSE,
    locale = locale(encoding = "UTF-8")
  )

  required <- c(
    "评测模式", "平台/样本", "参考/比对", "SV Caller", "深度",
    "refine FP", "refine FN", "refine Precision", "refine Recall",
    "refine F1", "refine ΔF1/5x", "状态"
  )
  missing_columns <- setdiff(required, names(raw))
  if (length(missing_columns) > 0L) {
    stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
  }

  selected <- raw |>
    transmute(
      eval_mode = 评测模式,
      sample = `平台/样本`,
      reference_aligner = `参考/比对`,
      caller = as.character(`SV Caller`),
      depth = as.character(深度),
      depth_x = as.numeric(sub("x$", "", depth)),
      refine_FP = as.numeric(`refine FP`),
      refine_FN = as.numeric(`refine FN`),
      refine_precision = as.numeric(`refine Precision`),
      refine_recall = as.numeric(`refine Recall`),
      refine_F1 = as.numeric(`refine F1`),
      refine_delta_F1_per_5x = as.numeric(`refine ΔF1/5x`),
      status = as.character(状态)
    ) |>
    filter(caller %in% CALLERS, depth_x %in% EXPECTED_DEPTHS) |>
    mutate(caller = factor(caller, levels = CALLERS)) |>
    arrange(caller, depth_x)

  if (nrow(selected) != length(CALLERS) * length(EXPECTED_DEPTHS)) {
    stop(
      "Expected ", length(CALLERS) * length(EXPECTED_DEPTHS),
      " selected observations but found ", nrow(selected)
    )
  }
  if (any(selected$status != "已完成")) {
    stop("Selected callers contain non-complete depth-gradient rows")
  }

  metric_values <- unlist(
    selected[c("refine_precision", "refine_recall", "refine_F1")],
    use.names = FALSE
  )
  if (any(!is.finite(metric_values)) || any(metric_values < 0 | metric_values > 1)) {
    stop("Selected refine performance metrics must be finite and within [0, 1]")
  }
  if (any(!is.finite(selected$refine_FP)) ||
      any(!is.finite(selected$refine_FN)) ||
      any(selected$refine_FP < 0) || any(selected$refine_FN < 0)) {
    stop("Selected refine FP and FN counts must be finite and non-negative")
  }

  expected_delta_na <- selected$depth_x == min(EXPECTED_DEPTHS)
  if (any(is.na(selected$refine_delta_F1_per_5x) != expected_delta_na)) {
    stop("Refine delta F1 must be missing only at the baseline 5x depth")
  }
  if (any(!is.finite(selected$refine_delta_F1_per_5x[!expected_delta_na]))) {
    stop("Non-baseline refine delta F1 values must be finite")
  }

  key_counts <- selected |> count(caller, depth_x, name = "n")
  if (nrow(key_counts) != length(CALLERS) * length(EXPECTED_DEPTHS) ||
      any(key_counts$n != 1L)) {
    stop("Caller-depth design contains missing or duplicated keys")
  }

  observed <- selected |>
    group_by(caller) |>
    summarise(depths = paste(depth_x, collapse = ";"), .groups = "drop")
  if (any(observed$depths != paste(EXPECTED_DEPTHS, collapse = ";"))) {
    stop("Selected callers do not share the expected numeric depth sequence")
  }

  delta_check <- selected |>
    group_by(caller) |>
    arrange(depth_x, .by_group = TRUE) |>
    mutate(
      delta_recomputed = (refine_F1 - lag(refine_F1)) /
        ((depth_x - lag(depth_x)) / 5),
      delta_rounding_residual = refine_delta_F1_per_5x - delta_recomputed
    ) |>
    ungroup()
  max_delta_residual <- max(
    abs(delta_check$delta_rounding_residual),
    na.rm = TRUE
  )
  if (max_delta_residual > 1.1e-4) {
    stop("Refine delta F1 is inconsistent with adjacent-depth F1 changes")
  }

  selected <- selected |>
    left_join(
      delta_check |>
        select(caller, depth_x, delta_recomputed, delta_rounding_residual),
      by = c("caller", "depth_x")
    )

  attr(selected, "audit") <- data.frame(
    source_file = basename(DATA_FILE),
    source_rows = nrow(raw),
    selected_rows = nrow(selected),
    selected_callers = paste(CALLERS, collapse = "|"),
    selected_depths = paste0(EXPECTED_DEPTHS, "x", collapse = "|"),
    excluded_rows = nrow(raw) - nrow(selected),
    excluded_callers = "sawfish|SVDSS",
    excluded_depths = "90x",
    exclusion_reason = "user-defined reporting scope; sawfish/SVDSS and all 90x observations are not reported",
    complete_selected_rows = sum(selected$status == "已完成"),
    missing_selected_rows = sum(selected$status != "已完成"),
    plotted_metrics = "refine Recall|refine F1|refine ΔF1/5x",
    retained_unplotted_fields = "refine Precision|refine FP|refine FN",
    max_delta_recalculation_residual = max_delta_residual,
    reuse_level = "style-only inheritance",
    transform_changes = "none",
    smoothing_used = FALSE,
    interpolation_used = FALSE,
    aggregation_used = FALSE
  )

  selected
}

theme_reference_style <- function() {
  theme_classic(base_size = 7.0, base_family = BASE_FAMILY) +
    theme(
      axis.line = element_line(colour = "#111111", linewidth = 0.32),
      axis.ticks = element_line(colour = "#111111", linewidth = 0.28),
      axis.ticks.length = unit(1.6, "pt"),
      axis.title = element_text(size = 7.2, colour = "#111111"),
      axis.title.y = element_blank(),
      axis.text = element_text(size = 6.1, colour = "#111111"),
      axis.text.x = element_text(margin = margin(t = 1.2)),
      panel.grid = element_blank(),
      panel.spacing.y = unit(4.0, "mm"),
      strip.placement = "outside",
      strip.background = element_blank(),
      strip.text.y.left = element_text(
        size = 7.2, face = "plain", colour = "#111111", angle = 90,
        margin = margin(r = 1.2, unit = "mm")
      ),
      plot.title = element_text(
        size = 9.2, face = "plain", colour = "#111111", hjust = 0.5,
        margin = margin(b = 0.5)
      ),
      plot.subtitle = element_text(
        size = 6.3, face = "plain", colour = "#555555", hjust = 0.5,
        margin = margin(b = 2.0)
      ),
      legend.position = "right",
      legend.direction = "vertical",
      legend.box = "vertical",
      legend.title = element_blank(),
      legend.text = element_text(size = 6.3, colour = "#222222"),
      legend.key.width = unit(6.5, "mm"),
      legend.key.height = unit(5.5, "mm"),
      legend.spacing.y = unit(1.5, "mm"),
      legend.margin = margin(l = 2.0, unit = "mm"),
      plot.margin = margin(t = 2.5, r = 2.5, b = 2.0, l = 2.3, unit = "mm")
    )
}

make_caller_plot <- function(d, caller_name) {
  caller_data <- d |>
    filter(as.character(caller) == caller_name) |>
    mutate(
      recall_label = sprintf("%.3f", refine_recall),
      f1_label = sprintf("%.3f", refine_F1),
      delta_label = ifelse(
        is.na(refine_delta_F1_per_5x),
        NA_character_,
        sprintf("%.4f", refine_delta_F1_per_5x)
      ),
      delta_label_y = refine_delta_F1_per_5x + ifelse(
        refine_delta_F1_per_5x >= 0,
        0.006,
        -0.006
      ),
      delta_label_vjust = ifelse(refine_delta_F1_per_5x >= 0, 0, 1)
    )

  score_data <- caller_data |>
    mutate(panel = factor(
      "Refine score",
      levels = c("Refine score", "Refine ΔF1 / 5×")
    ))
  delta_data <- caller_data |>
    filter(!is.na(refine_delta_F1_per_5x)) |>
    mutate(panel = factor(
      "Refine ΔF1 / 5×",
      levels = c("Refine score", "Refine ΔF1 / 5×")
    ))
  delta_upper <- if (max(delta_data$refine_delta_F1_per_5x) <= 0.06) 0.065 else 0.21
  panel_anchors <- data.frame(
    depth_x = c(5, 5, 5, 5),
    y = c(0, 1, -0.015, delta_upper),
    panel = factor(
      c("Refine score", "Refine score", "Refine ΔF1 / 5×", "Refine ΔF1 / 5×"),
      levels = c("Refine score", "Refine ΔF1 / 5×")
    )
  )

  ggplot() +
    geom_blank(
      data = panel_anchors,
      aes(x = depth_x, y = y)
    ) +
    geom_col(
      data = score_data,
      mapping = aes(x = depth_x, y = refine_recall, fill = "Refine recall"),
      width = 3.2,
      colour = BAR_EDGE,
      linewidth = 0.25
    ) +
    geom_line(
      data = score_data,
      aes(x = depth_x, y = refine_F1, colour = "Refine F1", group = 1),
      linewidth = 0.38,
      lineend = "round"
    ) +
    geom_point(
      data = score_data,
      aes(x = depth_x, y = refine_F1, colour = "Refine F1"),
      shape = 23,
      fill = DIAMOND_FILL,
      size = 2.45,
      stroke = 0.42
    ) +
    geom_text(
      data = score_data,
      aes(x = depth_x, y = refine_recall + 0.017, label = recall_label),
      size = 1.85,
      family = BASE_FAMILY,
      colour = "#111111",
      vjust = 0
    ) +
    geom_text(
      data = score_data,
      aes(x = depth_x, y = refine_F1 + 0.027, label = f1_label),
      size = 1.85,
      family = BASE_FAMILY,
      colour = "#111111",
      vjust = 0
    ) +
    geom_hline(
      data = data.frame(
        panel = factor(
          "Refine ΔF1 / 5×",
          levels = c("Refine score", "Refine ΔF1 / 5×")
        ),
        baseline = 0
      ),
      aes(yintercept = baseline),
      colour = "#A8A8A8",
      linewidth = 0.28,
      linetype = "33"
    ) +
    geom_line(
      data = delta_data,
      aes(x = depth_x, y = refine_delta_F1_per_5x, group = 1),
      colour = LINE_GREY,
      linewidth = 0.38,
      lineend = "round"
    ) +
    geom_point(
      data = delta_data,
      aes(x = depth_x, y = refine_delta_F1_per_5x),
      shape = 23,
      fill = DIAMOND_FILL,
      colour = LINE_GREY,
      size = 2.45,
      stroke = 0.42
    ) +
    geom_text(
      data = delta_data,
      aes(
        x = depth_x,
        y = delta_label_y,
        label = delta_label,
        vjust = delta_label_vjust
      ),
      size = 1.75,
      family = BASE_FAMILY,
      colour = "#111111"
    ) +
    scale_fill_manual(
      values = c(`Refine recall` = BAR_FILL),
      breaks = "Refine recall",
      guide = guide_legend(order = 2, override.aes = list(colour = BAR_EDGE))
    ) +
    scale_colour_manual(
      values = c(`Refine F1` = LINE_GREY),
      breaks = "Refine F1",
      guide = guide_legend(
        order = 1,
        override.aes = list(shape = 23, fill = DIAMOND_FILL, size = 2.6, linewidth = 0.38)
      )
    ) +
    scale_x_continuous(
      breaks = EXPECTED_DEPTHS,
      labels = paste0(EXPECTED_DEPTHS, "×"),
      limits = c(2.5, 72.5),
      expand = expansion(mult = 0)
    ) +
    scale_y_continuous(
      breaks = function(limits) {
        if (max(limits, na.rm = TRUE) > 0.5) {
          seq(0, 1, by = 0.2)
        } else if (max(limits, na.rm = TRUE) <= 0.1) {
          seq(0, 0.06, by = 0.01)
        } else {
          c(0, 0.05, 0.10, 0.15, 0.20)
        }
      },
      labels = function(values) {
        if (max(values, na.rm = TRUE) > 0.5) {
          ifelse(values == 0, "0", sprintf("%.1f", values))
        } else {
          sprintf("%.2f", values)
        }
      },
      expand = expansion(mult = 0)
    ) +
    labs(
      title = caller_name,
      subtitle = "BGI · HG002 · GRCh38 · minimap2 · refine",
      x = "Sequencing depth",
      y = NULL
    ) +
    facet_grid(
      rows = vars(panel),
      scales = "free_y",
      switch = "y",
      axes = "all_x",
      axis.labels = "all_x"
    ) +
    coord_cartesian(clip = "off") +
    theme_reference_style()
}

make_score_only_plot <- function(d, caller_name) {
  caller_data <- d |>
    filter(as.character(caller) == caller_name) |>
    mutate(
      recall_label = sprintf("%.3f", refine_recall),
      f1_label = sprintf("%.3f", refine_F1)
    )

  ggplot(caller_data, aes(x = depth_x)) +
    geom_col(
      aes(y = refine_recall, fill = "Refine recall"),
      width = 3.2,
      colour = BAR_EDGE,
      linewidth = 0.25
    ) +
    geom_line(
      aes(y = refine_F1, colour = "Refine F1", group = 1),
      linewidth = 0.38,
      lineend = "round"
    ) +
    geom_point(
      aes(y = refine_F1, colour = "Refine F1"),
      shape = 23,
      fill = DIAMOND_FILL,
      size = 2.45,
      stroke = 0.42
    ) +
    geom_text(
      aes(y = refine_recall + 0.017, label = recall_label),
      size = 1.85,
      family = BASE_FAMILY,
      colour = "#111111",
      vjust = 0
    ) +
    geom_text(
      aes(y = refine_F1 + 0.027, label = f1_label),
      size = 1.85,
      family = BASE_FAMILY,
      colour = "#111111",
      vjust = 0
    ) +
    scale_fill_manual(
      values = c(`Refine recall` = BAR_FILL),
      breaks = "Refine recall",
      guide = guide_legend(order = 2, override.aes = list(colour = BAR_EDGE))
    ) +
    scale_colour_manual(
      values = c(`Refine F1` = LINE_GREY),
      breaks = "Refine F1",
      guide = guide_legend(
        order = 1,
        override.aes = list(
          shape = 23,
          fill = DIAMOND_FILL,
          size = 2.6,
          linewidth = 0.38
        )
      )
    ) +
    scale_x_continuous(
      breaks = EXPECTED_DEPTHS,
      labels = paste0(EXPECTED_DEPTHS, "×"),
      limits = c(2.5, 72.5),
      expand = expansion(mult = 0)
    ) +
    scale_y_continuous(
      breaks = seq(0, 1, by = 0.2),
      labels = c("0", "0.2", "0.4", "0.6", "0.8", "1.0"),
      limits = c(0, 1),
      expand = expansion(mult = 0)
    ) +
    labs(
      title = caller_name,
      subtitle = "BGI · HG002 · GRCh38 · minimap2 · refine",
      x = "Sequencing depth",
      y = "Refine score"
    ) +
    coord_cartesian(clip = "off") +
    theme_reference_style() +
    theme(
      axis.title.y = element_text(
        size = 7.2,
        colour = "#111111",
        angle = 90,
        margin = margin(r = 1.5, unit = "mm")
      )
    )
}

save_figure <- function(plot, stem, width_mm = 183, height_mm = 142,
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

message("Reading ", basename(DATA_FILE))
depth_data <- read_depth_gradient()
audit <- attr(depth_data, "audit")
manifests <- list()

for (caller_name in CALLERS) {
  p_with_delta <- make_caller_plot(depth_data, caller_name)
  stem_with_delta <- file.path(
    OUTPUT_DIR,
    paste0("sv_depth_refine_reference_style_", caller_name)
  )
  save_figure(p_with_delta, stem_with_delta, width_mm = 183, height_mm = 142)

  p_score_only <- make_score_only_plot(depth_data, caller_name)
  stem_score_only <- file.path(
    OUTPUT_DIR,
    paste0("sv_depth_refine_score_only_", caller_name)
  )
  save_figure(p_score_only, stem_score_only, width_mm = 183, height_mm = 82)

  caller_data <- depth_data |>
    filter(as.character(caller) == caller_name)
  manifests[[paste0(caller_name, "_with_delta")]] <- data.frame(
    variant = "with_delta",
    caller = caller_name,
    selected_points = nrow(caller_data),
    depth_levels = length(unique(caller_data$depth_x)),
    depth_min = min(caller_data$depth_x),
    depth_max = max(caller_data$depth_x),
    bar_metric = "refine Recall",
    line_metric = "refine F1",
    lower_metric = "refine ΔF1/5x",
    labels = "score values to three decimals; delta values to four decimals",
    x_geometry = "continuous numeric depth; observed values only",
    bar_baseline = 0,
    delta_metric_shown = TRUE,
    delta_definition = "adjacent-depth refine F1 change normalized per 5x",
    delta_baseline_depth = "5x; undefined and intentionally unplotted",
    delta_scale = "caller-specific linear range with explicit zero baseline",
    delta_min = min(caller_data$refine_delta_F1_per_5x, na.rm = TRUE),
    delta_max = max(caller_data$refine_delta_F1_per_5x, na.rm = TRUE),
    smoothing_used = FALSE,
    interpolation_used = FALSE,
    aggregation_used = FALSE,
    uncertainty_model_used = FALSE,
    reuse_level = "style-only inheritance",
    width_mm = 183,
    height_mm = 142,
    output_stem = basename(stem_with_delta)
  )
  manifests[[paste0(caller_name, "_score_only")]] <- data.frame(
    variant = "score_only",
    caller = caller_name,
    selected_points = nrow(caller_data),
    depth_levels = length(unique(caller_data$depth_x)),
    depth_min = min(caller_data$depth_x),
    depth_max = max(caller_data$depth_x),
    bar_metric = "refine Recall",
    line_metric = "refine F1",
    lower_metric = NA_character_,
    labels = "score values to three decimals",
    x_geometry = "continuous numeric depth; observed values only",
    bar_baseline = 0,
    delta_metric_shown = FALSE,
    delta_definition = NA_character_,
    delta_baseline_depth = NA_character_,
    delta_scale = NA_character_,
    delta_min = NA_real_,
    delta_max = NA_real_,
    smoothing_used = FALSE,
    interpolation_used = FALSE,
    aggregation_used = FALSE,
    uncertainty_model_used = FALSE,
    reuse_level = "style-only inheritance",
    width_mm = 183,
    height_mm = 82,
    output_stem = basename(stem_score_only)
  )
}

write_csv(
  depth_data |> mutate(caller = as.character(caller)),
  file.path(OUTPUT_DIR, "source_data_reference_style.csv")
)
write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit_reference_style.csv"))
write_csv(
  bind_rows(manifests),
  file.path(OUTPUT_DIR, "render_manifest_reference_style.csv")
)

message("Created with-delta and score-only caller figures in: ", OUTPUT_DIR)
