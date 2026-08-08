# QA — phasing main figure e

## Scientific contract

- Core claim: the fraction of heterozygous SVs assigned phased genotypes varies by
  platform, mapper and depth.
- Figure role: SV phasing-coverage evidence; it is intentionally separate from the
  Truvari F1 panel, which evaluates SV call-set detection agreement.
- Archetype: one-row, two-panel depth-response small multiple.
- Metric scope: phased heterozygous SV fraction only.
- Reviewer risk addressed: the panel does not call this fraction “SV phasing
  accuracy” and does not imply that the haplotype orientation is truth-validated.

## Data integrity and denominator checks

- All 18 source rows are retained: three platforms × two mappers × three depths.
- Every trajectory contains exactly the ordered 10×, 30× and 50× observations.
- All rows use HG002, GRCh38 and completed LongPhase workflows.
- Phased heterozygous SV (%) is recomputed as 100 × phased heterozygous SVs / all
  heterozygous SVs.
- The denominator is strictly positive in every row, and every numerator lies between
  zero and its corresponding denominator.
- Recomputed fractions agree with the rounded rates recorded in the source table.
- The complete observed range, 65.1436%–78.4769%, lies within the fixed 60%–82%
  linear display range.
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
  this panel retains its own numerator/denominator validation and linear bounds.
- Final size: 88 × 48 mm.
- Platform colours match the preceding panels; the assembled main figure supplies one
  shared legend.
- Mapper identity is spatial, with one independent plotting region per mapper; all
  exact observations use solid lines and filled circles.
- Depths occupy centres 1, 2 and 3 and pale guides occupy boundaries 0.5, 1.5, 2.5
  and 3.5. No display offset or redundant mapper encoding is used.
- Minimum configured text size is 6.0 pt; mapper titles are bold 7.2 pt.
- Nimbus Sans is used as the installed Arial-compatible fallback and is embedded in PDF.
- SVG and PDF retain editable text; TIFF and PNG are rendered at 600 dpi.
- Final-size raster inspection confirms that all 18 points, six trajectories, mapper
  titles, repeated depth axes and percentage scales are readable without clipping.
- Image-integrity fields are not applicable because the panel contains no source imagery.

## Automated preflight

Static preflight reports 11 passes, three warnings and no failures. The remaining
warnings are limited to native R parsing and physical width/DPI values stored in named
constants; these are checked directly against the generated outputs.
