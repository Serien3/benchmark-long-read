# Extended Data d — WhatsHap phased-SNV fraction across depth

This R-only task renders the WhatsHap phased heterozygous-SNV depth-response panel
specified as Extended Data panel d. It retains all 18 platform–mapper–depth outputs
and places the two mapper workflows in independent, equally sized plotting regions
without averaging.

Run from any working directory:

```bash
Rscript scripts/phasing/phasing_ed_d_whatshap_phased_snv_depth/phasing_ed_d_whatshap_phased_snv_depth.R
```

Outputs are written under `figures/phasing/phasing_ed_d_whatshap_phased_snv_depth/` as
editable SVG/PDF, 600-dpi TIFF/PNG, plotted Source Data, paired mapper differences,
a filter audit, metric definition and a render manifest.

Figure contract:

- Core conclusion: WhatsHap phased heterozygous-SNV yield changes with depth and
  differs between mapper workflows in all three platforms.
- Evidence role: independent reporting of phasing yield and mapper dependence; it is
  not a truth-validated accuracy metric and is not pooled with LongPhase.
- Archetype: one-row, two-panel quantitative depth-response small multiple.
- Metric: `100 × Phased SNVs / Het SNVs` on a linear 94–100% display range.
- Statistics: none. Each point is one deterministic pipeline output; mapper outputs
  are not replicates and connecting segments join adjacent measured depths only.
- Mapper differences remain available in the paired-difference audit table, but are
  not overprinted as cross-panel connectors.
- Final size: 88 × 48 mm.
