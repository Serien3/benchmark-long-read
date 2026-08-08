# Phasing main figure c — LongPhase NG50 depth trajectories

This R-only task renders the phase-block NG50 depth-response panel specified as main
figure panel c. It retains all 18 platform–mapper–depth workflow outputs and draws six
raw trajectories without averaging, smoothing or uncertainty bands.

Run from any working directory:

```bash
Rscript scripts/phasing/phasing_main_c_longphase_ng50_depth/phasing_main_c_longphase_ng50_depth.R
```

Outputs are written under `figures/phasing/phasing_main_c_longphase_ng50_depth/` as editable
SVG/PDF, 600-dpi TIFF/PNG, plotted Source Data, a filter audit, metric definition and
a render manifest.

Figure contract:

- Core conclusion: increasing depth extends LongPhase phase-block NG50 in all six
  workflows, with platform-dependent magnitudes and gains.
- Archetype: one-row, two-panel depth-response small multiple; this panel supplies
  depth-response evidence that is absent from the matched 30× profile.
- Metric: genome-normalized phase-block NG50 on a linear Mb scale.
- Statistics: none. Each point is one deterministic pipeline output; mapper outputs
  are not replicates and the connecting segments are not fitted trends.
- Visual hierarchy: mapper identity is carried spatially by two independent plotting
  regions; platform identity uses the fixed project colours and a shared legend is
  supplied once in the assembled main figure.
- Depth geometry: 10×, 30× and 50× occupy category centres 1, 2 and 3; pale vertical
  guides mark boundaries 0.5, 1.5, 2.5 and 3.5, matching the coverage-breadth panel.
- Marks: every exact observation is a filled circle connected by a straight solid
  segment within one platform–mapper series; mapper is not redundantly encoded.
- Final size: 88 × 48 mm.
