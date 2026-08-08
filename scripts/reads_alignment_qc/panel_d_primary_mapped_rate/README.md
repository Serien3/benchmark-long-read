# Panel d — 30× primary mapped-read rate

This task renders a compact annotated heatmap for the read-level mapping
retention result. It reports the complete 30× platform × reference × aligner
matrix without reusing the coverage breadth values already shown in Panel c.

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

- Rows are BGI, ONT and HiFi; the adjacent coloured dots preserve the fixed
  platform palette used in Panel c.
- Columns are grouped into GRCh38 and T2T-CHM13, with minimap2 and winnowmap
  shown in the same order within each group.
- A single sequential blue-grey scale encodes
  `100 × Primary mapped rate` from 97.9% to 100.0%.
- Every cell contains its exact percentage to two decimal places, with
  contrast-aware black or white text.
- All 12 observations are displayed once. There are no connector segments,
  coverage values, summaries, ranking badges or fitted trends.

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

The plot is rendered at the Nature-style single-column size of 89 × 54 mm.
It is a standalone panel rather than a manuscript figure assembly.

