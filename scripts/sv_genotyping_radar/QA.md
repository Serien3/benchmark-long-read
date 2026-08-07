# Figure QA contract

- Core purpose: compare three sequencing platforms across matched depth,
  aligner, and caller conditions in downstream SV analysis.
- Figure role: caller-level comparative summary.
- Archetype: independent quantitative radar chart.
- Backend: R only.
- Final size: 89 mm x 93 mm per independent caller panel.
- Data integrity: no aggregation, rescaling, smoothing, imputation, or sampling.
- Expected design: 18 values per caller/benchmark, three platform profiles and
  six depth-by-aligner axes.
- Radial scale: fixed 0 to 1 in every output so caller figures remain comparable.
- Radial grid: 20-percentage-point intervals; no caller-specific zooming.
- Platform encoding: established orange, teal, and purple palette.
- Aligner encoding: explicit axis labels; vertices have no marker glyphs.
- Uncertainty: no error bars because the current benchmark tables contain point
  estimates rather than replicates or confidence intervals.
- Typography: Arial/Helvetica-compatible family and the same size hierarchy as
  the SV precision-recall figures.
- Export: editable SVG/PDF, 320 dpi PNG preview, LZW-compressed 600 dpi TIFF.
- Traceability: exact plotted input and a per-panel render manifest are exported.
- Formal metric mapping: radial value is the original `gt-F1`; refine fields are
  not used. The preparation script records this in `data_filter_audit.csv`.
- Main reviewer risk: radar polygon area is not interpreted or reported; claims
  must be based on labelled radial values and matched profile comparisons.
- Adaptive trial: caller-specific truncated axes are labelled in every subtitle
  and manifest. Polygon area comparisons across panels are prohibited.
