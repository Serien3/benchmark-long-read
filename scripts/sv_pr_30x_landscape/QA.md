# Figure QA contract

- Core conclusion: at matched 30× depth, precision–recall trade-offs depend on
  platform, caller, aligner, and truth context.
- Archetype: two independent quantitative PR landscapes.
- Reuse level: style-only inheritance from the approved PR figures.
- Backend: R only.
- Final dimensions: 74 × 74 mm per figure, matching the approved PR series.
- Expected observations: 24 per truth context and 48 total.
- Data: raw precision, recall, and F1; T2T-Q100 and CMRG only.
- Platform encoding: orange/teal/purple outline colour.
- Caller encoding: circle/triangle/square/diamond shape.
- Aligner encoding: solid minimap2 versus hollow winnowmap interior.
- Depth encoding: none; every point is 30× and uses full opacity.
- Legend: intentionally hidden until manuscript-level assembly.
- Geometry: no jitter, smoothing, aggregation, trajectories, or imputation.
- F1 contours: analytically derived from `F1 = 2PR/(P+R)`.
- Axis geometry: each truth context uses its own symmetric x/y limits and
  fixed 1:1 physical aspect ratio; cross-panel distances are not compared.
- Typography/rendering: Helvetica-compatible type, white background, thin
  grey frame, restrained dashed F1 contours, antialiased R devices.
- Export: editable SVG/PDF, 320 dpi PNG preview, LZW-compressed 600 dpi TIFF.
- Source-data traceability: plotted data, exclusion counts, axis windows, and
  transform flags are exported beside the figure.
- Main reviewer risk: benchmark-specific axis windows improve legibility but
  require explicit attention to tick labels when comparing truth contexts.
