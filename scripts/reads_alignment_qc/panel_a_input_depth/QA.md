# Figure QA contract — Panel a

- Core conclusion: the nested 10× and 30× inputs are closely matched across
  platforms; BGI and HiFi also reach the nominal 50× target, whereas the ONT
  highest-depth subset contains 47.768× of available sequence yield.
- Manuscript role: experimental-design evidence in the opening main figure;
  this panel establishes input comparability rather than ranking platforms.
- Archetype: compact three-row nested-depth ruler.
- Reuse level: build the statistical geometry anew, with style-only inheritance
  from the established platform palette, Panel c typography, pale guide colour
  and export conventions.
- Backend: R only.
- Final dimensions: 60 × 34 mm, matching the planned approximately 30%-width
  top-row slot within the future 183-mm figure assembly.
- Data: all nine rows of the reads-QC table; no exclusions.
- Rows: BGI, ONT and HiFi occupy fixed, spatially independent positions and use
  the fixed orange, teal and purple platform colours.
- Geometry: each row contains three contiguous segments. Their right boundaries
  are the achieved 10×, 30× and highest-depth subset values; a pale background
  track extends to the nominal 50× target.
- Reference encoding: pale vertical guides identify target depths of 10×, 30×
  and 50×; white internal cuts identify the observed 10× and 30× boundaries.
- Labels: all nine achieved depths are generated from the plotting data and
  printed directly inside the corresponding segments.
- Overlap: none — no points, trajectories or legends are used, and one platform
  can no longer occlude another.
- Replicate statement: 10×, 30× and highest-depth inputs are nested technical
  subsets, not independent replicates; no uncertainty or significance layer is
  defined.
- Typography: Nimbus Sans/Helvetica-compatible sans serif; 5–7 pt final text;
  black labels on orange/teal and white labels on purple.
- Export: editable SVG/PDF, 600 dpi LZW TIFF and 320 dpi PNG preview.
- Traceability: source rows, segment boundaries, increments, target attainment,
  filtering, dimensions and checksums are exported beside the figure.
- Main rendering risk: observed 10× and 30× boundaries lie extremely close to
  their target guides. Direct three-decimal labels preserve those differences
  without visually magnifying them.

## Executed validation

- Data contract: PASS — 9/9 rows plotted, 0 excluded, and all nine platform ×
  target-depth keys are unique.
- Nested-structure audit: PASS — three platform rulers and nine positive,
  strictly ordered segments were recovered; every source observation maps to
  one segment endpoint.
- Numeric guard: PASS — ONT highest depth is asserted as 47.768×. At 10× and
  30×, the maximum absolute target deviation is 0.011×.
- Visibility audit: PASS — BGI, ONT and HiFi occupy separate rows; nine values
  have nine direct labels and there are zero overplotted platform trajectories.
- R syntax/runtime: PASS — the final script parses and renders successfully
  with R 4.6.1 and emits no runtime warnings.
- Static source preflight: READY — 12 PASS, 2 reviewed WARN and 0 FAIL. The
  syntax warning is the validator's generic request for a real R parse check,
  which passed separately. The 60-mm width warning is expected because this is
  an explicitly sized subpanel within a future 183-mm assembly rather than a
  standalone journal column.
- Raster dimensions: PASS — PNG 755 × 428 px at 320 dpi; TIFF 1417 × 803 px at
  600 dpi with LZW compression, matching 60 × 34 mm after integer rounding.
- Vector dimensions: PASS — the one-page PDF is approximately 170 × 96 pt;
  SVG is 170.08 × 96.38 pt, matching 60 × 34 mm.
- Editable text/font: PASS — SVG contains 16 text elements; PDF embeds subsetted
  Nimbus Sans Regular and Bold fonts with Unicode mapping.
- Visual inspection at final size: PASS — all nine values, row labels, target
  headings, pale guides and white internal boundaries are unclipped and legible.
  The grey remainder between ONT 47.768× and the 50× target remains visible.
- Layout inspection: PASS — the three rulers occupy the principal canvas area;
  the former square plotting region and detached legend have been removed.
- Statistics: descriptive only. `n` is nine nested technical conditions from
  one HG002 dataset. Biological replicates, centre/spread, uncertainty
  intervals, tests, multiple-comparison correction and p-values are not defined.
- Source data: `source_data_plotted.csv`; segment geometry and target-attainment
  values are supplied in `nested_depth_ruler_audit.csv`.
- Image-integrity operations: not applicable — vector quantitative diagram with
  no raster source image, cropping or contrast manipulation.

