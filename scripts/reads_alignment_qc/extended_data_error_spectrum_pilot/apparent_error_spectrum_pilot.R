#!/usr/bin/env Rscript

# =============================================================================
# Extended Data: apparent alignment-error spectrum in GRCh38 pilot regions
#
# Scientific contract
#   Claim      : in the matched 30x GRCh38/GIAB-masked pilot regions, total
#                apparent alignment-error burden is platform-specific, is
#                dominated by deletion bases for BGI and ONT, and retains the
#                same platform ordering with minimap2 and winnowmap.
#   Role       : Extended Data bridge between reported read Q-score profiles,
#                alignment QC and later donor-specific error analysis.
#   Evidence   : all six platform x aligner observations in the pilot table.
#   Archetype  : compact 3 x 2 stacked horizontal-bar matrix.
#   Encoding   : rows = platform; columns = aligner; stack length = mismatch,
#                insertion and deletion bases per 1,000 aligned Q20 bases;
#                exact label = total apparent-error burden.
#   Integrity  : component rates are recomputed from raw counts and one common
#                denominator; no aggregation, uncertainty, test, p-value,
#                ranking, point or connector.
#   Reuse      : style-only inheritance from Panels d/e: 89 x 54 mm geometry,
#                typography, platform row markers, white background and greys.
# =============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(grid)
  library(svglite)
  library(ragg)
  library(systemfonts)
})

find_root <- function() {
  arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(arg) == 1L) {
    script_path <- normalizePath(sub("^--file=", "", arg))
    return(dirname(dirname(dirname(dirname(script_path)))))
  }
  normalizePath(getwd())
}

ROOT <- find_root()
INPUT_FILE <- file.path(ROOT, "data", "error_spectrum_pilot.csv")
OUTPUT_DIR <- file.path(
  ROOT,
  "figures",
  "reads_alignment_qc",
  "extended_data_error_spectrum_pilot"
)
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

PLATFORMS <- c("BGI", "ONT", "HiFi")
ALIGNERS <- c("minimap2", "winnowmap")
COMPONENTS <- c("Mismatch", "Insertion", "Deletion")

PLATFORM_COLOURS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)
COMPONENT_COLOURS <- c(
  Mismatch = "#425A65",
  Insertion = "#7FA8B7",
  Deletion = "#D7B26D"
)

SCALE_LIMIT_PER_1K <- 18
CELL_WIDTH <- 1.58
CELL_HEIGHT <- 0.46

WIDTH_MM = 89
HEIGHT_MM = 54
PNG_DPI = 320
TIFF_DPI = 600
OUTPUT_STEM <- "apparent_error_spectrum_pilot_30x"

choose_font <- function() {
  candidates <- c(
    "Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans"
  )
  available <- unique(systemfonts::system_fonts()$family)
  selected <- candidates[candidates %in% available][1]
  if (is.na(selected)) "sans" else selected
}

BASE_FAMILY <- choose_font()

if (identical(BASE_FAMILY, "Nimbus Sans") &&
    !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  nimbus_metrics <- grDevices::pdfFonts("NimbusSan")[[1]]
  do.call(
    grDevices::pdfFonts,
    setNames(list(nimbus_metrics), BASE_FAMILY)
  )
}

assert_near <- function(observed, expected, label, tolerance = 1e-8) {
  if (length(observed) != 1L || !is.finite(observed) ||
      abs(observed - expected) > tolerance) {
    stop(label, " changed: expected ", expected, "; observed ", observed)
  }
}

# ---- Data contract ---------------------------------------------------------

required_columns <- c(
  "Dataset", "Aligner", "Depth", "Reference", "Region bases",
  "Truth masked sites", "Reads seen", "Aligned Q20 bases",
  "Mismatch bases", "Insertion events", "Insertion bases",
  "Deletion events", "Deletion bases", "Total error bases",
  "Mismatch / 1k Q20", "Insertion bases / 1k Q20",
  "Deletion bases / 1k Q20", "Total error / 1k Q20",
  "Total error rate"
)

raw <- read_csv(
  INPUT_FILE,
  show_col_types = FALSE,
  progress = FALSE,
  locale = locale(encoding = "UTF-8")
)

missing_columns <- setdiff(required_columns, names(raw))
if (length(missing_columns) > 0L) {
  stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
}

n_source <- nrow(raw)
if (n_source != 6L) {
  stop("Expected exactly six apparent-error pilot observations; found ", n_source)
}

plot_data <- raw %>%
  transmute(
    source_dataset = Dataset,
    platform = factor(sub("_latest$", "", Dataset), levels = PLATFORMS),
    aligner = factor(Aligner, levels = ALIGNERS),
    depth_label = Depth,
    nominal_depth_x = as.numeric(sub("x$", "", Depth)),
    reference = Reference,
    region_bases = as.numeric(`Region bases`),
    truth_masked_sites = as.numeric(`Truth masked sites`),
    reads_seen = as.numeric(`Reads seen`),
    aligned_q20_bases = as.numeric(`Aligned Q20 bases`),
    mismatch_bases = as.numeric(`Mismatch bases`),
    insertion_events = as.numeric(`Insertion events`),
    insertion_bases = as.numeric(`Insertion bases`),
    deletion_events = as.numeric(`Deletion events`),
    deletion_bases = as.numeric(`Deletion bases`),
    total_error_bases = as.numeric(`Total error bases`),
    provided_mismatch_per_1k = as.numeric(`Mismatch / 1k Q20`),
    provided_insertion_per_1k =
      as.numeric(`Insertion bases / 1k Q20`),
    provided_deletion_per_1k =
      as.numeric(`Deletion bases / 1k Q20`),
    provided_total_per_1k = as.numeric(`Total error / 1k Q20`),
    provided_total_error_rate = as.numeric(`Total error rate`)
  ) %>%
  arrange(aligner, platform)

if (any(is.na(plot_data$platform))) {
  stop("Unexpected platform label in apparent-error pilot data")
}
if (any(is.na(plot_data$aligner))) {
  stop("Unexpected aligner label in apparent-error pilot data")
}
if (any(plot_data$depth_label != "30x") ||
    any(plot_data$nominal_depth_x != 30)) {
  stop("All apparent-error pilot observations must be nominal 30x")
}
if (any(plot_data$reference != "GRCh38")) {
  stop("All apparent-error pilot observations must use GRCh38")
}
if (n_distinct(plot_data$region_bases) != 1L ||
    unique(plot_data$region_bases) != 2981290) {
  stop("Pilot-region size changed from the confirmed 2,981,290 bases")
}
if (n_distinct(plot_data$truth_masked_sites) != 1L ||
    unique(plot_data$truth_masked_sites) != 6488) {
  stop("Truth-site mask count changed from the confirmed 6,488 sites")
}

numeric_fields <- plot_data %>%
  select(
    region_bases, truth_masked_sites, reads_seen, aligned_q20_bases,
    mismatch_bases, insertion_events, insertion_bases,
    deletion_events, deletion_bases, total_error_bases,
    starts_with("provided_")
  )
if (any(!is.finite(as.matrix(numeric_fields)))) {
  stop("All apparent-error pilot numeric values must be finite")
}
if (any(as.matrix(numeric_fields) < 0)) {
  stop("Apparent-error pilot counts and rates must be non-negative")
}
if (any(plot_data$aligned_q20_bases <= 0)) {
  stop("Aligned Q20 base denominators must be strictly positive")
}

duplicate_keys <- plot_data %>%
  count(platform, aligner, name = "n") %>%
  filter(n != 1L)
if (nrow(duplicate_keys) > 0L) {
  stop("Platform x aligner keys are not unique")
}

expected_keys <- expand.grid(
  platform = PLATFORMS,
  aligner = ALIGNERS,
  stringsAsFactors = FALSE
)
observed_keys <- plot_data %>%
  transmute(
    platform = as.character(platform),
    aligner = as.character(aligner)
  )
if (nrow(anti_join(expected_keys, observed_keys,
                  by = c("platform", "aligner"))) > 0L ||
    nrow(anti_join(observed_keys, expected_keys,
                  by = c("platform", "aligner"))) > 0L) {
  stop("The pilot table is not the complete symmetric 3 x 2 matrix")
}

plot_data <- plot_data %>%
  mutate(
    component_sum_bases = mismatch_bases + insertion_bases + deletion_bases,
    mismatch_per_1k = 1000 * mismatch_bases / aligned_q20_bases,
    insertion_per_1k = 1000 * insertion_bases / aligned_q20_bases,
    deletion_per_1k = 1000 * deletion_bases / aligned_q20_bases,
    total_per_1k = 1000 * total_error_bases / aligned_q20_bases,
    total_error_rate = total_error_bases / aligned_q20_bases,
    deletion_share_pct = 100 * deletion_bases / total_error_bases
  )

if (any(plot_data$component_sum_bases != plot_data$total_error_bases)) {
  stop("Total error bases do not equal mismatch + insertion + deletion bases")
}

rounding_tolerance_per_1k <- 0.0005001
rounding_tolerance_rate <- 0.0000051
rate_checks <- c(
  abs(plot_data$mismatch_per_1k - plot_data$provided_mismatch_per_1k),
  abs(plot_data$insertion_per_1k - plot_data$provided_insertion_per_1k),
  abs(plot_data$deletion_per_1k - plot_data$provided_deletion_per_1k),
  abs(plot_data$total_per_1k - plot_data$provided_total_per_1k)
)
if (any(rate_checks > rounding_tolerance_per_1k)) {
  stop("At least one recomputed per-1k rate differs from its rounded source value")
}
if (any(abs(plot_data$total_error_rate -
            plot_data$provided_total_error_rate) > rounding_tolerance_rate)) {
  stop("At least one recomputed total error rate differs from its source value")
}
if (any(plot_data$total_per_1k > SCALE_LIMIT_PER_1K)) {
  stop("At least one total apparent-error rate exceeds the common 0-18 scale")
}

# ---- Descriptive audits ----------------------------------------------------

platform_ranges <- plot_data %>%
  group_by(platform) %>%
  summarise(
    n_aligners = n(),
    minimum_total_per_1k = min(total_per_1k),
    maximum_total_per_1k = max(total_per_1k),
    minimum_deletion_share_pct = min(deletion_share_pct),
    maximum_deletion_share_pct = max(deletion_share_pct),
    .groups = "drop"
  )

condition_order <- plot_data %>%
  arrange(aligner, desc(total_per_1k)) %>%
  group_by(aligner) %>%
  summarise(
    platform_order = paste(as.character(platform), collapse = " > "),
    maximum_total_per_1k = max(total_per_1k),
    minimum_total_per_1k = min(total_per_1k),
    platform_spread_per_1k =
      maximum_total_per_1k - minimum_total_per_1k,
    .groups = "drop"
  )

if (any(condition_order$platform_order != "BGI > ONT > HiFi")) {
  stop("The platform ordering changed in at least one aligner condition")
}

minimap2_totals <- plot_data %>%
  filter(aligner == "minimap2") %>%
  transmute(
    platform = as.character(platform),
    minimap2_total_per_1k = total_per_1k
  )
winnowmap_totals <- plot_data %>%
  filter(aligner == "winnowmap") %>%
  transmute(
    platform = as.character(platform),
    winnowmap_total_per_1k = total_per_1k
  )

aligner_delta <- inner_join(
  minimap2_totals,
  winnowmap_totals,
  by = "platform"
) %>%
  mutate(
    winnowmap_minus_minimap2_per_1k =
      winnowmap_total_per_1k - minimap2_total_per_1k,
    winnowmap_relative_change_pct =
      100 * winnowmap_minus_minimap2_per_1k /
      minimap2_total_per_1k
  ) %>%
  arrange(factor(platform, levels = PLATFORMS))

if (nrow(aligner_delta) != 3L) {
  stop("Expected exactly three matched platform aligner pairs")
}
if (!(aligner_delta$winnowmap_relative_change_pct[
      aligner_delta$platform == "BGI"] < 0 &&
      aligner_delta$winnowmap_relative_change_pct[
      aligner_delta$platform == "ONT"] < 0 &&
      aligner_delta$winnowmap_relative_change_pct[
      aligner_delta$platform == "HiFi"] > 0)) {
  stop("The confirmed direction of the matched aligner changes has changed")
}

range_value <- function(platform_name, field) {
  platform_ranges[
    as.character(platform_ranges$platform) == platform_name,
    field,
    drop = TRUE
  ]
}

assert_near(
  round(range_value("BGI", "minimum_total_per_1k"), 3),
  17.239,
  "BGI minimum total apparent-error rate"
)
assert_near(
  round(range_value("BGI", "maximum_total_per_1k"), 3),
  17.552,
  "BGI maximum total apparent-error rate"
)
assert_near(
  round(range_value("ONT", "minimum_total_per_1k"), 3),
  6.351,
  "ONT minimum total apparent-error rate"
)
assert_near(
  round(range_value("ONT", "maximum_total_per_1k"), 3),
  6.436,
  "ONT maximum total apparent-error rate"
)
assert_near(
  round(range_value("HiFi", "minimum_total_per_1k"), 3),
  1.101,
  "HiFi minimum total apparent-error rate"
)
assert_near(
  round(range_value("HiFi", "maximum_total_per_1k"), 3),
  1.117,
  "HiFi maximum total apparent-error rate"
)

# ---- Matrix geometry -------------------------------------------------------

matrix_data <- plot_data %>%
  mutate(
    condition_x = case_when(
      aligner == "minimap2" ~ 1.00,
      aligner == "winnowmap" ~ 3.00,
      TRUE ~ NA_real_
    ),
    platform_y = case_when(
      platform == "BGI" ~ 3,
      platform == "ONT" ~ 2,
      platform == "HiFi" ~ 1,
      TRUE ~ NA_real_
    ),
    track_xmin = condition_x - CELL_WIDTH / 2,
    track_xmax = condition_x + CELL_WIDTH / 2,
    track_ymin = platform_y - CELL_HEIGHT / 2,
    track_ymax = platform_y + CELL_HEIGHT / 2,
    total_xend = track_xmin +
      CELL_WIDTH * total_per_1k / SCALE_LIMIT_PER_1K,
    total_label = sprintf("%.3f", total_per_1k),
    label_inside = total_per_1k >= 15,
    label_x = if_else(label_inside, total_xend - 0.045, total_xend + 0.050),
    label_hjust = if_else(label_inside, 1, 0)
  )

if (any(!is.finite(matrix_data$condition_x)) ||
    any(!is.finite(matrix_data$platform_y))) {
  stop("Failed to map at least one matrix row or column")
}
if (sum(matrix_data$label_inside) != 2L) {
  stop("Expected only the two BGI total labels to be placed inside bars")
}

component_data <- plot_data %>%
  select(
    platform, aligner, mismatch_per_1k,
    insertion_per_1k, deletion_per_1k
  ) %>%
  pivot_longer(
    cols = ends_with("_per_1k"),
    names_to = "component_source",
    values_to = "component_rate_per_1k"
  ) %>%
  mutate(
    component = case_when(
      component_source == "mismatch_per_1k" ~ "Mismatch",
      component_source == "insertion_per_1k" ~ "Insertion",
      component_source == "deletion_per_1k" ~ "Deletion",
      TRUE ~ NA_character_
    ),
    component = factor(component, levels = COMPONENTS)
  ) %>%
  arrange(aligner, platform, component) %>%
  group_by(platform, aligner) %>%
  mutate(
    stack_end_per_1k = cumsum(component_rate_per_1k),
    stack_start_per_1k = lag(stack_end_per_1k, default = 0)
  ) %>%
  ungroup() %>%
  left_join(
    matrix_data %>%
      select(
        platform, aligner, condition_x, platform_y,
        track_xmin, track_xmax, track_ymin, track_ymax
      ),
    by = c("platform", "aligner")
  ) %>%
  mutate(
    segment_xmin = track_xmin +
      CELL_WIDTH * stack_start_per_1k / SCALE_LIMIT_PER_1K,
    segment_xmax = track_xmin +
      CELL_WIDTH * stack_end_per_1k / SCALE_LIMIT_PER_1K
  )

stack_totals <- component_data %>%
  group_by(platform, aligner) %>%
  summarise(stack_total_per_1k = max(stack_end_per_1k), .groups = "drop") %>%
  left_join(
    plot_data %>% select(platform, aligner, total_per_1k),
    by = c("platform", "aligner")
  )
if (any(abs(stack_totals$stack_total_per_1k -
            stack_totals$total_per_1k) > 1e-10)) {
  stop("Stacked component rates do not recover the total apparent-error rate")
}

platform_markers <- matrix_data %>%
  distinct(platform, platform_y) %>%
  mutate(marker_colour = unname(PLATFORM_COLOURS[as.character(platform)]))

scale_ticks <- crossing(
  condition_x = c(1.00, 3.00),
  tick_value = c(0, 6, 12, 18)
) %>%
  mutate(
    track_xmin = condition_x - CELL_WIDTH / 2,
    tick_x = track_xmin +
      CELL_WIDTH * tick_value / SCALE_LIMIT_PER_1K,
    tick_label = as.character(tick_value)
  )

# ---- Traceable outputs -----------------------------------------------------

write_csv(
  plot_data %>%
    mutate(
      platform = as.character(platform),
      aligner = as.character(aligner),
      across(where(is.numeric), ~ round(.x, 8))
    ),
  file.path(OUTPUT_DIR, "source_data_plotted.csv"),
  na = ""
)
write_csv(
  component_data %>%
    transmute(
      platform = as.character(platform),
      aligner = as.character(aligner),
      component = as.character(component),
      component_rate_per_1k,
      stack_start_per_1k,
      stack_end_per_1k,
      condition_x,
      platform_y,
      track_xmin,
      track_xmax,
      segment_xmin,
      segment_xmax
    ) %>%
    mutate(across(where(is.numeric), ~ round(.x, 8))),
  file.path(OUTPUT_DIR, "component_rates_audit.csv"),
  na = ""
)
write_csv(
  matrix_data %>%
    transmute(
      platform = as.character(platform),
      aligner = as.character(aligner),
      total_per_1k,
      total_label,
      condition_x,
      platform_y,
      track_xmin,
      track_xmax,
      total_xend,
      label_inside,
      label_x,
      label_hjust,
      scale_limit_per_1k = SCALE_LIMIT_PER_1K
    ) %>%
    mutate(across(where(is.numeric), ~ round(.x, 8))),
  file.path(OUTPUT_DIR, "matrix_cell_geometry_audit.csv"),
  na = ""
)
write_csv(
  plot_data %>%
    transmute(
      platform = as.character(platform),
      aligner = as.character(aligner),
      deletion_bases,
      total_error_bases,
      deletion_share_pct
    ) %>%
    mutate(across(where(is.numeric), ~ round(.x, 6))),
  file.path(OUTPUT_DIR, "deletion_share_audit.csv"),
  na = ""
)
write_csv(
  aligner_delta %>% mutate(across(where(is.numeric), ~ round(.x, 8))),
  file.path(OUTPUT_DIR, "aligner_delta_audit.csv"),
  na = ""
)
write_csv(
  platform_ranges %>%
    mutate(
      platform = as.character(platform),
      across(where(is.numeric), ~ round(.x, 8))
    ),
  file.path(OUTPUT_DIR, "platform_range_audit.csv"),
  na = ""
)
write_csv(
  condition_order %>%
    mutate(
      aligner = as.character(aligner),
      across(where(is.numeric), ~ round(.x, 8))
    ),
  file.path(OUTPUT_DIR, "condition_platform_order_audit.csv"),
  na = ""
)

data_audit <- data.frame(
  source_file = basename(INPUT_FILE),
  source_rows = n_source,
  selected_rows = nrow(plot_data),
  excluded_rows = n_source - nrow(plot_data),
  expected_unique_keys = 6L,
  observed_unique_keys = nrow(distinct(plot_data, platform, aligner)),
  depth = "30x",
  reference = "GRCh38",
  region_bases = unique(plot_data$region_bases),
  truth_masked_sites = unique(plot_data$truth_masked_sites),
  common_scale = paste0("0-", SCALE_LIMIT_PER_1K, " per 1,000 Q20 bases"),
  rate_transform = paste(
    "1,000 x component error bases / aligned Q20 bases;",
    "components sum to total"
  ),
  geometry = paste(
    "3 x 2 stacked horizontal-bar matrix; common zero baseline;",
    "exact total label; no points, connectors or aggregation"
  ),
  replicate_statement = paste(
    "one HG002 30x technical subset per platform; aligner conditions are not",
    "biological replicates"
  ),
  stringsAsFactors = FALSE
)
write_csv(
  data_audit,
  file.path(OUTPUT_DIR, "data_filter_audit.csv"),
  na = ""
)

# ---- Figure ----------------------------------------------------------------

apparent_error_plot <- ggplot() +
  geom_rect(
    data = matrix_data,
    aes(
      xmin = track_xmin,
      xmax = track_xmax,
      ymin = track_ymin,
      ymax = track_ymax
    ),
    inherit.aes = FALSE,
    fill = "#EEF1F2",
    colour = "#D7D7D7",
    linewidth = 0.24
  ) +
  geom_rect(
    data = component_data,
    aes(
      xmin = segment_xmin,
      xmax = segment_xmax,
      ymin = track_ymin,
      ymax = track_ymax,
      fill = component
    ),
    inherit.aes = FALSE,
    colour = NA
  ) +
  geom_text(
    data = matrix_data,
    aes(
      x = label_x,
      y = platform_y,
      label = total_label,
      hjust = label_hjust
    ),
    inherit.aes = FALSE,
    family = BASE_FAMILY,
    fontface = "bold",
    size = 1.94,
    colour = "#171717"
  ) +
  geom_point(
    data = platform_markers,
    aes(x = 0.05, y = platform_y, colour = marker_colour),
    inherit.aes = FALSE,
    size = 1.70,
    shape = 16,
    show.legend = FALSE
  ) +
  annotate(
    "text", x = 2.00, y = 4.02, label = "GRCh38 30×",
    family = BASE_FAMILY, fontface = "bold", size = 2.54,
    colour = "#111111"
  ) +
  annotate(
    "segment", x = 0.21, xend = 3.79, y = 3.72, yend = 3.72,
    colour = "#D7D7D7", linewidth = 0.34
  ) +
  annotate(
    "text",
    x = c(1.00, 3.00),
    y = 3.50,
    label = ALIGNERS,
    family = BASE_FAMILY,
    size = 2.12,
    colour = "#292929"
  ) +
  annotate(
    "segment",
    x = c(0.21, 2.21),
    xend = c(1.79, 3.79),
    y = 0.57,
    yend = 0.57,
    colour = "#4D4D4D",
    linewidth = 0.28
  ) +
  geom_segment(
    data = scale_ticks,
    aes(x = tick_x, xend = tick_x, y = 0.51, yend = 0.63),
    inherit.aes = FALSE,
    colour = "#4D4D4D",
    linewidth = 0.28
  ) +
  geom_text(
    data = scale_ticks,
    aes(x = tick_x, y = 0.38, label = tick_label),
    inherit.aes = FALSE,
    family = BASE_FAMILY,
    size = 1.85,
    colour = "#3A3A3A"
  ) +
  annotate(
    "text", x = 2.00, y = 0.10,
    label = "Apparent error bases per 1,000 aligned Q20 bases",
    family = BASE_FAMILY, fontface = "bold", size = 2.04,
    colour = "#222222"
  ) +
  scale_fill_manual(
    name = NULL,
    values = COMPONENT_COLOURS,
    breaks = COMPONENTS,
    limits = COMPONENTS,
    drop = FALSE
  ) +
  scale_colour_identity() +
  scale_x_continuous(
    limits = c(-0.02, 3.84),
    expand = expansion(mult = 0)
  ) +
  scale_y_continuous(
    breaks = c(3, 2, 1),
    labels = PLATFORMS,
    limits = c(-0.01, 4.17),
    expand = expansion(mult = 0)
  ) +
  coord_cartesian(clip = "off") +
  guides(
    fill = guide_legend(
      nrow = 1,
      byrow = TRUE,
      override.aes = list(colour = NA)
    )
  ) +
  labs(x = NULL, y = NULL) +
  theme_void(base_size = 6.7, base_family = BASE_FAMILY) +
  theme(
    axis.text.y = element_text(
      colour = "#171717", size = 6.4, face = "bold",
      margin = margin(r = 4.0)
    ),
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.justification = "center",
    legend.text = element_text(colour = "#292929", size = 5.7),
    legend.key = element_blank(),
    legend.key.width = unit(4.0, "mm"),
    legend.key.height = unit(2.2, "mm"),
    legend.spacing.x = unit(1.0, "mm"),
    legend.margin = margin(0.5, 0, 0, 0, unit = "mm"),
    legend.box.spacing = unit(0.2, "mm"),
    plot.margin = margin(1.5, 2.0, 0.7, 2.0, unit = "mm")
  )

draw_apparent_error_plot <- function() {
  print(apparent_error_plot)
}

# ---- Export ----------------------------------------------------------------

width_in <- WIDTH_MM / 25.4
height_in <- HEIGHT_MM / 25.4

svg_path <- file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".svg"))
pdf_path <- file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".pdf"))
tiff_path <- file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".tiff"))
png_path <- file.path(OUTPUT_DIR, paste0(OUTPUT_STEM, ".png"))

svglite::svglite(
  svg_path,
  width = width_in,
  height = height_in,
  bg = "white",
  fix_text_size = FALSE
)
draw_apparent_error_plot()
grDevices::dev.off()

grDevices::cairo_pdf(
  pdf_path,
  width = width_in,
  height = height_in,
  family = BASE_FAMILY,
  bg = "white",
  onefile = TRUE
)
draw_apparent_error_plot()
grDevices::dev.off()

ragg::agg_tiff(
  tiff_path,
  width = WIDTH_MM,
  height = HEIGHT_MM,
  units = "mm",
  res = TIFF_DPI,
  compression = "lzw",
  background = "white"
)
draw_apparent_error_plot()
grDevices::dev.off()

ragg::agg_png(
  png_path,
  width = WIDTH_MM,
  height = HEIGHT_MM,
  units = "mm",
  res = PNG_DPI,
  background = "white"
)
draw_apparent_error_plot()
grDevices::dev.off()

rendered_paths <- c(svg_path, pdf_path, tiff_path, png_path)
render_manifest <- data.frame(
  file = basename(rendered_paths),
  format = c("SVG", "PDF", "TIFF", "PNG"),
  width_mm = WIDTH_MM,
  height_mm = HEIGHT_MM,
  dpi = c(NA, NA, TIFF_DPI, PNG_DPI),
  editable_text = c(TRUE, TRUE, FALSE, FALSE),
  base_family = BASE_FAMILY,
  selected_rows = nrow(plot_data),
  plotted_cells = nrow(matrix_data),
  plotted_segments = nrow(component_data),
  geometry = paste(
    "3 x 2 stacked horizontal-bar matrix; exact total labels;",
    "common zero-based 0-18 per-1,000 scale"
  ),
  row_encoding = "platform: BGI, ONT, HiFi with fixed colour markers",
  column_encoding = "aligner: minimap2, winnowmap",
  stack_encoding = "mismatch, insertion and deletion bases per 1,000 Q20 bases",
  point_data_geometries = 0L,
  connector_geometries = 0L,
  bytes = as.numeric(file.info(rendered_paths)$size),
  md5 = unname(tools::md5sum(rendered_paths)),
  stringsAsFactors = FALSE
)
write_csv(
  render_manifest,
  file.path(OUTPUT_DIR, "render_manifest.csv"),
  na = ""
)

message("Rendered apparent-error pilot figure to: ", OUTPUT_DIR)
message("Plotted conditions: ", nrow(matrix_data), " / 6")
message("Plotted component segments: ", nrow(component_data), " / 18")
message("Point data geometries: 0")
message("Connector segments: 0")
message("Font family: ", BASE_FAMILY)
