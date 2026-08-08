# Phasing main figure a — experimental logic

This R-only task renders the compact workflow panel specified as main figure panel a.
It reports the matched HG002 design, the LongPhase joint SNP–SV primary analysis,
and the WhatsHap SNP phasing/haplotag validation path. It intentionally contains no
platform ranking or quantitative result values.

Run from any working directory:

```bash
Rscript scripts/phasing/phasing_main_a_experimental_logic/phasing_main_a_experimental_logic.R
```

The script writes SVG, PDF, 600-dpi TIFF and 600-dpi PNG files plus source-data,
filter-audit, metric-definition and render-manifest CSVs under
`figures/phasing/phasing_main_a_experimental_logic/`.

Figure contract:

- Core conclusion: all platform comparisons arise from a matched HG002 design and
  are evaluated through separate LongPhase primary and WhatsHap validation paths.
- Archetype: schematic-led composite; this is the wide schematic panel.
- Role: establish the experimental system and metric vocabulary before quantitative
  comparison panels.
- Final size: 183 × 31 mm.
- Statistics: none; this panel encodes workflow structure only.
- Reviewer risk addressed: the SV phased fraction is separated from Truvari call-set
  F1, and haplotag yield is not presented as phasing accuracy.
