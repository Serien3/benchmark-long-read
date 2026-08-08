# QA — phasing main figure b

## Scientific contract

- Core claim: under matched 30× HG002 conditions, platform differences are
  metric-dependent across SNP phasing coverage, long-range continuity and local
  phasing errors.
- Figure role: primary quantitative comparison; no overall platform score or winner
  is encoded.
- Archetype: one-row, four-panel grouped-bar grid with independent metric scales.
- Evidence hierarchy: all four metrics are co-primary because phased coverage, NG50,
  switch error and Hamming error answer distinct questions.
- Reviewer risk addressed: mapper outputs are exposed rather than averaged, and
  Hamming and switch errors are not treated as interchangeable measures.

## Source-data and transformation checks

- Both LongPhase source tables contain 18 rows and complete 3-platform × 2-mapper ×
  3-depth designs.
- The panel selects all six 30× combinations; the 12 excluded rows per table are the
  10× and 50× observations assigned to the separate depth-response panels.
- Join keys are unique and match one-to-one across platform, reference, mapper and
  depth.
- All selected rows use HG002, GRCh38 and completed workflows.
- Plotted values are recomputed as:
  - phased benchmark SNPs (%) = 100 × phased SNPs / benchmark SNPs;
  - phase-block NG50 (Mb) = recorded NG50 (kb) / 1,000;
  - switch errors per 10,000 assessed pairs = 10,000 × switch errors / assessed pairs;
  - blockwise Hamming error (%) = 100 × blockwise Hamming errors / covered variants.
- Recomputed rates agree with the rounded rates stored in the source tables.
- Source Data contains 24 plotted values from six unique workflow outputs.
- No rows are averaged, aggregated, smoothed or interpolated.

## Statistics

- n definition: one deterministic workflow output for each platform–mapper combination.
- Biological replicates: not applicable; the benchmark sample is HG002.
- Technical replicates: none.
- Center statistic: none.
- Spread or interval: none.
- Statistical test: none.
- Multiple-comparison correction: not applicable.
- P-value display: none.
- Error bars: none; the two mapper outputs are not treated as replicates.

## Visual and render checks

- Backend: R only (`ggplot2`, `svglite`, `cairo_pdf`, `ragg`).
- Final size: 183 × 52 mm.
- Reuse level: structural adaptation of the supplied four-panel bar-chart reference.
- Platform colours follow the locked manuscript palette. Mapper identity is spatial:
  minimap2 and winnowmap are the two x-axis regions in every metric plot.
- Each mapper region contains exactly three borderless bars in BGI, ONT and HiFi
  order. Fixed platform offsets −0.250, 0 and +0.250 replace automatic dodging;
  each bar is 0.200 category units wide, leaving a uniform 0.050-unit gap between
  adjacent bars. No averaging, connector or redundant mapper mark is used.
- Pale vertical guides mark the mapper-group boundaries at 0.5, 1.5 and 2.5; bars
  remain centred within the two regions and do not intersect the guides. Each compact
  triplet spans 0.700 category units and retains 0.150 units of clearance from both
  surrounding boundaries.
- Axis labels state every unit and denominator. NG50, switch-error burden and Hamming
  error start at zero. The phased-SNP panel alone uses the explicit 98.5–100% window;
  exact values and the window policy are exported in Source Data and
  `axis_window_audit.csv`.
- The phased-SNP truncated window is interpreted only within-panel and must not be
  used to compare bar lengths with another metric panel.
- No ideal region, threshold, value label, winner mark or rank annotation is added.
- Minimum configured text size is 5.8 pt; the main panel label is bold 8 pt and the
  four metric titles are bold 7 pt.
- Nimbus Sans is used as the installed Arial-compatible fallback and is embedded in PDF.
- SVG and PDF retain editable text; TIFF and PNG are rendered at 600 dpi.
- Final-size raster inspection confirms that all 24 bars, eight mapper groups, four
  metric titles, repeated axes and the shared platform legend are unclipped.
- Image-integrity fields are not applicable because the figure has no source imagery.

## Automated preflight

The static preflight reports 11 passes, three warnings and no failures. The warnings
are limited to the validator requesting native R parsing and not recognizing width/DPI
stored in named constants. Native `Rscript` parsing, PDF physical dimensions and the
actual 600-dpi raster devices are checked separately.
