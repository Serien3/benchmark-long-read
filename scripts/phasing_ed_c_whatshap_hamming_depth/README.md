# Extended Data c — WhatsHap Hamming depth response

This R-only task renders the WhatsHap blockwise Hamming-error depth-response panel
specified as Extended Data panel c. It retains all 18 platform–mapper–depth outputs
and draws six raw trajectories without averaging, smoothing, fitted trends or
uncertainty bands.

Run from any working directory:

```bash
Rscript scripts/phasing_ed_c_whatshap_hamming_depth/phasing_ed_c_whatshap_hamming_depth.R
```

Outputs are written under `figures/phasing_ed_c_whatshap_hamming_depth/` as editable
SVG/PDF, 600-dpi TIFF/PNG, plotted Source Data, a filter audit, metric definition and
a render manifest.

Figure contract:

- Core conclusion: WhatsHap blockwise Hamming error changes non-uniformly with depth
  across platforms and mapper workflows.
- Evidence role: independent validation of local phasing accuracy and its workflow
  dependence; WhatsHap values are not pooled or directly ranked with LongPhase.
- Archetype: one-row, two-panel quantitative depth-response small multiple.
- Metric: `100 × Blockwise Hamming / Covered variants` on a log10 display scale.
- Statistics: none. Each point is one deterministic pipeline output; mapper outputs
  are not replicates and connecting segments are not fitted trends.
- Visual hierarchy: mapper identity is encoded spatially in independent `minimap2`
  and `winnowmap` regions; platform identity uses the manuscript-wide colors, solid
  lines and filled circles. Depths sit at three evenly spaced category centers.
- Final size: 88 × 48 mm.
