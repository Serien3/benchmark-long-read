#!/usr/bin/env Rscript

# =============================================================================
# CMRG 30x SV precision-recall landscape with a focus-and-context inset
#
# Scientific contract
#   Claim      : the full panel preserves all precision-recall trade-offs,
#                while the inset resolves the 15 observations inside the
#                compact high-performance PR region.
#   Evidence   : all 24 unaggregated CMRG observations at GRCh38 / 30x.
#   Archetype  : one quantitative PR landscape with an embedded detail view.
#   Encoding   : colour = platform; shape = caller; solid/hollow = aligner.
#   Integrity  : the inset redraws exact raw coordinates inside a declared
#                rectangular ROI; no jitter, smoothing, aggregation, or
#                selective method removal is used.
#   Reuse      : data guards, palette, typography, F1 contours, and export
#                devices are inherited from the approved landscape script.
# =============================================================================

# Reuse the approved implementation without executing its export driver. This
# keeps the original script and all original outputs byte-for-byte untouched.
find_this_root <- function() {
  arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(arg) == 1L) {
    script_path <- normalizePath(sub("^--file=", "", arg))
    return(dirname(dirname(dirname(script_path))))
  }
  normalizePath(getwd())
}

TASK_ROOT <- find_this_root()
BASE_SCRIPT <- file.path(
  TASK_ROOT,
  "scripts",
  "sv_pr_30x_landscape",
  "sv_pr_30x_landscape.R"
)

if (!file.exists(BASE_SCRIPT)) {
  stop("Approved base script not found: ", BASE_SCRIPT)
}

base_lines <- readLines(BASE_SCRIPT, warn = FALSE, encoding = "UTF-8")
driver_line <- grep("^# ---- Driver", base_lines)
if (length(driver_line) != 1L || driver_line <= 1L) {
  stop("Could not isolate the reusable section of the approved base script")
}
eval(parse(text = base_lines[seq_len(driver_line - 1L)]), envir = .GlobalEnv)

# Make the inherited font/export contract explicit in this derivative script so
# it remains independently auditable. BASE_FAMILY is resolved by the approved
# script from Arial, Helvetica, Nimbus Sans, Liberation Sans, or sans.
PUBLICATION_FONT_FAMILIES <- c(
  "Arial",
  "Helvetica",
  "Nimbus Sans",
  "Liberation Sans",
  "sans"
)
if (!(BASE_FAMILY %in% PUBLICATION_FONT_FAMILIES)) {
  stop("Resolved font is outside the publication-safe sans-serif contract")
}

# ---- Inset contract --------------------------------------------------------

# The tighter ROI is defined only by PR coordinates. Relative to the previous
# high-precision inset, it excludes two low-recall HiFi/cuteSV observations,
# two lower-recall ONT/cuteSV observations, and one low-precision HiFi/SVDSS
# observation while retaining every point inside this declared rectangle.
ROI_X <- c(0.70, 0.86)
ROI_Y <- c(0.905, 1.010)

# Inset viewport in the main panel data coordinates. This lower-left region
# contains no observations, so the overlay cannot conceal a plotted result.
INSET_BOX <- c(
  xmin = 0.270,
  xmax = 0.720,
  ymin = 0.310,
  ymax = 0.650
)

# Approximate upper corners of the actual inset coordinate panel after space
# for tick labels is reserved. Connectors terminate at the panel border rather
# than at an additional outer decoration frame.
INSET_PANEL_TOP <- c(
  left = 0.345,
  right = 0.700,
  y = 0.631
)

ROI_COLOUR <- "#858585"
CONNECTOR_COLOUR <- "#A0A0A0"
MAIN_PANEL_BORDER_COLOUR <- "#696969"
MAIN_PANEL_BORDER_WIDTH <- 0.32

in_roi <- function(d) {
  d %>%
    filter(
      recall >= ROI_X[1],
      recall <= ROI_X[2],
      precision >= ROI_Y[1],
      precision <= ROI_Y[2]
    )
}

make_inset_plot <- function(d) {
  ggplot(d, aes(x = recall, y = precision)) +
    geom_point(
      aes(
        colour = platform,
        fill = platform_aligner,
        shape = caller
      ),
      size = 1.55,
      stroke = 0.48,
      alpha = 1,
      show.legend = FALSE
    ) +
    shared_scales() +
    scale_x_continuous(
      breaks = c(0.72, 0.78, 0.84),
      labels = label_number(accuracy = 0.01),
      expand = expansion(mult = 0)
    ) +
    scale_y_continuous(
      breaks = c(0.92, 0.96, 1.00),
      labels = label_number(accuracy = 0.01),
      expand = expansion(mult = 0)
    ) +
    coord_cartesian(
      xlim = ROI_X,
      ylim = ROI_Y,
      expand = FALSE,
      clip = "on"
    ) +
    labs(x = NULL, y = NULL) +
    theme_reference_pr() +
    theme(
      plot.title = element_blank(),
      plot.subtitle = element_blank(),
      axis.title = element_blank(),
      axis.text = element_text(size = 5.00, colour = "#565656"),
      axis.ticks = element_line(colour = "#777777", linewidth = 0.20),
      axis.ticks.length = unit(1.0, "pt"),
      panel.border = element_rect(
        colour = "#696969",
        fill = NA,
        linewidth = 0.30
      ),
      plot.background = element_rect(
        fill = "white",
        colour = NA
      ),
      panel.background = element_rect(fill = "white", colour = NA),
      plot.margin = margin(t = 1.3, r = 1.5, b = 1.1, l = 1.2, unit = "mm")
    )
}

save_inset_figure <- function(
  plot,
  stem,
  width_mm = 74,
  height_mm = 74,
  preview_res = 320,
  print_res = 600
) {
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
  print(plot)
  dev.off()

  svglite::svglite(
    paste0(stem, ".svg"),
    width = width_in,
    height = height_in,
    bg = "white",
    system_fonts = list(sans = BASE_FAMILY)
  )
  print(plot)
  dev.off()

  grDevices::cairo_pdf(
    paste0(stem, ".pdf"),
    width = width_in,
    height = height_in,
    family = BASE_FAMILY,
    bg = "white"
  )
  print(plot)
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
  print(plot)
  dev.off()
}

make_cmrg_inset_figure <- function(d) {
  zoom_data <- in_roi(d)
  previous_zoom_data <- d %>%
    filter(
      recall >= 0.57,
      recall <= 0.86,
      precision >= 0.885,
      precision <= 1.010
    )
  row_key <- function(x) {
    paste(
      as.character(x$caller),
      as.character(x$platform),
      as.character(x$aligner),
      sep = "|"
    )
  }
  excluded_from_previous <- setdiff(
    row_key(previous_zoom_data),
    row_key(zoom_data)
  )
  expected_focus_exclusions <- c(
    "cuteSV|HiFi|minimap2",
    "cuteSV|HiFi|winnowmap",
    "cuteSV|ONT|minimap2",
    "cuteSV|ONT|winnowmap",
    "SVDSS|HiFi|winnowmap"
  )

  if (nrow(d) != 24L) {
    stop("CMRG main panel must contain exactly 24 observations")
  }
  if (nrow(zoom_data) != 15L) {
    stop(
      "Declared inset ROI must contain exactly 15 observations; observed ",
      nrow(zoom_data)
    )
  }
  if (!setequal(excluded_from_previous, expected_focus_exclusions)) {
    stop(
      "Tighter coordinate ROI no longer excludes exactly the five ",
      "declared focus-boundary observations"
    )
  }

  inset_grob <- ggplotGrob(make_inset_plot(d))
  main <- make_pr_plot(d) +
    theme(
      panel.border = element_rect(
        colour = MAIN_PANEL_BORDER_COLOUR,
        fill = NA,
        linewidth = MAIN_PANEL_BORDER_WIDTH
      )
    )

  # Rectangle and connectors use the main PR coordinate system. The inset is
  # drawn last with an opaque white background so connector endpoints terminate
  # cleanly at its upper border.
  main +
    annotate(
      "rect",
      xmin = ROI_X[1],
      xmax = ROI_X[2],
      ymin = ROI_Y[1],
      ymax = ROI_Y[2],
      fill = NA,
      colour = ROI_COLOUR,
      linewidth = 0.25,
      linetype = "33"
    ) +
    annotation_custom(
      grob = inset_grob,
      xmin = INSET_BOX[["xmin"]],
      xmax = INSET_BOX[["xmax"]],
      ymin = INSET_BOX[["ymin"]],
      ymax = INSET_BOX[["ymax"]]
    ) +
    annotate(
      "segment",
      x = ROI_X[1],
      y = ROI_Y[1],
      xend = INSET_PANEL_TOP[["left"]],
      yend = INSET_PANEL_TOP[["y"]],
      colour = CONNECTOR_COLOUR,
      linewidth = 0.18,
      linetype = "33",
      lineend = "butt"
    ) +
    annotate(
      "segment",
      x = ROI_X[2],
      y = ROI_Y[1],
      xend = INSET_PANEL_TOP[["right"]],
      yend = INSET_PANEL_TOP[["y"]],
      colour = CONNECTOR_COLOUR,
      linewidth = 0.18,
      linetype = "33",
      lineend = "butt"
    )
}

# ---- Driver ---------------------------------------------------------------

spec <- BENCHMARKS[["CMRG"]]
message("[CMRG inset] reading ", spec$file)
d <- read_benchmark(spec, "CMRG")
audit <- attr(d, "audit")
zoom_data <- in_roi(d)
p <- make_cmrg_inset_figure(d)

stem <- file.path(OUTPUT_DIR, "sv_pr_30x_CMRG_inset")
save_inset_figure(p, stem)

source_data <- d %>%
  mutate(
    across(c(caller, platform, aligner, platform_aligner), as.character),
    shown_in_inset = (recall >= ROI_X[1] &
      recall <= ROI_X[2] &
      precision >= ROI_Y[1] &
      precision <= ROI_Y[2])
  )

write_csv(
  source_data,
  file.path(OUTPUT_DIR, "source_data_plotted_CMRG_inset.csv")
)
write_csv(
  audit,
  file.path(OUTPUT_DIR, "data_filter_audit_CMRG_inset.csv")
)
write_csv(
  data.frame(
    benchmark = "CMRG",
    truth_set = unique(d$truth_set),
    depth = TARGET_DEPTH,
    plotted_points_main = nrow(d),
    plotted_points_inset = nrow(zoom_data),
    excluded_from_previous_inset = 5L,
    inset_selection_rule = paste0(
      "rectangular coordinate crop: ",
      "0.70<=recall<=0.86; 0.905<=precision<=1.010"
    ),
    inset_x_min = ROI_X[1],
    inset_x_max = ROI_X[2],
    inset_y_min = ROI_Y[1],
    inset_y_max = ROI_Y[2],
    inset_viewport_xmin = INSET_BOX[["xmin"]],
    inset_viewport_xmax = INSET_BOX[["xmax"]],
    inset_viewport_ymin = INSET_BOX[["ymin"]],
    inset_viewport_ymax = INSET_BOX[["ymax"]],
    inset_panel_connector_left = INSET_PANEL_TOP[["left"]],
    inset_panel_connector_right = INSET_PANEL_TOP[["right"]],
    inset_panel_connector_y = INSET_PANEL_TOP[["y"]],
    inset_outer_frame = FALSE,
    inset_coordinate_panel_border = TRUE,
    main_panel_border_colour = MAIN_PANEL_BORDER_COLOUR,
    main_panel_border_width = MAIN_PANEL_BORDER_WIDTH,
    jitter_used = FALSE,
    aggregation_used = FALSE,
    point_coordinates_changed = FALSE,
    output_stem = basename(stem)
  ),
  file.path(OUTPUT_DIR, "render_manifest_CMRG_inset.csv")
)

message(
  "Created CMRG focus-and-context PR figure with ",
  nrow(d),
  " main-panel points and ",
  nrow(zoom_data),
  " inset points: ",
  stem
)
