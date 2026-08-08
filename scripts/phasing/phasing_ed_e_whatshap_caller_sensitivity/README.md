# Extended Data e — WhatsHap caller sensitivity at 30×

This R-only task renders the paired Clair3–DeepVariant sensitivity profile specified
as Extended Data panel e. It retains all six matched 30× platform–mapper workflows
and reports phased heterozygous-SNV fraction, phase-block NG50 and blockwise Hamming
error without averaging or ranking.

Run from any working directory:

```bash
Rscript scripts/phasing/phasing_ed_e_whatshap_caller_sensitivity/phasing_ed_e_whatshap_caller_sensitivity.R
```

Outputs are written under `figures/phasing/phasing_ed_e_whatshap_caller_sensitivity/` as
editable SVG/PDF, 600-dpi TIFF/PNG, plotted Source Data, paired caller differences,
a Clair3 field cross-check, a filter audit, metric definitions and a render manifest.

Figure contract:

- Core conclusion: changing the input SNP caller alters WhatsHap phasing yield,
  continuity and local error in workflow-specific and metric-specific directions.
- Evidence role: workflow-sensitivity evidence; the figure does not assign an overall
  winner or reduce the three metrics to a composite score.
- Archetype: three-column paired dumbbell profile.
- Pairing unit: one 30× platform–mapper workflow; Clair3 and DeepVariant are the two
  deterministic endpoints, not statistical replicates.
- Caller encoding: Clair3 is a filled circle and DeepVariant an open diamond; platform
  colors remain fixed to the manuscript palette.
- Final size: 183 × 60 mm.
