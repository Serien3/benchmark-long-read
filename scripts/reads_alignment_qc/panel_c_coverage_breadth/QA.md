# Figure QA contract — Panel c

- Core conclusion: reference-base coverage breadth rises mainly before 30×,
  is closely grouped among platforms on GRCh38, remains more
  platform-separated on T2T-CHM13, and is broadly similar between minimap2 and
  winnowmap within matched conditions.
- Manuscript role: hero evidence in the opening reads/alignment QC figure.
- Archetype: one-row, four-panel depth-response small multiple.
- Reuse level: structural adaptation of the author-supplied cuteHap example,
  retaining its four independent plotting regions, bold titles, category-
  boundary guides, repeated x-axis titles and circular line marks while
  omitting unsupported inset boxes.
- Backend: R only.
- Final dimensions: 183 × 59.5 mm, matching the intended full-width hero slot.
- Data: all 36 alignment-QC rows; no exclusions or aggregation.
- Matrix: 3 platforms × 3 nominal depths × 2 references × 2 aligners.
- Platform encoding: BGI `#FFB000`, ONT `#13A4A6`, HiFi `#9400D3`.
- Aligner encoding: separate spatial panels with the aligner stated in each
  bold panel title; no redundant line-type or point-shape channel.
- Depth geometry: 10×, 30× and 50× occupy category centres 1, 2 and 3;
  vertical guides occupy boundaries 0.5, 1.5, 2.5 and 3.5. Observations are
  therefore centred between guides exactly as in the supplied example.
- Geometry: exact observations connected only within a fixed
  platform–aligner–reference series; no jitter, smoothing, interpolation or
  fitted trend.
- Replicate statement: 10×, 30× and 50× are nested technical subsets of one
  HG002 dataset per platform, not biological replicates.
- Axes: x positions are nominal 10×, 30× and 50×. GRCh38 uses 92.0–94.5%
  and T2T-CHM13 uses 97.5–100.0%; the identical 2.5-percentage-point span
  preserves visual comparability of slopes and gaps. Panel a separately
  records the ONT 50× subset's approximate input depth of 47.768×.
- Axis interpretation: every small multiple displays its own explicit percent
  ticks; the shifted windows reveal the observed trajectories without changing
  the scale of a percentage-point difference.
- Typography: Helvetica-compatible sans serif; white background; no internal
  subpanel tags, bold centred titles, one x-axis title per plot and pale
  boundary guides.
- Legend strategy: no legend inside this row, matching the supplied example;
  platform colours follow the project-wide contract and are identified once
  in the assembled main figure.
- Export: editable SVG/PDF, 600 dpi LZW TIFF and 320 dpi PNG preview.
- Traceability: plotted values, all paired aligner differences, depth gains,
  derived summaries, row counts, dimensions and checksums are exported.
- Main reviewer risk: the two reference groups use shifted y windows. The
  identical 2.5-point spans and explicit per-panel percentage labels retain
  quantitative comparability, while exact values remain in Source Data.

## Executed validation

- Data contract: PASS — 36/36 source rows plotted, 0 excluded, with 36 unique
  reference × aligner × platform × depth keys and no missing matrix cell.
- Transformation audit: PASS — every plotted percentage equals
  `100 × Coverage rate`; all values are finite and lie inside the declared
  reference-specific window (GRCh38 92.0–94.5%; T2T-CHM13 97.5–100.0%).
- Narrative-value guards: PASS — at 30×, GRCh38 spans 92.94–93.33% and
  T2T-CHM13 spans 98.31–99.43%. The corresponding six-condition ranges are
  0.39 and 1.12 percentage points.
- Matched-aligner audit: PASS — 18 paired comparisons; median signed
  `winnowmap − minimap2` difference is −0.025 percentage points, median
  absolute difference is 0.050 and maximum absolute difference is 0.210.
- Depth-response audit: PASS — across 12 platform–aligner–reference series,
  the median gain is 0.650 percentage points from 10× to 30× and 0.185 from
  30× to 50×.
- R syntax/runtime: PASS — the final script parses and renders successfully
  with R 4.6.1 and emits no runtime warnings.
- Coordinate-grammar audit: PASS — all 36 rows map 10×, 30× and 50× to
  centres 1, 2 and 3; all four vertical guides are fixed at boundaries 0.5,
  1.5, 2.5 and 3.5, so no guide intersects an observation centre.
- Static source preflight: READY — 13 PASS, 1 reviewed WARN and 0 FAIL. The
  sole warning is the validator's generic request for an R parse check, which
  was run separately. The 183-mm width passed the double-column check.
- Raster dimensions: PASS — PNG 2305 × 749 px at 320 dpi; TIFF
  4322 × 1405 px at 600 dpi with LZW compression, matching 183 × 59.5 mm after
  integer pixel rounding.
- Vector dimensions: PASS — the one-page PDF is approximately 518 × 168 pt;
  SVG is 518.74 × 168.66 pt, both matching 183 × 59.5 mm.
- Editable text/font: PASS — SVG contains 36 text elements; PDF embeds
  subsetted Nimbus Sans Regular and Bold fonts with Unicode mapping.
- Visual inspection at final size: PASS — all four centred titles, four
  repeated x-axis titles, three centred depth ticks per plot,
  reference-specific percent axes, four pale boundary guides per plot and
  filled-circle trajectories are unclipped and legible. No panel-local legend,
  inset, callout box or local magnification is present.
- Overlap inspection: PASS — exact coordinates are not jittered. ONT and HiFi
  coincide at 92.50% for GRCh38–minimap2 at 10×, so their point centres
  necessarily overlap; the two coloured incoming trajectories and Source Data
  retain both observations without introducing a false positional difference.
- Statistics: descriptive only. `n` is 36 technical conditions from one HG002
  dataset per platform; the three depths are nested subsets, not independent
  replicates. Biological replicates, across-sample centre/spread, uncertainty
  intervals, statistical tests, multiple-comparison correction and p-value
  display are not defined.
- Source data: `source_data_plotted.csv`; paired-difference and depth-change
  derivations are supplied in the adjacent audit CSV files.
- Image-integrity operations: not applicable — vector quantitative chart with
  no raster source image, cropping or contrast manipulation.
