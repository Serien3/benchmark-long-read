# BGI SV refine sequencing-depth response

`sv_depth_gradient_bgi_reference_style.R` creates two independent caller-specific
figures for the reported 5–70× cuteSV and Sniffles2 BGI depth-gradient series.

- grey-blue bars with thin borders: refine Recall;
- grey line with brown diamonds: refine F1;
- an aligned lower region: refine delta F1 per 5x;
- both aligned regions display the same depth ticks; only the lower region carries
  the shared x-axis title;
- score values are labelled to three decimals and delta values to four decimals;
- classic black axes, no grid, and a right-side legend;
- 183 x 142 mm output so both aligned regions and their labels remain legible;
- numeric depth geometry is retained from 5× through 70× at 5× intervals;
- 90× observations are explicitly excluded from plotting, derived adjacent-depth
  calculations, and plotted source-data export by the user-defined reporting scope;
- 5x has no delta point because it has no preceding depth;
- refine Precision, FP, and FN remain in source data but are not plotted;
- no smoothing, interpolation, aggregation, imputation, or error bars are used.

Run from the repository root:

```bash
Rscript scripts/sv_depth_gradient_bgi/sv_depth_gradient_bgi_reference_style.R
```

Outputs are written to `figures/codex_sv_depth_gradient_bgi/` as PNG, SVG,
PDF, and 600 dpi TIFF, with plotted source data, a filter audit, and a render
manifest. Full output stems begin with `sv_depth_refine_reference_style_`.
Additional score-only outputs omit the delta region and begin with
`sv_depth_refine_score_only_`.
