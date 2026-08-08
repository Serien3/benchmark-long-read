# QA — phasing main figure a

## Scientific contract

- Core claim: the platform comparison is built on 18 matched HG002
  platform–mapper–depth combinations and two explicitly separated phasing paths.
- Evidence role: experimental-system definition; no performance conclusion or result
  value is encoded.
- Primary path: alignment BAM, Clair3 heterozygous biallelic SNPs and Sniffles2 SVs
  carrying read names feed LongPhase joint SNP–SV phasing.
- Validation path: alignment BAM and Clair3 SNP VCF feed WhatsHap SNP phasing,
  GIAB comparison and haplotag analysis.
- Interpretation guard: SV phased fraction and Truvari F1 remain separate concepts;
  haplotag yield is not labelled as accuracy.

## Data integrity

- The schematic has 13 workflow records and no quantitative observations.
- No workflow record was omitted, aggregated, interpolated or statistically summarized.
- The six primary phasing/result tables each contain 18 unique matched combinations.
- The caller-sensitivity table contains 18 Clair3 rows and six 30× DeepVariant rows.
- Cross-table platform–mapper–depth keys match within the LongPhase and WhatsHap
  evidence families.
- Phased SNP rate, switch error rate, Hamming rate, SV phased rate and haplotag rate
  were independently recomputed from their recorded numerators and denominators and
  agree within the precision stored in the source tables.

## Render and visual checks

- Backend: R only (`grid`, `svglite`, `cairo_pdf`, `ragg`).
- Final dimensions: 183 × 31 mm; the small increase over the 28 mm design estimate
  preserves a 5.0 pt minimum text size without changing the planned full-width role.
- Typeface: Nimbus Sans, the installed Arial-compatible fallback; embedded in PDF.
- Panel label: bold lowercase `a`, 8 pt.
- Platform identity uses the locked BGI/ONT/HiFi colours; mapper identity also uses
  solid versus dashed line style and therefore does not rely on colour.
- SVG and PDF retain editable text; TIFF and PNG are exported at 600 dpi.
- Final-size raster inspection: no clipping, overlap, broken arrows or illegible labels.
- Statistics and image-integrity fields are not applicable because the panel contains
  neither quantitative inference nor source imagery.

## Automated preflight

The static source preflight reports 10 passes, four warnings and no failures. The
warnings are parser limitations for a low-level `grid` script: text sizes, width and
DPI are held in named variables and helper calls rather than the patterns recognized
by the validator. R parsing, actual device dimensions, 600-dpi device calls and the
final-size output were checked directly.
