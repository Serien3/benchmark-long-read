# Phasing results manuscript draft

> **Editorial note:** `Fig. X` denotes the first phasing main figure, `Fig. Y` the second phasing main figure, and `Extended Data Fig. Z` the retained WhatsHap depth-response figure. Replace these placeholders after the manuscript-wide figure order is fixed. The text below is drafted as a Results section; the material after “Author notes” is not manuscript prose.

## Results

### Sequencing platforms occupy distinct phasing regimes under matched conditions

We benchmarked SNP and structural-variant (SV) phasing in HG002 across BGI, ONT and HiFi data at 10×, 30× and 50× sequencing depth. All datasets were aligned to GRCh38 with minimap2 and winnowmap. LongPhase provided the primary SNP–SV phasing analysis, with SNP accuracy assessed against the GIAB v5.0q phased-SNP truth set and SV calls evaluated against T2T-Q100 v1.1. A parallel WhatsHap workflow tested whether the main platform patterns persisted under an independent phasing procedure and enabled analysis of SNP-caller and haplotag dependencies (Fig. Xa).

At 30×, LongPhase separated long-range phase continuity from local phasing accuracy (Fig. Xb). BGI produced the longest phase blocks, with phase-block NG50 values of 1.70 Mb using minimap2 and 1.74 Mb using winnowmap. The corresponding values were 1.02 Mb for ONT with either mapper and 0.32–0.33 Mb for HiFi. HiFi phased the largest fraction of benchmark SNPs, reaching 99.59% with minimap2 and 99.45% with winnowmap, and had the lowest blockwise Hamming error at 0.50–0.61%. ONT phased 99.08–99.16% of benchmark SNPs with Hamming error of 1.41–1.59%. BGI phased 98.69–98.80% with Hamming error of 3.31–3.61%. Switch-error burdens remained low across all six workflows, ranging from 1.05 to 1.62 errors per 10,000 assessed pairs. These measurements placed BGI at the long-block end of the performance range and HiFi at the high-completeness, low-Hamming-error end.

### Depth produces platform-specific gains in continuity and accuracy

Increasing depth extended phase blocks at markedly different rates (Fig. Xc). With minimap2, BGI NG50 increased from 0.61 Mb at 10× to 1.70 Mb at 30× and 2.57 Mb at 50×; winnowmap gave a closely matched trajectory of 0.64, 1.74 and 2.52 Mb. ONT increased from 0.80–0.82 Mb at 10× to 1.19 Mb at 50×. HiFi remained shorter, increasing from 0.17 Mb to 0.37 Mb. BGI thus gained approximately 1.9 Mb of genome-normalized phase-block continuity between 10× and 50×, compared with gains of approximately 0.37–0.39 Mb for ONT and 0.20 Mb for HiFi.

The accuracy response followed a different pattern (Fig. Xd). ONT blockwise Hamming error fell from 10.94–11.12% at 10× to 1.41–1.59% at 30×, with 50× values of 1.17–1.55%. BGI showed a non-monotonic response, spanning 3.58–4.24% at 10×, 3.31–3.61% at 30× and 2.87–4.09% at 50×. HiFi remained below 0.7% at every depth and mapper combination, although its Hamming error rose gradually from 0.46–0.54% at 10× to 0.56–0.69% at 50×. Added coverage consequently affected phase-block length and blockwise accuracy through distinct platform-specific trajectories.

### SV phasing follows a ranking distinct from SNP phase continuity

The SV analysis yielded a different platform ordering from SNP phase-block NG50 (Fig. Xe). At 30×, the fraction of heterozygous SVs assigned a phased genotype was 76.79% for ONT and 76.73% for HiFi with minimap2, compared with 71.52% for BGI. Winnowmap produced lower phased fractions of 70.23%, 69.81% and 65.65%, respectively. Phased-SV fraction changed little or declined between 30× and 50×, indicating that additional depth beyond 30× did not provide a general increase in this yield measure.

Benchmark F1 improved most strongly from 10× to 30× (Fig. Xf). With minimap2, F1 increased from 0.679–0.722 at 10× to 0.754–0.786 at 30× across the three platforms, followed by a smaller increase to 0.758–0.791 at 50×. Winnowmap showed the same pattern, increasing from 0.668–0.709 to 0.749–0.771 and then to 0.754–0.774. HiFi achieved the highest 30× and 50× F1 with both mappers. ONT produced the largest phased heterozygous-SV fraction at 30×. The separation between phased-SV yield and benchmark F1 established distinct performance dimensions for SV phasing and SV call-set agreement.

### An independent WhatsHap workflow reproduces the continuity–accuracy separation

WhatsHap independently recovered the principal separation between long phase blocks and low blockwise error (Fig. Ya). At 30×, BGI phase-block NG50 reached 2.50–2.54 Mb, exceeding ONT at 1.56–1.59 Mb and HiFi at 0.615–0.616 Mb. The Hamming-error ordering ran in the opposite direction: HiFi achieved 1.68–2.16%, ONT 4.49–4.97% and BGI 7.35–7.51%. Phased heterozygous-SNV fraction depended strongly on mapper. Winnowmap yielded 99.48–99.73% across the three platforms, while minimap2 yielded 94.60% for ONT, 95.03% for BGI and 97.43% for HiFi. The switch-error burden supplied a separate accuracy view: HiFi recorded 6.89–7.80 errors per 10,000 assessed pairs, compared with 4.50–5.40 for BGI and ONT, so its low Hamming error did not translate into the lowest switch-error count in this workflow.

The full WhatsHap depth series reinforced the difference between continuity and local error (Extended Data Fig. Za,b). BGI NG50 increased from 0.92–0.95 Mb at 10× to 3.83–3.87 Mb at 50×, while ONT increased from 1.28–1.29 Mb to 1.98–2.02 Mb and HiFi from 0.36 Mb to 0.71 Mb. ONT Hamming error fell sharply from 16.09–16.59% at 10× to 4.49–4.97% at 30×, then reached 5.92–5.97% at 50×. BGI and HiFi showed modest increases in Hamming error over the same depth range. Independent phasing thus reproduced the platform separation in continuity and exposed metric-specific accuracy behavior.

### Mapper and SNP-caller choices shape phasing yield and downstream haplotype tagging

Changing the SNP caller produced large, platform-specific shifts in all three WhatsHap readouts at 30× (Fig. Yb). Relative to Clair3, DeepVariant reduced the phased heterozygous-SNV fraction by 20.5–38.6 percentage points across the six platform–mapper combinations. For BGI, DeepVariant increased NG50 from 2.50–2.53 Mb to 4.00–4.04 Mb and increased Hamming error from 7.35–7.51% to 20.45–20.53%. ONT NG50 decreased from 1.56–1.59 Mb to 1.20–1.21 Mb, accompanied by a reduction in Hamming error from 4.49–4.97% to 2.34–3.46%. HiFi NG50 decreased from 0.62 Mb to 0.41 Mb, while Hamming error remained within 1.67–2.25%. Caller effects were thus metric- and platform-specific, with continuity, phased-SNV yield and blockwise accuracy moving in different directions.

Mapper dependence persisted across the depth series (Fig. Yc). With minimap2, phased heterozygous-SNV fraction decreased between 10× and 50× from 96.53% to 94.56% for BGI, from 96.17% to 94.56% for ONT and from 98.61% to 96.61% for HiFi. Winnowmap maintained values between 99.45% and 99.74% across all platforms and depths. At 30×, the winnowmap-minus-minimap2 difference was 4.48 percentage points for BGI, 4.88 for ONT and 2.30 for HiFi. These paired trajectories identify mapper choice as a major determinant of the fraction of heterozygous SNVs incorporated into WhatsHap phase blocks.

The workflow differences extended to haplotag assignment yield (Fig. Yd). At 30×, the fraction of processed alignments assigned to H1 or H2 was highest for HiFi, at 59.08% with minimap2 and 66.10% with winnowmap. BGI reached 52.72% and 58.43%, respectively, while ONT reached 49.73% and 49.62%. These values changed by less than 1.3 percentage points from 10× to 50× within each platform–mapper workflow, indicating limited depth dependence over the tested range. H1/H2 ratios remained close to balance across all 18 combinations, ranging from 1.003 to 1.029. Platform and mapper influenced the proportion of alignments available for downstream haplotype-resolved analysis, while haplotype balance remained stable.

Collectively, the results define platform-specific phasing regimes whose apparent strengths depend on whether the objective is long-range continuity, local SNP accuracy, phased-SV yield, SV benchmark agreement or downstream haplotag recovery. The evidence is bounded to HG002 genomic DNA, GRCh38, the selected truth sets and the evaluated analysis workflows.

## Author notes

### Section outline

- Establish the matched HG002 design and the roles of LongPhase and WhatsHap.
- Resolve the 30× continuity–accuracy trade-off using the four-metric LongPhase profile.
- Track how depth changes phase-block continuity and Hamming error.
- Separate phased-SV yield from SV benchmark F1.
- Test whether WhatsHap reproduces the principal platform separation.
- Quantify caller and mapper dependence, then connect these effects to haplotag yield.
- Close with one bounded scope statement.

### Terminology ledger

| Canonical term | First-use definition | Usage decision |
|---|---|---|
| BGI | BGI long-read platform | Use `BGI` throughout; do not alternate with a technology nickname until the manuscript defines one |
| ONT | Oxford Nanopore Technologies platform | Define manuscript-wide at first occurrence, then use `ONT` |
| HiFi | PacBio HiFi platform | Use `HiFi` consistently |
| phase-block NG50 | Genome-normalized phase-block NG50 | Report in Mb |
| phased heterozygous-SNV fraction | Phased SNVs divided by heterozygous SNVs | Treat as phasing yield; accuracy is evaluated separately |
| blockwise Hamming error | Orientation-corrected blockwise disagreement against phased-SNP truth | Report as percentage |
| switch-error burden | Switch errors per 10,000 assessed pairs | Keep distinct from blockwise Hamming error |
| phased heterozygous-SV fraction | Phased SVs divided by heterozygous SVs | Treat as SV phasing yield |
| SV benchmark F1 | Truvari F1 against T2T-Q100 v1.1 | Treat as call-set agreement; phase direction is outside this metric |
| taggable alignment yield | H1- or H2-assigned alignments divided by processed alignments | Keep the observation unit as alignments |

### Claim–evidence map

| Claim | Evidence | Status |
|---|---|---|
| BGI produced the longest SNP phase blocks | LongPhase and WhatsHap NG50 at 30× and across depth | Supported |
| HiFi combined high phased-SNP completeness with low LongPhase Hamming error | LongPhase 30× phased rate and Hamming error | Supported |
| Depth effects differed among platforms and metrics | LongPhase NG50 and Hamming trajectories at 10×, 30× and 50× | Supported |
| SV phasing yield and benchmark F1 formed distinct rankings | LongPhase phased-SV fraction and Truvari F1 | Supported |
| WhatsHap reproduced the continuity–Hamming separation | WhatsHap 30× profile and depth-response panels | Supported |
| Mapper and caller choices materially altered WhatsHap outputs | Phased-SNV depth trajectories and Clair3–DeepVariant paired comparisons | Supported |
| Platform and mapper affected downstream haplotag recovery | H1+H2 assignment rates across all depths | Supported |

### Assumptions or missing inputs

- Figure identifiers `X`, `Y` and `Z` are placeholders pending manuscript-wide assembly.
- The prose uses `BGI` as the canonical platform label because the current figures and source tables use that name. Replace it manuscript-wide if a more specific technology name is selected.
- No inferential statistics are reported because each plotted value represents one deterministic workflow output for a single HG002 benchmark sample, with no biological or technical replicate series.
- Citations for LongPhase, WhatsHap, GIAB, Truvari, T2T-Q100, minimap2, winnowmap, Clair3 and DeepVariant should be inserted during manuscript-wide reference integration.

### Why this structure

- The section begins with the matched design and moves immediately to the central continuity–accuracy result.
- Depth and SV analyses extend the primary observation before the independent WhatsHap validation is introduced.
- Caller and mapper sensitivity precede haplotag yield, linking workflow choices to a downstream consequence.
- Metric boundaries and study scope are stated once at the end instead of interrupting each result paragraph.
