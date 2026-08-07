# SV genotype-F1 depth × workflow grid

Run:

```bash
Rscript scripts/codex/sv_gt_depth_workflow_grid/sv_gt_depth_workflow_grid.R
```

The script creates one 4 x 2 figure for GIAB v5.0q and one for CMRG:

- rows: cuteSV, Sniffles2, sawfish, SVDSS;
- columns: minimap2, winnowmap;
- x-axis: 10x, 30x, 50x;
- y-axis: original `gt-F1`;
- coloured trajectories: BGI, ONT, HiFi.

All eight workflow panels share one truth-set-level y-axis. GIAB uses 0.48-0.75
and CMRG uses 0.15-0.90; these ranges include every observation and are not
adapted by caller, aligner, platform, or depth. The first labelled tick remains
inset from the panel origin.

Outputs are written to `figures/codex_sv_gt_depth_workflow_grid/` as PNG, SVG,
PDF, and TIFF, together with the exact plotted data and audit manifests.
