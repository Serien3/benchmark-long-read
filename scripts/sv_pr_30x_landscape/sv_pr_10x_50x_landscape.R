#!/usr/bin/env Rscript

# =============================================================================
# SV precision-recall landscapes at 10x and 50x
#
# Scientific contract
#   Claim      : platform performance and caller/aligner trade-offs remain
#                benchmark- and depth-dependent outside the matched 30x view.
#   Evidence   : 24 unaggregated observations per truth set and depth.
#   Archetype  : four independent quantitative PR landscapes.
#   Encoding   : colour = platform; shape = caller; solid/hollow = aligner.
#   Integrity  : raw precision and recall only; no jitter, smoothing,
#                aggregation, uncertainty model, depth opacity, or inset.
#   Style      : the approved 30x PR visual language with the darker frame.
# =============================================================================

# Load the approved plotting definitions without executing its 30x driver.
script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
TASK_ROOT <- if (length(script_arg) == 1L) {
  dirname(dirname(dirname(normalizePath(sub("^--file=", "", script_arg)))))
} else {
  normalizePath(getwd())
}
BASE_SCRIPT <- file.path(
  TASK_ROOT, "scripts", "sv_pr_30x_landscape", "sv_pr_30x_landscape.R"
)
base_lines <- readLines(BASE_SCRIPT, warn = FALSE, encoding = "UTF-8")
driver_line <- grep("^# ---- Driver", base_lines)
if (length(driver_line) != 1L) {
  stop("Could not identify the driver boundary in the approved 30x script")
}
eval(parse(text = base_lines[seq_len(driver_line - 1L)]), envir = .GlobalEnv)

OUTPUT_DIR <- file.path(ROOT, "figures", "sv_pr_30x_landscape")
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
TARGET_DEPTHS <- c("10x", "50x")
PUBLICATION_FONT_FAMILIES <- c(
  "Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "sans"
)
if (!(BASE_FAMILY %in% PUBLICATION_FONT_FAMILIES)) {
  stop("The selected font is outside the publication font contract")
}

read_benchmark_at_depth <- function(spec, benchmark_key, target_depth) {
  path <- file.path(DATA_DIR, spec$file)
  raw <- readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    locale = readr::locale(encoding = "UTF-8")
  )

  if (ncol(raw) < 9L) {
    stop("Expected at least nine columns in ", spec$file)
  }
  names(raw)[1:6] <- c(
    "aligner", "reference", "eval_mode", "caller", "platform", "depth"
  )

  n_source <- nrow(raw)
  grch38 <- raw %>% dplyr::filter(reference == "GRCh38")
  core_all_depths <- grch38 %>%
    dplyr::filter(
      caller %in% CALLERS,
      platform %in% PLATFORMS,
      aligner %in% ALIGNERS,
      depth %in% c("10x", "30x", "50x")
    )

  plotted <- core_all_depths %>%
    dplyr::filter(depth == target_depth) %>%
    dplyr::transmute(
      benchmark = benchmark_key,
      truth_set = spec$label,
      reference = reference,
      eval_mode = eval_mode,
      caller = factor(caller, levels = CALLERS),
      platform = factor(platform, levels = PLATFORMS),
      aligner = factor(aligner, levels = ALIGNERS),
      depth = depth,
      precision = as.numeric(precision),
      recall = as.numeric(recall),
      F1 = as.numeric(F1),
      platform_aligner = factor(
        paste(as.character(platform), as.character(aligner), sep = "__"),
        levels = PLATFORM_ALIGNER_LEVELS
      )
    ) %>%
    dplyr::arrange(aligner, caller, platform)

  if (any(!is.finite(plotted$precision)) ||
      any(!is.finite(plotted$recall)) ||
      any(!is.finite(plotted$F1))) {
    stop(benchmark_key, " ", target_depth, " contains non-finite values")
  }
  if (any(plotted$precision < 0 | plotted$precision > 1) ||
      any(plotted$recall < 0 | plotted$recall > 1) ||
      any(plotted$F1 < 0 | plotted$F1 > 1)) {
    stop(benchmark_key, " ", target_depth, " contains values outside [0, 1]")
  }

  duplicate_keys <- plotted %>%
    dplyr::count(caller, platform, aligner, depth, name = "n") %>%
    dplyr::filter(n != 1L)
  if (nrow(duplicate_keys) > 0L) {
    stop(benchmark_key, " ", target_depth, " has duplicated design keys")
  }

  expected <- tidyr::expand_grid(
    caller = factor(CALLERS, levels = CALLERS),
    platform = factor(PLATFORMS, levels = PLATFORMS),
    aligner = factor(ALIGNERS, levels = ALIGNERS)
  )
  missing_keys <- expected %>%
    dplyr::anti_join(
      plotted %>% dplyr::select(caller, platform, aligner),
      by = c("caller", "platform", "aligner")
    )
  if (nrow(missing_keys) > 0L || nrow(plotted) != 24L) {
    stop(
      benchmark_key, " ", target_depth,
      " is incomplete for the symmetric 4 x 3 x 2 design"
    )
  }

  attr(plotted, "audit") <- data.frame(
    benchmark = benchmark_key,
    truth_set = spec$label,
    depth = target_depth,
    source_file = spec$file,
    source_rows = n_source,
    grch38_rows = nrow(grch38),
    core_rows_all_depths = nrow(core_all_depths),
    plotted_rows = nrow(plotted),
    excluded_non_grch38 = n_source - nrow(grch38),
    excluded_noncore_rows = nrow(grch38) - nrow(core_all_depths),
    excluded_other_depths = nrow(core_all_depths) - nrow(plotted),
    filter_rule = paste0(
      "reference=GRCh38; callers=cuteSV|Sniffles2|sawfish|SVDSS; ",
      "platforms=BGI|ONT|HiFi; aligners=minimap2|winnowmap; depth=",
      target_depth, "; metrics=raw precision|recall|F1"
    )
  )

  plotted
}

make_pr_plot_at_depth <- function(d, target_depth) {
  base_plot <- make_pr_plot(d)
  lim <- attr(base_plot, "window")
  f1_levels <- attr(base_plot, "f1_levels")
  depth_label <- sub("x$", "×", target_depth)

  p <- base_plot +
    labs(subtitle = paste0("GRCh38 · ", depth_label)) +
    theme(
      panel.border = element_rect(
        colour = "#696969", fill = NA, linewidth = 0.32
      ),
      plot.title = element_text(size = 8.6),
      plot.subtitle = element_text(size = 6.8),
      axis.title = element_text(size = 7.4),
      axis.text = element_text(size = 6.2)
    )

  attr(p, "window") <- lim
  attr(p, "f1_levels") <- f1_levels
  p
}

save_depth_figure <- function(plot, stem, width_mm = 74, height_mm = 74,
                              preview_res = 320, print_res = 600) {
  width_in <- width_mm / 25.4
  height_in <- height_mm / 25.4

  ragg::agg_png(
    paste0(stem, ".png"), width = width_mm, height = height_mm,
    units = "mm", res = preview_res, background = "white", scaling = 1
  )
  print(plot)
  grDevices::dev.off()

  svglite::svglite(
    paste0(stem, ".svg"), width = width_in, height = height_in,
    bg = "white", system_fonts = list(sans = BASE_FAMILY)
  )
  print(plot)
  grDevices::dev.off()

  grDevices::cairo_pdf(
    paste0(stem, ".pdf"), width = width_in, height = height_in,
    family = BASE_FAMILY, bg = "white"
  )
  print(plot)
  grDevices::dev.off()

  ragg::agg_tiff(
    paste0(stem, ".tiff"), width = width_mm, height = height_mm,
    units = "mm", res = print_res, background = "white",
    compression = "lzw", scaling = 1
  )
  print(plot)
  grDevices::dev.off()
}

all_data <- list()
audits <- list()
render_rows <- list()

for (target_depth in TARGET_DEPTHS) {
  for (benchmark_key in names(BENCHMARKS)) {
    spec <- BENCHMARKS[[benchmark_key]]
    result_key <- paste(target_depth, benchmark_key, sep = "__")
    message("[", benchmark_key, " · ", target_depth, "] reading ", spec$file)
    d <- read_benchmark_at_depth(spec, benchmark_key, target_depth)
    all_data[[result_key]] <- d
    audits[[result_key]] <- attr(d, "audit")

    p <- make_pr_plot_at_depth(d, target_depth)
    lim <- attr(p, "window")
    f1_levels <- attr(p, "f1_levels")
    stem <- file.path(
      OUTPUT_DIR,
      paste0("sv_pr_", target_depth, "_", benchmark_key)
    )
    save_depth_figure(p, stem)

    render_rows[[result_key]] <- data.frame(
      benchmark = benchmark_key,
      truth_set = unique(d$truth_set),
      depth = target_depth,
      plotted_points = nrow(d),
      x_metric = "recall",
      y_metric = "precision",
      x_min = lim$x[1],
      x_max = lim$x[2],
      y_min = lim$y[1],
      y_max = lim$y[2],
      symmetric_within_panel = isTRUE(all.equal(lim$x, lim$y)),
      f1_contours = paste(fmt_f1(f1_levels), collapse = ";"),
      depth_alpha_used = FALSE,
      jitter_used = FALSE,
      aggregation_used = FALSE,
      inset_used = FALSE,
      legend_shown = FALSE,
      output_stem = basename(stem)
    )
  }
}

source_data <- dplyr::bind_rows(all_data) %>%
  dplyr::mutate(
    dplyr::across(
      c(caller, platform, aligner, platform_aligner), as.character
    )
  )

readr::write_csv(
  source_data,
  file.path(OUTPUT_DIR, "source_data_plotted_10x_50x.csv")
)
readr::write_csv(
  dplyr::bind_rows(audits),
  file.path(OUTPUT_DIR, "data_filter_audit_10x_50x.csv")
)
readr::write_csv(
  dplyr::bind_rows(render_rows),
  file.path(OUTPUT_DIR, "render_manifest_10x_50x.csv")
)

message("Created 10x and 50x SV PR landscapes in: ", OUTPUT_DIR)
