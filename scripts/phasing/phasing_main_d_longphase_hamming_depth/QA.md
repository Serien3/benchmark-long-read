# QA — phasing main figure d

## Scientific contract

- Core claim: local phasing consistency changes with sequencing depth in a
  platform- and mapper-dependent manner and is not uniformly monotonic.
- Figure role: local-accuracy depth evidence complementary to the NG50 continuity
  panel; it does not repeat the same scientific quantity.
- Archetype: one-row, two-panel depth-response small multiple.
- Metric scope: blockwise Hamming error only; switch error is retained as a separate
  metric because it answers a different phasing-accuracy question.
- Reviewer risk addressed: the log axis is explicit, all raw mapper outputs remain
  visible, and no trajectory is presented as a fitted trend.

## Data integrity and log guard

- All 18 source rows are retained: three platforms × two mappers × three depths.
- Every trajectory contains exactly the ordered 10×, 30× and 50× observations.
- All rows use HG002, GRCh38 and completed LongPhase workflows.
- Hamming error (%) is recomputed as 100 × blockwise Hamming errors / covered truth
  variants; reconstructed rates agree with the rounded source rates.
- All denominators are positive and all plotted percentages are strictly positive.
- The observed range is 0.4631%–11.1233%; therefore no pseudocount, clipping or
  zero-value exception is needed for the log10 axis.
- The major ticks are 0.5%, 1%, 2%, 5% and 10%, matching the design contract.
- No row is excluded, averaged, aggregated, smoothed or interpolated.
- Straight segments connect adjacent measured depths only.

## Statistics

- n definition: one deterministic workflow output per platform–mapper–depth combination.
- Biological replicates: not applicable; the benchmark sample is HG002.
- Technical replicates: none.
- Center statistic: none.
- Spread or interval: none.
- Statistical test: none.
- Multiple-comparison correction: not applicable.
- P-value display: none.
- Error bars: none; mapper outputs are not statistical replicates.

## Visual and render checks

- Backend: R only (`ggplot2`, `svglite`, `cairo_pdf`, `ragg`).
- Reuse level: structural adaptation of the coverage-breadth depth-panel grammar;
  metric transformation, source fields, bounds and log guards remain panel-specific.
- Final size: 88 × 48 mm.
- Platform colours match panels a–c; the assembled figure supplies one shared legend.
- Mapper identity is spatial: minimap2 and winnowmap occupy independent plotting
  regions, and all observations use solid lines and filled circles.
- Depths occupy centres 1, 2 and 3; pale guides occupy boundaries 0.5, 1.5, 2.5 and
  3.5. No display offset, jitter or duplicated mapper encoding remains.
- Minimum configured text size is 6.0 pt; mapper titles are bold 7.2 pt.
- Nimbus Sans is used as the installed Arial-compatible fallback and is embedded in PDF.
- SVG and PDF retain editable text; TIFF and PNG are rendered at 600 dpi.
- Final-size raster inspection confirms that all 18 points, six trajectories, five log
  ticks, both mapper titles and repeated depth axes are visible without clipping.
- Image-integrity fields are not applicable because the panel contains no source imagery.

## Automated preflight

Static preflight reports 11 passes, three warnings and no failures. The log-guard check
passes explicitly. Remaining warnings are limited to the validator requesting native R
parsing and not recognizing width/DPI held in named constants; those properties are
checked against the actual outputs.
