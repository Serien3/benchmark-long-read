# Figure QA contract — apparent alignment-error spectrum pilot

- Core conclusion: within the matched 30× GRCh38/GIAB-masked pilot regions,
  total apparent alignment-error burden follows BGI > ONT > HiFi under both
  aligners, with deletion bases dominating the BGI and ONT spectra.
- Manuscript role: Extended Data evidence adjoining the reads/alignment QC
  section; method-level baseline for later donor-specific error analysis.
- Archetype: 3 × 2 stacked horizontal-bar matrix.
- Backend: R only.
- Final dimensions: 89 × 54 mm.
- Data: all six source rows; one row per platform × aligner condition.
- Denominator: aligned Q20 bases after the recorded primary/MAPQ/BQ filters.
- Stack: mismatch, insertion and deletion bases per 1,000 aligned Q20 bases;
  the three components exactly recover the total.
- Platform encoding: fixed row order plus BGI `#FFB000`, ONT `#13A4A6` and
  HiFi `#9400D3` row markers.
- Component encoding: mismatch `#425A65`, insertion `#7FA8B7`, deletion
  `#D7B26D`.
- Geometry: six common 0–18 tracks, eighteen component segments and six exact
  total labels; no data points, pair connectors, aggregation or inference.
- Export: editable SVG/PDF, 600 dpi LZW TIFF and 320 dpi PNG preview.
- Traceability: raw counts, recomputed rates, stack coordinates, deletion
  shares, aligner deltas, row counts, dimensions and checksums are exported.

## Executed validation

- Data contract: PASS — 6/6 rows retained, zero exclusions, and all six
  platform × aligner keys occur exactly once. Every row is GRCh38/30× with
  2,981,290 region bases and 6,488 masked truth sites.
- Numeric reconstruction: PASS — each row satisfies
  `total = mismatch + insertion + deletion` in raw bases; rates recomputed from
  aligned Q20 bases reproduce all rounded source-rate columns.
- Platform-order audit: PASS — minimap2 and winnowmap both read
  BGI > ONT > HiFi. Recomputed ranges are BGI 17.239–17.552, ONT
  6.351–6.436 and HiFi 1.101–1.117 per 1,000 aligned Q20 bases.
- Composition audit: PASS — deletion bases account for 85.396–85.659% of BGI,
  84.527–84.628% of ONT and 57.337–58.650% of HiFi totals.
- Matched-aligner audit: PASS — winnowmap changes the total by −1.779% for BGI,
  −1.318% for ONT and +1.474% for HiFi, without changing platform order.
- Geometry audit: PASS — six common-scale tracks contain exactly eighteen
  component segments; stacked endpoints recover every total to numerical
  precision. Only the two BGI labels are placed inside long bars.
- R syntax/runtime: PASS — the final source parses and renders all four formats
  without warnings under R 4.6.1.
- Static source preflight: READY FOR VISUAL QA — 13 PASS, one reviewed R parse
  reminder and zero FAIL; the independent R parse check passed.
- Raster export: PASS — PNG is 1121 × 680 px at 320 dpi; TIFF is
  2102 × 1275 px at 600 dpi with LZW compression, matching 89 × 54 mm after
  integer-pixel rounding.
- Vector export: PASS — PDF is 252 × 153 pt and SVG is
  252.28 × 153.07 pt, both matching 89 × 54 mm.
- Editable text/font: PASS — SVG contains 24 text elements; PDF embeds subsetted
  Nimbus Sans Regular and Bold fonts with Unicode mapping.
- Visual inspection at final size: PASS — all six totals, both aligner labels,
  four ticks per column and the three-component legend are unclipped; the thin
  mismatch segments remain visible and the pale tracks preserve the common
  0–18 comparison domain without empty-looking cells.
- Cross-panel consistency: PASS — header weight, row order, platform markers,
  grey tracks, value-label hierarchy, margins and 89 × 54 mm slot align with
  Panels d/e.
- Statistics: descriptive only. `n = 6` technical mapping conditions from one
  HG002 30× subset per platform; no biological replicate, centre/spread
  estimate, uncertainty interval, hypothesis test, multiple-comparison
  correction or p value is defined.
- Source data: `source_data_plotted.csv`; recomputed components, geometry,
  deletion shares and matched aligner changes are in adjacent audit CSV files.
- Image-integrity operations: not applicable — vector quantitative chart with
  no raster source image or image adjustment.
