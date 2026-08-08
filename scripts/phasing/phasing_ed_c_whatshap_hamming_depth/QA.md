# QA record — Extended Data c

## Scientific contract

- **Core claim:** WhatsHap blockwise Hamming error changes non-uniformly with sequencing depth across platforms and mapper workflows.
- **Figure role:** Independent validation of local SNP phasing accuracy and its workflow dependence; this evidence is distinct from phase-block continuity and phased-SNV yield.
- **Archetype:** One-row, two-panel quantitative depth-response small multiple.
- **Metric scope:** Blockwise Hamming error only, defined from orientation-corrected phase blocks against phased SNP truth.
- **Reviewer risk addressed:** The full dynamic range remains readable without suppressing high-error 10× observations, and connected observations are not described as fitted trends.

## Data integrity and transformation

- Source: `data/phasing_accuracy_whatshap.csv`.
- All 18 source rows are retained: three platforms × two mappers × three depths.
- Every trajectory contains exactly the measured 10×, 30× and 50× observations.
- All rows use HG002, GRCh38 and completed WhatsHap workflows against a consistent GIAB v5.0q phased-SNP truth scope.
- Blockwise Hamming error (%) is independently recomputed as `100 × Blockwise Hamming / Covered variants`.
- All covered-variant denominators are positive and all recomputed percentages are strictly positive.
- Recomputed proportions agree with the rounded source `Hamming rate` values within 0.00006.
- The observed range is 1.4721–16.5881% and is fully contained by the 1.2–20% log10 display range.
- No pseudocount is needed or applied.
- Source Data retain the untransformed percentages and raw numerator/denominator counts; log10 is only a display transformation.
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
- **Source data:** `figures/phasing/phasing_ed_c_whatshap_hamming_depth/source_data_plotted.csv`.
- **Error bars:** None; mapper outputs are not statistical replicates.

## Visual and render audit

- Final size: 88 × 48 mm.
- Backend: R only (`ggplot2`, `svglite`, Cairo PDF and `ragg`).
- The y-axis uses log10 spacing with explicitly labelled original percentage ticks at 1, 2, 5, 10 and 20%.
- Platform colors match the manuscript constants and all preceding panels.
- Mapper identity is encoded spatially in two independent, equally sized regions titled `minimap2` and `winnowmap`; there is no mapper line/shape legend.
- Each mapper region uses three evenly spaced depth-category centers (10×, 30× and 50×) with pale vertical boundary guides; no display offset is used and the error percentages remain unchanged.
- Platform identity uses the fixed manuscript colors, solid lines and filled circles. A shared platform legend is supplied by the assembled Extended Data figure.
- Minimum configured text size: 5.6 pt; panel tag is bold lowercase 8 pt.
- Nimbus Sans is used as the installed Arial-compatible fallback and is embedded in the PDF.
- SVG and PDF retain editable text; the SVG contains live text elements.
- TIFF and PNG are 2078 × 1133 px at 600 dpi.
- Native-resolution inspection found all 18 points and six trajectories visible, with no clipping, title collision or hidden endpoint.
- Image-integrity fields are not applicable because the panel contains no source imagery.

## Automated and independent checks

- `validate_figure.py`: 11 PASS, 3 WARN, 0 FAIL; the log-axis guard passed explicitly.
- The syntax warning is resolved by a successful full `Rscript parse()` check.
- The DPI and width warnings are static-parser limitations: named constants and rendered manifests confirm 600 dpi and 88 mm.
- Independent checks confirmed the complete 18-row design, six unique trajectories, three ordered depths per trajectory, exact metric recomputation, positive denominators, positive log inputs and exact depth-index mapping to category centers 1–3.
- PDF inspection confirmed one 249 × 136 pt page and embedded Nimbus Sans Regular/Bold fonts.
