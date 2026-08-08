# 长读长测序平台评测：论文可视化与 Results 草稿

本仓库面向 HG002 长读长测序平台评测的科研可视化与论文写作。当前已经形成三个主要实验模块：`reads_alignment_qc`、`SV_benchmark` 和 `phasing`。三者在论文中的总体关系为：

> **输入 reads 与比对基线 → 结构变异检测及流程依赖 → SNP/SV 相位与单倍型可用性**

## 总览

| 实验模块 | 论文中的任务 | 正文组图规划 | 设计文档 | Results 草稿 |
|---|---|---|---|---|
| `reads_alignment_qc` | 建立公平比较所需的输入与比对基线 | 1张正文组图，默认a–d | [组图与叙事计划](docs/reads-alignment-qc-figure-plan.md) | [Results草稿](docs/reads-alignment-qc-results.md) |
| `SV_benchmark` | 比较SV检测表现、深度响应和特殊SV候选谱 | 1张a–i正文大组图 | [组图与叙事计划](docs/sv-results-figure-plan.md) | [Results草稿](docs/sv-benchmark-results.md) |
| `phasing` | 比较SNP/SV相位连续性、准确性和下游可用性 | 2张正文组图 + 1张精简Extended Data | [组图与叙事计划](docs/phasing_results_visualization_plan.md) | [Results草稿](docs/phasing_results.md) |

## 1. Reads 与 alignment QC

### 正文组图

图题：

> **Depth-controlled long-read sequencing reveals distinct read profiles and reference-dependent coverage breadth**

默认正文组图由四个 panel 构成：

```text
┌── a  Approximate input depth ──┬── b  30× integrated read profile ──┐
├────────────── c  Reference-base coverage breadth ──────────────────┤
├────────────── d  30× primary mapped-read rate ─────────────────────┤
└─────────────────────────────────────────────────────────────────────┘
```

- **a** 核验三个平台在10×、30×和名义50×层级的实际输入深度。
- **b** 在严格匹配的30×层级报告read length、reported read Q-score和mean-Q>20组成。
- **c** 作为hero panel，完整报告三平台 × 三深度 × 两参考 × 两aligner的reference-base coverage breadth。
- **d** 报告30×条件下的primary mapped-read rate，补充read-level retention证据。
- BAM output footprint已独立出图，默认放入Extended Data；**版面和正文任务允许时可作为可选panel e**。

详细设计、指标定义和组图尺寸见[reads/alignment QC组图计划](docs/reads-alignment-qc-figure-plan.md)。

### 已完成可视化

| 可视化 | 论文定位 | 结果目录 | 脚本目录 |
|---|---|---|---|
| Approximate input depth | 正文a：输入剂量与嵌套下采样 | [figures/reads_alignment_qc/panel_a_input_depth](figures/reads_alignment_qc/panel_a_input_depth/) | [scripts/reads_alignment_qc/panel_a_input_depth](scripts/reads_alignment_qc/panel_a_input_depth/) |
| 30× integrated read profile | 正文b：read length与reported Q组成 | [figures/reads_alignment_qc/panel_b_read_profile](figures/reads_alignment_qc/panel_b_read_profile/) | [scripts/reads_alignment_qc/panel_b_read_profile](scripts/reads_alignment_qc/panel_b_read_profile/) |
| Reference-base coverage breadth | 正文c：reference、depth与aligner响应 | [figures/reads_alignment_qc/panel_c_coverage_breadth](figures/reads_alignment_qc/panel_c_coverage_breadth/) | [scripts/reads_alignment_qc/panel_c_coverage_breadth](scripts/reads_alignment_qc/panel_c_coverage_breadth/) |
| 30× primary mapped-read rate | 正文d：read-level mapping retention | [figures/reads_alignment_qc/panel_d_primary_mapped_rate](figures/reads_alignment_qc/panel_d_primary_mapped_rate/) | [scripts/reads_alignment_qc/panel_d_primary_mapped_rate](scripts/reads_alignment_qc/panel_d_primary_mapped_rate/) |
| 30× BAM output footprint | 默认Extended Data，可选正文e | [figures/reads_alignment_qc/panel_e_bam_footprint](figures/reads_alignment_qc/panel_e_bam_footprint/) | [scripts/reads_alignment_qc/panel_e_bam_footprint](scripts/reads_alignment_qc/panel_e_bam_footprint/) |
| Apparent alignment-error spectrum pilot | Extended Data：GIAB-masked局部alignment residual | [figures/reads_alignment_qc/extended_data_error_spectrum_pilot](figures/reads_alignment_qc/extended_data_error_spectrum_pilot/) | [scripts/reads_alignment_qc/extended_data_error_spectrum_pilot](scripts/reads_alignment_qc/extended_data_error_spectrum_pilot/) |

### Results叙述闭环

> **输入剂量是否匹配 → 匹配产量下的read信息结构 → 比对后的reference覆盖与read保留 → 为下游分析建立解释基线**

正文先确认10×和30×的对称输入，再报告平台间read length与reported Q-score组成差异；随后展示这些差异经过统一比对后在GRCh38上接近收敛、在T2T-CHM13上保留更强分化，并用primary mapped-read rate补足read-level证据。结尾将这些观测限定为后续SV、phasing和assembly结果的输入背景，不形成平台综合排名。

完整英文Results见[docs/reads-alignment-qc-results.md](docs/reads-alignment-qc-results.md)。

## 2. Structural variant benchmark

### 正文组图

图题：

> **Workflow- and depth-dependent structural variant detection and candidate profiles across long-read platforms**

SV部分规划为一张a–i正文大组图：

```text
┌──────── a  T2T-Q100 detection F1 ────────┬── b  CMRG detection F1 ──┐
├── c  T2T-Q100 30× PR ─┬── d  CMRG 30× PR ─┬── e  TP/FN/FP counts ──┤
├──────── f  BGI depth: cuteSV ────────────┬── g  BGI depth: Sniffles2 ┤
├──────────── h  Low-VAF SV candidates ────┬── i  MEI composition ─────┤
└───────────────────────────────────────────────────────────────────────┘
```

- **a–b** 完整展示T2T-Q100与CMRG中的caller–aligner detection F1轨迹。
- **c–d** 用30× Precision–Recall landscape展开F1的直接数据构成。
- **e** 用cuteSV与Sniffles2的TP-base、FN、TP-call和FP绝对数量连接PR比例与benchmark记录。
- **f–g** 展示BGI 5×–70×密集深度梯度下两个caller的refined recall和refined F1。
- **h–i** 分别报告low-VAF SV和移动元件插入候选的数量与组成。
- caller调参、GT-F1、其它深度PR和深度增量视图进入支持材料。

详细设计、数据口径和支持材料安排见[SV组图与叙事计划](docs/sv-results-figure-plan.md)。

> **组图前必须校正：** `sv_f1_caller_aligner`目录中现有`sv_detection_f1_GIAB5`不能作为正文panel a。全基因组检测F1必须从`data/sv_benchmark_T2TQ100.csv`重新绘制，不能只替换标题。

### 已完成可视化

| 可视化 | 论文定位 | 结果目录 | 脚本目录 |
|---|---|---|---|
| Caller × aligner detection F1 | 正文a–b；CMRG可用，T2T-Q100 panel a待按正确源表重绘 | [figures/SV_benchmark/sv_f1_caller_aligner](figures/SV_benchmark/sv_f1_caller_aligner/) | [scripts/sv_f1_caller_aligner](scripts/sv_f1_caller_aligner/) |
| SV Precision–Recall landscape | 正文c–d使用30× inset；10×与50×版本用于支持材料 | [figures/SV_benchmark/sv_pr_30x_landscape](figures/SV_benchmark/sv_pr_30x_landscape/) | [scripts/sv_pr_30x_landscape](scripts/sv_pr_30x_landscape/) |
| TP/FN/FP benchmark accounting donuts | 正文e：T2T-Q100、30×、minimap2、2 callers × 3平台 | [figures/SV_benchmark/sv_benchmark_accounting_donut](figures/SV_benchmark/sv_benchmark_accounting_donut/) | [scripts/sv_benchmark_accounting_donut](scripts/sv_benchmark_accounting_donut/) |
| BGI SV depth gradient | 正文f–g使用score-only版本；含cuteSV与Sniffles2完整5×–70×轨迹 | [figures/SV_benchmark/sv_depth_gradient_bgi](figures/SV_benchmark/sv_depth_gradient_bgi/) | [scripts/sv_depth_gradient_bgi](scripts/sv_depth_gradient_bgi/) |
| Low-VAF/mosaic SV candidate landscape | 正文h：六个workflow的SV类型计数与VAF组成 | [figures/SV_benchmark/mosaic_sv_dual_track](figures/SV_benchmark/mosaic_sv_dual_track/) | [scripts/mosaic_sv_dual_track](scripts/mosaic_sv_dual_track/) |
| xTEA-long MEI candidate composition | 正文i使用100% composition版本；绝对计数版用于支持材料 | [figures/SV_benchmark/me_xtea](figures/SV_benchmark/me_xtea/) | [scripts/me_xtea](scripts/me_xtea/) |
| cuteSV与Sniffles2参数敏感性 | 支持材料：cuteSV factorial/targeted scans、Sniffles2矩阵和跨深度验证 | [figures/SV_benchmark/caller_tuning](figures/SV_benchmark/caller_tuning/) | [scripts/sv_caller_tuning](scripts/sv_caller_tuning/) |

### Results叙述闭环

> **总体workflow表现 → 30× PR与原始计数分解 → caller特异的深度响应 → 特殊SV任务中的候选输出 → 统一解释边界**

正文先用T2T-Q100和CMRG说明平台表现随caller、aligner和benchmark context变化，再由30× PR与TP/FN/FP记录解释F1差异的来源。BGI密集深度梯度检验增加深度后的caller响应，支持材料中的调参结果说明参数敏感性。最后以low-VAF SV和MEI候选谱扩展任务范围，同时明确无独立truth set的候选数量不等同于灵敏度或准确率。

完整英文Results见[docs/sv-benchmark-results.md](docs/sv-benchmark-results.md)。

## 3. Phasing

### 正文组图

Phasing部分规划为两张正文主图和一张精简Extended Data。

正文主图1建议题目：

> **Sequencing platforms exhibit distinct trade-offs between phasing continuity and accuracy**

```text
┌──────────────── a  Experimental logic ────────────────┐
├────────────── b  30× LongPhase SNP profile ──────────┤
├── c  NG50 vs depth ──┬── d  Hamming error vs depth ──┤
├── e  SV phased rate ─┼── f  SV benchmark F1 ─────────┤
└───────────────────────────────────────────────────────┘
```

正文主图2建议题目：

> **Workflow choices shape SNP phasing robustness and downstream haplotype-tagging yield**

```text
┌──────────── a  30× WhatsHap profile ────────────┐
├──────── b  Clair3–DeepVariant sensitivity ──────┤
├── c  Phased-SNV fraction ─┬── d  Haplotag yield ┤
└──────────────────────────────────────────────────┘
```

**空间允许还是排版在一张大图中**

精简Extended Data保留WhatsHap NG50与Hamming error的完整深度轨迹。详细科学问题、指标分工和组图版式见[phasing可视化与叙事计划](docs/phasing_results_visualization_plan.md).

### 已完成可视化

#### 正文主图1：LongPhase核心结果

| Panel | 可视化 | 结果目录 | 脚本目录 |
|---|---|---|---|
| a | 对称实验设计与LongPhase/WhatsHap分析路径 | [figures/phasing/phasing_main_a_experimental_logic](figures/phasing/phasing_main_a_experimental_logic/) | [scripts/phasing/phasing_main_a_experimental_logic](scripts/phasing/phasing_main_a_experimental_logic/) |
| b | 30× LongPhase四指标SNP phasing profile | [figures/phasing/phasing_main_b_longphase_30x_profile](figures/phasing/phasing_main_b_longphase_30x_profile/) | [scripts/phasing/phasing_main_b_longphase_30x_profile](scripts/phasing/phasing_main_b_longphase_30x_profile/) |
| c | LongPhase phase-block NG50深度响应 | [figures/phasing/phasing_main_c_longphase_ng50_depth](figures/phasing/phasing_main_c_longphase_ng50_depth/) | [scripts/phasing/phasing_main_c_longphase_ng50_depth](scripts/phasing/phasing_main_c_longphase_ng50_depth/) |
| d | LongPhase blockwise Hamming error深度响应 | [figures/phasing/phasing_main_d_longphase_hamming_depth](figures/phasing/phasing_main_d_longphase_hamming_depth/) | [scripts/phasing/phasing_main_d_longphase_hamming_depth](scripts/phasing/phasing_main_d_longphase_hamming_depth/) |
| e | LongPhase phased heterozygous-SV fraction | [figures/phasing/phasing_main_e_longphase_sv_phased_depth](figures/phasing/phasing_main_e_longphase_sv_phased_depth/) | [scripts/phasing/phasing_main_e_longphase_sv_phased_depth](scripts/phasing/phasing_main_e_longphase_sv_phased_depth/) |
| f | LongPhase SV benchmark F1深度响应 | [figures/phasing/phasing_main_f_longphase_sv_f1_depth](figures/phasing/phasing_main_f_longphase_sv_f1_depth/) | [scripts/phasing/phasing_main_f_longphase_sv_f1_depth](scripts/phasing/phasing_main_f_longphase_sv_f1_depth/) |

**a 图若保留，仍需后续手绘**

#### 正文主图2：独立验证、流程敏感性与下游可用性

以下目录保留早期`phasing_ed_*`命名；根据当前计划，其中a、d、e和f已提升为正文主图2的四个panel。

| 正文panel | 可视化 | 结果目录 | 脚本目录 |
|---|---|---|---|
| a | 30× WhatsHap四指标独立验证 | [figures/phasing/phasing_ed_a_whatshap_30x_profile](figures/phasing/phasing_ed_a_whatshap_30x_profile/) | [scripts/phasing/phasing_ed_a_whatshap_30x_profile](scripts/phasing/phasing_ed_a_whatshap_30x_profile/) |
| b | Clair3–DeepVariant caller敏感性 | [figures/phasing/phasing_ed_e_whatshap_caller_sensitivity](figures/phasing/phasing_ed_e_whatshap_caller_sensitivity/) | [scripts/phasing/phasing_ed_e_whatshap_caller_sensitivity](scripts/phasing/phasing_ed_e_whatshap_caller_sensitivity/) |
| c | WhatsHap phased heterozygous-SNV fraction深度响应 | [figures/phasing/phasing_ed_d_whatshap_phased_snv_depth](figures/phasing/phasing_ed_d_whatshap_phased_snv_depth/) | [scripts/phasing/phasing_ed_d_whatshap_phased_snv_depth](scripts/phasing/phasing_ed_d_whatshap_phased_snv_depth/) |
| d | WhatsHap haplotag assignment yield | [figures/phasing/phasing_ed_f_whatshap_haplotag_yield](figures/phasing/phasing_ed_f_whatshap_haplotag_yield/) | [scripts/phasing/phasing_ed_f_whatshap_haplotag_yield](scripts/phasing/phasing_ed_f_whatshap_haplotag_yield/) |

#### Extended Data：WhatsHap完整深度稳健性

| Panel | 可视化 | 结果目录 | 脚本目录 |
|---|---|---|---|
| a | WhatsHap block NG50深度响应 | [figures/phasing/phasing_ed_b_whatshap_ng50_depth](figures/phasing/phasing_ed_b_whatshap_ng50_depth/) | [scripts/phasing/phasing_ed_b_whatshap_ng50_depth](scripts/phasing/phasing_ed_b_whatshap_ng50_depth/) |
| b | WhatsHap blockwise Hamming error深度响应 | [figures/phasing/phasing_ed_c_whatshap_hamming_depth](figures/phasing/phasing_ed_c_whatshap_hamming_depth/) | [scripts/phasing/phasing_ed_c_whatshap_hamming_depth](scripts/phasing/phasing_ed_c_whatshap_hamming_depth/) |

### Results叙述闭环

> **30×连续性与局部准确性分离 → 深度响应 → SV phased yield与benchmark F1分工 → WhatsHap独立复现 → caller/mapper依赖与haplotag可用性**

正文先用LongPhase的30×四指标概览建立“长程连续性”和“局部准确性”两个独立性能维度，再沿深度追踪平台特异轨迹。SV phased fraction与SV benchmark F1分别回答相位覆盖和call-set agreement。第二张主图用WhatsHap验证主要结构，并进一步展示SNP caller、mapper和haplotag yield的流程依赖。结尾将结论限定于HG002、GRCh38、既定truth set和当前分析流程，不建立跨指标综合赢家。

完整英文Results见[docs/phasing_results.md](docs/phasing_results.md)。