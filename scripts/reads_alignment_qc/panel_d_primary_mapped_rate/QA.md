# Figure QA contract — Panel d

- Core conclusion: primary mapping retention remains distinctly structured by
  platform across all four matched 30× reference–aligner conditions.
- Manuscript role: compact read-level mapping evidence after Panel c reports
  position-level coverage breadth.
- Archetype: 3 × 4 annotated quantitative heatmap.
- Reuse level: build anew, with style-only inheritance from Panel c's fixed
  platform accents, Helvetica-compatible typography, title hierarchy, white
  background and export conventions.
- Backend: R only.
- Final dimensions: 89 × 54 mm, matching a Nature-style single-column slot.
- Data: 12 strict-30× rows selected from the 36-row alignment-QC matrix; 24
  non-30× rows are outside the prespecified panel scope.
- Rows: BGI, ONT and HiFi, each accompanied by its fixed platform-colour dot.
- Columns: GRCh38 minimap2, GRCh38 winnowmap, T2T-CHM13 minimap2 and
  T2T-CHM13 winnowmap.
- Value encoding: one shared sequential blue-grey fill scale from 97.9% to
  100.0%; every cell also reports the exact value to two decimal places.
- Geometry: each platform × reference × aligner observation appears in one and
  only one cell; no connector, aggregation, smoothing, fitted trend, ranking
  badge, uncertainty interval, test or p-value.
- Replicate statement: one HG002 30× technical subset per platform; reference
  and aligner conditions are not biological replicates.
- Typography: Nimbus Sans/Helvetica-compatible sans serif; 5.8 pt minimum text,
  bold reference-group headings and contrast-aware black/white cell labels.
- Export: editable SVG/PDF, 600 dpi LZW TIFF and 320 dpi PNG preview.
- Traceability: plotted values, paired aligner differences, platform/reference
  ranges, condition-level platform order, filtering and checksums are exported.
- Main rendering risk: label contrast at intermediate fills. The label colour
  is derived from the plotted percentage and was checked in the final raster.

## Executed validation

- Data contract: PASS — 12/36 rows selected by the strict `Depth == "30x"`
  rule, 24 non-30× rows excluded, and all 12 reference × aligner × platform
  keys are present exactly once.
- Transformation audit: PASS — every displayed percentage equals
  `100 × Primary mapped rate`; all values are finite and lie within the
  declared 97.9–100.0% fill domain.
- Cell audit: PASS — 12 selected observations produce exactly 12 labelled
  cells; the plotting source does not read or derive coverage breadth.
- Platform structure: PASS — the observed order is HiFi > BGI > ONT in each of
  the four reference–aligner columns. BGI spans 99.02–99.69%, ONT spans
  97.94–98.34% and HiFi spans 99.92–100.00%.
- Aligner response: PASS — six matched reference × platform pairs are present;
  `winnowmap − minimap2` ranges from −0.36 to +0.01 percentage points and the
  maximum absolute difference is 0.36 percentage points.
- R syntax/runtime: PASS — the final script parses and renders successfully
  with R 4.6.1 and emits no runtime warnings.
- Static source preflight: READY — 13 PASS, 1 reviewed WARN and 0 FAIL. The
  warning is the validator's generic request for an R parse check; the separate
  `Rscript parse()` check passed. The 89-mm single-column width and 600 dpi TIFF
  export passed automatically.
- Raster dimensions: PASS — PNG 1121 × 680 px at 320 dpi; TIFF 2102 × 1275 px
  at 600 dpi with LZW compression, matching 89 × 54 mm after integer rounding.
- Vector dimensions: PASS — the one-page PDF is approximately 252 × 153 pt;
  SVG is 252.28 × 153.07 pt, matching 89 × 54 mm.
- Editable text/font: PASS — SVG contains 25 text elements; PDF embeds subsetted
  Nimbus Sans Regular and Bold fonts with Unicode mapping.
- Visual inspection at final size: PASS — all 12 labels are legible, black and
  white labels retain contrast across the fill range, reference headings and
  repeated aligner labels are unclipped, and the colour bar is readable.
- Layout inspection: PASS — the matrix occupies the principal canvas area;
  the previous wide-panel whitespace has been removed while preserving group
  separation between GRCh38 and T2T-CHM13.
- Statistics: descriptive only. `n` is 12 technical conditions from one HG002
  30× subset per platform. Biological replicates, across-sample centre/spread,
  uncertainty intervals, statistical tests, multiple-comparison correction and
  p-value display are not defined.
- Source data: `source_data_plotted.csv`; paired differences, platform ranges,
  reference ranges and condition ordering are supplied in adjacent audit CSVs.
- Image-integrity operations: not applicable — vector quantitative chart with
  no raster source image, cropping or contrast manipulation.

