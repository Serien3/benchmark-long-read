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

OUTPUT_STEM <- "mobile_element_xtea_paired_stacked"
width_mm = 89
height_mm = 78
PLATFORM_LEVELS <- c("BGI", "ONT", "HiFi")
ALIGNER_LEVELS <- c("minimap2", "winnowmap")
FAMILY_LEVELS <- c("ALU", "LINE1", "SVA", "HERV")

# Harmonized with the existing SV figures: muted, printable, and restrained.
FAMILY_COLORS <- c(
  ALU = "#A8B0BE",
  LINE1 = "#A98970",
  SVA = "#6F9FA0",
  HERV = "#765B96"
)
SEGMENT_EDGE <- "#707780"
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

  selected <- raw |>
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
    arrange(platform, aligner)

  if (nrow(selected) != 6L) stop("Expected 6 platform-aligner observations")
  if (any(is.na(selected$platform)) || any(is.na(selected$aligner))) {
    stop("Unexpected platform or aligner label")
  }
  key_counts <- selected |> count(platform, aligner, name = "n")
  if (nrow(key_counts) != 6L || any(key_counts$n != 1L)) {
    stop("Platform-aligner design contains missing or duplicated keys")
  }
  if (any(selected$depth != "30x") || any(selected$reference != "GRCh38") ||
      any(selected$tool != "xTEA-long")) {
    stop("Selected rows do not share the declared depth/reference/tool")
  }
  if (any(!startsWith(selected$status, "completed"))) {
    stop("Selected rows contain an incomplete workflow")
  }
  if (any(selected$result_basis != "merged_* final")) {
    stop("Selected rows are not based on final merged-family results")
  }

  numeric_values <- unlist(
    selected[c("total_merged_me", "ALU", "LINE1", "SVA", "HERV")],
    use.names = FALSE
  )
  if (any(!is.finite(numeric_values)) || any(numeric_values < 0)) {
    stop("MEI counts must be finite and non-negative")
  }
  if (any(selected$family_sum_residual != 0)) {
    stop("Total merged ME does not equal ALU + LINE1 + SVA + HERV")
  }

  long <- selected |>
    pivot_longer(
      cols = all_of(FAMILY_LEVELS),
      names_to = "family",
      values_to = "count"
    ) |>
    mutate(
      family = factor(family, levels = FAMILY_LEVELS),
      segment_label = ifelse(count >= 100, scales::comma(count), "")
    )

  list(raw = raw, wide = selected, long = long)
}

theme_mei <- function() {
  theme_classic(base_size = 7.0, base_family = BASE_FAMILY) +
    theme(
      axis.line = element_line(colour = "#111111", linewidth = 0.32),
      axis.ticks = element_line(colour = "#111111", linewidth = 0.28),
      axis.ticks.length = unit(1.6, "pt"),
      axis.title = element_text(size = 7.2, colour = TEXT_COLOR),
      axis.title.x = element_text(margin = margin(t = 3.0)),
      axis.title.y = element_text(margin = margin(r = 3.0)),
      axis.text = element_text(size = 5.8, colour = TEXT_COLOR),
      axis.text.x = element_text(margin = margin(t = 1.5)),
      panel.grid = element_blank(),
      panel.spacing.x = unit(2.7, "mm"),
      strip.background = element_blank(),
      strip.text = element_text(
        size = 7.0, face = "plain", colour = TEXT_COLOR,
        margin = margin(b = 1.5)
      ),
      plot.title = element_text(
        size = 9.2, face = "plain", colour = TEXT_COLOR, hjust = 0.5,
        margin = margin(b = 0.5)
      ),
      plot.subtitle = element_text(
        size = 6.3, face = "plain", colour = SECONDARY_TEXT, hjust = 0.5,
        margin = margin(b = 2.0)
      ),
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.title = element_text(size = 6.2, colour = TEXT_COLOR),
      legend.text = element_text(size = 6.0, colour = TEXT_COLOR),
      legend.key.width = unit(4.2, "mm"),
      legend.key.height = unit(3.2, "mm"),
      legend.spacing.x = unit(1.3, "mm"),
      legend.margin = margin(t = 1.0, unit = "mm"),
      plot.margin = margin(t = 2.5, r = 2.5, b = 1.5, l = 2.0, unit = "mm")
    )
}

make_plot <- function(long, wide) {
  ggplot(long, aes(x = aligner, y = count, fill = family)) +
    geom_col(
      width = 0.70,
      colour = SEGMENT_EDGE,
      linewidth = 0.20,
      position = position_stack(reverse = TRUE)
    ) +
    geom_text(
      aes(label = segment_label),
      position = position_stack(vjust = 0.5, reverse = TRUE),
      size = 1.62,
      family = BASE_FAMILY,
      colour = TEXT_COLOR,
      lineheight = 0.9
    ) +
    geom_text(
      data = wide,
      aes(
        x = aligner,
        y = total_merged_me + 105,
        label = scales::comma(total_merged_me)
      ),
      inherit.aes = FALSE,
      size = 1.75,
      family = BASE_FAMILY,
      fontface = "plain",
      colour = TEXT_COLOR
    ) +
    geom_segment(
      data = wide,
      aes(
        x = aligner,
        xend = aligner,
        y = total_merged_me - HERV / 2,
        yend = total_merged_me + 22
      ),
      inherit.aes = FALSE,
      colour = unname(FAMILY_COLORS[["HERV"]]),
      linewidth = 0.30,
      lineend = "round"
    ) +
    geom_text(
      data = wide,
      aes(
        x = aligner,
        y = total_merged_me + 42,
        label = paste0("HERV ", HERV)
      ),
      inherit.aes = FALSE,
      size = 1.75,
      family = BASE_FAMILY,
      fontface = "plain",
      colour = unname(FAMILY_COLORS[["HERV"]])
    ) +
    facet_grid(cols = vars(platform), scales = "free_x", space = "free_x") +
    scale_fill_manual(
      values = FAMILY_COLORS,
      breaks = FAMILY_LEVELS,
      drop = FALSE
    ) +
    scale_y_continuous(
      limits = c(0, 2180),
      breaks = seq(0, 2000, by = 500),
      labels = scales::label_comma(),
      expand = expansion(mult = c(0, 0))
    ) +
    labs(
      title = "Mobile-element insertions",
      subtitle = "HG002 · GRCh38 · 30× · xTEA-long",
      x = "Aligner",
      y = "Merged MEI candidates",
      fill = "MEI family"
    ) +
    guides(fill = guide_legend(nrow = 1, byrow = TRUE)) +
    theme_mei()
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
      total_merged_me,
      combined_only_lines,
      status,
      result_basis,
      notes
    )
  write_csv(source_data, file.path(OUTPUT_DIR, "source_data_plotted.csv"))

  audit <- tibble::tibble(
    source_file = basename(DATA_FILE),
    source_rows = nrow(data_objects$raw),
    selected_rows = nrow(data_objects$wide),
    excluded_rows = nrow(data_objects$raw) - nrow(data_objects$wide),
    selected_platforms = paste(PLATFORM_LEVELS, collapse = "|"),
    selected_aligners = paste(ALIGNER_LEVELS, collapse = "|"),
    complete_selected_rows = sum(startsWith(data_objects$wide$status, "completed")),
    plotted_measure = "final merged-family candidate count",
    plotted_families = paste(FAMILY_LEVELS, collapse = "|"),
    unplotted_audit_field = "Combined-only lines",
    unplotted_field_reason = "intermediate audit count; not an additional MEI family and not part of Total merged ME",
    max_total_minus_family_sum = max(abs(data_objects$wide$family_sum_residual)),
    old_failed_marker_rows = sum(grepl("old \\.failed flag", data_objects$wide$status)),
    old_failed_marker_interpretation = "retained because Slurm and xTea exit code were 0 and final merged outputs are present",
    reuse_level = "style-only inheritance from existing SV figures",
    transform_changes = "wide-to-long reshape only",
    aggregation_used = FALSE,
    uncertainty_available = FALSE,
    inferential_statistics_used = FALSE,
    smoothing_used = FALSE,
    interpolation_used = FALSE
  )
  write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"))

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
    family_order = paste(FAMILY_LEVELS, collapse = "|"),
    family_colors = paste(paste(names(FAMILY_COLORS), FAMILY_COLORS, sep = "="), collapse = "|"),
    min_total = min(data_objects$wide$total_merged_me),
    max_total = max(data_objects$wide$total_merged_me),
    all_bars_start_at_zero = TRUE,
    direct_total_labels = TRUE,
    direct_herv_labels = TRUE,
    herv_callout_preserves_segment_height = TRUE,
    internal_labels_threshold = 100,
    error_bars = FALSE,
    statistical_annotations = FALSE,
    base_font_family = BASE_FAMILY,
    png_dpi = 320,
    tiff_dpi = 600
  )
  write_csv(manifest, file.path(OUTPUT_DIR, "render_manifest.csv"))
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

message("Wrote MEI figure and provenance files to: ", OUTPUT_DIR)
