# Panel e — 30× BAM output footprint

This task renders the operational storage-footprint panel for the
reads/alignment QC figure set. It compares minimap2 and winnowmap within each
platform and reference genome at the strict 30× condition.

The panel defaults to Extended Data. It may replace or accompany the primary
mapped-read panel only if storage footprint is discussed as a distinct Results
dimension.

## Run

```bash
Rscript scripts/reads_alignment_qc/panel_e_bam_footprint/panel_e_bam_footprint.R
```

## Input

- `data/alignment_qc.csv`
- Filter: `Depth == "30x"`.
- Expected selection: 3 platforms × 2 references × 2 aligners = 12 unique
  conditions.

## Evidence mapping

- Facets identify GRCh38 and T2T-CHM13 and share a zero-based 0–115 GiB axis.
- Platform names define the rows; the established platform colours reinforce
  that identity without a redundant colour legend.
- A filled circle identifies minimap2 and an open diamond identifies
  winnowmap.
- A thin neutral segment joins only the two aligners belonging to the same
  platform and reference genome.
- The metric is the BAM file size generated under the current unified software,
  preset, sorting and output settings. It does not measure runtime, memory,
  energy or monetary cost.

## Outputs

Outputs are written to
`figures/reads_alignment_qc/panel_e_bam_footprint/`:

- `bam_output_footprint_30x.svg`
- `bam_output_footprint_30x.pdf`
- `bam_output_footprint_30x.tiff`
- `bam_output_footprint_30x.png`
- `source_data_plotted.csv`
- `paired_aligner_differences.csv`
- `platform_range_audit.csv`
- `matched_platform_to_hifi_ratios.csv`
- `data_filter_audit.csv`
- `render_manifest.csv`

The plot is rendered at 183 × 38 mm, matching Panel d's compact full-width
geometry. It is a single plot rather than a manuscript figure assembly.

