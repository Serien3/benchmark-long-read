# Figure QA contract — Panel e

- Core conclusion: under the current unified workflow, BAM output footprint at
  30× differs substantially by platform and more modestly by aligner.
- Manuscript role: operational evidence; default Extended Data panel and
  retained main-figure replacement option.
- Archetype: two-facet matched-condition dot plot.
- Reuse level: structural adaptation of Panel d's confirmed geometry, with a
  new metric-specific data contract and zero-based axis.
- Backend: R only.
- Final dimensions: 183 × 38 mm, matching Panel d's compact full-width slot.
- Data: 12 strict-30× rows selected from the 36-row alignment-QC matrix; 24
  non-30× rows are excluded by the prespecified panel scope.
- Platform encoding: fixed rows plus BGI `#FFB000`, ONT `#13A4A6` and HiFi
  `#9400D3`; no redundant platform legend.
- Aligner encoding: minimap2 = filled circle; winnowmap = open diamond.
- Pair connection: one thin neutral segment joins the matched aligner values
  within each platform and reference.
- Geometry: exact x positions and shared row positions; no jitter, dodge,
  smoothing, aggregation or fitted trend.
- Replicate statement: one HG002 30× technical subset per platform; aligner and
  reference conditions are not biological replicates.
- Axis: both reference facets share a zero-based 0–115 GiB x domain, supporting
  direct absolute-size comparison without a truncated bar-like baseline.
- Scope: BAM size describes output storage under the current workflow and does
  not establish runtime, peak-memory, energy or cost differences.
- Typography: Helvetica-compatible sans serif; black row labels; frameless
  legend; white background and sparse pale vertical reading guides.
- Export: editable SVG/PDF, 600 dpi LZW TIFF and 320 dpi PNG preview.
- Traceability: all plotted values, matched differences, platform ranges,
  matched HiFi ratios, row counts, dimensions and checksums are exported.
- Main reviewer risk: BAM size is pipeline- and format-dependent. The figure
  reports the prespecified workflow output directly and avoids broader
  operational claims.

## Executed validation

- Data contract: PASS — 12/36 rows selected by the strict `Depth == "30x"`
  rule, 24 non-30× rows excluded, and all 12 reference × aligner × platform
  keys are present exactly once.
- Numeric guard: PASS — all BAM sizes are finite, non-negative and lie within
  the declared 0–115 GiB axis; no unit conversion is applied.
- Platform-range audit: PASS — BGI spans 90.51–109.30 GiB, ONT spans
  81.35–102.88 GiB and HiFi spans 34.45–41.01 GiB across the four displayed
  reference–aligner conditions.
- Matched-aligner audit: PASS — six reference × platform pairs were recovered.
  Winnowmap BAMs are 6.639–11.480% smaller than their matched minimap2 BAMs
  under the recorded workflow.
- Matched-platform audit: PASS — the eight matched BGI/ONT-to-HiFi footprint
  ratios range from 2.361× to 2.719×.
- R syntax/runtime: PASS — the final script parses and renders successfully
  with R 4.6.1 and emits no runtime warnings.
- Static source preflight: READY — 13 PASS, 1 reviewed WARN and 0 FAIL. The
  sole warning is the validator's generic request for an R parse check, which
  was run separately. The 183-mm width passed the double-column check.
- Raster dimensions: PASS — PNG 2305 × 478 px at 320 dpi; TIFF
  4322 × 897 px at 600 dpi with LZW compression, matching 183 × 38 mm after
  integer pixel rounding.
- Vector dimensions: PASS — the one-page PDF is approximately 518 × 107 pt;
  SVG is 518.74 × 107.72 pt, both matching 183 × 38 mm.
- Editable text/font: PASS — SVG contains 21 text elements; PDF embeds
  subsetted Nimbus Sans Regular and Bold fonts with Unicode mapping.
- Visual inspection at final size: PASS — facets, platform rows, 20-GiB ticks,
  pair segments and aligner legend are unclipped and legible. The zero origin,
  common facet scale and restrained geometry support direct absolute-size
  comparison.
- Consistency inspection: PASS — dimensions, typography, platform colours,
  marker semantics, connectors, facet order and spacing match Panel d.
- Statistics: descriptive only. `n` is 12 technical conditions from one HG002
  30× subset per platform. Biological replicates, across-sample centre/spread,
  uncertainty intervals, statistical tests, multiple-comparison correction and
  p-value display are not defined.
- Source data: `source_data_plotted.csv`; matched aligner differences, platform
  ranges and matched HiFi ratios are supplied in adjacent audit CSV files.
- Image-integrity operations: not applicable — vector quantitative chart with
  no raster source image, cropping or contrast manipulation.
