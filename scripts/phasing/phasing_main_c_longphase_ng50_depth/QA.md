# QA — phasing main figure c

## Scientific contract

- Core claim: LongPhase phase-block NG50 changes with depth in a
  platform-dependent manner across the complete matched design.
- Figure role: depth-response evidence that cannot be recovered from the 30× profile.
- Archetype: one-row, two-panel depth-response small multiple.
- Metric scope: genome-normalized phase-block NG50 only; N50, maximum block length,
  block count and phased SNP rate remain in Source Data or other reporting layers.
- Reviewer risk addressed: both mapper trajectories remain visible, and connected
  observations are not described as fitted or inferential trends.

## Data integrity

- All 18 source rows are retained: three platforms × two mappers × three depths.
- Every trajectory contains exactly the ordered 10×, 30× and 50× observations.
- All rows use HG002, GRCh38 and completed LongPhase workflows.
- Plotted NG50 in Mb is calculated exactly as recorded NG50 in kb divided by 1,000.
- No row is excluded, averaged, aggregated, smoothed or interpolated.
- Straight segments connect adjacent measured depths only.
- The linear y-axis starts at zero and spans the complete 0.1698–2.5653 Mb range.

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
- Final size: 88 × 48 mm.
- Structural reuse: the coverage-breadth depth-panel grammar is retained, with two
  independent mapper plotting regions, centred titles and repeated depth axes.
- Platform colours match panels a and b. The assembled main figure supplies one
  shared platform legend, as in the reference depth-panel row.
- Mapper identity is spatial: minimap2 and winnowmap each occupy one plotting region;
  all exact observations therefore use solid lines and filled circles.
- Depths map to category centres 1, 2 and 3, while four pale vertical guides remain at
  boundaries 0.5, 1.5, 2.5 and 3.5. No point lies on a guide and no display offset is used.
- Minimum configured text size is 6.0 pt; mapper titles are bold 7.2 pt.
- Nimbus Sans is used as the installed Arial-compatible fallback and is embedded in PDF.
- SVG and PDF retain editable text; TIFF and PNG are rendered at 600 dpi.
- Final-size raster inspection confirms that all 18 points and six trajectories are
  visible and that both mapper titles, repeated depth axes and y scales are not clipped.
- Image-integrity fields are not applicable because the panel contains no source imagery.

## Automated preflight

Static preflight reports 11 passes, three warnings and no failures. The warnings are
limited to the validator requesting native R parsing and not recognizing physical
width/DPI stored in named constants. Native R parsing, device dimensions, embedded
fonts and actual raster resolution are checked separately.
