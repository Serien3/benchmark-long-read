# QA — phasing main figure f

## Scientific contract

- Core claim: SV call-set F1 changes strongly from 10× to 30× and comparatively
  little from 30× to 50×, with platform- and mapper-specific levels.
- Figure role: truth-set agreement of the SV call set; this evidence is distinct from
  the phased heterozygous genotype fraction in panel e.
- Archetype: one-row, two-panel depth-response small multiple.
- Metric scope: Truvari SV detection F1 against T2T-Q100 v1.1.
- Reviewer risk addressed: the panel does not label F1 as SV phasing orientation
  accuracy and keeps its truth set and benchmarking tool visible.

## Data integrity and metric reconstruction

- All 18 source rows are retained: three platforms × two mappers × three depths.
- Every trajectory contains exactly the ordered 10×, 30× and 50× observations.
- All rows use HG002, GRCh38, T2T-Q100 v1.1 SV truth and Truvari 5.1.1.
- TP-base, FP and FN are finite and non-negative; all precision and recall
  denominators are positive.
- Precision is recomputed as TP-base / (TP-base + FP).
- Recall is recomputed as TP-base / (TP-base + FN).
- F1 is recomputed as 2 × TP-base / (2 × TP-base + FP + FN).
- Recomputed precision, recall and F1 agree with the rounded source metrics.
- The observed F1 range, 0.6684–0.7912, is fully contained within the fixed
  0.65–0.81 linear axis.
- No row is excluded, averaged, aggregated, smoothed or interpolated.
- Straight segments connect adjacent measured depths only.

## Statistics

- n definition: one deterministic Truvari benchmark output per
  platform–mapper–depth combination.
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
  this panel independently reconstructs F1 and applies its own axis range.
- Final size: 88 × 48 mm.
- Platform colours match panels c–e; the assembled main figure supplies one shared
  platform legend.
- Mapper identity is spatial, with one independent plotting region per mapper; all
  observations use solid lines and filled circles.
- Depths occupy centres 1, 2 and 3 and pale guides occupy boundaries 0.5, 1.5, 2.5
  and 3.5. No display offset or redundant mapper encoding is used.
- Minimum configured text size is 6.0 pt; mapper titles are bold 7.2 pt.
- Nimbus Sans is used as the installed Arial-compatible fallback and is embedded in PDF.
- SVG and PDF retain editable text; TIFF and PNG are rendered at 600 dpi.
- Final-size raster inspection confirms that all 18 points, six trajectories, the
  highest 0.7912 point, mapper titles and repeated depth axes are unclipped.
- Image-integrity fields are not applicable because the panel contains no source imagery.

## Automated preflight

Static preflight reports 11 passes, three warnings and no failures. Remaining warnings
are limited to native R parsing and physical width/DPI stored in named constants; these
are verified directly against the generated files.
