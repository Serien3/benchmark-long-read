#!/usr/bin/env Rscript

# =============================================================================
# Caller-level SV radar figures
#
# Input is a normalized, auditable table with one untransformed proportion per
# caller / benchmark / platform / aligner / depth. This production driver never
# fabricates, imputes, rescales, smooths, or aggregates experimental values.
# =============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
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
source(file.path(
  ROOT, "scripts", "codex", "sv_genotyping_radar", "radar_core.R"
))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || length(args) > 3L) {
  stop(
    "Usage: Rscript scripts/codex/sv_genotyping_radar/",
    "sv_genotyping_radar.R <normalized_input.csv> [output_dir] [full|adaptive]"
  )
}

input_path <- normalizePath(args[[1]], mustWork = TRUE)
output_dir <- if (length(args) >= 2L) {
  args[[2]]
} else {
  file.path(ROOT, "figures", "codex_sv_genotyping_radar")
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
radial_mode <- if (length(args) == 3L) args[[3]] else "full"
if (!radial_mode %in% c("full", "adaptive")) {
  stop("Radial mode must be either 'full' or 'adaptive'")
}

raw <- read_csv(input_path, show_col_types = FALSE, progress = FALSE)
required <- c("caller", "platform", "aligner", "depth", "value")
missing <- setdiff(required, names(raw))
if (length(missing) > 0L) {
  stop("Input is missing columns: ", paste(missing, collapse = ", "))
}
if (!"benchmark" %in% names(raw)) raw$benchmark <- "benchmark"
if (!"truth_set" %in% names(raw)) raw$truth_set <- raw$benchmark
if (!"reference" %in% names(raw)) raw$reference <- ""
if (!"metric" %in% names(raw)) raw$metric <- "Performance"

data <- raw %>%
  transmute(
    benchmark = as.character(benchmark),
    truth_set = as.character(truth_set),
    reference = as.character(reference),
    metric = as.character(metric),
    caller = as.character(caller),
    platform = as.character(platform),
    aligner = as.character(aligner),
    depth = as.character(depth),
    value = as.numeric(value)
  )

if (anyNA(data$benchmark) || anyNA(data$truth_set) ||
    anyNA(data$metric) || anyNA(data$caller) ||
    any(data$benchmark == "") || any(data$truth_set == "") ||
    any(data$metric == "") || any(data$caller == "")) {
  stop("benchmark, truth_set, metric, and caller identifiers must be non-empty")
}

metadata_conflicts <- data %>%
  distinct(benchmark, caller, truth_set, reference, metric) %>%
  count(benchmark, caller, name = "n") %>%
  filter(n != 1L)
if (nrow(metadata_conflicts) > 0L) {
  stop("Each benchmark/caller panel must have one truth_set/reference/metric definition")
}

panel_keys <- data %>%
  distinct(benchmark, caller, truth_set, reference, metric) %>%
  arrange(benchmark, caller)
manifest <- vector("list", nrow(panel_keys))

safe_name <- function(x) {
  cleaned <- gsub("[^A-Za-z0-9._-]+", "_", x)
  gsub("^_+|_+$", "", cleaned)
}

for (i in seq_len(nrow(panel_keys))) {
  key <- panel_keys[i, , drop = FALSE]
  panel_data <- data %>%
    filter(benchmark == key$benchmark, caller == key$caller) %>%
    select(depth, platform, aligner, value)

  # The core validator enforces the complete symmetric 3 x 2 x 6 design.
  checked <- validate_radar_data(panel_data)
  scale_spec <- if (radial_mode == "adaptive") {
    adaptive_radar_scale(checked$value)
  } else {
    list(limits = c(0, 1), breaks = seq(0, 1, by = 0.2), step = 0.2)
  }
  range_label <- if (radial_mode == "adaptive") {
    sprintf(
      "range %.0f\u2013%.0f%%",
      100 * scale_spec$limits[1], 100 * scale_spec$limits[2]
    )
  } else {
    NULL
  }
  subtitle_parts <- c(key$metric, key$truth_set, key$reference, range_label)
  subtitle_parts <- subtitle_parts[nzchar(subtitle_parts)]
  plot <- make_sv_radar(
    checked,
    title = key$caller,
    subtitle = paste(subtitle_parts, collapse = " \u00b7 "),
    radial_limits = scale_spec$limits,
    radial_breaks = scale_spec$breaks,
    line_halo = radial_mode == "adaptive"
  )
  stem <- file.path(
    output_dir,
    paste0("sv_radar_", safe_name(key$caller), "_", safe_name(key$benchmark))
  )
  save_sv_radar(plot, stem)

  manifest[[i]] <- data.frame(
    benchmark = key$benchmark,
    truth_set = key$truth_set,
    reference = key$reference,
    metric = key$metric,
    caller = key$caller,
    plotted_rows = nrow(checked),
    profiles = n_distinct(checked$series),
    axes = length(RADAR_AXIS_ORDER),
    minimum = min(checked$value),
    maximum = max(checked$value),
    error_bars = FALSE,
    radial_mode = radial_mode,
    radial_min = scale_spec$limits[1],
    radial_max = scale_spec$limits[2],
    radial_step = scale_spec$step,
    output_stem = basename(stem)
  )
}

write_csv(data, file.path(output_dir, "source_data_plotted.csv"))
write_csv(bind_rows(manifest), file.path(output_dir, "render_manifest.csv"))
message("Created ", nrow(panel_keys), " caller-level radar figure(s) in: ", output_dir)
