# SV detection F1: caller × aligner workflow view

This R-only figure set displays the original SV detection `F1` values from the
GIAB v5.0q and CMRG benchmark tables.

- x axis: four callers under minimap2, followed by the same four callers under
  winnowmap;
- colour: sequencing platform (`BGI`, `ONT`, `HiFi`);
- each caller contains three equally spaced depth columns (`10x`, `30x`,
  `50x`); all three platforms share the same x coordinate within a depth
  column, while opacity redundantly encodes depth;
- line: ordered `10x -> 30x -> 50x` trajectory within each
  platform × caller × aligner workflow;
- metric: original `F1` only; neither `gt-F1` nor any refine field is used.

Run from the repository root:

```bash
Rscript scripts/sv_f1_caller_aligner/sv_f1_caller_aligner.R
```

Outputs are written to `figures/codex_sv_f1_caller_aligner/` as PNG, SVG, PDF,
and 600 dpi TIFF. The exact plotted rows, filter audit, and render manifest are
exported beside the figures.
