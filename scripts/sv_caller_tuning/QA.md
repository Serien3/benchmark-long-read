# QA record

- Backend: R/ggplot2 only for all visual outputs and previews.
- Authoritative source: `最新数据评测.xlsx`.
- Extraction: dependency-free workbook XML parser; exact expected row counts are
  enforced before CSVs are written.
- Metric integrity: precision/recall/F1 triplets are recomputed to the workbook's
  displayed precision where all three values are available.
- Design integrity: cuteSV round 1 is verified as a unique `2 × 3^4` design;
  Sniffles2 50x is verified as a unique `3 × 3` design; cross-depth data are
  verified as six unique depth-MAPQ keys.
- Transformations: none. No smoothing, interpolation, statistical testing,
  aggregation, ranking, or missing-value imputation.
- Final widths: 89 mm, 120 mm, or 183 mm according to information density.
- Exports: editable SVG/PDF, 600 dpi TIFF, 300 dpi PNG.
- Font: first available of Arial, Helvetica, Nimbus Sans, Liberation Sans, sans.
- Palette: uniform dark blue/teal/muted rust and a non-rainbow sequential heat
  map. The cuteSV HiFi PR panel intentionally inherits the manuscript PR-panel
  encoding: orange circles = previous parameters, purple diamonds = HiFi-specific
  parameters, and increasing opacity = 10x/30x/50x.
- PR template reuse: structural adaptation. Precision, recall, F1 contours,
  square coordinate system, depth-opacity progression, theme, and 74 mm export
  size match the established SV PR figure family. Recall and precision use one
  identical data-driven joint range and a 1:1 coordinate ratio; F1 contours are
  recalculated around the observed F1 range (0.76/0.80/0.84). No source
  observation or metric was changed.
- Known provenance issue: the `cuteSV-HiFi` worksheet calls the whole-genome
  benchmark “GIAB v5.0q”. The plot describes this explicitly as the workbook label;
  the biological provenance should be confirmed before manuscript citation.
- Known missingness: HiFi-specific refined F1 at 50x is absent and is not imputed
  or plotted. The available incomplete source table is preserved.
