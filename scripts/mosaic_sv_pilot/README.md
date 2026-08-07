# Mosaic-SV pilot figures

Run:

```bash
Rscript scripts/mosaic_sv_pilot/mosaic_sv_pilot_figures.R
```

The script reads only `data/mosaic_sv_pilot.csv` and writes three independent
publication figures to `figures/codex_mosaic_sv_pilot/`:

1. SV-type proportion radar for minimap2;
2. SV-type proportion radar for winnowmap;
3. absolute VAF-bin stacked bars for all six platform-aligner workflows.

Radar spokes use a shared 0–60% scale and are never normalized independently.
All spokes use the same square-root radial transform, with tick labels retained
as the true proportions; this expands the 0–5% region occupied by rare DUP/INV
classes without changing their denominators.
The stacked bars retain absolute candidate counts; their two segments sum exactly
to each workflow's total. These are low-VAF candidate summaries without a truth
set, not precision/recall measurements or verified biological mosaic burdens.
