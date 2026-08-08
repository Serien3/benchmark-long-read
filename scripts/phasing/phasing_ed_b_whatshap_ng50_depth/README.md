# Extended Data b — WhatsHap NG50 depth response

This R-only task renders the WhatsHap phase-block NG50 depth-response panel specified
as Extended Data panel b. It retains all 18 platform–mapper–depth workflow outputs and
draws six raw trajectories without averaging, smoothing, fitted trends or uncertainty
bands.

Run from any working directory:

```bash
Rscript scripts/phasing/phasing_ed_b_whatshap_ng50_depth/phasing_ed_b_whatshap_ng50_depth.R
```

Outputs are written under `figures/phasing/phasing_ed_b_whatshap_ng50_depth/` as editable
SVG/PDF, 600-dpi TIFF/PNG, plotted Source Data, a filter audit, metric definition and
a render manifest.

Figure contract:

- Core conclusion: WhatsHap phase-block NG50 changes with depth in a
  platform-dependent manner across the complete matched design.
- Evidence role: independent validation of depth-dependent phasing continuity; values
  are not pooled or directly ranked with LongPhase.
- Archetype: one-row, two-panel quantitative depth-response small multiple.
- Metric: genome-normalized phase-block NG50 on a linear Mb scale.
- Statistics: none. Each point is one deterministic pipeline output; mapper outputs
  are not replicates and connecting segments are not fitted trends.
- Visual hierarchy: mapper identity is encoded spatially in independent `minimap2`
  and `winnowmap` regions; platform identity uses the manuscript-wide colors, solid
  lines and filled circles. Depths sit at three evenly spaced category centers.
- Final size: 88 × 48 mm.
