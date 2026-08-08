# Phasing main figure f — LongPhase SV benchmark F1

This R-only task renders the SV call-set F1 depth-response panel specified as main
figure panel f. It retains all 18 platform–mapper–depth outputs and recomputes
precision, recall and F1 from Truvari TP-base, FP and FN counts.

Run from any working directory:

```bash
Rscript scripts/phasing_main_f_longphase_sv_f1_depth/phasing_main_f_longphase_sv_f1_depth.R
```

Outputs are written under `figures/phasing_main_f_longphase_sv_f1_depth/` as editable
SVG/PDF, 600-dpi TIFF/PNG, plotted Source Data, a filter audit, metric definition and
a render manifest.

Figure contract:

- Core conclusion: SV call-set F1 improves strongly from 10× to 30× and changes less
  from 30× to 50×, with platform- and mapper-specific levels.
- Archetype: one-row, two-panel depth-response small multiple; this panel evaluates SV
  detection agreement and is intentionally separate from phased-genotype coverage.
- Metric: Truvari F1 against T2T-Q100 v1.1, recomputed as
  `2 × TP-base / (2 × TP-base + FP + FN)`.
- Statistics: none. Each point is one deterministic benchmark output; connected line
  segments are not fitted trends and mapper outputs are not replicates.
- Terminology guard: F1 is not labelled as truth-validated phasing orientation accuracy.
- Visual hierarchy: mapper identity is carried spatially by two independent plotting
  regions; category-centred depths, pale boundary guides, solid lines and filled
  circles match the coverage-breadth panel.
- Final size: 88 × 48 mm.
