# Figure QA contract

- Core conclusion: within each caller and truth set, six platform-by-aligner
  trajectories show how precision and recall change with matched depth.
- Archetype: independent quantitative comparison panels.
- Backend: R only.
- Final dimensions: 74 mm x 74 mm per panel.
- Data integrity: no aggregation, smoothing, imputation, or downsampling.
- Expected observations: 18 per panel and 144 across all eight panels.
- Platform encoding: color.
- Platform palette: orange, teal, and purple sampled from the supplied PR
  reference; aligner shape remains a redundant non-color cue.
- Aligner encoding: circle versus diamond.
- Depth encoding: opacity only; point size is constant at 2.15 mm.
- Depth contrast: point alpha is 0.18/0.58/1.00 for 10x/30x/50x; line segments
  inherit the destination-depth alpha, giving medium 10x->30x and strong
  30x->50x segments.
- Axis geometry: precision and recall use identical limits and ticks with a
  fixed 1:1 physical aspect ratio.
- Axis window: caller-specific lower bound calculated from the joint
  precision/recall range; 1.005 upper headroom; first labelled tick strictly
  inside the panel rather than at the lower-left corner.
- Legend: temporarily hidden at the user request.
- Typography/rendering: inherited directly from the approved reference-effect
  reconstruction; caller-only title, Helvetica-compatible type, thin grey
  frame, short grey F1 dashes, and antialiased R raster/vector devices.
- Trajectory ordering: 10x, 30x, 50x.
- F1 contours: analytically derived from `F1 = 2PR/(P+R)`.
- Export: editable SVG/PDF, 320 dpi PNG preview, and LZW-compressed 600 dpi
  TIFF.
- Source-data traceability: the script exports the plotted rows, filter audit,
  and per-panel rendering limits.
- Main reviewer risk: axes are adapted per caller to preserve useful visual
  resolution, but are always symmetric within a panel; exported limits must be
  considered when comparing different callers side by side.
