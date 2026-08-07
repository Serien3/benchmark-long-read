# QA record

- Source rows: 6; retained rows: 6; exclusions: none.
- Complete design: 3 platforms × 2 aligners at 30× with Sniffles2 mosaic mode.
- `Total calls = DEL + INS + DUP + INV + BND` for every workflow.
- `Total calls = VAF 5–10% + VAF 10–20%` for every workflow.
- Radar values are within-workflow SV-type proportions; each polygon sums to 100%.
- Both radar figures use the same canonical spoke order and the same 0–60% radial
  domain. A single `sqrt(proportion / 0.60)` radial transform is applied to every
  spoke, while grid labels show the true proportions. No per-spoke normalization
  or area-based total-count encoding is used.
- Radar rings, spokes, and outlines are calculated directly in Cartesian
  coordinates, so the platform profiles use true straight polygon edges rather
  than curved edges introduced by a polar-coordinate transform.
- Exact total candidate counts are encoded directly by the absolute heights of
  the VAF stacked bars and printed above them.
- No uncertainty intervals or inferential statistics are shown because the six
  workflows are not replicates and the source contains no uncertainty estimates.
- Interpretation is restricted to candidate burden, VAF-bin composition, and
  platform/aligner-dependent candidate profiles. No truth-based accuracy or
  verified biological mosaic burden is claimed.
- Styling uses the existing platform color mapping and the established muted
  grey-blue/brown count-composition palette.
- Radar style adaptation is visual only: light polygonal grids, round vertex
  markers, and unfilled coloured profiles are inherited while the common
  square-root scale and true tick labels are retained.
- VAF stacked-bar segment outlines match the MEI composition figure exactly
  (`#777D84`, 0.16 mm) for downstream-panel consistency.
- Statistical annotation: n is one 30× HG002 workflow per platform-aligner
  combination; no biological or technical replicates, center/spread estimate,
  hypothesis test, multiple-testing correction, or p-value is applicable.
- Export check: editable SVG/PDF plus 320-dpi PNG and 600-dpi LZW TIFF were
  generated; the radar canvases are 89 × 93 mm and the VAF canvas is 105 × 75 mm.
