# QA record — Extended Data e

## Scientific contract

- **Core claim:** Changing the input SNP caller alters WhatsHap phasing yield, phase-block continuity and local Hamming error in workflow-specific and metric-specific directions.
- **Figure role:** Caller-sensitivity evidence that complements the primary platform and mapper comparisons.
- **Archetype:** Three-column paired dumbbell profile.
- **Pairing unit:** One 30× platform–mapper workflow. Clair3 and DeepVariant are deterministic workflow endpoints, not replicates.
- **Reviewer risk addressed:** All three affected metric families are shown together, preventing a caller comparison based on only one favorable outcome; no composite score or overall ranking is constructed.

## Data inclusion and pairing

- Primary source: `data/phasing_compare_whatshap_callers.csv`.
- The source contains 24 unique rows: 18 Clair3 depth results and six DeepVariant 30× results.
- The panel retains all 12 rows at 30×: three platforms × two mappers × two callers.
- The 12 excluded rows are Clair3 10× and 50× observations, which belong to the separately specified depth-response panels. DeepVariant is available only at 30× in this experiment.
- The selected rows form six complete caller pairs and three metrics, yielding 36 plotted endpoints and 18 paired connectors.
- No row is averaged, aggregated, imputed or selected by outcome.
- The fixed caller-specific y offset is +0.10 row units for Clair3 and −0.10 for DeepVariant. It only prevents point occlusion; all quantitative x values are unchanged.
- Grey connectors join the two caller endpoints within the same platform, mapper and metric. They are paired differences, not uncertainty intervals.

## Metric and field audit

- **Phased heterozygous SNVs (%):** `100 × source Phased SNVs fraction`. The structured caller table reports the fraction but does not expose DeepVariant phased/heterozygous-SNV counts; no unavailable denominator was invented. The six Clair3 values independently agree with the dedicated count-derived WhatsHap block table within source rounding.
- **Phase-block NG50 (Mb):** direct source value. The legacy caller-table header is `Block N50 Mb`, but all six Clair3 values map to the dedicated genome-normalized `WhatsHap block NG50` field within 0.006 Mb; the panel therefore uses the manuscript-wide NG50 label.
- **Blockwise Hamming error (%):** independently recomputed as `100 × Blockwise hamming / Covered variants` for both callers.
- All covered-variant denominators are positive, error counts are non-negative and do not exceed their denominators.
- Recomputed Hamming proportions agree with the rounded source rate field within 0.00006.
- All selected rows use the same GIAB v5.0q masked phased-SNP truth scope with 2,184,586 truth heterozygous SNVs.
- Observed plotted ranges are 60.88–99.73%, 0.41–4.04 Mb and 1.6718–20.5334%, respectively.
- The dedicated field cross-check also confirms exact Clair3 covered-variant and Hamming-count matches.

## Statistics legend minimum

- **n definition:** Six paired deterministic 30× platform–mapper workflows.
- **Biological replicates:** Not applicable; one HG002 benchmark sample.
- **Technical replicates:** None represented.
- **Center statistic:** None.
- **Spread/interval:** None.
- **Test:** None.
- **Multiple-comparison correction:** Not applicable.
- **p-value display:** None.
- **Source data:** `figures/phasing_ed_e_whatshap_caller_sensitivity/source_data_plotted.csv`.
- **Paired differences:** `figures/phasing_ed_e_whatshap_caller_sensitivity/paired_caller_differences.csv`.
- **Field mapping audit:** `figures/phasing_ed_e_whatshap_caller_sensitivity/clair3_field_crosscheck.csv`.
- **Error bars:** None; callers and mappers are not statistical replicates.

## Visual and render audit

- Final size: 183 × 60 mm.
- Backend: R only (`ggplot2`, `svglite`, Cairo PDF and `ragg`).
- Each metric has its own clearly labelled linear x scale and unit; no dual y-axis or hidden normalization is used.
- Platform colors match the manuscript constants and all preceding panels.
- Clair3 uses a filled circle; DeepVariant uses an open diamond. Caller interpretation therefore does not depend on color.
- Platform and mapper are both written in each row label; platform is redundantly encoded by point color.
- Minimum configured text size: 5.7 pt; panel tag is bold lowercase 8 pt.
- Nimbus Sans is used as the installed Arial-compatible fallback and all PDF font subsets are embedded.
- SVG and PDF retain editable text; the SVG contains live text elements.
- TIFF and PNG are 4322 × 1417 px at 600 dpi.
- Native-resolution inspection found all 36 endpoints and 18 connectors visible, including the near-coincident HiFi Hamming endpoints; no clipping or label collision was observed.
- Image-integrity fields are not applicable because the panel contains no source imagery.

## Automated and independent checks

- `validate_figure.py`: 11 PASS, 3 WARN, 0 FAIL.
- The syntax warning is resolved by a successful full `Rscript parse()` check.
- The DPI and width warnings are static-parser limitations: named constants and rendered manifests confirm 600 dpi and 183 mm.
- Independent checks confirmed all 36 endpoint values, 18 paired differences, six workflows, two callers, three metrics, Hamming formula and denominators, common truth scope and the six-row Clair3 field mapping.
- PDF inspection confirmed one 518 × 170 pt page and embedded Nimbus Sans Regular/Bold font subsets.
