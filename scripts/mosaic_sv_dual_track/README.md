# Mosaic-SV stacked bars with VAF pies

Run from any location with:

```bash
Rscript scripts/mosaic_sv_dual_track/mosaic_sv_dual_track.R
```

The script reads the six matched 30× HG002 Sniffles2 mosaic-mode summaries and
overwrites one double-column publication figure plus its source-data and audit
files.

- Six absolute stacked bars report `DEL`, `INS`, `DUP`, `INV`, and `BND` counts.
- Six equal-size pies report the marginal `VAF 5–10%` and `VAF 10–20%`
  proportions for the corresponding workflow.
- Bars begin at zero and share one count axis.
- Pie size and vertical position carry no quantitative meaning; only wedge angle
  and the printed percentage encode VAF composition.
- The pies summarize all candidates in each bar. They do not imply an
  `SV type × VAF bin` joint distribution.

All workflows are retained in fixed design order. No result-based sorting,
uncertainty interval, hypothesis test, or truth-based performance interpretation
is applied.

