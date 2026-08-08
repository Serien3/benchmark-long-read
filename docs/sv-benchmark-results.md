# Structural variant detection varies with workflow, benchmark context and sequencing depth

> Manuscript-ready Results draft. Replace `Fig. X` and `Supplementary Fig. X`
> with final numbering during assembly. The author notes after the horizontal
> rule are not part of the manuscript text.

## Structural variant detection varied across platforms, workflows and benchmark contexts

We benchmarked structural variant (SV) detection in HG002 at matched sequencing depths within a common GRCh38 analysis framework. BGI, Oxford Nanopore Technologies (ONT) and PacBio HiFi data were evaluated at 10×, 30× and 50× with two aligners, minimap2 and winnowmap, and four callers, cuteSV, Sniffles2, sawfish and SVDSS. The resulting design contained 72 complete platform–depth–aligner–caller combinations for each benchmark. We used the HG002 T2T-Q100 v1.1 truth set for the genome-wide analysis and the Genome in a Bottle (GIAB) Challenging Medically-Relevant Genes (CMRG) benchmark for difficult medically relevant regions (Fig. Xa,b).

Against T2T-Q100 v1.1, the three platforms occupied overlapping performance ranges whose order changed across workflows. At 30×, median detection F1 across the eight caller–aligner workflows was 0.810 for BGI, 0.829 for ONT and 0.825 for HiFi (Fig. Xa). Median precision at this depth was 0.915, 0.922 and 0.930, respectively, and median recall was 0.729, 0.760 and 0.751. Individual 30× workflows spanned F1 ranges of 0.777–0.824 for BGI, 0.801–0.846 for ONT and 0.766–0.848 for HiFi, exceeding the separation between the platform medians. Increasing depth from 10× to 30× raised median F1 by 0.0566 for BGI, 0.0339 for ONT and 0.0444 for HiFi. The corresponding changes from 30× to 50× were 0.0027, 0.0020 and 0.0064. Across callers and depths, the paired median winnowmap-minus-minimap2 F1 was −0.0056 for BGI, −0.0068 for ONT and −0.0190 for HiFi. These distributions placed most of the observed depth gain between 10× and 30× and showed that workflow choice remained a major component of each platform's performance profile.

Changing the benchmark context reorganized the workflow landscape (Fig. Xb). At 30× in CMRG, median F1 across platforms and aligners was 0.890 for sawfish, 0.851 for Sniffles2, 0.790 for cuteSV and 0.742 for SVDSS. BGI–minimap2–SVDSS produced the lowest F1 at all three depths, decreasing from 0.671 at 10× to 0.405 at 30× and 0.266 at 50×. Recall increased from 0.746 to 0.834 and 0.857 across the same depths, while precision decreased from 0.609 to 0.268 and 0.157. False-positive calls rose from 104 to 495 and 996 as false negatives fell from 55 to 36 and 31, directly linking the F1 loss to an expanding false-positive burden. The aligner relationship also changed with benchmark context. Median winnowmap-minus-minimap2 F1 in CMRG was +0.0084 for BGI, +0.0081 for ONT and −0.0051 for HiFi. Together, the T2T-Q100 and CMRG results showed that benchmark context altered relative performance among platform–caller–aligner combinations within the matched design.

## Precision–recall structure linked F1 differences to benchmark counts

We next resolved results at the matched intermediate depth of 30× into their precision and recall components across all 24 platform–aligner–caller combinations in each benchmark (Fig. Xc,d). T2T-Q100 workflows formed a compact high-precision band: precision ranged from 0.899 to 0.945 and recall from 0.656 to 0.776, producing F1 values of 0.766–0.848. CMRG occupied a broader region, with precision from 0.268 to 1.000, recall from 0.585 to 0.848 and F1 from 0.405 to 0.915. The expanded CMRG range captured both high-performing workflows and the precision collapse of BGI–SVDSS, while the T2T-Q100 inset resolved workflow differences within the dense genome-wide cluster. These precision–recall positions showed how workflows with similar F1 differed in error balance and how a caller-specific increase in false positives could dominate the benchmark score.

Direct benchmark accounting provided the corresponding event counts for cuteSV and Sniffles2 under minimap2 at 30× (Fig. Xe). For cuteSV, truth-side true positives (TP-base) ranged from 19,233 to 20,391 across platforms, with 7,743–8,893 false negatives; call-side true positives (TP-call) ranged from 16,819 to 17,988, with 1,059–1,462 false positives. Sniffles2 produced 19,969–21,314 TP-base records and 18,112–19,251 TP-call records, with 6,794–8,115 false negatives and 1,180–1,623 false positives. ONT produced the largest TP-base count for both callers, and HiFi produced the fewest false positives. Sniffles2 produced more TP-base and TP-call records than cuteSV on all three platforms, together with 121–174 additional false positives. These counts accounted for the higher recall observed for ONT and the higher precision observed for HiFi in the two minimap2 workflows.

## BGI depth responses differed between SV callers

To examine depth response at finer resolution, we evaluated BGI data from 5× to 70× in 5× increments with GRCh38/minimap2 and the refined Truvari output (Fig. Xf,g). All 14 depths were complete for cuteSV and Sniffles2. For cuteSV, refined recall increased from 0.681 at 5× to 0.799 at 30×, 0.840 at 50× and 0.845 at 70×. Refined F1 increased from 0.794 to 0.877, 0.900 and 0.904 at the same depths. The trajectory retained incremental gains through the upper part of the series, with refined F1 increasing by 0.011 between 40× and 70×.

Sniffles2 showed a steeper low-depth response. Refined recall increased from 0.468 at 5× to 0.712 at 10×, 0.803 at 20× and 0.827 at 30×. Refined F1 increased from 0.632 to 0.821, 0.878 and 0.892 over the same depths. From 40× to 70×, refined recall remained between 0.833 and 0.835 and refined F1 remained between 0.896 and 0.898. The two callers consequently reached similar high-depth F1 values through different trajectories: Sniffles2 accumulated most of its gain by 30×, while cuteSV continued to gain gradually at higher depths. This dense series showed that the depth required to approach the upper performance range depended on the caller used in the workflow.

Caller-specific parameter analyses quantified configuration sensitivity in the BGI 50× GRCh38/minimap2 workflow (Supplementary Fig. X). The 162-combination cuteSV factorial scan spanned raw F1 values of 0.5848–0.8104 and refined F1 values of 0.6863–0.9007. Fourteen targeted follow-up runs narrowed these ranges to 0.8090–0.8179 and 0.9016–0.9100, respectively; a minimum support of 3 and a mapping-quality threshold of 20 produced both maxima. The Sniffles2 3×3 auto-support and mapping-quality matrix varied over narrower intervals: raw whole-genome F1 was 0.8063–0.8095, refined whole-genome F1 was 0.9003–0.9024 and CMRG F1 was 0.8543–0.8627. The cross-endpoint setting with an auto-support multiplier of 0.10 and a mapping-quality threshold of 10 yielded F1 values of 0.8091, 0.9022 and 0.8627 for these three endpoints, placing the whole-genome scores within 0.0004 and 0.0002 of their respective maxima and reaching the CMRG maximum. These analyses defined the tested parameter response for each caller and documented the basis for the BGI-specific configurations.

## Specialized analyses revealed distinct low-VAF SV and mobile-element candidate profiles

We extended the SV analysis to SV candidates with a low variant allele frequency (low-VAF) using Sniffles2 mosaic mode at 30× (Fig. Xh). Candidate totals differed across both platforms and aligners. Minimap2 and winnowmap produced 3,357 and 4,098 candidates for BGI, 2,477 and 3,620 for ONT, and 1,185 and 1,933 for HiFi, respectively. Winnowmap increased the candidate total within every platform. Candidate composition also shifted across platforms. BGI profiles contained 45–47% deletions and 42–44% insertions. ONT profiles contained 38–40% deletions and approximately 48% insertions. HiFi profiles were more insertion-weighted, with 26–31% deletions and 53–59% insertions. Candidates in the 10–20% VAF interval accounted for 56–58% of the BGI and ONT outputs and 64–65% of the HiFi outputs. Both candidate burden and composition changed with the platform–aligner workflow in the low-VAF analysis.

Mobile-element insertion (MEI) calling produced a narrower aggregate range (Fig. Xi). Across the six xTEA-long workflows, final merged candidate totals ranged from 1,962 to 2,011. ALU comprised 81.5–82.7% of candidates, LINE1 10.3–11.3%, SVA 6.4–7.1% and HERV 0.3–0.4%, corresponding to six to eight HERV candidates per workflow. The limited variation in total yield and family proportions contrasted with the wider spread of low-VAF SV candidate counts. At the aggregate level, MEI family composition remained similar across the three platforms and two aligners.

Across the SV experiments, matched-depth performance varied with caller, aligner, benchmark context and sequencing depth. The specialized analyses showed additional platform–aligner differences in the abundance and composition of reported candidates. The benchmark conclusions are restricted to HG002, GRCh38, T2T-Q100 v1.1, GIAB CMRG and the evaluated tool versions. No independent truth set was available for the low-VAF or MEI analyses, so those panels quantify candidate output and do not establish sensitivity, precision or event-level concordance.

---

## 作者说明（不纳入正文）

### 结构与逻辑

- 第1–3段建立对称评测矩阵，依次报告T2T-Q100总体结果及CMRG中的相对变化。
- 第4–5段将detection F1还原为30× PR位置与TP-base、FN、TP-call和FP原始记录。
- 第6–8段用BGI密集深度梯度和调参矩阵说明caller特异的深度与参数响应。
- 第9–10段扩展到low-VAF SV和MEI候选谱；末段统一收束主张和解释边界。

### 术语口径

| Canonical term | First-use form | Variants avoided |
|---|---|---|
| structural variant | structural variant (SV) | structure variant, structural variation call |
| T2T-Q100 v1.1 | HG002 T2T-Q100 v1.1 truth set | GIAB v5.0q SV truth, GIAB5 |
| GIAB CMRG | Genome in a Bottle (GIAB) Challenging Medically-Relevant Genes (CMRG) benchmark | CMRG truth, difficult-region truth used without expansion |
| detection F1 | detection F1 | SV F1, raw F1 when the metric role is ambiguous |
| refined F1 / refined recall | refined Truvari output; refined F1; refined recall | refine F1, refine Recall in prose |
| low-VAF SV candidates | low variant allele frequency (low-VAF) candidates | mosaic variants when truth status is implied |
| mobile-element insertion | mobile-element insertion (MEI) | ME variant, mobile element event |
| workflow | platform–depth–aligner–caller combination | replicate |

### 主张与证据对应

| 主张 | 直接证据 | 审计结论 |
|---|---|---|
| 平台表现依赖具体workflow | 每个benchmark的72个完整组合、30×平台范围重叠、配对aligner变化 | 支持 |
| benchmark context改变相对表现 | T2T-Q100与CMRG分布、caller中位数、BGI–SVDSS precision/FP轨迹 | 支持 |
| 匹配深度的主要增益出现在30×以前 | 10×→30×及30×→50×的平台中位F1变化 | 仅作描述性总结时支持 |
| 深度响应依赖caller | cuteSV和Sniffles2完整的5×–70× BGI序列 | 支持 |
| low-VAF候选输出随平台和aligner变化 | 六个workflow的候选总数、SV类型与VAF组成 | 仅在候选输出层面支持 |
| MEI总体组成在workflow间接近 | 六个workflow的总数与四类家族比例 | 仅在总体组成层面支持；缺少事件级交集 |

### 投稿前待处理项

- a–i正文大组图完成后统一替换全部`Fig. X`占位符。
- panel a必须由`data/sv_benchmark_T2TQ100.csv`重绘；当前GIAB5标记版本不能进入正文。
- 全文统一“refined F1”或“Truvari-refined F1”的最终写法。
- `cuteSV-HiFi`六点参数敏感性图的“GIAB v5.0q”来源标签独立确认前不在正文引用。
- 工具版本与软件引用放入Methods；本稿未虚构外部参考文献。
