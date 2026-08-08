# Extended Data f — WhatsHap haplotag yield

This R-only task renders the WhatsHap haplotag assignment-yield panel specified as
Extended Data panel f. It retains all 18 platform–mapper–depth outputs and draws six
raw trajectories without averaging, smoothing, fitted trends or uncertainty bands.

Run from any working directory:

```bash
Rscript scripts/phasing/phasing_ed_f_whatshap_haplotag_yield/phasing_ed_f_whatshap_haplotag_yield.R
```

Outputs are written under `figures/phasing/phasing_ed_f_whatshap_haplotag_yield/` as editable
SVG/PDF, 600-dpi TIFF/PNG, plotted Source Data, a filter audit, metric definition,
haplotype-balance audit and render manifest.

Figure contract:

- Core conclusion: the fraction of processed alignments assigned to H1 or H2 differs
  across platforms and mapper workflows and changes modestly with depth.
- Evidence role: downstream haplotag usability; it is not a truth-set phasing-accuracy
  metric and does not count unique reads.
- Archetype: one-row, two-panel quantitative depth-response small multiple.
- Metric: `100 × (H1 + H2) / alignments processed`.
- Statistics: none. Each point is one deterministic pipeline output; mapper outputs
  are not replicates and connecting segments are not fitted trends.
- Visual hierarchy: mapper identity is encoded spatially in independent `minimap2`
  and `winnowmap` regions; platform identity uses the manuscript-wide colors, solid
  lines and filled circles.
- Haplotype balance: H1/H2 ratios range from 1.0033 to 1.0287 and remain in Source
  Data rather than being rendered as a low-information 50/50 stacked chart.
- Final size: 88 × 48 mm.
