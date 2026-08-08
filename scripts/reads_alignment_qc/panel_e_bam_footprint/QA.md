# Figure QA contract — Panel e

- Core conclusion: at matched nominal 30× input, BAM output footprint shows a
  stable platform hierarchy across all four reference × aligner conditions,
  with directly readable aligner- and reference-associated changes.
- Manuscript role: operational complement to Panel d; default Extended Data
  panel with a reserved 89-mm main-figure slot.
- Archetype: 3 × 4 in-cell horizontal-bar matrix.
- Backend: R only.
- Final dimensions: 89 × 54 mm, identical to Panel d.
- Data: 12 strict-30× rows from the 36-row alignment-QC matrix; all platform ×
  reference × aligner keys occur once.
- Row encoding: BGI, ONT and HiFi in fixed order; bar fills use the established
  platform colours `#FFB000`, `#13A4A6` and `#9400D3`.
- Column encoding: GRCh38/minimap2, GRCh38/winnowmap,
  T2T-CHM13/minimap2 and T2T-CHM13/winnowmap.
- Quantitative encoding: every cell has the same zero-based 0–115 GiB track;
  coloured bar length and an exact two-decimal label both encode BAM size.
- Geometry: 12 tracks and 12 bars; zero points, zero pair connectors, no
  aggregation, jitter, smoothing, fit or ranking mark.
- Typography: Helvetica-compatible Nimbus Sans; 6–7 pt hierarchy, bold
  reference headers and row labels, black quantitative labels.
- Style alignment: white background, Panel c platform palette, Panel d matrix
  order and header rules, and the same single-column export slot.
- Export: editable SVG/PDF, 600 dpi LZW TIFF and 320 dpi PNG preview.
- Traceability: source values, bar geometry, platform ordering, matched aligner
  changes, matched reference changes, platform ranges, dimensions and file
  checksums are exported beside the figure.

## Executed validation

- Data contract: PASS — 12/36 rows selected by `Depth == "30x"`; the 24 other
  depth rows are outside this panel, and the complete 3 × 2 × 2 key matrix is
  present exactly once.
- Numeric and geometry guards: PASS — all values are finite and within
  0–115 GiB; all bar endpoints lie within their tracks; eight long-bar labels
  are inside and four HiFi short-bar labels are outside.
- Platform-order audit: PASS — all four reference × aligner columns read
  BGI > ONT > HiFi. BGI spans 90.51–109.30 GiB, ONT 81.35–102.88 GiB and
  HiFi 34.45–41.01 GiB.
- Matched-aligner audit: PASS — all six winnowmap BAMs are smaller than their
  minimap2 counterparts by 6.639–11.480%.
- Matched-reference audit: PASS — all six T2T-CHM13 BAMs are smaller than the
  matched GRCh38 BAMs by 2.97–14.70 GiB (7.017–15.305%).
- Matched-platform audit: PASS — the eight BGI/ONT-to-HiFi ratios are
  2.361×–2.719×.
- R syntax/runtime: PASS — the final source parses and renders all four formats
  without runtime warnings.
- Static source preflight: READY FOR VISUAL QA — 13 PASS, one reviewed R parse
  reminder and zero FAIL; the independent R parse check passed.
- Raster dimensions: PASS — PNG is 1121 × 680 px at 320 dpi; TIFF is
  2102 × 1275 px at 600 dpi with LZW compression, matching 89 × 54 mm after
  integer-pixel rounding.
- Vector dimensions: PASS — PDF is 252 × 153 pt and SVG is
  252.28 × 153.07 pt, both matching 89 × 54 mm.
- Editable text/font: PASS — SVG contains 25 text elements; PDF embeds subsetted
  Nimbus Sans Regular and Bold fonts with Unicode mapping.
- Visual inspection at final size: PASS — all 12 bars and values are legible;
  long-bar labels remain inside their fills, short-bar labels remain on the
  pale track, and no header, row label, aligner label or scale label is clipped.
- Cross-panel consistency inspection: PASS — reference headings, header rules,
  platform/column order, font hierarchy, margins and final dimensions align
  with Panel d; platform colours align with Panel c.
- Statistics: descriptive only. `n = 12` technical mapping conditions derived
  from one HG002 30× subset per platform. No centre/spread estimate,
  uncertainty interval, hypothesis test, correction or p value is defined.
- Source data: `source_data_plotted.csv`; all derived comparisons and plotting
  coordinates are in the adjacent audit CSV files.
- Image-integrity operations: not applicable — this is a vector quantitative
  chart with no raster source image or image adjustment.
