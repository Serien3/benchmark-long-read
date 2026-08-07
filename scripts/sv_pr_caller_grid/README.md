# Platform-centred SV PR caller grid

Run:

```bash
Rscript scripts/codex/sv_pr_caller_grid/sv_pr_caller_grid.R
```

The script creates two independent 2 x 2 figures, one for GIAB v5.0q and one
for CMRG. Caller is shown as a facet so that platform performance can be tested
for workflow robustness without overlaying all 72 observations on one axis.

## Encoding

- Platform: BGI orange `#FFB000`, ONT teal `#13A4A6`, HiFi purple `#9400D3`.
- Aligner: minimap2 circle, winnowmap diamond.
- Depth: 10x/30x/50x use alpha 0.18/0.58/1.00.
- Lines: matched depth trajectories within platform and aligner.
- Facets: cuteSV, Sniffles2, sawfish, SVDSS.

All four caller panels within a truth set use identical precision and recall
limits, breaks, and physical 1:1 scaling. The first labelled tick is inset from
the panel corner, matching the established SV PR style. The input values are
the original precision and recall columns; no refine values are used.

Outputs are written to `figures/codex_sv_pr_caller_grid/` as PNG, SVG, PDF,
and TIFF, together with the exact plotted source rows and audit manifests.
