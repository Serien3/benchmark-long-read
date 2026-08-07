# Panel d — 30× primary mapped-read rate

This task renders the read-level mapping-retention panel for the
reads/alignment QC opening figure. It reports primary mapped-read rate across
the complete 30× reference × aligner matrix without reusing the coverage
breadth values already shown in Panel c.

## Run

```bash
Rscript scripts/reads_alignment_qc/panel_d_primary_mapped_rate/panel_d_primary_mapped_rate.R
```

## Input

- `data/alignment_qc.csv`
- Filter: `Depth == "30x"`.
- Expected selection: 3 platforms × 2 references × 2 aligners = 12 unique
  conditions.

## Evidence mapping

- Two independent panels identify GRCh38 and T2T-CHM13.
- The x axis contains the two aligner categories; the y axis reports
  `100 × Primary mapped rate` on the same 97.5–100.10% window in both panels.
- BGI, ONT and HiFi use the established Panel c palette and the same filled
  circular mark vocabulary.
- Aligner categories sit at the centres of three pale vertical boundary
  guides, matching Panel c's categorical layout grammar.
- All 12 observations are plotted at their exact coordinates. There are no
  connector segments, breadth values, jitter, summaries or fitted trends.

## Outputs

Outputs are written to
`figures/reads_alignment_qc/panel_d_primary_mapped_rate/`:

- `primary_mapped_read_rate_30x.svg`
- `primary_mapped_read_rate_30x.pdf`
- `primary_mapped_read_rate_30x.tiff`
- `primary_mapped_read_rate_30x.png`
- `source_data_plotted.csv`
- `paired_aligner_differences.csv`
- `platform_range_audit.csv`
- `reference_range_audit.csv`
- `condition_platform_order_audit.csv`
- `data_filter_audit.csv`
- `render_manifest.csv`

The plot is rendered at 183 × 52 mm as a standalone full-width panel. It is
not a manuscript figure assembly.

