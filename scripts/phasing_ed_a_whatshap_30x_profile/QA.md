# QA record — Extended Data a

## Figure contract

- **Question:** At matched 30× depth, how do the six WhatsHap platform × mapper workflows compare across SNP phasing yield, contiguity, local switch accuracy, and blockwise Hamming accuracy?
- **Archetype:** Four aligned grouped-bar panels with mapper groups and platform bars.
- **Inference level:** Descriptive, independent validation of WhatsHap outputs only. No cross-phaser pooling or ranking is performed.
- **Primary visual encoding:** Mapper is encoded spatially as `minimap2` and `winnowmap` x-axis groups; platform is encoded by the fixed manuscript color of each solid bar. A single platform legend appears in the header.

## Data inclusion and integrity

- Source files: `data/phasing_block_stats_whatshap.csv` and `data/phasing_accuracy_whatshap.csv`.
- Each source contains 18 rows. All six 30× rows (three platforms × two mappers) were retained from each source; the 12 rows at 10× and 50× were excluded because they belong to separately specified depth-response panels.
- The join key is dataset, reference, mapper, and depth. The resulting six workflow outputs are unique and complete.
- The figure contains 24 plotted bars: six workflow outputs × four metrics.
- No missing-data removal, averaging, imputation, error bars, hypothesis tests, mapper-as-replicate treatment, or cross-phaser pooling was used.
- Bar width is 0.200 category units and platform offsets are −0.250, 0 and +0.250, leaving 0.050-unit gaps within each mapper group and clear separation from group boundaries.

## Metric and denominator audit

- Phased heterozygous SNVs (%) = `100 × Phased SNVs / Het SNVs`.
- Phase-block NG50 is the source field `WhatsHap block NG50`, recorded in Mb.
- Switch errors per 10,000 assessed pairs = `10,000 × Switch errors / Assessed pairs`.
- Blockwise Hamming error (%) = `100 × Blockwise Hamming / Covered variants`.
- All `Het SNVs`, `Assessed pairs`, and `Covered variants` denominators are positive.
- Recomputed rates agree with the rounded source rate fields at their stored scales: proportions for phased-SNV and Hamming rates, and errors per pair for switch-error rate.

## Statistics legend minimum

- **n definition:** Six deterministic 30× workflow outputs (three platforms × two mappers).
- **Biological replicates:** Not applicable; one HG002 benchmark sample.
- **Technical replicates:** None represented.
- **Center statistic:** None.
- **Spread/interval:** None.
- **Test:** None.
- **Multiple-comparison correction:** Not applicable.
- **p-value display:** None.
- **Source data:** `figures/phasing_ed_a_whatshap_30x_profile/source_data_plotted.csv`.

## Axis audit

- Phased heterozygous SNVs use a continuous 94–100% window with explicit ticks at 94, 96, 98 and 100%; all six values (94.6024–99.7327%) are inside the window.
- The truncated percentage axis is limited to this linearly scaled within-panel comparison; no cross-metric bar-length comparison is valid or intended.
- NG50 uses a 0–3 Mb zero-baseline axis; observed values are 0.615–2.535 Mb.
- Switch-error burden uses a 0–9 zero-baseline axis; observed values are 4.4965–7.7987 per 10,000 assessed pairs.
- Blockwise Hamming error uses a 0–8% zero-baseline axis; observed values are 1.6818–7.5051%.
- All limits, observed ranges and baseline policies are recorded in `axis_window_audit.csv`.

## Render and accessibility audit

- Final size: 183 × 52 mm.
- Backend: R only (`ggplot2`, `svglite`, Cairo PDF, and `ragg`).
- Minimum source-configured text size: 5.9 pt.
- Font: Nimbus Sans fallback; embedded in the PDF.
- Vector outputs: editable-text SVG and PDF.
- Raster outputs: TIFF and PNG at 600 dpi (4322 × 1228 px).
- Platform colors follow the manuscript constants; mapper is independently recoverable from its spatial group label, so interpretation does not depend on color alone.
- Final PNG was inspected at native resolution: titles, axes, all 24 bars, mapper labels, shared platform legend and panel tag are legible; no clipping or overlap was observed.

## Automated and independent checks

- `validate_figure.py`: 11 PASS, 3 WARN, 0 FAIL.
- The syntax warning is resolved by a successful full `Rscript parse()` check.
- The DPI and width warnings are conservative static-parser limitations: the final constants are 600 dpi and 183 mm, confirmed in `render_manifest.csv` and the rendered files.
- Independent source-data checks confirmed 24 rows, six unique platform × mapper outputs, four metrics, the 30×/GRCh38 scope, positive denominators, all four metric transformations, valid axis windows and contained bar geometry.
- PDF inspection confirmed one 518 × 147 pt page and embedded Nimbus Sans Regular/Bold fonts.
- SVG inspection confirmed live text elements rather than outlined labels.
