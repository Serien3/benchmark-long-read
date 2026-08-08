# Extended Data — apparent alignment-error spectrum pilot

This task renders the complete six-condition apparent-error pilot for the
reads/alignment QC result set. It compares BGI, ONT and HiFi at nominal 30×
under minimap2 and winnowmap in the same GRCh38/GIAB-masked pilot regions.

The figure is an Extended Data result, not a replacement for the planned
donor-specific empirical error analysis. Its quantitative object is the
remaining alignment disagreement after the recorded primary-alignment,
mapping-quality and base-quality filters.

## Run

```bash
Rscript scripts/reads_alignment_qc/extended_data_error_spectrum_pilot/apparent_error_spectrum_pilot.R
```

## Input and calculation

- Input: `data/error_spectrum_pilot.csv`.
- Expected matrix: 3 platforms × 2 aligners = 6 unique conditions.
- Fixed conditions: GRCh38, nominal 30×, 2,981,290 region bases and 6,488
  masked truth sites.
- Component rate:
  `1,000 × component error bases / aligned Q20 bases`.
- Total rate: mismatch + insertion + deletion component rates.

The script recomputes all rates from raw counts and verifies that their rounded
values match the supplied summary columns.

## Evidence mapping

- Rows are BGI, ONT and HiFi; columns are minimap2 and winnowmap.
- Every condition uses the same zero-based 0–18 track.
- Mismatch, insertion and deletion bases form one additive horizontal stack.
- A three-decimal label reports the exact total apparent-error burden.
- Platform-coloured row markers preserve the visual vocabulary used throughout
  the reads/alignment QC figure set; stack colours encode error component only.
- No events, points, pair connectors, error bars, fitted trends or rankings are
  drawn.

The figure directly shows the stable BGI > ONT > HiFi total-burden ordering,
the deletion-dominated spectra of BGI and ONT, and the comparatively small
change between aligners.

## Outputs

Outputs are written to
`figures/reads_alignment_qc/extended_data_error_spectrum_pilot/`:

- `apparent_error_spectrum_pilot_30x.svg`
- `apparent_error_spectrum_pilot_30x.pdf`
- `apparent_error_spectrum_pilot_30x.tiff`
- `apparent_error_spectrum_pilot_30x.png`
- `source_data_plotted.csv`
- `component_rates_audit.csv`
- `matrix_cell_geometry_audit.csv`
- `deletion_share_audit.csv`
- `aligner_delta_audit.csv`
- `platform_range_audit.csv`
- `condition_platform_order_audit.csv`
- `data_filter_audit.csv`
- `render_manifest.csv`

The standalone plot is rendered at 89 × 54 mm using the same typography,
platform colours and export contract as Panels d/e.
