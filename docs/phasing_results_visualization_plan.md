# Phasing Results 科学叙事与 Nature 级可视化方案

## Summary

Phasing 部分暂定采用“两张正文主图 + 一张精简 Extended Data”的结构：

- 正文主图1由 LongPhase 主导，回答平台在相位覆盖、长程连续性、局部准确性和 SV 相位上的核心差异。
- 正文主图2使用 WhatsHap 提供独立 phaser 验证，并展开 mapper、variant caller 和 haplotag 的流程依赖与下游可用性。
- Extended Data 保留 WhatsHap NG50 与 Hamming error 的完整深度响应，作为正文结论的补充稳健性证据。
- 主文核心结论是“三平台占据不同性能区间”，不设置综合分数或总体赢家。
- 所有 panel 单独用 R 导出；论文中的组图只提供版式设计，不在仓库中生成合并图。

核心论点：

> Under matched HG002 conditions, long-read platforms occupied distinct phasing regimes: BGI produced the longest phase blocks, HiFi achieved the most complete and locally accurate SNP phasing, and ONT showed intermediate but depth-responsive performance, while SV phasing followed a different platform ranking.

正文主图2的支持论点：

> The principal continuity–accuracy separation was reproduced by an independent phasing workflow, whereas mapper and variant-caller choices materially altered phased-SNV yield and error profiles, with platform-specific consequences for downstream haplotype tagging.

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

## 正文主图1：平台间的 SNP–SV phasing 性能权衡

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

使用四张并列的紧凑分组柱状图：

- 四列：
  1. Phased benchmark SNPs (%)
  2. Phase-block NG50 (Mb)
  3. Switch errors per 10,000 assessed pairs
  4. Blockwise Hamming error (%)
- 每列的x轴分为minimap2和winnowmap两个区域；每个区域保留BGI、ONT、HiFi
  三个原始柱，不计算均值或误差线。
- 使用固定平台色、无边框实心柱、居中粗体标题和浅灰mapper区域边界；平台
  图例只出现一次。
- NG50、switch error和Hamming error使用零基线；phased SNP百分比因六个结果
  均集中于98.69–99.59%，使用明确标刻的98.5–100%窗口，并禁止跨指标比较柱长。
- 该图让读者同时看到：
  - BGI的NG50显著更长；
  - HiFi的phased rate更高、Hamming error更低；
  - ONT处于两者之间；
  - mapper影响可由相邻的两个mapper柱组直接观察。
- 不标注“best”“worst”或“trade-off”；结论由四列数据自然产生。
- 单图尺寸约183 × 52 mm。

### c. LongPhase phase-block NG50随深度变化

- x轴：10×、30×、50×。
- y轴：NG50，单位Mb，线性尺度。
- mapper拆分为并列的minimap2和winnowmap独立区域；每个区域展示三条平台原始轨迹。
- 三个深度使用等距类别中心和浅灰区域边界；平台统一为实线、实心圆及固定配色。
- 展示BGI连续性随深度持续增长，以及平台排序在两个mapper下保持一致。
- 单图尺寸约88 × 48 mm。

### d. LongPhase Hamming error随深度变化

- y轴使用log尺度，建议刻度0.5%、1%、2%、5%、10%。
- 沿用panel c的双mapper空间分区、等距深度中心和平台轨迹语法。
- 展示ONT从10×到30×的大幅改善、HiFi持续较低、BGI非单调的准确性变化。
- 不添加趋势拟合、显著性检验或人工阈值。
- 单图尺寸约88 × 48 mm。

### e. LongPhase SV phased heterozygous fraction

- 沿用panel c的双mapper空间分区，完整展示18个原始观测及六条平台×mapper轨迹。
- y轴约60–80%，根据实际范围留固定边距。
- 回答“有多少杂合SV被写成phased genotype”，不暗示方向正确。
- 单图尺寸约88 × 48 mm。

### f. LongPhase SV benchmark F1

- y轴统一约0.65–0.80。
- 沿用panel c的双mapper空间分区和平台轨迹语法。
- 直接显示10×到30×的大幅提升和30×到50×的边际收益递减。
- 与panel e并列，使读者区分“被相位的比例”和“call-set检测质量”。
- 单图尺寸约88 × 48 mm。

## 正文主图2：流程稳健性与下游单倍型可用性

建议标题：

**Workflow choices shape SNP phasing robustness and downstream haplotype-tagging yield**

图型为定量证据网格，以30× WhatsHap 四指标概览作为独立验证主证据，caller
敏感性作为流程依赖主证据，深度×mapper和haplotag作为支持证据。建议全宽约
183 × 165–175 mm：

```text
┌──────────────── a. matched 30× WhatsHap profile ─────────────────┐
├──────────── b. Clair3–DeepVariant sensitivity ───────────────────┤
├──── c. phased SNV fraction vs depth ──┬── d. haplotag yield ─────┤
└────────────────────────────────────────┴───────────────────────────┘
```

### a. 30× WhatsHap 独立验证

完整复用正文主图1 panel b的四列紧凑分组柱状图语法，但使用WhatsHap口径：

- Phased heterozygous SNVs (%)
- Block NG50 (Mb)
- Switch errors per 10,000 pairs
- Blockwise Hamming error (%)

该panel独立支持“BGI连续性最高、HiFi Hamming error最低”的主趋势，但不将两个phaser直接混合排名。

- 每列的x轴均为minimap2和winnowmap两个区域，每区依次保留BGI、ONT和HiFi
  三个实心柱；柱宽、组内间距、浅灰区域边界、平台配色和共享页眉图例与正文主图1 panel b一致。
- NG50、switch error和Hamming error采用零基线；phased heterozygous SNV比例
  使用明确标刻的94–100%窗口，禁止跨指标比较柱长。
- 单图尺寸约183 × 52 mm；对应现有独立交付 `phasing_ed_a_whatshap_30x_profile`。

### b. Caller敏感性综合哑铃图

使用30×的六个“平台 × mapper”组合：

- 行：平台与mapper组合。
- 三列：phased SNV fraction、block NG50、Hamming error。
- Clair3与DeepVariant为同一行的两个端点，以浅灰线连接。
- 该图报告caller改变覆盖、连续性和准确性的不同方向，避免只展示其中一种有利指标。
- 单图尺寸约183 × 60 mm；对应现有独立交付 `phasing_ed_e_whatshap_caller_sensitivity`。

该panel是正文主图2中最重要的流程敏感性证据。其含义是固定平台、mapper和
30×深度后更换SNP caller仍可显著改变下游WhatsHap结果；不得把caller端点当作
技术重复或将差异概括为单一综合分数。

### c. WhatsHap phased-SNV fraction 深度响应

复用正文主图1 panel c的视觉语法：minimap2和winnowmap作为并列独立区域，
区域内以固定平台色、实线和实心圆连接10×、30×、50×原始观测；两个区域使用
相同y尺度与等距深度中心，不再通过虚实线、空心点或水平偏移编码mapper。
phased SNV fraction的mapper差异保留在原始值及配对差异审计表中，不计算
“mapper平均值”，也不跨独立区域绘制连接线。
- 该panel明确展示depth response受mapper约束，不能将phased-SNV yield解释为
  truth-validated phasing accuracy。
- 单图尺寸约88 × 48 mm；对应现有独立交付 `phasing_ed_d_whatshap_phased_snv_depth`。

### d. Haplotag可分配率

- x轴：10×、30×、50×。
- y轴：taggable alignments (%)。
- 复用正文主图1 panel c的双mapper空间分区语法，展示3平台 × 2 mapper的原始轨迹。
- H1/H2 ratio接近1的结果写入正文、图注和Source Data，不再绘制信息量很低的50/50堆叠图。
- 明确单位是alignments，而不是唯一reads或truth-validated assignments。
- 单图尺寸约88 × 48 mm；对应现有独立交付 `phasing_ed_f_whatshap_haplotag_yield`。

### 正文提升映射

现有单图文件名继续保留，组装到正文主图2时只更新panel字母：

| 正文主图2 panel | 现有独立交付 | 原规划位置 | 新证据角色 |
|---|---|---|---|
| a | `phasing_ed_a_whatshap_30x_profile` | ED a | 独立phaser复现 |
| b | `phasing_ed_e_whatshap_caller_sensitivity` | ED e | caller敏感性 |
| c | `phasing_ed_d_whatshap_phased_snv_depth` | ED d | mapper × depth依赖 |
| d | `phasing_ed_f_whatshap_haplotag_yield` | ED f | 下游haplotag可用性 |

## Extended Data：WhatsHap完整深度稳健性

建议标题：

**Depth-dependent continuity and local phasing error in the independent WhatsHap workflow**

保留两个与正文主图1深度曲线对应、但不承担新的正文论点的完整验证panel：

```text
┌──────── a. WhatsHap NG50 vs depth ───────┬─ b. Hamming vs depth ─┐
└───────────────────────────────────────────┴───────────────────────┘
```

### a. WhatsHap block NG50 深度响应

- 对应现有独立交付 `phasing_ed_b_whatshap_ng50_depth`。
- 作为正文主图1 panel c与正文主图2 panel a中连续性结果的完整深度验证。
- 保留全部3平台 × 2 mapper × 3深度原始观测，不与LongPhase数值合并。

### b. WhatsHap blockwise Hamming error 深度响应

- 对应现有独立交付 `phasing_ed_c_whatshap_hamming_depth`。
- 作为正文主图1 panel d与正文主图2 panel a中局部准确性结果的完整深度验证。
- 使用已声明的log10显示尺度和原始百分比刻度，不增加趋势拟合或显著性检验。

## Results写作顺序

1. **Matched-depth phasing separates long-range continuity from local accuracy**  
   介绍实验设计后，以正文主图1b报告30×核心差异：BGI长block、HiFi低Hamming error与高覆盖、ONT居中。

2. **Increasing depth produces platform-specific gains in SNP phasing**  
   用正文主图1c–d说明连续性普遍增加，但准确性并非对所有平台和mapper单调改善；重点报告ONT 10×到30×的恢复。

3. **SV phasing follows a performance ranking distinct from SNP continuity**  
   用正文主图1e–f分别报告SV phased rate与F1，并指出30×以后F1接近平台期。

4. **Independent WhatsHap analysis confirms the continuity–accuracy separation**  
   用正文主图2a说明主要平台趋势跨phaser存在；Extended Data a–b提供完整深度验证。

5. **Variant caller and haplotag analyses expose workflow dependence and downstream yield**  
   用正文主图2b–d依次报告caller敏感性、mapper × depth依赖和alignment可分配性；
   不把phased-SNV fraction或haplotag rate写成truth-validated相位准确率。

“BGI可能更适合复杂区域、长程连锁或haplotype-resolved SV”的表述留在Discussion，并使用“may facilitate”或“is consistent with”，因为当前数据未直接评测这些下游任务。

## 视觉与实现规范

- 固定平台色：BGI `#FFB000`、ONT `#13A4A6`、HiFi `#9400D3`。
- 深度响应图（正文主图1 c–f、正文主图2 c–d、Extended Data a–b）：mapper以并列独立区域编码；
  两个区域内均使用平台色实线与实心圆，并共享y尺度和深度类别几何。
- 仍在共享坐标系中比较mapper的其他图：minimap2使用实线/实心圆，winnowmap
  使用虚线/空心圆。
- caller敏感性：Clair3实心圆，DeepVariant空心菱形；平台颜色保持不变。
- LongPhase和WhatsHap不在同一坐标系中直接比较。
- 白底、Arial/Nimbus Sans、最终尺寸6.5–8 pt文本、细轴线、无装饰边框。
- 正文主图1b与正文主图2a使用彼此匹配的四张原始值分组柱图；不使用其他柱形图，不使用
  雷达图、热图、双y轴、显著性星号、误差带或人为综合排名。
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
- 两张正文主图的30×概览数据必须同时保留两个mapper。
- LongPhase与WhatsHap不同truth-site计数和block统计范围不得跨表合并。
- 图注分别定义phased rate、NG50、switch error、Hamming error、SV F1和taggable rate。
- 最终按目标尺寸检查文字、颜色、空心点、log轴、图例和裁切；SVG文本保持可编辑。
- 两张正文主图任一panel被遮住后，都应缺失一个独立证据环节；否则降级至Extended Data或删除。

## 当前暂定选择

- 目标期刊：Nature系列，兼容Nature Communications和Genome Research。
- 主文额度：两张phasing正文主图；主图1报告LongPhase核心发现，主图2报告
  WhatsHap独立验证、流程敏感性和haplotag下游可用性。
- 叙事中心：平台性能权衡，不突出总体赢家。
- 主证据层级：LongPhase为核心发现流程；WhatsHap作为正文中的独立验证与
  workflow-dependence证据，两者不在同一坐标系中直接合并排名。
- 主比较深度：30×；10×和50×用于深度响应。
- 产出方式：R生成独立panel，论文排版阶段按上述wireframe组装。
