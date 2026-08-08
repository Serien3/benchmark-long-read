# Extended Data a — 30× WhatsHap SNP profile

This R-only task renders the four-metric 30× WhatsHap comparison specified as
Extended Data panel a. All three platforms and both mappers are shown as six raw
workflow outputs in four aligned grouped-bar panels; values are neither averaged nor
treated as replicates.

Run from any working directory:

```bash
Rscript scripts/phasing/phasing_ed_a_whatshap_30x_profile/phasing_ed_a_whatshap_30x_profile.R
```

Outputs are written under `figures/phasing/phasing_ed_a_whatshap_30x_profile/` as editable
SVG/PDF, 600-dpi TIFF/PNG, plotted Source Data, a filter audit, metric definitions and
a render manifest.

Figure contract:

- Core conclusion: the independent WhatsHap analysis provides a workflow-specific
  30× profile of SNP phasing coverage, continuity and local error.
- Archetype: four independent grouped-bar panels; this is the primary
  independent-validation panel and structurally matches Main panel b.
- Evidence: phased heterozygous SNV percentage, WhatsHap phase-block NG50, switch
  errors per 10,000 assessed pairs and blockwise Hamming error percentage.
- Statistics: none. Each bar is one deterministic pipeline output for one mapper;
  no biological replicates, averaging or inferential tests are present.
- Visual hierarchy: each metric contains `minimap2` and `winnowmap` x-axis groups,
  with BGI, ONT and HiFi represented by fixed-color solid bars. A single platform
  legend is shared in the header.
- Axis policy: NG50, switch-error burden and Hamming error use zero baselines; phased
  heterozygous SNVs use an explicit 94–100% window because all six values lie within
  94.60–99.73% and comparisons are restricted to that panel.
- Scope guard: WhatsHap counts and blocks remain separate from LongPhase outputs.
- Final size: 183 × 52 mm.
