# 30× SV precision–recall landscape

This R-only script creates the two independent plots planned for panel c of
the SV Results figure.

```bash
Rscript scripts/sv_pr_30x_landscape/sv_pr_30x_landscape.R
```

Outputs are written to `figures/sv_pr_30x_landscape/` as two independent figure
sets: `sv_pr_30x_T2TQ100` and `sv_pr_30x_CMRG`. Each is exported as editable
SVG/PDF, 600 dpi TIFF, and a 320 dpi PNG preview. No legend is drawn at this
stage. The exact plotted rows, filter audit, and render manifest are exported
beside the figures.

## Data contract

- Truth contexts: HG002 T2T-Q100 v1.1 and GIAB CMRG
- Reference: GRCh38
- Depth: 30× only
- Platforms: BGI, ONT, HiFi
- Aligners: minimap2, winnowmap
- Callers: cuteSV, Sniffles2, sawfish, SVDSS
- Metrics: raw precision, recall, and F1
- Observations: 24 per truth context, 48 total

The previously mislabeled GIAB v5.0q SV table is not used. T2T-Q100 is read
from `data/sv_benchmark_T2TQ100.csv`.

## Encoding

- x: Recall
- y: Precision
- platform: outline colour
- caller: point shape
- aligner: solid (`minimap2`) versus hollow (`winnowmap`) interior
- depth opacity: not used, because depth is fixed at 30×
- legend: intentionally omitted for later manuscript-level assembly

The two truth contexts use independently calculated, symmetric PR windows.
This preserves the compact T2T cluster and the full CMRG low-precision failure
range without moving or transforming any point. Axis limits are exported in
the render manifest and must be considered when comparing the panels.
