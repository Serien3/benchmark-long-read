# QA record — Extended Data b

## Scientific contract

- **Core claim:** WhatsHap phase-block NG50 changes with sequencing depth in a platform-dependent manner across the complete matched design.
- **Figure role:** Independent depth-response validation of phasing continuity; this panel supplies information absent from the matched 30× profile.
- **Archetype:** One-row, two-panel quantitative depth-response small multiple.
- **Metric scope:** Genome-normalized phase-block NG50 only. Median, mean and maximum block length and block count remain in Source Data rather than being redundantly plotted.
- **Reviewer risk addressed:** Both mapper trajectories remain visible, and connected observations are not described as fitted or inferential trends.

## Data integrity

- Source: `data/phasing_block_stats_whatshap.csv`.
- All 18 source rows are retained: three platforms × two mappers × three depths.
- Every trajectory contains exactly the measured 10×, 30× and 50× observations.
- All rows use HG002, GRCh38, completed WhatsHap 2.8 workflows.
- The plotted metric is the source field `WhatsHap block NG50`, already recorded in Mb; no numerical transformation is applied.
- The observed range is 0.363–3.868 Mb, fully contained by the linear 0–4.25 Mb axis.
- No row is excluded, averaged, aggregated, smoothed, fitted or interpolated.
- Straight segments connect adjacent measured depths only.
- No LongPhase value or statistic is merged with the WhatsHap outputs.

## Statistics legend minimum

- **n definition:** 18 deterministic workflow outputs; one per platform × mapper × depth combination.
- **Biological replicates:** Not applicable; one HG002 benchmark sample.
- **Technical replicates:** None represented.
- **Center statistic:** None.
- **Spread/interval:** None.
- **Test:** None.
- **Multiple-comparison correction:** Not applicable.
- **p-value display:** None.
- **Source data:** `figures/phasing_ed_b_whatshap_ng50_depth/source_data_plotted.csv`.
- **Error bars:** None; mapper outputs are not statistical replicates.

## Visual and render audit

- Final size: 88 × 48 mm.
- Backend: R only (`ggplot2`, `svglite`, Cairo PDF and `ragg`).
- Platform colors match the manuscript constants and all preceding panels.
- Mapper identity is encoded spatially in two independent, equally sized regions titled `minimap2` and `winnowmap`; there is no mapper line/shape legend.
- Each mapper region uses three evenly spaced depth-category centers (10×, 30× and 50×) with pale vertical boundary guides; no display offset or numerical transformation of depth is used.
- Platform identity uses the fixed manuscript colors, solid lines and filled circles. A shared platform legend is supplied by the assembled Extended Data figure.
- Minimum configured text size: 5.6 pt; panel tag is bold lowercase 8 pt.
- Nimbus Sans is used as the installed Arial-compatible fallback and is embedded in the PDF.
- SVG and PDF retain editable text; the SVG contains live text elements.
- TIFF and PNG are 2078 × 1133 px at 600 dpi.
- Native-resolution inspection found all 18 points and six trajectories visible, with no clipping, title collision or hidden endpoint.
- Image-integrity fields are not applicable because the panel contains no source imagery.

## Automated and independent checks

- `validate_figure.py`: 11 PASS, 3 WARN, 0 FAIL.
- The syntax warning is resolved by a successful full `Rscript parse()` check.
- The DPI and width warnings are static-parser limitations: named constants and rendered manifests confirm 600 dpi and 88 mm.
- Independent checks confirmed 18 plotted rows, six unique trajectories, three ordered depths per trajectory, exact equality between source and plotted NG50 values, positive NG50 values, and exact depth-index mapping to category centers 1–3.
- PDF inspection confirmed one 249 × 136 pt page and embedded Nimbus Sans Regular/Bold fonts.
