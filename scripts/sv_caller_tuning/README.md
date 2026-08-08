# SV caller tuning supporting figures

This workflow draws 11 stand-alone supporting figures for cuteSV and Sniffles2.
It reads only tables extracted directly from `最新数据评测.xlsx`; every extracted
row retains its workbook sheet and row number.

Run from the repository root:

```bash
python3 scripts/sv_caller_tuning/extract_tuning_from_xlsx.py
Rscript scripts/sv_caller_tuning/sv_caller_tuning_support.R
```

Outputs are written to `figures/SV_benchmark/caller_tuning/` as editable SVG and
PDF, 600 dpi TIFF, and 300 dpi PNG preview. The four cuteSV factorial atlases use
shared limits within raw and refined pairs. No result is ranked, starred, smoothed,
interpolated, or aggregated.

The workbook-labelled cuteSV HiFi table is shown with that provenance wording.
The incomplete refined series (missing HiFi-specific 50x) is not plotted. Its five
available rows and the four-row CMRG table remain in `data/caller_tuning_xlsx/`.
