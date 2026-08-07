# Panel b — integrated 30× read profile

This task renders the read-level evidence panel for the reads/alignment QC
opening figure. At the strict 30× input condition, the three platform rows are
aligned across read length, reported read Q and mean-Q>20 composition.

## Run

```bash
Rscript scripts/reads_alignment_qc/panel_b_read_profile/panel_b_read_profile.R
```

## Input

- `data/reads_qc_nanoplot_q20.csv`
- Filter: `Depth == "30x"`.
- Expected selection: one HG002 observation for each of BGI, ONT and HiFi.

## Evidence mapping

- Colour identifies platform and row labels make that identity explicit.
- Mean, median and N50 are independent observed summaries and are not joined.
- The Q20 read fraction and Q20-read base share are joined within a platform
  because they describe the number and base contribution of the same read
  subset.
- Q20-read base share is derived as
  `100 × Mean-Q>20 read yield (Gb) / total yield (Gb)`.
- Absolute Q20-read yields are retained in Source Data: 38.92 Gb for BGI,
  80.13 Gb for ONT and 88.53 Gb for HiFi.

## Outputs

Outputs are written to `figures/reads_alignment_qc/panel_b_read_profile/`:

- `integrated_read_profile_30x.svg`
- `integrated_read_profile_30x.pdf`
- `integrated_read_profile_30x.tiff`
- `integrated_read_profile_30x.png`
- `source_data_input_30x.csv`
- `source_data_plotted.csv`
- `data_filter_audit.csv`
- `render_manifest.csv`

The visualization is rendered at its intended top-row panel size of
120 × 52 mm. It is a single integrated plot, not a manuscript figure assembly.

