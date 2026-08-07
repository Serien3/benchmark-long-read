# xTEA-long mobile-element insertion figure

Run from anywhere inside the repository:

```bash
Rscript scripts/me_xtea/me_xtea_paired_stacked.R
Rscript scripts/me_xtea/me_xtea_paired_stacked_composition.R
```

The script reads only `data/mobile_element_xtea.csv` and writes the single-panel
paired stacked-bar figure to `figures/codex_me_xtea/` in PNG, TIFF, SVG, and PDF
formats. The same output directory also contains plotted source data, a filter
audit, and a render manifest.

The `composition` script writes a separate 100% stacked version without
overwriting the absolute-count figure. It places all six workflows on one axis,
uses paired spacing for each platform, reports family percentages inside bars,
keeps absolute totals as `n=` labels, and directly labels the true-height HERV
cap.

Figure semantics:

- facets: sequencing platform;
- paired bars: aligner (`minimap2`, `winnowmap`);
- stacked segments: final merged ALU, LINE1, SVA, and HERV candidates;
- labels above bars: total merged MEI candidates.
- purple callouts: exact HERV counts, linked to the true-height HERV cap without
  changing its encoded size.

`Combined-only lines` is retained in the exported source data for auditing but is
not plotted because it is an intermediate combined-file count, not an additional
MEI family. The figure reports candidate yield and composition, not detection
accuracy; no truth set, replicate uncertainty, or inferential test is available in
this table.
