# QA record — Extended Data f

## Scientific contract

- **Core claim:** The fraction of processed alignments assigned to H1 or H2 differs across platforms and mapper workflows and changes modestly across the measured depths.
- **Figure role:** Downstream haplotag usability evidence; this panel does not measure truth-set phasing accuracy.
- **Archetype:** One-row, two-panel quantitative depth-response small multiple.
- **Metric scope:** Taggable alignment yield only. H1/H2 balance is retained in Source Data and the figure legend rather than rendered as a low-information 50/50 stacked chart.
- **Reviewer risk addressed:** The denominator and observation unit are explicit: processed alignments, not unique reads or truth-validated haplotype assignments.

## Data integrity and metric audit

- Source: `data/phasing_haplotag_whatshap.csv`.
- All 18 source rows are retained: three platforms × two mappers × three depths.
- Every trajectory contains exactly the measured 10×, 30× and 50× observations.
- All rows use HG002, GRCh38 and completed WhatsHap haplotag workflows.
- `Tagged H1+H2` equals `H1 + H2` exactly in every row.
- Taggable alignments (%) are independently recomputed as `100 × (H1 + H2) / Alignments processed`.
- All processed-alignment denominators are positive, and tagged counts do not exceed processed counts.
- Recomputed proportions agree with the rounded source `Taggable rate` values within 0.00006.
- The observed taggable-alignment range is 49.3835–66.2178% and is fully contained by the shared linear 45–70% axis.
- Recomputed H1 and H2 fractions sum exactly to one. H1/H2 ratios range from 1.0033 to 1.0287; H1 accounts for 50.0833–50.7082% of tagged alignments.
- No row is excluded, averaged, aggregated, smoothed, fitted or interpolated.
- Straight segments connect adjacent measured depths only.

## Axis and interpretation audit

- The shared linear y-axis spans 45–70%, with all values and platform labels visible.
- A non-zero lower bound is appropriate for a line plot of percentage differences; no bar length or area encoding implies a zero baseline.
- The exact range is explicit and no discontinuous or broken axis is used.
- Mapper identity is encoded spatially in independent `minimap2` and `winnowmap` regions; there is no mapper line/shape legend or display offset.
- Both regions use evenly spaced depth-category centers, identical y scales and pale vertical boundary guides.

## Statistics legend minimum

- **n definition:** 18 deterministic workflow outputs; one per platform × mapper × depth combination.
- **Biological replicates:** Not applicable; one HG002 benchmark sample.
- **Technical replicates:** None represented.
- **Center statistic:** None.
- **Spread/interval:** None.
- **Test:** None.
- **Multiple-comparison correction:** Not applicable.
- **p-value display:** None.
- **Source data:** `figures/phasing_ed_f_whatshap_haplotag_yield/source_data_plotted.csv`.
- **Haplotype-balance audit:** `figures/phasing_ed_f_whatshap_haplotag_yield/haplotype_balance_audit.csv`.
- **Error bars:** None; mapper outputs are not statistical replicates.

## Visual and render audit

- Final size: 88 × 48 mm.
- Backend: R only (`ggplot2`, `svglite`, Cairo PDF and `ragg`).
- Platform colors match the manuscript constants and all preceding panels.
- Platform trajectories use fixed manuscript colors, solid lines and filled circles. A shared platform legend is supplied by the assembled Extended Data figure.
- Minimum configured text size: 5.6 pt; panel tag is bold lowercase 8 pt.
- Nimbus Sans is used as the installed Arial-compatible fallback and is embedded in the PDF.
- SVG and PDF retain editable text; the SVG contains live text elements.
- TIFF and PNG are 2078 × 1133 px at 600 dpi.
- Native-resolution inspection found all 18 points and six trajectories visible; no clipping, title collision or data occlusion remains.
- Image-integrity fields are not applicable because the panel contains no source imagery.

## Automated and independent checks

- `validate_figure.py`: 11 PASS, 3 WARN, 0 FAIL.
- The syntax warning is resolved by a successful full `Rscript parse()` check.
- The DPI and width warnings are static-parser limitations: named constants and rendered manifests confirm 600 dpi and 88 mm.
- Independent checks confirmed the complete 18-row design, six trajectories, H1+H2 count identity, taggable-rate formula, positive denominators, H1/H2 balance and exact depth-index mapping to category centers 1–3.
- PDF inspection confirmed one 249 × 136 pt page and embedded Nimbus Sans Regular/Bold fonts.
