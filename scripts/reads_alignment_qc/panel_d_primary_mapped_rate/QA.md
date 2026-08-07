# Figure QA contract — Panel d

- Core conclusion: primary mapping retention remains separated among platforms
  at the matched 30× condition and therefore adds a read-level dimension not
  represented by reference-base coverage breadth alone.
- Manuscript role: primary supporting evidence below the Panel c hero plot.
- Archetype: two-facet matched-condition dot plot.
- Reuse level: build anew, with style-only inheritance from the established
  platform palette, alignment-marker vocabulary, Helvetica-compatible
  typography and export conventions.
- Backend: R only.
- Final dimensions: 183 × 38 mm, matching the intended compact full-width slot.
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
- Axis: both reference facets share the explicit 97.5–100.05% x domain. A dot
  plot rather than a bar chart makes the non-zero lower bound unambiguous.
- Typography: Helvetica-compatible sans serif; black row labels; frameless
  legend; white background and sparse pale vertical reading guides.
- Export: editable SVG/PDF, 600 dpi LZW TIFF and 320 dpi PNG preview.
- Traceability: all plotted values, matched differences, platform ranges,
  before/after row counts, dimensions and checksums are exported.
- Main reviewer risk: identical or nearly identical aligner values can overlap.
  Filled circles and open diamonds are layered at the exact coordinates so both
  identities remain visible without artificial offsets.

## Executed validation

- Data contract: PASS — 12/36 rows selected by the strict `Depth == "30x"`
  rule, 24 non-30× rows excluded, and all 12 reference × aligner × platform
  keys are present exactly once.
- Transformation audit: PASS — every plotted percentage equals
  `100 × Primary mapped rate`; all values are finite and lie within the
  declared 97.5–100.05% axis.
- Matched-pair audit: PASS — six reference × platform pairs were recovered.
  Their `winnowmap − minimap2` differences range from −0.36 to +0.01
  percentage points; the maximum absolute difference is 0.36.
- Platform-range guards: PASS — BGI spans 99.02–99.69%, ONT spans
  97.94–98.34% and HiFi spans 99.92–100.00% across the four displayed
  reference–aligner conditions.
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
- Visual inspection at final size: PASS — facet headings, platform rows,
  0.5-percentage-point ticks, connector segments and the aligner legend are
  unclipped and legible. Panel d remains visually subordinate to the larger
  coverage-breadth hero panel.
- Overlap inspection: PASS — the identical GRCh38 HiFi pair and near-identical
  pairs remain at their exact coordinates; the filled-circle/open-diamond
  combination makes coincidence visible without jitter.
- Statistics: descriptive only. `n` is 12 technical conditions from one HG002
  30× subset per platform. Biological replicates, across-sample centre/spread,
  uncertainty intervals, statistical tests, multiple-comparison correction and
  p-value display are not defined.
- Source data: `source_data_plotted.csv`; matched differences and platform
  ranges are supplied in the adjacent audit CSV files.
- Image-integrity operations: not applicable — vector quantitative chart with
  no raster source image, cropping or contrast manipulation.
