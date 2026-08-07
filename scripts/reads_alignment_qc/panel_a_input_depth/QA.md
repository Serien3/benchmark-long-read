# Figure QA contract — Panel a

- Core conclusion: 10× and 30× inputs are closely depth matched across all
  three platforms; BGI and HiFi also reach 50×, while the ONT nominal-50×
  subset contains 47.768× of available sequence yield.
- Manuscript role: experimental-design evidence in the opening main figure;
  this panel does not rank platform performance.
- Archetype: compact identity-reference line plot.
- Reuse level: build anew, with style-only inheritance from the project-wide
  platform palette, Helvetica-compatible typography and export conventions.
- Backend: R only.
- Final dimensions: 60 × 52 mm, matching the intended compact top-row slot.
- Data: all nine rows of the reads-QC table; no exclusions.
- Platform encoding: BGI `#FFB000`, ONT `#13A4A6`, HiFi `#9400D3`.
- Reference encoding: thin grey dashed `y=x` line denotes exact target matching.
- Annotation: only the observed ONT nominal-50× value, 47.77×.
- Geometry: exact numeric positions; no jitter, dodge, smoothing, aggregation
  or fitted trend.
- Replicate statement: 10×, 30× and 50× are nested technical subsets, not
  independent replicates; no uncertainty or significance layer is defined.
- Axes: common 0–52× limits with a fixed 1:1 physical aspect ratio.
- Typography: Helvetica-compatible sans serif; black labels; frameless legend;
  white background; no decorative grid.
- Export: editable SVG/PDF, 600 dpi LZW TIFF and 320 dpi PNG preview.
- Traceability: plotted rows, transformation fields, filter counts, file sizes
  and checksums are exported beside the figure.
- Main reviewer risk: near-identical 10×/30× observations visually overlap.
  This is the measured result and is retained without artificial displacement;
  the exact nine values remain available in Source Data.

## Executed validation

- Data contract: PASS — 9/9 rows plotted, 0 excluded, and all nine
  platform × target-depth keys are unique.
- Numeric guard: PASS — the ONT nominal-50× value is asserted as 47.768×.
- R syntax/runtime: PASS — the final script parses and renders successfully
  with R 4.6.1.
- Static source preflight: READY — 12 PASS, 2 reviewed WARN and 0 FAIL.
  The syntax warning is the validator's generic request for an R parse check,
  which was run separately. The 60-mm-width warning is expected because this
  is an intentionally compact panel slot within a future 183-mm figure, not a
  standalone journal-column figure.
- Raster dimensions: PASS — PNG 755 × 655 px at 320 dpi; TIFF 1417 × 1228 px
  at 600 dpi, matching 60 × 52 mm after integer pixel rounding.
- Vector dimensions: PASS — one-page PDF is approximately 170 × 147 pt,
  matching 60 × 52 mm; SVG uses the same physical dimensions.
- Editable text/font: PASS — SVG contains text elements; PDF embeds a subset
  of Nimbus Sans, a Helvetica-compatible sans-serif family.
- Visual inspection at final size: PASS — axes, legend, identity reference,
  platform trajectories and the 47.77× value label are unclipped and legible.
  The platform overlap at 10×/30× and for BGI/HiFi at 50× is preserved as
  evidence of depth matching rather than separated with artificial jitter.
- Statistics: not applicable — one HG002 observation per technical condition,
  no center/spread estimate, test, correction or p-value.
- Image-integrity operations: not applicable — vector quantitative chart with
  no raster source image, cropping or contrast manipulation.
