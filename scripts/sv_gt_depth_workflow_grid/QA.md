# Figure QA contract

- Core claim: platform genotyping performance and depth response are compared
  across matched caller-by-aligner workflows.
- Role: platform-centred depth and workflow interaction evidence.
- Archetype: quantitative 4 x 2 grid; one independent figure per truth set.
- Backend: R only.
- Final size: 183 mm x 165 mm.
- Data: 72 observations per figure and 144 total; no aggregation or sampling.
- Rows: four callers; columns: two aligners; x-axis: three matched depths.
- Platform encoding: established BGI orange, ONT teal, and HiFi purple.
- Metric: original `gt-F1`; refine fields are not used.
- Shared scale: one fixed y-range across all eight panels within a truth set.
- Uncertainty: benchmark tables contain point estimates, so no error bars.
- Caller interpretation: analytical workflow, not a statistical replicate.
- Export: editable SVG/PDF, 320 dpi PNG, LZW-compressed 600 dpi TIFF.
- Reviewer risk: the broad CMRG scale is driven by real SVDSS differences and
  is retained rather than hidden with caller-specific scaling.
