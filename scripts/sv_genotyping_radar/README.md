# Caller-level SV radar figures

This directory contains the production radar implementation. It deliberately
contains no simulated values; the style-only demonstration is isolated under
`try/`.

## Input contract

The normalized CSV must contain:

| column | role |
|---|---|
| `benchmark` | truth-set identifier; optional, defaults to `benchmark` |
| `truth_set` | displayed truth-set label; optional |
| `reference` | displayed reference label; optional |
| `metric` | radial metric label; optional, defaults to `Performance` |
| `caller` | one output figure per caller and benchmark |
| `platform` | exactly `BGI`, `ONT`, or `HiFi` |
| `aligner` | exactly `minimap2` or `winnowmap` |
| `depth` | exactly `10x`, `30x`, or `50x` |
| `value` | untransformed proportion in `[0, 1]` |

Each caller/benchmark panel must contain exactly 18 rows. The three platform
profiles each contain six vertices: 10x, 30x, and 50x crossed with the two
aligners.

## Run

```bash
Rscript scripts/codex/sv_genotyping_radar/sv_genotyping_radar.R \
  normalized_input.csv [output_directory] [full|adaptive]
```

The script produces independent PNG, SVG, PDF, and TIFF figures plus the exact
plotted source data and a render manifest.

`full` keeps a common 0-100% radial axis. `adaptive` uses an explicitly labelled
caller-level truncated radial range with real percentage ticks and white line
halos; it is intended for resolving small platform differences. Polygon areas
must not be compared across adaptive panels because their radial ranges differ.

### Run the official GIAB v5.0q and CMRG data

```bash
Rscript scripts/codex/sv_genotyping_radar/prepare_actual_gt_f1.R
Rscript scripts/codex/sv_genotyping_radar/sv_genotyping_radar.R \
  figures/codex_sv_genotyping_radar/normalized_gt_f1.csv \
  figures/codex_sv_genotyping_radar
```

The preparation step selects GRCh38, the four callers shared by both truth
sets, all three platforms, both aligners, and 10x/30x/50x. The plotted radial
metric is the original `gt-F1`; no `refine` field is used.

## Visual contract

- Radar geometry follows the supplied references: clockwise axes from the top,
  straight polygonal 20% contours, horizontal labels, and a bottom legend.
- Platform colours are identical to the SV PR figures: BGI `#FFB000`, ONT
  `#13A4A6`, and HiFi `#9400D3`.
- The six axes directly encode depth-by-aligner combinations, so no additional
  aligner line type or point shape is needed. Vertices have no point markers.
- Compact axis labels use `MM2` for minimap2 and `WM` for winnowmap.
- Values are plotted on the original 0-1 scale; no per-axis normalization is
  allowed because it would distort cross-platform differences.
- No error bars are drawn unless a future source table contains a defensible
  uncertainty definition. The current benchmark values are point estimates.
