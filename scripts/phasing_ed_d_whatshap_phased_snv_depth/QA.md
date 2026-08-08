# QA record — Extended Data d

## Scientific contract

- **Core claim:** WhatsHap phased heterozygous-SNV yield changes with depth and differs between mapper workflows across all three platforms.
- **Figure role:** Independent reporting of phasing yield and workflow dependence; this metric is distinct from truth-validated phasing accuracy.
- **Archetype:** One-row, two-panel quantitative depth-response small multiple.
- **Reviewer risk addressed:** Mapper workflows occupy independent regions while a common y scale preserves valid comparison; platform trajectories remain distinguishable through fixed manuscript colors.

## Data integrity and metric audit

- Source: `data/phasing_block_stats_whatshap.csv`.
- All 18 source rows are retained: three platforms × two mappers × three depths.
- Every trajectory contains exactly the measured 10×, 30× and 50× observations.
- All rows use HG002, GRCh38 and completed WhatsHap 2.8 workflows.
- Phased heterozygous SNVs (%) are independently recomputed as `100 × Phased SNVs / Het SNVs`.
- All heterozygous-SNV denominators are positive, and every numerator lies within its corresponding denominator.
- Recomputed proportions agree with the rounded source `Phased SNV rate` values within 0.00006.
- The observed percentage range is 94.5571–99.7412%.
- Nine complete within-platform, within-depth mapper pairs were confirmed. Winnowmap-minus-minimap2 differences range from 0.9684 to 4.9496 percentage points.
- No row is excluded, averaged, aggregated, smoothed, fitted or interpolated.
- Straight colored segments connect adjacent measured depths only.
- Mapper-paired differences remain in `paired_mapper_differences.csv` for auditability but are not drawn across the independent plotting regions.
- No LongPhase result or truth-site count is merged with the WhatsHap outputs.

## Axis and interpretation audit

- The shared linear y-axis spans 94–100%; all 18 observations are inside the displayed range.
- A non-zero lower bound is appropriate for this line-based percentage comparison because the task is to resolve absolute percentage-point differences rather than encode magnitude by bar length or area.
- The exact axis range and percentage ticks are explicit, and no discontinuous or broken axis is used.
- The metric reports the fraction of heterozygous SNVs assigned to phase blocks. It is phasing yield, not truth-validated phasing accuracy.

## Statistics legend minimum

- **n definition:** 18 deterministic workflow outputs; one per platform × mapper × depth combination.
- **Biological replicates:** Not applicable; one HG002 benchmark sample.
- **Technical replicates:** None represented.
- **Center statistic:** None.
- **Spread/interval:** None.
- **Test:** None.
- **Multiple-comparison correction:** Not applicable.
- **p-value display:** None.
- **Source data:** `figures/phasing_ed_d_whatshap_phased_snv_depth/source_data_plotted.csv`.
- **Paired geometry data:** `figures/phasing_ed_d_whatshap_phased_snv_depth/paired_mapper_differences.csv`.
- **Error bars:** None; mapper outputs are not statistical replicates.

## Visual and render audit

- Final size: 88 × 48 mm.
- Backend: R only (`ggplot2`, `svglite`, Cairo PDF and `ragg`).
- Mapper regions share identical y limits, tick positions and x geometry.
- Platform colors match the manuscript constants and all preceding panels.
- Mapper identity is encoded spatially in regions titled `minimap2` and `winnowmap`; platform trajectories use solid lines and filled circles, with no mapper line/shape legend.
- Each region uses evenly spaced depth-category centers and pale vertical boundary guides. A shared platform legend is supplied by the assembled Extended Data figure.
- Minimum configured text size: 5.5 pt; panel tag is bold lowercase 8 pt.
- Nimbus Sans is used as the installed Arial-compatible fallback and is embedded in the PDF.
- SVG and PDF retain editable text; the SVG contains live text elements.
- TIFF and PNG are 2078 × 1133 px at 600 dpi.
- Native-resolution inspection found all 18 points and six trajectories visible, with no clipping, title collision or hidden endpoint.
- Image-integrity fields are not applicable because the panel contains no source imagery.

## Automated and independent checks

- `validate_figure.py`: 11 PASS, 3 WARN, 0 FAIL.
- The syntax warning is resolved by a successful full `Rscript parse()` check.
- The DPI and width warnings are static-parser limitations: named constants and rendered manifests confirm 600 dpi and 88 mm.
- Independent checks confirmed the complete 18-row design, six unique trajectories, exact percentage recomputation, nine complete mapper pairs, exact paired-difference export and no out-of-range observation.
- PDF inspection confirmed one 249 × 136 pt page and embedded Nimbus Sans Regular/Bold fonts.
