# Phasing main figure e — LongPhase phased heterozygous SV fraction

This R-only task renders the phased heterozygous SV depth-response panel specified as
main figure panel e. It retains all 18 platform–mapper–depth outputs and reports the
fraction of heterozygous SV genotypes written as phased, without treating that fraction
as truth-validated haplotype-orientation accuracy.

Run from any working directory:

```bash
Rscript scripts/phasing_main_e_longphase_sv_phased_depth/phasing_main_e_longphase_sv_phased_depth.R
```

Outputs are written under `figures/phasing_main_e_longphase_sv_phased_depth/` as
editable SVG/PDF, 600-dpi TIFF/PNG, plotted Source Data, a filter audit, metric
definition and a render manifest.

Figure contract:

- Core conclusion: the proportion of heterozygous SVs assigned phased genotypes
  differs by platform, mapper and depth.
- Archetype: one-row, two-panel depth-response small multiple; this panel reports SV
  phasing coverage and is intentionally separate from the call-set F1 panel.
- Metric: phased heterozygous SVs divided by all heterozygous SVs, displayed on a
  linear percentage scale.
- Statistics: none. Each point is one deterministic pipeline output; connected line
  segments are not fitted trends and mapper outputs are not replicates.
- Visual hierarchy: mapper identity is carried spatially by two independent plotting
  regions; platform identity uses fixed project colours and the assembled figure's
  single shared platform legend.
- Depth geometry and marks match the coverage-breadth panel: category-centred depths,
  pale boundary guides, solid lines and filled circles.
- Final size: 88 × 48 mm.
