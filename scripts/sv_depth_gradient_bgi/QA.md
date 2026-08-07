# QA record

- Core claim: increasing BGI depth improves refined SV detection, but the
  marginal F1 gain declines and approaches zero at higher depth.
- Figure archetype: caller-specific quantitative validation with aligned score
  and marginal-gain regions.
- Backend: R only using ggplot2, svglite, Cairo PDF, and ragg.
- Data: 28/28 requested observations are complete, comprising 14 numeric depth
  values (5–70×, every 5×) for each of cuteSV and Sniffles2.
- Scope: sawfish, SVDSS, and every 90× observation are excluded by the
  user-defined reporting scope; the 60-to-28 row change is recorded in the audit
  table.
- Upper region: zero-baseline bars show refine Recall and the diamond line shows
  refine F1; its y-axis is fixed at 0-1 for both callers.
- Lower region: the same diamond-line grammar shows source-provided refine
  delta F1 per 5x. The value is the adjacent-depth F1 change normalized per 5x.
- The 5× delta is undefined and intentionally unplotted. Because 90× is outside
  the reporting scope, 70× is the final displayed and derived depth.
- Caller-specific linear delta ranges are used because the panel's purpose is
  within-caller saturation, not caller ranking; every axis remains explicitly labelled.
- All displayed adjacent depths are separated by their true 5× horizontal distance.
- Both regions show the same depth ticks; the x-axis title appears once at the
  bottom to avoid redundant titles.
- Refine Precision, FP, and FN are retained in source data for traceability but
  are not encoded in the figure.
- Reuse level: style-only inheritance. No external values or statistical
  structure are reused.
- No smoothing, interpolation, aggregation, imputation, uncertainty interval,
  or statistical test is used.
- Final size per plot: 183 x 142 mm. SVG and PDF keep editable text; TIFF is
  exported at 600 dpi; PNG is a 320 dpi preview.
- A second 183 x 82 mm score-only export is produced for each caller. It uses
  the identical upper-region data and styling but contains no delta marks.
- Static preflight: all substantive checks pass. The validator emits its generic
  R syntax warning because it performs only a delimiter check; an actual
  `Rscript parse()` check passes before delivery.
