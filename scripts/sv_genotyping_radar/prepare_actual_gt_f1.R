#!/usr/bin/env Rscript

# Normalize the two official SV benchmark tables for the caller-level
# genotyping radar figures. The selected metric is the original gt-F1 column;
# refine columns are intentionally not read into the plotted data.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
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
OUTPUT_DIR <- file.path(ROOT, "figures", "codex_sv_genotyping_radar")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

CALLERS <- c("cuteSV", "Sniffles2", "sawfish", "SVDSS")
PLATFORMS <- c("BGI", "ONT", "HiFi")
ALIGNERS <- c("minimap2", "winnowmap")
DEPTHS <- c("10x", "30x", "50x")

BENCHMARKS <- list(
  GIAB5 = list(file = "sv_benchmark_GIAB5.0q.csv", truth_set = "GIAB v5.0q"),
  CMRG = list(file = "sv_benchmark_CMRG.csv", truth_set = "GIAB CMRG")
)

normalize_benchmark <- function(benchmark, spec) {
  path <- file.path(ROOT, "data", spec$file)
  raw <- read_csv(path, show_col_types = FALSE, progress = FALSE)
  if (ncol(raw) < 13L || !"gt-F1" %in% names(raw)) {
    stop(spec$file, " does not contain the required gt-F1 field")
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
      benchmark = benchmark,
      truth_set = spec$truth_set,
      reference = reference,
      metric = "Genotype F1",
      caller = caller,
      platform = platform,
      depth = depth,
      aligner = aligner,
      value = as.numeric(`gt-F1`)
    ) %>%
    arrange(caller, platform, depth, aligner)

  expected <- expand_grid(
    caller = CALLERS,
    platform = PLATFORMS,
    depth = DEPTHS,
    aligner = ALIGNERS
  )
  missing_keys <- expected %>%
    anti_join(
      selected %>% select(caller, platform, depth, aligner),
      by = c("caller", "platform", "depth", "aligner")
    )
  duplicates <- selected %>%
    count(caller, platform, depth, aligner, name = "n") %>%
    filter(n != 1L)

  if (nrow(selected) != 72L || nrow(missing_keys) > 0L || nrow(duplicates) > 0L) {
    stop(benchmark, " does not contain the complete symmetric 4 x 3 x 3 x 2 design")
  }
  if (any(!is.finite(selected$value)) || any(selected$value < 0 | selected$value > 1)) {
    stop(benchmark, " contains invalid gt-F1 values")
  }

  attr(selected, "audit") <- data.frame(
    benchmark = benchmark,
    source_file = spec$file,
    source_rows = nrow(raw),
    plotted_rows = nrow(selected),
    metric_source_column = "gt-F1",
    refine_used = FALSE,
    reference = "GRCh38"
  )
  selected
}

normalized <- list()
audit <- list()
for (benchmark in names(BENCHMARKS)) {
  normalized[[benchmark]] <- normalize_benchmark(benchmark, BENCHMARKS[[benchmark]])
  audit[[benchmark]] <- attr(normalized[[benchmark]], "audit")
}

normalized <- bind_rows(normalized)
if (nrow(normalized) != 144L) stop("Expected 144 total radar values")

write_csv(normalized, file.path(OUTPUT_DIR, "normalized_gt_f1.csv"))
write_csv(bind_rows(audit), file.path(OUTPUT_DIR, "data_filter_audit.csv"))
message("Prepared 144 official gt-F1 values in: ", OUTPUT_DIR)
