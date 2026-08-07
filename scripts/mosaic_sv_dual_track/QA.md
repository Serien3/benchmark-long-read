# QA record

## Figure contract

- Core conclusion: the six matched workflows have distinct absolute candidate
  burdens, SV-type compositions, and VAF-bin compositions; the figure does not
  assign an accuracy or sensitivity ranking.
- Archetype: one quantitative landscape plot with stacked bars and aligned
  summary pies.
- Role: advanced-application / workflow-profile evidence.
- Backend: R only.
- Final size: 183 × 112 mm.
- Hero evidence: five-type absolute stacked bars for all six workflows.
- Supporting evidence: equal-size two-slice VAF pies aligned above the bars.
- Reviewer risk: no mosaic truth set, no replicates, and no event-level overlap;
  candidate counts cannot be interpreted as precision, sensitivity, biological
  mosaic burden, or cross-platform concordance.

## Data integrity

- Source rows: 6; retained rows: 6; exclusions: none.
- Complete design: 3 platforms × 2 aligners at 30× with Sniffles2 mosaic mode.
- `Total calls = DEL + INS + DUP + INV + BND` for every workflow.
- `Total calls = VAF 5–10% + VAF 10–20%` for every workflow.
- All bars start at zero and use the same untransformed absolute-count axis.
- All pies have identical physical size and a shared non-quantitative vertical
  position above the bar panel.
- Pie wedges report within-workflow VAF proportions; both percentages are
  printed directly.
- The bar and pie are separate marginal summaries; no `SV type × VAF bin`
  cross-classification is implied.
- No aggregation, smoothing, interpolation, missing-value removal, or
  result-based sorting is used.
- No uncertainty intervals, hypothesis tests, p-values, or statistical
  annotations are shown because the six workflows are not replicates.

## Style adaptation

- Reuse level: structural adaptation of a user-provided bar-plus-pie reference.
- Retained reference qualities: compact vertical bars, clean white background,
  dashed group separators, purple-grey pies, white wedge boundaries, restrained
  labels, and strong sans-serif hierarchy.
- Scientific changes: one shared zero-based count axis, equal-area pies, direct
  VAF labels, and fixed platform–aligner design order.
- Platform colors match the established manuscript SV mapping exactly.
- SV-type colors retain the muted manuscript composition palette.
- Nimbus Sans was selected in the current environment.

## Export and visual QA

- Editable SVG and PDF plus 320-dpi PNG and 600-dpi LZW TIFF were generated.
- PDF page size resolves to approximately 183 × 112 mm.
- PNG dimensions: 2305 × 1411 pixels.
- TIFF dimensions: 4322 × 2645 pixels.
- SVG contains editable text elements.
- R runtime completed without warnings or errors.
- Automated source preflight: 11 PASS, 3 WARN, 0 FAIL.
- Reviewed warnings:
  - the static validator requested an R parse/runtime check; both completed;
  - final width and raster DPI are stored in named constants, so the validator
    did not detect them; the manifest and rendered file dimensions confirm
    183 mm, 320 dpi, and 600 dpi outputs.
- The pie radii were calibrated against the final panel aspect ratio so the
  rendered pies are circular rather than elliptical.
- Final-size visual inspection found no clipping, label collision, or illegible
  percentage annotation.
