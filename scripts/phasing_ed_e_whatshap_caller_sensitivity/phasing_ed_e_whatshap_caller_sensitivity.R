#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
  library(svglite)
  library(ragg)
  library(systemfonts)
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
CALLER_FILE <- file.path(ROOT, "data", "phasing_compare_whatshap_callers.csv")
BLOCK_FILE <- file.path(ROOT, "data", "phasing_block_stats_whatshap.csv")
ACCURACY_FILE <- file.path(ROOT, "data", "phasing_accuracy_whatshap.csv")
OUTPUT_DIR <- file.path(ROOT, "figures", "phasing_ed_e_whatshap_caller_sensitivity")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

FIGURE_STEM <- "phasing_ed_e_whatshap_caller_sensitivity"
WIDTH_MM <- 183
HEIGHT_MM <- 60
DPI <- 600
TARGET_DEPTH <- "30x"

EXPECTED_PLATFORMS <- c("BGI", "ONT", "HiFi")
EXPECTED_MAPPERS <- c("minimap2", "winnowmap")
EXPECTED_CALLERS <- c("Clair3", "DeepVariant")

PLATFORM_COLORS <- c(
  BGI = "#FFB000",
  ONT = "#13A4A6",
  HiFi = "#9400D3"
)

font_candidates <- c("Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans")
available_fonts <- unique(systemfonts::system_fonts()$family)
BASE_FAMILY <- font_candidates[font_candidates %in% available_fonts][1]
if (is.na(BASE_FAMILY)) BASE_FAMILY <- "sans"

if (identical(BASE_FAMILY, "Nimbus Sans") &&
    !(BASE_FAMILY %in% names(grDevices::pdfFonts()))) {
  nimbus_metrics <- grDevices::pdfFonts("NimbusSan")[[1]]
  do.call(grDevices::pdfFonts, setNames(list(nimbus_metrics), BASE_FAMILY))
}

read_source <- function(path) {
  read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    locale = locale(encoding = "UTF-8")
  )
}

raw <- read_source(CALLER_FILE)
block_raw <- read_source(BLOCK_FILE)
accuracy_raw <- read_source(ACCURACY_FILE)

required <- c(
  "Dataset", "Aligner", "Caller", "Depth", "Phased SNVs fraction",
  "Phase blocks", "Block N50 Mb", "Covered variants", "GIAB het SNVs",
  "Blockwise hamming", "Blockwise hamming rate", "Status"
)
missing_columns <- setdiff(required, names(raw))
if (length(missing_columns) > 0L) {
  stop("Missing required caller-comparison columns: ", paste(missing_columns, collapse = ", "))
}
if (nrow(raw) != 24L) stop("Expected exactly 24 caller-comparison rows")
if (sum(raw$Caller == "Clair3") != 18L || sum(raw$Caller == "DeepVariant") != 6L) {
  stop("Expected 18 Clair3 rows and six DeepVariant rows in the source")
}

source_keys <- paste(raw$Dataset, raw$Aligner, raw$Caller, raw$Depth, sep = "|")
if (anyDuplicated(source_keys)) stop("Caller-comparison source keys are not unique")

selected <- raw |>
  filter(Depth == TARGET_DEPTH) |>
  transmute(
    dataset = Dataset,
    platform = sub("_latest$", "", Dataset),
    mapper = Aligner,
    caller = Caller,
    depth = Depth,
    phased_snv_fraction = as.numeric(`Phased SNVs fraction`),
    phased_snv_pct = 100 * as.numeric(`Phased SNVs fraction`),
    phase_blocks = as.numeric(`Phase blocks`),
    source_block_n50_mb = as.numeric(`Block N50 Mb`),
    block_ng50_mb = as.numeric(`Block N50 Mb`),
    covered_variants = as.numeric(`Covered variants`),
    giab_het_snvs = as.numeric(`GIAB het SNVs`),
    blockwise_hamming_errors = as.numeric(`Blockwise hamming`),
    source_hamming_rate = as.numeric(`Blockwise hamming rate`),
    hamming_error_pct = 100 * as.numeric(`Blockwise hamming`) / as.numeric(`Covered variants`),
    status = Status
  ) |>
  mutate(
    platform = factor(platform, levels = EXPECTED_PLATFORMS),
    mapper = factor(mapper, levels = EXPECTED_MAPPERS),
    caller = factor(caller, levels = EXPECTED_CALLERS)
  ) |>
  arrange(platform, mapper, caller)

expected_keys <- expand.grid(
  platform = EXPECTED_PLATFORMS,
  mapper = EXPECTED_MAPPERS,
  caller = EXPECTED_CALLERS,
  stringsAsFactors = FALSE
) |>
  transmute(key = paste(platform, mapper, caller, sep = "|"))
observed_keys <- selected |>
  transmute(key = paste(as.character(platform), as.character(mapper), as.character(caller), sep = "|"))
if (nrow(selected) != 12L || anyDuplicated(observed_keys$key) ||
    !setequal(expected_keys$key, observed_keys$key)) {
  stop("The selected data are not the complete six-workflow x two-caller 30x design")
}

numeric_fields <- c(
  "phased_snv_fraction", "phased_snv_pct", "phase_blocks", "block_ng50_mb",
  "covered_variants", "giab_het_snvs", "blockwise_hamming_errors", "hamming_error_pct"
)
if (any(!is.finite(unlist(selected[numeric_fields], use.names = FALSE)))) {
  stop("All plotted caller-comparison fields must be finite")
}
if (any(selected$phased_snv_fraction < 0 | selected$phased_snv_fraction > 1)) {
  stop("Phased-SNV fractions must lie in [0, 1]")
}
if (any(selected$block_ng50_mb <= 0)) stop("Block NG50 values must be positive")
if (any(selected$covered_variants <= 0)) stop("Covered-variant denominators must be positive")
if (any(selected$blockwise_hamming_errors < 0)) stop("Hamming error counts must be non-negative")
if (any(selected$blockwise_hamming_errors > selected$covered_variants)) {
  stop("Hamming error counts cannot exceed covered variants")
}
if (any(selected$status != "Complete")) stop("All selected caller comparisons must be complete")
if (n_distinct(selected$giab_het_snvs) != 1L) stop("GIAB truth-site scope is inconsistent")

hamming_residual <- selected$hamming_error_pct / 100 - selected$source_hamming_rate
if (max(abs(hamming_residual)) > 6e-5) {
  stop("Recomputed Hamming rates disagree with the rounded source rates")
}

# The legacy caller-table header says N50, but its Clair3 values map to the
# genome-normalized WhatsHap NG50 field used throughout the figure set.
clair3_selected <- selected |>
  filter(caller == "Clair3") |>
  mutate(
    platform_chr = as.character(platform),
    mapper_chr = as.character(mapper)
  )

block_30x <- block_raw |>
  filter(Depth == TARGET_DEPTH) |>
  transmute(
    dataset = Dataset,
    mapper_chr = Mapper,
    reference = Reference,
    dedicated_phased_snv_rate = as.numeric(`Phased SNV rate`),
    dedicated_block_ng50_mb = as.numeric(`WhatsHap block NG50`)
  )

accuracy_30x <- accuracy_raw |>
  filter(Depth == TARGET_DEPTH) |>
  transmute(
    dataset = Dataset,
    mapper_chr = Mapper,
    dedicated_covered_variants = as.numeric(`Covered variants`),
    dedicated_blockwise_hamming = as.numeric(`Blockwise Hamming`),
    dedicated_hamming_rate = as.numeric(`Hamming rate`)
  )

crosscheck <- clair3_selected |>
  inner_join(block_30x, by = c("dataset", "mapper_chr")) |>
  inner_join(accuracy_30x, by = c("dataset", "mapper_chr")) |>
  mutate(
    phased_rate_residual = phased_snv_fraction - dedicated_phased_snv_rate,
    ng50_residual_mb = block_ng50_mb - dedicated_block_ng50_mb,
    hamming_rate_residual = source_hamming_rate - dedicated_hamming_rate,
    covered_variants_match = covered_variants == dedicated_covered_variants,
    hamming_count_match = blockwise_hamming_errors == dedicated_blockwise_hamming
  )

if (nrow(crosscheck) != 6L ||
    max(abs(crosscheck$phased_rate_residual)) > 6e-5 ||
    max(abs(crosscheck$ng50_residual_mb)) > 0.006 ||
    max(abs(crosscheck$hamming_rate_residual)) > 6e-5 ||
    any(!crosscheck$covered_variants_match) ||
    any(!crosscheck$hamming_count_match) ||
    any(crosscheck$reference != "GRCh38")) {
  stop("Clair3 caller-table fields do not map cleanly to the dedicated WhatsHap tables")
}

write_csv(
  crosscheck |>
    transmute(
      platform = platform_chr, mapper = mapper_chr, depth,
      phased_rate_residual,
      ng50_residual_mb,
      hamming_rate_residual,
      covered_variants_match,
      hamming_count_match,
      mapping_note = paste(
        "legacy Block N50 Mb header maps to the dedicated genome-normalized",
        "WhatsHap block NG50 field"
      )
    ),
  file.path(OUTPUT_DIR, "clair3_field_crosscheck.csv"),
  na = ""
)

metric_spec <- data.frame(
  metric_key = c("phased_snv_pct", "block_ng50_mb", "hamming_error_pct"),
  metric_label = c(
    "Phased heterozygous\nSNVs (%)",
    "Phase-block\nNG50 (Mb)",
    "Blockwise Hamming\nerror (%)"
  ),
  display_unit = c("%", "Mb", "%"),
  transformation = c(
    "100 * source Phased SNVs fraction",
    "none; source field is recorded in Mb and maps to genome-normalized NG50",
    "100 * Blockwise hamming / Covered variants"
  ),
  axis_min = c(55, 0, 0),
  axis_max = c(101, 4.4, 22),
  stringsAsFactors = FALSE
)

row_spec <- data.frame(
  platform = rep(EXPECTED_PLATFORMS, each = 2),
  mapper = rep(EXPECTED_MAPPERS, times = 3),
  row_label = c(
    "BGI · minimap2", "BGI · winnowmap",
    "ONT · minimap2", "ONT · winnowmap",
    "HiFi · minimap2", "HiFi · winnowmap"
  ),
  row_y = c(6.6, 6.0, 4.6, 4.0, 2.6, 2.0),
  stringsAsFactors = FALSE
)

long <- selected |>
  pivot_longer(
    cols = all_of(metric_spec$metric_key),
    names_to = "metric_key",
    values_to = "display_value"
  ) |>
  left_join(metric_spec, by = "metric_key") |>
  mutate(
    platform_chr = as.character(platform),
    mapper_chr = as.character(mapper),
    caller_chr = as.character(caller)
  ) |>
  left_join(row_spec, by = c("platform_chr" = "platform", "mapper_chr" = "mapper")) |>
  mutate(
    metric_label = factor(metric_label, levels = metric_spec$metric_label),
    display_y = row_y + if_else(caller_chr == "Clair3", 0.10, -0.10)
  ) |>
  arrange(metric_label, desc(row_y), caller)

if (nrow(long) != 36L || any(!is.finite(long$display_value)) || any(is.na(long$row_y))) {
  stop("Expected 36 finite metric endpoints with valid row positions")
}

paired <- long |>
  select(
    platform_chr, mapper_chr, row_label, row_y, metric_key, metric_label,
    caller_chr, display_value, display_y
  ) |>
  pivot_wider(
    names_from = caller_chr,
    values_from = c(display_value, display_y)
  ) |>
  mutate(caller_delta = display_value_DeepVariant - display_value_Clair3) |>
  arrange(metric_label, desc(row_y))

if (nrow(paired) != 18L || any(!is.finite(paired$caller_delta))) {
  stop("Expected 18 complete paired caller comparisons")
}

write_csv(
  long |>
    transmute(
      platform = platform_chr, mapper = mapper_chr, caller = caller_chr,
      depth, row_label, metric_key, metric = as.character(metric_label),
      display_value, display_unit, display_y,
      source_phased_snv_fraction = phased_snv_fraction,
      source_block_n50_mb,
      numerator_blockwise_hamming_errors = blockwise_hamming_errors,
      denominator_covered_variants = covered_variants,
      source_hamming_rate,
      giab_het_snvs,
      transformation
    ),
  file.path(OUTPUT_DIR, "source_data_plotted.csv"),
  na = ""
)

write_csv(
  paired |>
    transmute(
      platform = platform_chr, mapper = mapper_chr, row_label,
      metric_key, metric = as.character(metric_label),
      clair3_value = display_value_Clair3,
      deepvariant_value = display_value_DeepVariant,
      deepvariant_minus_clair3 = caller_delta,
      connector_definition = "DeepVariant minus Clair3 within the same 30x platform-mapper workflow"
    ),
  file.path(OUTPUT_DIR, "paired_caller_differences.csv"),
  na = ""
)

write_csv(metric_spec, file.path(OUTPUT_DIR, "metric_definitions.csv"), na = "")

audit <- data.frame(
  source_file = basename(CALLER_FILE),
  source_rows = nrow(raw),
  selected_rows = nrow(selected),
  excluded_rows = nrow(raw) - nrow(selected),
  source_clair3_rows = sum(raw$Caller == "Clair3"),
  source_deepvariant_rows = sum(raw$Caller == "DeepVariant"),
  selected_clair3_rows = sum(selected$caller == "Clair3"),
  selected_deepvariant_rows = sum(selected$caller == "DeepVariant"),
  inclusion_rule = "Depth == 30x; all three platforms, both mappers and both callers retained",
  exclusion_reason = "Clair3 10x and 50x rows belong to depth-response panels; DeepVariant is available at 30x only",
  expected_design = "6 platform-mapper workflows x 2 callers x 3 metrics",
  plotted_endpoints = nrow(long),
  paired_connectors = nrow(paired),
  aggregation = "none",
  averaging = "none",
  error_bars = "none; grey connectors are paired caller differences",
  caller_as_replicate = FALSE,
  mapper_as_replicate = FALSE,
  y_offset = "Clair3 +0.10 and DeepVariant -0.10 row units for visibility; x values are unchanged",
  crosscheck = "six Clair3 30x rows matched to dedicated WhatsHap block and accuracy tables",
  stringsAsFactors = FALSE
)
write_csv(audit, file.path(OUTPUT_DIR, "data_filter_audit.csv"), na = "")

axis_anchor_data <- metric_spec |>
  select(metric_label, axis_min, axis_max) |>
  pivot_longer(c(axis_min, axis_max), names_to = "anchor", values_to = "display_value") |>
  mutate(
    metric_label = factor(metric_label, levels = metric_spec$metric_label),
    display_y = 2.0
  )

guide_rows <- data.frame(row_y = row_spec$row_y)

theme_caller_sensitivity <- function() {
  theme_classic(base_size = 6.5, base_family = BASE_FAMILY) +
    theme(
      axis.line = element_line(colour = "#242424", linewidth = 0.34),
      axis.line.y = element_blank(),
      axis.ticks = element_line(colour = "#242424", linewidth = 0.30),
      axis.ticks.y = element_blank(),
      axis.ticks.length = grid::unit(1.4, "pt"),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      axis.text.x = element_text(size = 5.9, colour = "#343434", margin = margin(t = 1.1)),
      axis.text.y = element_text(size = 5.9, colour = "#343434", hjust = 1),
      panel.grid = element_blank(),
      panel.spacing.x = grid::unit(4.2, "mm"),
      strip.background = element_blank(),
      strip.text = element_text(
        size = 6.6, face = "bold", colour = "#252525",
        margin = margin(b = 2.0)
      ),
      plot.title = element_text(
        size = 7.5, face = "bold", colour = "#202124",
        margin = margin(b = 0.5)
      ),
      plot.subtitle = element_text(
        size = 5.9, colour = "#666B70", margin = margin(b = 0.6)
      ),
      plot.tag = element_text(size = 8.0, face = "bold", colour = "#202124"),
      plot.tag.position = c(0.001, 1.0),
      legend.position = "top",
      legend.direction = "horizontal",
      legend.justification = "right",
      legend.box.just = "right",
      legend.margin = margin(t = -2.5, r = 0, b = -1.0, l = 0, unit = "pt"),
      legend.title = element_text(size = 5.9, face = "bold", colour = "#343434"),
      legend.text = element_text(size = 5.7, colour = "#343434"),
      legend.key.width = grid::unit(4.0, "mm"),
      legend.key.height = grid::unit(3.0, "mm"),
      legend.spacing.x = grid::unit(0.8, "mm"),
      plot.margin = margin(t = 2.0, r = 2.3, b = 2.3, l = 2.2, unit = "mm")
    )
}

p <- ggplot(long, aes(x = display_value, y = display_y)) +
  geom_hline(
    data = guide_rows,
    aes(yintercept = row_y),
    inherit.aes = FALSE,
    colour = "#ECEFF1",
    linewidth = 0.34
  ) +
  geom_segment(
    data = paired,
    aes(
      x = display_value_Clair3, xend = display_value_DeepVariant,
      y = display_y_Clair3, yend = display_y_DeepVariant
    ),
    inherit.aes = FALSE,
    colour = "#C4C9CD",
    linewidth = 0.64,
    lineend = "round"
  ) +
  geom_blank(data = axis_anchor_data, aes(x = display_value, y = display_y)) +
  geom_point(
    aes(colour = platform_chr, shape = caller_chr),
    size = 2.45,
    stroke = 0.78,
    fill = "white"
  ) +
  facet_wrap(~metric_label, nrow = 1, scales = "free_x") +
  scale_colour_manual(values = PLATFORM_COLORS, guide = "none") +
  scale_shape_manual(
    name = "SNP caller",
    values = c(Clair3 = 16, DeepVariant = 23),
    breaks = EXPECTED_CALLERS,
    labels = c("Clair3", "DeepVariant")
  ) +
  scale_x_continuous(
    breaks = pretty_breaks(n = 5),
    labels = label_number(accuracy = 0.1, trim = TRUE),
    expand = expansion(mult = c(0.015, 0.015))
  ) +
  scale_y_continuous(
    breaks = row_spec$row_y,
    labels = row_spec$row_label,
    limits = c(1.65, 6.95),
    expand = expansion(mult = c(0, 0))
  ) +
  labs(
    title = "Variant-caller sensitivity of WhatsHap SNP phasing",
    subtitle = "HG002  |  GRCh38  |  matched 30× depth  |  paired platform–mapper workflows",
    tag = "e"
  ) +
  guides(
    shape = guide_legend(
      order = 1,
      override.aes = list(
        colour = "#303236", fill = "white", size = 2.35, stroke = 0.78
      )
    )
  ) +
  theme_caller_sensitivity()

save_one <- function(ext) {
  path <- file.path(OUTPUT_DIR, paste0(FIGURE_STEM, ".", ext))
  width_in <- WIDTH_MM / 25.4
  height_in <- HEIGHT_MM / 25.4

  if (ext == "svg") {
    svglite::svglite(
      path, width = width_in, height = height_in, bg = "white",
      system_fonts = list(sans = BASE_FAMILY)
    )
  } else if (ext == "pdf") {
    grDevices::cairo_pdf(
      path, width = width_in, height = height_in,
      family = BASE_FAMILY, bg = "white", onefile = TRUE
    )
  } else if (ext == "tiff") {
    ragg::agg_tiff(
      path, width = WIDTH_MM, height = HEIGHT_MM, units = "mm",
      res = DPI, background = "white", scaling = 1
    )
  } else if (ext == "png") {
    ragg::agg_png(
      path, width = WIDTH_MM, height = HEIGHT_MM, units = "mm",
      res = DPI, background = "white", scaling = 1
    )
  } else {
    stop("Unsupported extension: ", ext)
  }

  print(p)
  grDevices::dev.off()
  path
}

formats <- c("svg", "pdf", "tiff", "png")
outputs <- vapply(formats, save_one, character(1))
if (!all(file.exists(outputs)) || any(file.info(outputs)$size <= 0)) {
  stop("One or more figure exports are missing or empty")
}

manifest <- data.frame(
  file = basename(outputs),
  format = formats,
  width_mm = WIDTH_MM,
  height_mm = HEIGHT_MM,
  dpi = c(NA, NA, DPI, DPI),
  bytes = unname(file.info(outputs)$size),
  md5 = unname(tools::md5sum(outputs)),
  font_family = BASE_FAMILY,
  editable_text = c(TRUE, TRUE, FALSE, FALSE),
  plotted_endpoints = nrow(long),
  paired_connectors = nrow(paired),
  workflow_pairs = n_distinct(interaction(selected$platform, selected$mapper)),
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
write_csv(manifest, file.path(OUTPUT_DIR, "render_manifest.csv"), na = "")

message("Rendered WhatsHap caller-sensitivity profile to: ", OUTPUT_DIR)
