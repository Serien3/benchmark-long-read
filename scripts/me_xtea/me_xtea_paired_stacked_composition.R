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
DATA_FILE <- file.path(ROOT, "data", "mobile_element_xtea.csv")
OUTPUT_DIR <- file.path(ROOT, "figures", "codex_me_xtea")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

OUTPUT_STEM <- "mobile_element_xtea_paired_stacked_composition"
width_mm = 105
height_mm = 75

PLATFORM_LEVELS <- c("BGI", "ONT", "HiFi")
ALIGNER_LEVELS <- c("minimap2", "winnowmap")
FAMILY_LEVELS <- c("ALU", "LINE1", "SVA", "HERV")
X_POSITIONS <- c(1, 2, 4, 5, 7, 8)
PLATFORM_CENTERS <- c(BGI = 1.5, ONT = 4.5, HiFi = 7.5)

FAMILY_COLORS <- c(
  ALU = "#A8B0BE",
  LINE1 = "#A98970",
  SVA = "#6F9FA0",
  HERV = "#765B96"
)
SEGMENT_EDGE <- "#777D84"
TEXT_COLOR <- "#171717"
SECONDARY_TEXT <- "#555555"

font_candidates <- c("Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans")
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

if (identical(BASE_FAMILY, "Nimbus Sans") &&
    !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  nimbus_metrics <- grDevices::pdfFonts("NimbusSan")[[1]]
  do.call(grDevices::pdfFonts, setNames(list(nimbus_metrics), BASE_FAMILY))
}

read_mei_data <- function() {
  raw <- read_csv(
    DATA_FILE,
    show_col_types = FALSE,
    progress = FALSE,
    locale = locale(encoding = "UTF-8")
  )

  required <- c(
    "Dataset", "Mapper", "Depth", "Reference", "Tool", "Total merged ME",
    "ALU merged", "LINE1 merged", "SVA merged", "HERV merged",
    "Combined-only lines", "Status", "Result basis", "Notes"
  )
  missing_columns <- setdiff(required, names(raw))
  if (length(missing_columns) > 0L) {
    stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
  }

  wide <- raw |>
    transmute(
      dataset = as.character(Dataset),
      platform = sub("_latest$", "", as.character(Dataset)),
      aligner = as.character(Mapper),
      depth = as.character(Depth),
      reference = as.character(Reference),
      tool = as.character(Tool),
      total_merged_me = as.numeric(`Total merged ME`),
      ALU = as.numeric(`ALU merged`),
      LINE1 = as.numeric(`LINE1 merged`),
      SVA = as.numeric(`SVA merged`),
      HERV = as.numeric(`HERV merged`),
      combined_only_lines = as.numeric(`Combined-only lines`),
      status = as.character(Status),
      result_basis = as.character(`Result basis`),
      notes = as.character(Notes)
    ) |>
    mutate(
      platform = factor(platform, levels = PLATFORM_LEVELS),
      aligner = factor(aligner, levels = ALIGNER_LEVELS),
      family_sum = ALU + LINE1 + SVA + HERV,
      family_sum_residual = total_merged_me - family_sum
    ) |>
    arrange(platform, aligner) |>
    mutate(
      x = X_POSITIONS,
      total_label = paste0("n=", scales::comma(total_merged_me)),
      herv_proportion = HERV / total_merged_me,
      herv_label = sprintf("%.1f%% (%d)", 100 * herv_proportion, HERV)
    )

  if (nrow(wide) != 6L) stop("Expected 6 platform-aligner observations")
  if (any(is.na(wide$platform)) || any(is.na(wide$aligner))) {
    stop("Unexpected platform or aligner label")
  }
  key_counts <- wide |> count(platform, aligner, name = "n")
  if (nrow(key_counts) != 6L || any(key_counts$n != 1L)) {
    stop("Platform-aligner design contains missing or duplicated keys")
  }
  if (any(wide$depth != "30x") || any(wide$reference != "GRCh38") ||
      any(wide$tool != "xTEA-long")) {
    stop("Selected rows do not share the declared depth/reference/tool")
  }
  if (any(!startsWith(wide$status, "completed"))) {
    stop("Selected rows contain an incomplete workflow")
  }
  if (any(wide$result_basis != "merged_* final")) {
    stop("Selected rows are not based on final merged-family results")
  }
  numeric_values <- unlist(
    wide[c("total_merged_me", "ALU", "LINE1", "SVA", "HERV")],
    use.names = FALSE
  )
  if (any(!is.finite(numeric_values)) || any(numeric_values < 0)) {
    stop("MEI counts must be finite and non-negative")
  }
  if (any(wide$family_sum_residual != 0)) {
    stop("Total merged ME does not equal ALU + LINE1 + SVA + HERV")
  }

  long <- wide |>
    pivot_longer(
      cols = all_of(FAMILY_LEVELS),
      names_to = "family",
      values_to = "count"
    ) |>
    mutate(
      family = factor(family, levels = FAMILY_LEVELS),
      proportion = count / total_merged_me,
      segment_label = ifelse(
        family == "HERV",
        "",
        sprintf("%.1f%%", 100 * proportion)
      )
    )

  proportion_check <- long |>
    group_by(dataset, aligner) |>
    summarise(proportion_sum = sum(proportion), .groups = "drop")
  if (max(abs(proportion_check$proportion_sum - 1)) > 1e-12) {
    stop("Within-bar family proportions do not sum to one")
  }

  list(raw = raw, wide = wide, long = long)
}

theme_composition <- function() {
  theme_classic(base_size = 6.4, base_family = BASE_FAMILY) +
    theme(
      axis.line = element_line(colour = "#111111", linewidth = 0.28),
      axis.ticks = element_line(colour = "#111111", linewidth = 0.25),
      axis.ticks.length = unit(1.5, "pt"),
      axis.title.y = element_text(
        size = 6.8, colour = TEXT_COLOR, margin = margin(r = 3.0)
      ),
      axis.title.x = element_blank(),
      axis.text.y = element_text(size = 5.7, colour = TEXT_COLOR),
      axis.text.x = element_text(
        size = 5.5, colour = TEXT_COLOR, margin = margin(t = 1.2)
      ),
      panel.grid = element_blank(),
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.title = element_blank(),
      legend.text = element_text(size = 5.7, colour = TEXT_COLOR),
      legend.key.width = unit(4.0, "mm"),
      legend.key.height = unit(3.0, "mm"),
      legend.spacing.x = unit(1.4, "mm"),
      legend.margin = margin(t = 4.5, unit = "mm"),
      legend.background = element_rect(fill = NA, colour = NA),
      legend.box.background = element_blank(),
      plot.margin = margin(t = 2.0, r = 2.5, b = 2.0, l = 2.0, unit = "mm")
    )
}

make_plot <- function(long, wide) {
  group_labels <- tibble::tibble(
    platform = names(PLATFORM_CENTERS),
    x = unname(PLATFORM_CENTERS),
    y = -0.105
  )

  ggplot(long, aes(x = x, y = proportion, fill = family)) +
    geom_col(
      width = 0.58,
      colour = SEGMENT_EDGE,
      linewidth = 0.16,
      position = position_stack(reverse = TRUE)
    ) +
    geom_text(
      aes(label = segment_label),
      position = position_stack(vjust = 0.5, reverse = TRUE),
      size = 1.70,
      family = BASE_FAMILY,
      colour = TEXT_COLOR,
      lineheight = 0.9
    ) +
    geom_segment(
      data = wide,
      aes(
        x = x,
        xend = x,
        y = 1 - herv_proportion / 2,
        yend = 1.018
      ),
      inherit.aes = FALSE,
      colour = unname(FAMILY_COLORS[["HERV"]]),
      linewidth = 0.27,
      lineend = "round"
    ) +
    geom_text(
      data = wide,
      aes(x = x, y = 1.042, label = herv_label),
      inherit.aes = FALSE,
      size = 1.62,
      family = BASE_FAMILY,
      colour = unname(FAMILY_COLORS[["HERV"]])
    ) +
    geom_text(
      data = wide,
      aes(x = x, y = 1.108, label = total_label),
      inherit.aes = FALSE,
      size = 1.67,
      family = BASE_FAMILY,
      colour = TEXT_COLOR
    ) +
    geom_text(
      data = group_labels,
      aes(x = x, y = y, label = platform),
      inherit.aes = FALSE,
      size = 1.95,
      family = BASE_FAMILY,
      fontface = "plain",
      colour = TEXT_COLOR
    ) +
    scale_fill_manual(
      values = FAMILY_COLORS,
      breaks = FAMILY_LEVELS,
      drop = FALSE
    ) +
    scale_x_continuous(
      limits = c(0.4, 8.6),
      breaks = X_POSITIONS,
      labels = rep(ALIGNER_LEVELS, times = 3),
      expand = expansion(mult = c(0, 0))
    ) +
    scale_y_continuous(
      breaks = seq(0, 1, by = 0.25),
      labels = scales::label_percent(accuracy = 1),
      expand = expansion(mult = c(0, 0))
    ) +
    coord_cartesian(ylim = c(0, 1.145), clip = "off") +
    labs(
      x = NULL,
      y = "MEI family composition",
      fill = NULL
    ) +
    guides(fill = guide_legend(nrow = 1, byrow = TRUE)) +
    theme_composition()
}

write_provenance <- function(data_objects) {
  source_data <- data_objects$long |>
    transmute(
      dataset,
      platform = as.character(platform),
      aligner = as.character(aligner),
      depth,
      reference,
      tool,
      family = as.character(family),
      count,
      proportion,
      total_merged_me,
      combined_only_lines,
      status,
      result_basis,
      notes
    )
  write_csv(
    source_data,
    file.path(OUTPUT_DIR, "source_data_composition.csv")
  )

  audit <- tibble::tibble(
    source_file = basename(DATA_FILE),
    source_rows = nrow(data_objects$raw),
    selected_rows = nrow(data_objects$wide),
    excluded_rows = nrow(data_objects$raw) - nrow(data_objects$wide),
    selected_platforms = paste(PLATFORM_LEVELS, collapse = "|"),
    selected_aligners = paste(ALIGNER_LEVELS, collapse = "|"),
    complete_selected_rows = sum(startsWith(data_objects$wide$status, "completed")),
    plotted_measure = "within-workflow final merged-family composition",
    normalization_denominator = "Total merged ME within each platform-aligner workflow",
    absolute_total_retained = "direct n label above every bar",
    plotted_families = paste(FAMILY_LEVELS, collapse = "|"),
    unplotted_audit_field = "Combined-only lines",
    unplotted_field_reason = "intermediate audit count; not an additional MEI family and not part of Total merged ME",
    max_total_minus_family_sum = max(abs(data_objects$wide$family_sum_residual)),
    max_proportion_sum_residual = max(abs(
      data_objects$long |>
        group_by(dataset, aligner) |>
        summarise(total = sum(proportion), .groups = "drop") |>
        pull(total) - 1
    )),
    old_failed_marker_rows = sum(grepl("old \\.failed flag", data_objects$wide$status)),
    reuse_level = "build anew; style-only inheritance",
    transform_changes = "counts divided by the matching Total merged ME for 100% composition",
    aggregation_used = FALSE,
    uncertainty_available = FALSE,
    inferential_statistics_used = FALSE,
    smoothing_used = FALSE,
    interpolation_used = FALSE
  )
  write_csv(
    audit,
    file.path(OUTPUT_DIR, "data_filter_audit_composition.csv")
  )

  manifest <- tibble::tibble(
    output_stem = OUTPUT_STEM,
    figure_width_mm = width_mm,
    figure_height_mm = height_mm,
    source_file = basename(DATA_FILE),
    source_rows = nrow(data_objects$raw),
    workflows_plotted = nrow(data_objects$wide),
    stacked_segments_plotted = nrow(data_objects$long),
    platform_levels = paste(PLATFORM_LEVELS, collapse = "|"),
    aligner_levels = paste(ALIGNER_LEVELS, collapse = "|"),
    x_positions = paste(X_POSITIONS, collapse = "|"),
    family_order = paste(FAMILY_LEVELS, collapse = "|"),
    family_colors = paste(paste(names(FAMILY_COLORS), FAMILY_COLORS, sep = "="), collapse = "|"),
    y_axis = "0-100% within-workflow composition",
    absolute_total_labels = TRUE,
    direct_herv_labels = TRUE,
    herv_geometry_exaggerated = FALSE,
    title_embedded = FALSE,
    all_bars_start_at_zero = TRUE,
    error_bars = FALSE,
    statistical_annotations = FALSE,
    base_font_family = BASE_FAMILY,
    png_dpi = 320,
    tiff_dpi = 600
  )
  write_csv(
    manifest,
    file.path(OUTPUT_DIR, "render_manifest_composition.csv")
  )
}

save_all_formats <- function(plot_object) {
  width_in <- width_mm / 25.4
  height_in <- height_mm / 25.4

  ggsave(
    file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".png")),
    plot_object,
    device = ragg::agg_png,
    width = width_in,
    height = height_in,
    units = "in",
    dpi = 320,
    background = "white"
  )
  ggsave(
    file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".tiff")),
    plot_object,
    device = ragg::agg_tiff,
    width = width_in,
    height = height_in,
    units = "in",
    dpi = 600,
    compression = "lzw",
    background = "white"
  )
  svglite::svglite(
    file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".svg")),
    width = width_in,
    height = height_in,
    bg = "white"
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

data_objects <- read_mei_data()
plot_object <- make_plot(data_objects$long, data_objects$wide)
write_provenance(data_objects)
save_all_formats(plot_object)

message("Wrote MEI composition figure and provenance files to: ", OUTPUT_DIR)
