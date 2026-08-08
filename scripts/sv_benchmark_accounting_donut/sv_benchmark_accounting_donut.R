#!/usr/bin/env Rscript

# =============================================================================
# T2T-Q100 30x benchmark accounting — selected caller donut grid
#
# Figure contract
#   Purpose    : directly report matched and unmatched benchmark record counts
#                for two pre-specified callers with complete depth-gradient data.
#   Evidence   : six unaggregated T2T-Q100 observations at 30x/minimap2:
#                cuteSV and Sniffles2 across BGI, ONT and HiFi.
#   Encoding   : outer ring = truth accounting (tp-base + FN);
#                inner ring = call accounting (tp-call + FP).
#   Integrity  : each ring has its own denominator; raw counts are printed;
#                no ranking, smoothing, inference, or outcome-based ordering.
#   Reuse      : structural adaptation of the user-provided donut example;
#                SVTYPE sectors are not reused because no stratified data exist.
# =============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
  library(systemfonts)
  library(svglite)
  library(ragg)
  library(grid)
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
DATA_FILE <- file.path(ROOT, "data", "sv_benchmark_T2TQ100.csv")
OUTPUT_DIR <- file.path(
  ROOT, "figures", "SV_benchmark", "sv_benchmark_accounting_donut"
)
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

OUTPUT_STEM <- file.path(
  OUTPUT_DIR, "sv_benchmark_accounting_T2TQ100_30x_minimap2"
)

PLATFORM_LEVELS <- c("BGI", "ONT", "HiFi")
CALLER_LEVELS <- c("cuteSV", "Sniffles2")

OUTCOME_COLOURS <- c(
  "TP-base" = "#263952",
  "FN" = "#AAB5C8",
  "TP-call" = "#A33B3B",
  "FP" = "#E9A8AC"
)
PLATFORM_COLOURS <- c(
  "BGI" = "#F0A000",
  "ONT" = "#12A0A5",
  "HiFi" = "#8A00D4"
)

font_candidates <- c(
  "Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans"
)
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

if (identical(BASE_FAMILY, "Nimbus Sans") &&
    !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  nimbus_metrics <- grDevices::pdfFonts("NimbusSan")[[1]]
  do.call(grDevices::pdfFonts, setNames(list(nimbus_metrics), BASE_FAMILY))
}

read_selected_data <- function() {
  raw <- read_csv(
    DATA_FILE,
    show_col_types = FALSE,
    progress = FALSE,
    locale = locale(encoding = "UTF-8")
  )

  required <- c(
    "比对工具", "参考基因组", "评测模式", "SV Caller", "平台", "深度",
    "tp-base", "tp-call", "fp", "fn", "precision", "recall", "F1"
  )
  missing_columns <- setdiff(required, names(raw))
  if (length(missing_columns) > 0L) {
    stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
  }

  selected <- raw |>
    filter(
      比对工具 == "minimap2",
      参考基因组 == "GRCh38",
      深度 == "30x",
      `SV Caller` %in% CALLER_LEVELS,
      平台 %in% PLATFORM_LEVELS
    ) |>
    transmute(
      aligner = 比对工具,
      reference = 参考基因组,
      eval_mode = 评测模式,
      caller = factor(`SV Caller`, levels = CALLER_LEVELS),
      platform = factor(平台, levels = PLATFORM_LEVELS),
      depth = 深度,
      tp_base = as.numeric(`tp-base`),
      fn = as.numeric(fn),
      tp_call = as.numeric(`tp-call`),
      fp = as.numeric(fp),
      precision = as.numeric(precision),
      recall = as.numeric(recall),
      f1 = as.numeric(F1)
    ) |>
    arrange(caller, platform) |>
    mutate(
      truth_total = tp_base + fn,
      call_total = tp_call + fp,
      recall_check = tp_base / truth_total,
      precision_check = tp_call / call_total
    )

  if (nrow(selected) != 6L) {
    stop("Expected exactly 6 selected workflow observations; observed ", nrow(selected))
  }
  key_counts <- selected |> count(caller, platform, name = "n")
  if (nrow(key_counts) != 6L || any(key_counts$n != 1L)) {
    stop("Caller-platform design contains missing or duplicated keys")
  }
  numeric_fields <- c(
    "tp_base", "fn", "tp_call", "fp", "precision", "recall", "f1"
  )
  if (any(!is.finite(unlist(selected[numeric_fields], use.names = FALSE)))) {
    stop("Selected benchmark metrics must be finite")
  }
  if (any(unlist(selected[c("tp_base", "fn", "tp_call", "fp")]) < 0)) {
    stop("Benchmark counts must be non-negative")
  }
  if (max(abs(selected$recall_check - selected$recall)) > 1e-6) {
    stop("tp-base/(tp-base+FN) does not reproduce reported recall")
  }
  if (max(abs(selected$precision_check - selected$precision)) > 1e-6) {
    stop("tp-call/(tp-call+FP) does not reproduce reported precision")
  }

  list(raw = raw, selected = selected)
}

make_ring_data <- function(one_row) {
  tibble::tibble(
    ring = c("Truth set", "Truth set", "Call set", "Call set"),
    ring_x = c(2, 2, 1, 1),
    outcome = factor(
      c("TP-base", "FN", "TP-call", "FP"),
      levels = c("TP-base", "FN", "TP-call", "FP")
    ),
    count = c(one_row$tp_base, one_row$fn, one_row$tp_call, one_row$fp),
    total = c(
      one_row$truth_total, one_row$truth_total,
      one_row$call_total, one_row$call_total
    )
  ) |>
    group_by(ring, ring_x) |>
    arrange(outcome, .by_group = TRUE) |>
    mutate(
      proportion = count / total,
      ymax = cumsum(proportion),
      ymin = ymax - proportion,
      midpoint = (ymin + ymax) / 2,
      label_x = ifelse(ring == "Truth set", 1.82, 0.76),
      label_colour = ifelse(outcome %in% c("TP-base", "TP-call"), "white", "#242424")
    ) |>
    ungroup()
}

make_donut <- function(one_row, show_platform = TRUE) {
  ring_data <- make_ring_data(one_row)
  platform_name <- as.character(one_row$platform)

  direct_labels <- ring_data |>
    filter(outcome %in% c("FN", "TP-call"))
  tp_base_label <- ring_data |>
    filter(outcome == "TP-base")
  fp_label <- ring_data |>
    filter(outcome == "FP")

  p <- ggplot(ring_data) +
    geom_rect(
      aes(
        xmin = ring_x - 0.34,
        xmax = ring_x + 0.34,
        ymin = ymin,
        ymax = ymax,
        fill = outcome
      ),
      colour = "white",
      linewidth = 0.42
    ) +
    geom_text(
      data = direct_labels,
      aes(
        x = label_x,
        y = midpoint,
        label = comma(count),
        colour = label_colour
      ),
      family = BASE_FAMILY,
      size = 1.80,
      fontface = "plain",
      show.legend = FALSE
    ) +
    geom_text(
      data = tp_base_label,
      aes(x = 2.96, y = midpoint, label = comma(count)),
      family = BASE_FAMILY,
      size = 1.72,
      colour = "#202020",
      fontface = "plain"
    ) +
    geom_segment(
      data = fp_label,
      aes(x = 0.66, xend = 0.39, y = midpoint, yend = midpoint),
      colour = "#A45A60",
      linewidth = 0.28,
      lineend = "round"
    ) +
    geom_text(
      data = fp_label,
      aes(x = 0.25, y = midpoint, label = comma(count)),
      family = BASE_FAMILY,
      size = 1.72,
      colour = "#8F343A",
      fontface = "plain"
    ) +
    coord_polar(theta = "y", start = 0, direction = 1, clip = "off") +
    scale_fill_manual(values = OUTCOME_COLOURS, drop = FALSE) +
    scale_colour_identity() +
    scale_x_continuous(limits = c(0, 3.25), expand = expansion(mult = 0)) +
    labs(
      title = if (show_platform) platform_name else NULL
    ) +
    theme_void(base_family = BASE_FAMILY, base_size = 6.2) +
    theme(
      plot.title = element_text(
        size = 7.1,
        face = "bold",
        colour = unname(PLATFORM_COLOURS[platform_name]),
        hjust = 0.5,
        margin = margin(b = 0.5, unit = "mm")
      ),
      plot.margin = margin(t = 0.2, r = 0.5, b = 0.2, l = 0.5, unit = "mm"),
      legend.position = "none"
    )

  p
}

make_row_label <- function(label) {
  ggplot() +
    annotate(
      "text", x = 1, y = 1,
      label = label,
      family = BASE_FAMILY,
      fontface = "bold",
      size = 2.55,
      colour = "#1B1B1B",
      hjust = 0.5,
      angle = 90
    ) +
    xlim(0.8, 1.2) +
    ylim(0.8, 1.2) +
    theme_void()
}

make_legend <- function() {
  legend_data <- tibble::tibble(
    outcome = factor(
      c("TP-base", "FN", "TP-call", "FP"),
      levels = c("TP-base", "FN", "TP-call", "FP")
    ),
    x = seq_along(outcome),
    y = 1
  )

  ggplot(legend_data, aes(x = x, y = y, fill = outcome)) +
    geom_tile(width = 0.32, height = 0.32, colour = "white", linewidth = 0.25) +
    geom_text(
      aes(label = as.character(outcome)),
      x = legend_data$x + 0.23,
      hjust = 0,
      family = BASE_FAMILY,
      size = 1.8,
      colour = "#303030"
    ) +
    annotate(
      "text", x = 0.65, y = 1,
      label = "Outer: truth set",
      family = BASE_FAMILY,
      size = 1.8,
      hjust = 1,
      colour = "#303030"
    ) +
    annotate(
      "text", x = 5.05, y = 1,
      label = "Inner: call set",
      family = BASE_FAMILY,
      size = 1.8,
      hjust = 0,
      colour = "#303030"
    ) +
    scale_fill_manual(values = OUTCOME_COLOURS, drop = FALSE) +
    coord_cartesian(xlim = c(0.0, 6.0), ylim = c(0.72, 1.28), clip = "off") +
    theme_void() +
    theme(legend.position = "none", plot.margin = margin(0, 0, 0, 0))
}

draw_figure <- function(selected) {
  get_row <- function(caller_name, platform_name) {
    selected |>
      filter(caller == caller_name, platform == platform_name)
  }

  cute_plots <- lapply(
    PLATFORM_LEVELS,
    function(platform_name) {
      make_donut(get_row("cuteSV", platform_name), show_platform = TRUE)
    }
  )
  sniffles_plots <- lapply(
    PLATFORM_LEVELS,
    function(platform_name) {
      make_donut(get_row("Sniffles2", platform_name), show_platform = FALSE)
    }
  )

  grid.newpage()
  pushViewport(viewport(
    layout = grid.layout(
      nrow = 4,
      ncol = 4,
      widths = unit(c(0.16, 1, 1, 1), "null"),
      heights = unit(c(0.22, 1, 1, 0.18), "null")
    )
  ))

  title_vp <- viewport(layout.pos.row = 1, layout.pos.col = 1:4)
  pushViewport(title_vp)
  grid.text(
    "T2T-Q100 v1.1 benchmark accounting",
    x = 0.5, y = 0.68,
    gp = gpar(
      fontfamily = BASE_FAMILY, fontsize = 8.2,
      fontface = "bold", col = "#171717"
    )
  )
  grid.text(
    "HG002 · GRCh38 · 30× · minimap2",
    x = 0.5, y = 0.18,
    gp = gpar(fontfamily = BASE_FAMILY, fontsize = 6.2, col = "#5A5A5A")
  )
  popViewport()

  print(
    make_row_label("cuteSV"),
    vp = viewport(layout.pos.row = 2, layout.pos.col = 1)
  )
  print(
    make_row_label("Sniffles2"),
    vp = viewport(layout.pos.row = 3, layout.pos.col = 1)
  )
  for (i in seq_along(PLATFORM_LEVELS)) {
    print(
      cute_plots[[i]],
      vp = viewport(layout.pos.row = 2, layout.pos.col = i + 1)
    )
    print(
      sniffles_plots[[i]],
      vp = viewport(layout.pos.row = 3, layout.pos.col = i + 1)
    )
  }
  print(
    make_legend(),
    vp = viewport(layout.pos.row = 4, layout.pos.col = 1:4)
  )
  popViewport()
}

save_figure <- function(selected, stem, width_mm = 89, height_mm = 78,
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
  draw_figure(selected)
  dev.off()

  svglite::svglite(
    paste0(stem, ".svg"),
    width = width_in,
    height = height_in,
    bg = "white",
    system_fonts = list(sans = BASE_FAMILY)
  )
  draw_figure(selected)
  dev.off()

  grDevices::cairo_pdf(
    paste0(stem, ".pdf"),
    width = width_in,
    height = height_in,
    family = BASE_FAMILY,
    bg = "white"
  )
  draw_figure(selected)
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
  draw_figure(selected)
  dev.off()
}

write_audit_files <- function(raw, selected) {
  source_data <- selected |>
    mutate(
      caller = as.character(caller),
      platform = as.character(platform)
    ) |>
    select(
      aligner, reference, eval_mode, caller, platform, depth,
      tp_base, fn, truth_total, recall,
      tp_call, fp, call_total, precision, f1
    )

  write_csv(
    source_data,
    file.path(OUTPUT_DIR, "source_data_plotted.csv"),
    na = ""
  )

  audit <- tibble::tibble(
    source_file = basename(DATA_FILE),
    source_rows = nrow(raw),
    selected_rows = nrow(selected),
    selected_benchmark = "T2T-Q100 v1.1",
    selected_reference = "GRCh38",
    selected_depth = "30x",
    selected_aligner = "minimap2",
    selected_callers = paste(CALLER_LEVELS, collapse = "|"),
    selected_platforms = paste(PLATFORM_LEVELS, collapse = "|"),
    exclusion_reason = paste(
      "user-defined panel scope: T2T-Q100, 30x, minimap2,",
      "cuteSV and Sniffles2 only"
    ),
    aggregation_used = FALSE,
    smoothing_used = FALSE,
    ring_denominators = paste(
      "outer=tp-base+FN; inner=tp-call+FP;",
      "each workflow and ring normalized independently"
    ),
    reuse_level = "structural adaptation",
    unsupported_template_feature_omitted = "SVTYPE sectors"
  )
  write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"), na = "")

  manifest <- tibble::tibble(
    artifact = c(
      paste0(basename(OUTPUT_STEM), ".png"),
      paste0(basename(OUTPUT_STEM), ".svg"),
      paste0(basename(OUTPUT_STEM), ".pdf"),
      paste0(basename(OUTPUT_STEM), ".tiff"),
      "source_data_plotted.csv",
      "data_filter_audit.csv"
    ),
    role = c(
      "preview", "editable vector", "publication vector", "600 dpi print raster",
      "plotted source data", "filter and transformation audit"
    )
  )
  write_csv(manifest, file.path(OUTPUT_DIR, "render_manifest.csv"), na = "")
}

message("Reading ", DATA_FILE)
data_objects <- read_selected_data()
save_figure(data_objects$selected, OUTPUT_STEM)
write_audit_files(data_objects$raw, data_objects$selected)
message("Wrote figure package to ", OUTPUT_DIR)
