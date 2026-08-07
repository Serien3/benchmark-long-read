# Figure QA contract — Panel b

- Core conclusion: under the matched 30× input condition, BGI, ONT and HiFi
  show distinct but multidimensional read profiles in length, reported read Q
  and the composition of reads whose mean Q exceeds 20.
- Manuscript role: direct read-level evidence following the input-depth panel;
  it supports comparison without declaring an overall platform winner.
- Archetype: aligned faceted dot matrix with one shared platform axis.
- Reuse level: build anew, with style-only inheritance from the project-wide
  platform palette, Helvetica-compatible typography and export conventions.
- Backend: R only.
- Final dimensions: 120 × 52 mm, matching the intended wide top-row slot.
- Data: three strict-30× rows selected from nine reads-QC observations; the six
  10×/50× rows are excluded by the prespecified panel scope.
- Marks: 21 observed or explicitly derived marks — nine length summaries, six
  reported-Q summaries and six mean-Q>20 composition values.
- Platform encoding: BGI `#FFB000`, ONT `#13A4A6`, HiFi `#9400D3`; platform
  names are also encoded by fixed rows, so no redundant colour legend is used.
- Statistic encoding: filled circle = mean, filled triangle = median, filled
  diamond = N50, open circle = Q20 read fraction and open square = Q20-read
  base share.
- Pair connection: a thin neutral segment joins only the two composition values
  belonging to the same mean-Q>20 read subset and platform.
- Geometry: exact x positions and shared row positions; no jitter, dodge,
  smoothing, aggregation or fitted trend.
- Replicate statement: one HG002 30× technical subset per platform; no
  biological replicates and no inferential uncertainty layer.
- Axes: independent 0–32 kb, 0–35 reported-Q and 0–100% metric domains,
  communicated by facet headings rather than repeated axis titles.
- Typography: Helvetica-compatible sans serif; black labels; frameless legend;
  white background and only subtle horizontal row guides.
- Export: editable SVG/PDF, 600 dpi LZW TIFF and 320 dpi PNG preview.
- Traceability: both selected wide data and 21 plotted marks are exported,
  including the formula and source field for every transformation.
- Main reviewer risk: nearby mean/median values and the HiFi composition pair
  partially overlap at the exact measured positions. They remain undisplaced;
  shape differences and Source Data preserve identity and precision.

## Executed validation

- Data contract: PASS — 3/9 rows selected by the strict `Depth == "30x"`
  rule, 6 non-30× rows excluded, and BGI/ONT/HiFi occur exactly once.
- Mark audit: PASS — 21/21 expected marks exported with 21 unique
  platform × facet × statistic keys: 9 length, 6 reported-Q and 6 composition
  values.
- Independent formula audit: PASS — exported Q20-read base shares equal
  `100 × Q20-read yield / total yield` within the four-decimal export
  tolerance: 40.3358% BGI, 83.0019% ONT and 91.7124% HiFi.
- R syntax/runtime: PASS — the final script parses and renders successfully
  with R 4.6.1.
- Static source preflight: READY — 12 PASS, 2 reviewed WARN and 0 FAIL. The
  syntax warning is the validator's generic request for an R parse check,
  which was run separately. The 120-mm-width warning is expected because this
  is the planned wide slot beside Panel a in a future 183-mm main figure, not a
  standalone journal-column figure.
- Raster dimensions: PASS — PNG 1511 × 655 px at 320 dpi; TIFF
  2834 × 1228 px at 600 dpi with LZW compression, matching 120 × 52 mm after
  integer pixel rounding.
- Vector dimensions: PASS — the one-page PDF is approximately 340 × 147 pt;
  SVG is 340.16 × 147.40 pt, both matching 120 × 52 mm.
- Editable text/font: PASS — SVG contains 24 text elements; PDF embeds
  subsetted Nimbus Sans Regular and Bold with Unicode mapping.
- Visual inspection at final size: PASS — facet headings, platform rows, axis
  values and the five-entry statistic legend are unclipped and legible. Nearby
  mean/median or composition points remain visible through distinct shapes
  without altering their coordinates.
- Grayscale/redundancy: PASS — platform identity remains explicit in row
  labels, while statistic identity remains explicit through shape.
- Statistics: descriptive only. `n` is one HG002 30× technical subset per
  platform; biological replicates, across-sample center/spread, statistical
  test, multiple-comparison correction and p-value display are not defined.
  NanoPlot mean/median/N50 values are reported as observed summaries.
- Source data: `source_data_input_30x.csv` and `source_data_plotted.csv`.
- Image-integrity operations: not applicable — vector quantitative chart with
  no raster source image, cropping or contrast manipulation.
