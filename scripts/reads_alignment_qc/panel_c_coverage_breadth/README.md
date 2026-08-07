# Panel c — reference-base coverage breadth

This task renders the hero evidence panel for the reads/alignment QC opening
figure. It shows how reference bases covered at least once respond to nominal
depth, reference genome and aligner for all three sequencing platforms.

## Run

```bash
Rscript scripts/reads_alignment_qc/panel_c_coverage_breadth/panel_c_coverage_breadth.R
```

## Input

- `data/alignment_qc.csv`
- Expected matrix: 3 platforms × 3 depths × 2 references × 2 aligners =
  36 unique conditions.
- No rows are filtered or aggregated.

## Evidence mapping

- Four left-to-right small multiples identify GRCh38–minimap2,
  GRCh38–winnowmap, T2T-CHM13–minimap2 and T2T-CHM13–winnowmap.
- They are four independent plotting regions without internal subpanel tags,
  not a faceted coordinate system with one shared x-axis title.
- Each small multiple contains exactly three platform series and the same three
  nominal depths (10×, 30× and 50×).
- Colour identifies platform: BGI, ONT and HiFi; all exact observations use
  the same filled-circle and continuous-line grammar because aligner identity
  is now carried spatially by the panel title.
- Each line connects the three nested depth subsets from the same
  platform–aligner–reference series; it is not a replicate trajectory or a
  fitted trend.
- Coverage breadth is derived as `100 × Coverage rate` and means reference
  bases covered at ≥1×.
- GRCh38 uses 92.0–94.5% and T2T-CHM13 uses 97.5–100.0%. Both windows span
  exactly 2.5 percentage points, so vertical slopes and gaps remain
  geometrically comparable while each panel retains explicit percentage
  tick labels.
- The layout is a structural adaptation of the supplied cuteHap example:
  four narrow independent plots, bold centred titles, repeated x-axis titles
  and filled circular markers. Depths occupy category centres 1, 2 and 3;
  pale vertical guides mark the four category boundaries at 0.5, 1.5, 2.5
  and 3.5, so no observation lies on a guide. The panel-local legend is
  omitted to match this grammar; the full figure should provide the
  project-wide platform legend once. The example's inset boxes are not used.

## Outputs

Outputs are written to
`figures/reads_alignment_qc/panel_c_coverage_breadth/`:

- `reference_base_coverage_breadth.svg`
- `reference_base_coverage_breadth.pdf`
- `reference_base_coverage_breadth.tiff`
- `reference_base_coverage_breadth.png`
- `source_data_plotted.csv`
- `data_filter_audit.csv`
- `paired_aligner_differences.csv`
- `depth_gain_audit.csv`
- `derived_summary_audit.csv`
- `render_manifest.csv`

The plot is rendered at 183 × 59.5 mm, matching the supplied example's wide,
shallow visual rhythm while retaining journal-size text.
It is a single plot rather than a manuscript figure assembly.
