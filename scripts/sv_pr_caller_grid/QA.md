# Figure QA contract

- Core claim: platform PR differences are assessed for robustness across four
  caller workflows under matched depth and aligner conditions.
- Role: platform-centred workflow-sensitivity comparison.
- Archetype: quantitative 2 x 2 grid; one figure per truth set.
- Backend: R only.
- Final size: 183 mm x 174 mm, standard double-column width.
- Data: 72 observations per figure; 144 total; no aggregation or sampling.
- Panels: four callers in a fixed order with shared axes within each truth set.
- Axes: precision and recall have identical limits, ticks, and 1:1 scaling.
- Platform encoding: established orange, teal, and purple palette.
- Aligner encoding: circle versus diamond.
- Depth encoding: alpha only; point size remains 2.15 mm.
- F1 contours: analytic `F1 = 2PR/(P+R)` curves.
- Statistics: none; callers are analytical workflows, not replicates.
- Uncertainty: none available, therefore no error bars are drawn.
- Metric source: original precision/recall fields; refine fields are unused.
- Export: editable SVG/PDF, 320 dpi PNG, 600 dpi LZW TIFF.
- Reviewer risk: CMRG contains true low-performing SVDSS observations, so its
  shared range is broad. This is retained rather than hiding caller dependence
  through panel-specific zooming.
