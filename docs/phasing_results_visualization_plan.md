# Phasing Results 科学叙事与 Nature 级可视化方案

## Summary

Phasing 部分采用“一张主图 + 一张 Extended Data”的结构：

- 主图由 LongPhase 主导，回答平台在相位覆盖、长程连续性、局部准确性和 SV 相位上的核心差异。
- Extended Data 使用 WhatsHap 独立验证主趋势，并展开 mapper、variant caller 和 haplotag 的流程依赖。
- 主文核心结论是“三平台占据不同性能区间”，不设置综合分数或总体赢家。
- 所有 panel 单独用 R 导出；论文中的组图只提供版式设计，不在仓库中生成合并图。

核心论点：

> Under matched HG002 conditions, long-read platforms occupied distinct phasing regimes: BGI produced the longest phase blocks, HiFi achieved the most complete and locally accurate SNP phasing, and ONT showed intermediate but depth-responsive performance, while SV phasing followed a different platform ranking.

## 科学闭环

| 科学问题 | 实验与数据 | 主指标 | 能形成的结论 |
|---|---|---|---|
| 有多少变异可被相位？ | LongPhase/WhatsHap SNP VCF | SNP phased rate或phased SNV fraction | 相位覆盖能力 |
| 能形成多长单倍型区段？ | Phase-block统计 | Block NG50 | 长程连续性 |
| 单倍型分配是否正确？ | GIAB phased SNP truth | Switch errors、blockwise Hamming error | 相位方向和block内准确性 |
| 深度如何改变结果？ | 10×、30×、50× | 上述指标的原始轨迹 | 深度收益、平台敏感性及边际收益 |
| SV能否被联合相位？ | LongPhase SNP+SV | Phased heterozygous SV fraction | SV相位覆盖 |
| SV call set是否可靠？ | Truvari + T2T-Q100 | Precision、recall、F1 | SV检测一致性，而非SV相位方向准确性 |
| 是否能支持下游单倍型分析？ | WhatsHap haplotag | Taggable alignment rate、H1/H2 ratio | 下游可分配性与平衡性 |
| 结论是否依赖流程？ | 两个mapper、两个caller、两个phaser | 原始配对差异 | 平台效果与分析流程共同决定结果 |

指标取舍：

- 主连续性指标只用 genome-normalized block NG50；N50、最长/平均block和block数高度冗余，进入Source Data或补充表。
- Hamming error与switch error均保留，因为二者回答不同准确性问题；switch+flip与switch高度重复，不单独成图。
- SV phased rate与SV F1必须分别绘制，禁止双y轴或将F1称为“SV phasing accuracy”。
- 不绘制综合分数、雷达图、赢家标记、理想象限或结论性背景色。

## 主图：平台间的 SNP–SV phasing 性能权衡

建议标题：

**Sequencing platforms exhibit distinct trade-offs between phasing continuity and accuracy**

版式为全宽约183 × 180 mm：

```text
┌────────────────────── a. experimental logic ──────────────────────┐
├──────────────────── b. matched 30× SNP profile ───────────────────┤
├──────────── c. NG50 vs depth ───────┬──── d. Hamming vs depth ────┤
├──────── e. SV phased rate vs depth ─┼──────── f. SV F1 vs depth ──┤
└─────────────────────────────────────┴──────────────────────────────┘
```

### a. 紧凑实验流程

- 展示对称设计：HG002 × BGI/ONT/HiFi × minimap2/winnowmap × 10/30/50× × GRCh38。
- 主路径：BAM + Clair3 het SNP + Sniffles2 read-name SV → LongPhase → SNP stats/GIAB compare + SV phase rate/Truvari。
- 次路径：BAM + Clair3 VCF → WhatsHap phase/compare/haplotag，标记为独立验证与扩展分析。
- 仅使用文本、细线和简单VCF/BAM节点，不添加DNA装饰、平台设备图标或结论文字。
- 单图尺寸约183 × 28 mm。

### b. 30× LongPhase SNP综合结果图，主视觉

使用与已有read-profile图一致的横向分面dot matrix：

- 行：BGI、ONT、HiFi。
- 四列：
  1. Phased benchmark SNPs (%)
  2. Phase-block NG50 (Mb)
  3. Switch errors per 10,000 assessed pairs
  4. Blockwise Hamming error (%)
- 每个平台保留minimap2和winnowmap两个原始点，不计算均值或误差线。
- 该图让读者同时看到：
  - BGI的NG50显著更长；
  - HiFi的phased rate更高、Hamming error更低；
  - ONT处于两者之间；
  - mapper影响可由同一行的两个点直接观察。
- 不标注“best”“worst”或“trade-off”；结论由四列数据自然产生。
- 单图尺寸约183 × 52 mm。

### c. LongPhase phase-block NG50随深度变化

- x轴：10×、30×、50×。
- y轴：NG50，单位Mb，线性尺度。
- 六条原始轨迹：3平台 × 2 mapper。
- 展示BGI连续性随深度持续增长，以及平台排序在两个mapper下保持一致。
- 单图尺寸约88 × 48 mm。

### d. LongPhase Hamming error随深度变化

- y轴使用log尺度，建议刻度0.5%、1%、2%、5%、10%。
- 展示ONT从10×到30×的大幅改善、HiFi持续较低、BGI非单调的准确性变化。
- 不添加趋势拟合、显著性检验或人工阈值。
- 单图尺寸约88 × 48 mm。

### e. LongPhase SV phased heterozygous fraction

- 展示18组原始depth trajectories。
- y轴约60–80%，根据实际范围留固定边距。
- 回答“有多少杂合SV被写成phased genotype”，不暗示方向正确。
- 单图尺寸约88 × 48 mm。

### f. LongPhase SV benchmark F1

- y轴统一约0.65–0.80。
- 直接显示10×到30×的大幅提升和30×到50×的边际收益递减。
- 与panel e并列，使读者区分“被相位的比例”和“call-set检测质量”。
- 单图尺寸约88 × 48 mm。

## Extended Data：独立验证、流程敏感性和下游可用性

建议标题：

**Workflow and caller sensitivity of SNP phasing and haplotype tagging**

版式：

```text
┌────────────────── a. matched 30× WhatsHap profile ────────────────┐
├──────── b. NG50 vs depth ─────────┬──── c. Hamming vs depth ──────┤
├──── d. phased SNV fraction ───────┬──── f. haplotag yield ────────┤
├──────────────── e. Clair3–DeepVariant sensitivity ────────────────┤
└────────────────────────────────────────────────────────────────────┘
```

### a. 30× WhatsHap独立验证

重复主图b的视觉语法，但使用WhatsHap口径：

- Phased heterozygous SNVs (%)
- Block NG50 (Mb)
- Switch errors per 10,000 pairs
- Blockwise Hamming error (%)

该panel独立支持“BGI连续性最高、HiFi Hamming error最低”的主趋势，但不将两个phaser直接混合排名。

### b–d. WhatsHap深度响应

分别绘制：

- block NG50；
- blockwise Hamming error；
- phased SNV fraction。

其中phased SNV fraction图应突出显示winnowmap与minimap2之间的实际差距，不计算“mapper平均值”。

### e. Caller敏感性综合哑铃图

使用30×的六个“平台 × mapper”组合：

- 行：平台与mapper组合。
- 三列：phased SNV fraction、block NG50、Hamming error。
- Clair3与DeepVariant为同一行的两个端点，以浅灰线连接。
- 该图完整报告caller改变覆盖、连续性和准确性的不同方向，避免只展示其中一种有利指标。

### f. Haplotag可分配率

- x轴：10×、30×、50×。
- y轴：taggable alignments (%）。
- 展示3平台 × 2 mapper的原始轨迹。
- H1/H2 ratio接近1的结果写入正文、图注和Source Data，不再绘制信息量很低的50/50堆叠图。
- 明确单位是alignments，而不是唯一reads或truth-validated assignments。

## Results写作顺序

1. **Matched-depth phasing separates long-range continuity from local accuracy**  
   介绍实验设计后，以主图b报告30×核心差异：BGI长block、HiFi低Hamming error与高覆盖、ONT居中。

2. **Increasing depth produces platform-specific gains in SNP phasing**  
   用主图c–d说明连续性普遍增加，但准确性并非对所有平台和mapper单调改善；重点报告ONT 10×到30×的恢复。

3. **SV phasing follows a performance ranking distinct from SNP continuity**  
   用主图e–f分别报告SV phased rate与F1，并指出30×以后F1接近平台期。

4. **Independent WhatsHap analysis confirms the continuity–accuracy separation**  
   用Extended Data a–d说明主要平台趋势跨phaser存在，同时绝对数值受mapper影响。

5. **Variant caller and haplotag analyses expose workflow dependence and downstream yield**  
   用Extended Data e–f报告caller敏感性和alignment可分配性；不把haplotag rate写成相位准确率。

“BGI可能更适合复杂区域、长程连锁或haplotype-resolved SV”的表述留在Discussion，并使用“may facilitate”或“is consistent with”，因为当前数据未直接评测这些下游任务。

## 视觉与实现规范

- 固定平台色：BGI `#FFB000`、ONT `#13A4A6`、HiFi `#9400D3`。
- minimap2：实线、实心圆；winnowmap：虚线、空心圆。
- caller敏感性：Clair3实心圆，DeepVariant空心菱形；平台颜色保持不变。
- LongPhase和WhatsHap不在同一坐标系中直接比较。
- 白底、Arial/Nimbus Sans、最终尺寸6.5–8 pt文本、细轴线、无装饰边框。
- 不使用柱形图、雷达图、热图、双y轴、显著性星号、误差带或人为综合排名。
- 每个panel单独导出SVG、PDF、600-dpi TIFF和PNG，并附：
  - `source_data_plotted.csv`
  - `data_filter_audit.csv`
  - `render_manifest.csv`
  - 指标变换与分母说明
- 使用现有R包即可完成单图；`patchwork`当前缺失，但本方案不生成合并组图，因此无需新增依赖。

## 验收与数据测试

- LongPhase、WhatsHap和haplotag主表各严格包含18个唯一组合；caller表包含18个Clair3组合和6个30× DeepVariant组合。
- 所有图使用完整原始行，不把mapper作为统计重复。
- 百分比、kb→Mb和switch errors per 10,000转换均从原始计数复算。
- 主图30×数据必须同时保留两个mapper。
- LongPhase与WhatsHap不同truth-site计数和block统计范围不得跨表合并。
- 图注分别定义phased rate、NG50、switch error、Hamming error、SV F1和taggable rate。
- 最终按目标尺寸检查文字、颜色、空心点、log轴、图例和裁切；SVG文本保持可编辑。
- 主图任一panel被遮住后，都应缺失一个独立证据环节；否则删除该panel。

## 已锁定的默认选择

- 目标期刊：Nature系列，兼容Nature Communications和Genome Research。
- 主文额度：一张主图；流程敏感性与haplotag进入一张Extended Data。
- 叙事中心：平台性能权衡，不突出总体赢家。
- 主证据流程：LongPhase；WhatsHap作为独立验证。
- 主比较深度：30×；10×和50×用于深度响应。
- 产出方式：R生成独立panel，论文排版阶段按上述wireframe组装。
