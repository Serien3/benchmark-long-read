# QA record

- Core claim: SV detection differences among the three sequencing platforms
  vary with depth and the caller-aligner workflow.
- Plot type: one stand-alone quantitative trajectory chart per truth set.
- Backend: R only (`ggplot2`, `svglite`, `ragg`, Cairo PDF).
- Metric: original SV detection `F1`; `gt-F1` and all refine fields are excluded.
- Data: 72/72 required observations per truth set, comprising 24 depth
  trajectories and 48 explicitly constructed line segments.
- GIAB v5.0q filtering: 72 GRCh38 rows are plotted; 48 rows outside the shared
  symmetric design are excluded and recorded in `data_filter_audit.csv`.
- CMRG filtering: all 72 rows are plotted.
- No aggregation, statistical repeat model, uncertainty interval, random
  jitter, smoothing, or imputation is used.
- The x offsets are deterministic display positions: every caller contains
  three equally spaced columns ordered as 10x, 30x, 50x. BGI, ONT, and HiFi
  observations at the same depth share exactly the same x coordinate. The
  exported source-data table retains the exact F1 values.
- One exact tie occurs in CMRG for winnowmap, Sniffles2, and 30x: BGI and ONT
  both have F1 = 0.855. Their coloured trajectories converge at the shared
  point; no jitter or artificial offset is applied. Exact coincidence counts
  are recorded per benchmark in `render_manifest.csv`.
- Depth opacity is retained as a redundant cue at 0.30, 0.60, and 1.00. The
  non-linear visual ramp increases separation among depths while keeping the
  10x points visible on a white background at final size.
- The minimap2 and winnowmap divider is placed at the true midpoint between
  the two caller blocks.
- Y-axis display ranges are data-aware and recorded in `render_manifest.csv`.
  Their lower boundaries sit slightly below the first labelled tick, matching
  the inset-axis treatment used by the PR figures.
- Final size: 183 × 105 mm. SVG and PDF keep editable text; TIFF is exported at
  600 dpi; PNG is a 320 dpi preview.
- Static preflight: 13 PASS, 1 informational R-syntax warning, 0 FAIL. The R
  parser and full render both completed successfully.
- Visual inspection: no clipping or label overlap; the two aligner blocks and
  all platform/depth encodings remain distinguishable at final size.
- The top solid panel border is intentionally omitted. The highest dashed
  reference guide and its tick label are both retained.
