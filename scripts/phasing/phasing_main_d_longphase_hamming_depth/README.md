# Phasing main figure d — LongPhase Hamming-error depth trajectories

This R-only task renders the blockwise Hamming-error depth-response panel specified as
main figure panel d. It retains all 18 platform–mapper–depth outputs and uses a guarded
log10 percentage axis without fitting, averaging or uncertainty bands.

Run from any working directory:

```bash
Rscript scripts/phasing/phasing_main_d_longphase_hamming_depth/phasing_main_d_longphase_hamming_depth.R
```

Outputs are written under `figures/phasing/phasing_main_d_longphase_hamming_depth/` as editable
SVG/PDF, 600-dpi TIFF/PNG, plotted Source Data, a filter audit, metric definition and
a render manifest.

Figure contract:

- Core conclusion: depth changes local phasing consistency differently among
  platforms and mappers; the response is not uniformly monotonic.
- Archetype: one-row, two-panel depth-response small multiple; this panel supplies
  local-error depth evidence complementary to the NG50 continuity panel.
- Metric: blockwise Hamming errors divided by covered truth variants, displayed as a
  percentage on a log10 axis.
- Statistics: none. Each point is one deterministic pipeline output; connected line
  segments are not fitted trends and mapper outputs are not replicates.
- Visual hierarchy: mapper identity is carried spatially by two independent plotting
  regions; platform identity uses fixed project colours and the assembled figure's
  single shared platform legend.
- Depth geometry and marks match the coverage-breadth panel: category-centred depths,
  pale boundary guides, solid lines and filled circles.
- Final size: 88 × 48 mm.
