# SV precision-recall figures

Run from anywhere inside the repository:

```bash
Rscript scripts/codex/sv_pr_figures.R
```

The script generates eight independent caller-level PR figures: four callers
for each of the GIAB v5.0q and CMRG truth sets. Outputs are written under
`figures/codex_sv_pr/` as PNG, SVG, PDF, and TIFF.

## Encoding contract

- Platform: high-contrast reference palette (`BGI` orange `#FFB000`, `ONT`
  teal `#13A4A6`, `HiFi` purple `#9400D3`)
- Aligner: shape (`minimap2` circle, `winnowmap` diamond)
- Depth: high-contrast opacity (`10x` 0.18, `30x` 0.58, `50x` 1.00)
- Connected trajectory: depth order `10x -> 30x -> 50x` within each
  platform-by-aligner combination

Every panel contains exactly 18 source observations and six trajectories. Point
size is deliberately constant: sequencing depth is not encoded as bubble size.
Points are 2.15 mm, close to the supplied reference. Trajectories are rendered
as two explicit segments: the segment ending at 30x uses medium opacity and the
segment ending at 50x uses full opacity, so line strength increases with depth.
The current revision hides the in-panel legend and uses identical x/y limits,
breaks, and physical scaling so the precision-recall coordinate system is
square and symmetric. Each panel displays only the caller name as its title;
the truth set remains encoded in the output filename and render manifest.
The shared lower limit is calculated independently for each caller from the
union of its precision and recall values, producing a targeted magnification
without moving or transforming any point. The first labelled tick is inset
from the lower-left panel corner, matching the supplied reference style.

## Data scope

The symmetric main comparison uses GRCh38 and the four callers present in both
truth-set tables: `cuteSV`, `Sniffles2`, `sawfish`, and `SVDSS`. The GIAB-only
T2T-CHM13 rows and non-shared callers are excluded from this matched design.
The exact plotted rows and exclusion counts are exported with the figures.
