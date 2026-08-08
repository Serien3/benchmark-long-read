# Phasing main figure b — 30× LongPhase SNP profile

This R-only task renders the four-metric 30× LongPhase comparison specified as main
figure panel b. Four independent grouped-bar plots retain all three platforms and
both mappers as six raw workflow outputs per metric; mapper values are not averaged
or treated as replicates.

Run from any working directory:

```bash
Rscript scripts/phasing/phasing_main_b_longphase_30x_profile/phasing_main_b_longphase_30x_profile.R
```

Outputs are written under `figures/phasing/phasing_main_b_longphase_30x_profile/` as editable
SVG/PDF, 600-dpi TIFF/PNG, plotted Source Data, a filter audit, metric definitions and
a render manifest.

Figure contract:

- Core conclusion: at matched 30× depth, the three platforms occupy distinct but
  metric-dependent SNP phasing performance profiles.
- Archetype: one-row, four-panel grouped-bar grid; this is the main comparison panel.
- Evidence: phased benchmark SNP percentage, genome-normalized phase-block NG50,
  switch errors per 10,000 assessed pairs and blockwise Hamming error percentage.
- Statistics: none. Each bar is one deterministic pipeline output for one mapper;
  no biological replicates, averaging or inferential tests are present.
- Reviewer risk: the four metric denominators remain explicit, mapper outputs remain
  visible, and narrow-axis comparisons are labelled with their actual numeric scales.
- Layout: each metric plot has two mapper regions on the x axis and three fixed-colour
  platform bars per region. A single platform legend serves this panel and the
  mapper-separated depth panels in the assembled main figure.
- Axis policy: NG50, switch-error burden and Hamming error use zero baselines. Only
  phased benchmark SNP percentage uses a clearly ticked 98.5–100% window because all
  six values lie between 98.69% and 99.59%; bar lengths are compared within that
  metric only.
- Structural reuse: four independent narrow plotting regions, centred bold titles,
  pale mapper-boundary guides and borderless solid bars adapt the supplied reference.
- Bar rhythm: each mapper group uses a compact BGI–ONT–HiFi triplet with visibly
  wider bars and a fixed narrow inter-bar gap, matching the reference's grouped-bar
  density while accommodating three rather than two bars.
- Final size: 183 × 52 mm.
