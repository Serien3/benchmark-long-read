# Phasing figure delivery audit

Audit date: 2026-08-08  
Scope: all standalone panels specified in `docs/phasing_results_visualization_plan.md`  
Status: **complete — 12/12 panels delivered**

## Delivered panels

| Panel | Standalone figure | Final size (mm) | Evidence role | Status |
|---|---|---:|---|---|
| Main a | `phasing_main_a_experimental_logic` | 183 × 31 | Matched-design and analysis-path schematic | PASS |
| Main b | `phasing_main_b_longphase_30x_profile` | 183 × 52 | LongPhase four-metric grouped-bar profile at 30× | PASS |
| Main c | `phasing_main_c_longphase_ng50_depth` | 88 × 48 | LongPhase phase-block NG50 across depth | PASS |
| Main d | `phasing_main_d_longphase_hamming_depth` | 88 × 48 | LongPhase blockwise Hamming error across depth | PASS |
| Main e | `phasing_main_e_longphase_sv_phased_depth` | 88 × 48 | LongPhase phased heterozygous-SV fraction across depth | PASS |
| Main f | `phasing_main_f_longphase_sv_f1_depth` | 88 × 48 | LongPhase phased-SV benchmark F1 across depth | PASS |
| ED a | `phasing_ed_a_whatshap_30x_profile` | 183 × 52 | WhatsHap four-metric grouped-bar profile at 30× | PASS |
| ED b | `phasing_ed_b_whatshap_ng50_depth` | 88 × 48 | WhatsHap phase-block NG50 across depth | PASS |
| ED c | `phasing_ed_c_whatshap_hamming_depth` | 88 × 48 | WhatsHap blockwise Hamming error across depth | PASS |
| ED d | `phasing_ed_d_whatshap_phased_snv_depth` | 88 × 48 | WhatsHap phased heterozygous-SNV fraction across depth | PASS |
| ED e | `phasing_ed_e_whatshap_caller_sensitivity` | 183 × 60 | WhatsHap input-caller sensitivity at 30× | PASS |
| ED f | `phasing_ed_f_whatshap_haplotag_yield` | 88 × 48 | WhatsHap haplotag assignment yield across depth | PASS |

Each panel has a dedicated R script under `scripts/<figure_id>/` and a matching delivery directory under `figures/<figure_id>/`. No composite manuscript figure was generated.

## Reproducibility and export audit

- All 12 R scripts were rerun from the current repository data and completed successfully.
- Native R parsing passed for 12/12 scripts.
- Nature-figure static validation reported **0 failures** for every panel. The remaining warnings are parser limitations for named export arguments/native R syntax; the corresponding properties were verified from the actual outputs and manifests.
- Every panel contains SVG, PDF, 600-dpi TIFF and 600-dpi PNG exports plus `render_manifest.csv`.
- Manifest file existence, byte count, MD5 checksum, format, dimensions, DPI and editable-vector flags passed for 12/12 panels.
- All 12 PDFs contain embedded font subsets; all SVGs retain live text. The declared family is Nimbus Sans throughout.
- Every panel includes README and QA documentation. Quantitative and schematic deliveries include plotted source data, filter audit and metric-definition records; ED f additionally includes a haplotype-balance audit.

## Data-integrity and visual-grammar audit

- Experimental values are read only from the necessary structured CSV files in `data/`; no new benchmark results were inferred or substituted.
- LongPhase primary results and WhatsHap validation results remain explicitly separated; no cross-workflow pooling or overall ranking is used.
- Main b and the structurally matched ED a use four-panel grouped-bar designs with
  raw workflow values; no radar chart, heatmap, dual y-axis, significance annotation
  or aggregate rank is present.
- Platform colors are fixed across all panels: BGI `#FFB000`, ONT `#13A4A6`, HiFi `#9400D3`.
- Mapper encoding is fixed by layout context: shared-coordinate comparisons use
  minimap2 solid/filled and winnowmap dashed/open; revised depth-response panels
  Main c–f and ED b–d/f separate mappers spatially and use the same
  solid-line/filled-circle platform marks in both regions.
- Current PNGs for all 12 panels were inspected at final state. No clipping, label collision, data occlusion or legend intrusion was observed.
- The figures are R-only and remain standalone, one panel per export, as required.

## Delivery locations

- Figure sources: `scripts/phasing_*`
- Final exports and audit artifacts: `figures/phasing_*`
- Visualization specification: `docs/phasing_results_visualization_plan.md`
