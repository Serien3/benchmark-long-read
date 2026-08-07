# Reads 与比对 QC 正文结果图及科研叙事方案

> 状态：增强确认版  
> 确认日期：2026-08-06  
> 论文角色：开篇主结果图，用于建立后续变异检测、相位与组装分析的输入基线  
> 适用范围：HG002 三平台 reads QC、GRCh38/T2T-CHM13 双参考比对 QC  
> 当前不纳入：30×表观错误谱 pilot  
> 绘图后端：R；当前阶段分别输出独立单图，不直接生成组图

## 1. 图件科学契约

### 1.1 建议主图题目

> **Depth-controlled long-read sequencing reveals distinct read profiles and reference-dependent coverage breadth**

### 1.2 核心科学结论

> 匹配输入产量统一了测序剂量，却没有统一数据的信息结构：三个平台具有清晰不同的读长和平台报告 Q-score 组成；reference-base coverage breadth 在 30×后趋于饱和，在 GRCh38 上接近收敛、在 T2T-CHM13 上呈现更强的平台分化，而两种 aligner 的结果总体接近，primary mapped-read rate 仍保留平台差异。

这张图不是平台综合排名图，也不回答“哪个平台绝对最好”。它的论文功能是先定义三个平台实际提供了怎样的输入、这些差异经过统一比对后哪些收敛、哪些保留，从而为后续任务中的性能权衡建立可追踪的解释基线。

### 1.3 图件角色与证据层级

| 项目 | 已确认设计 |
|---|---|
| Figure archetype | 带 hero panel 的非对称 `quantitative grid` |
| 论文角色 | 开篇主图 / Fig. 1 级别的比较基线 |
| Hero evidence | 全部 36 个条件的 reference-base coverage breadth |
| Primary supporting evidence | 30× read profile；30× primary mapped-read rate |
| Experimental-design evidence | 9 个输入层级的 approximate input depth |
| Operational evidence | BAM output footprint，默认 Extended Data、保留主图替换位 |
| 统计定位 | 单个 HG002 的技术条件矩阵；描述性比较，不做群体推断 |
| 最终组图尺寸 | 183 mm 宽，目标高度 155–165 mm，绝不超过 170 mm |
| 单图后端 | R / ggplot2；SVG、PDF、TIFF 和预览 PNG |

证据阅读顺序固定为：

1. **比较是否公平**：输入剂量是否匹配；
2. **输入是什么**：匹配产量下的 read length 与 reported Q-score profile；
3. **比对后发生什么**：coverage breadth 如何响应 depth、reference 和 aligner；
4. **哪些差异仍保留**：primary mapped-read rate，以及可选的 BAM footprint；
5. **为什么影响后文**：相同总碱基量不等于相同的信息结构或分析输入。

## 2. 数据口径与术语定义

这一节只定义指标含义，避免同一个“coverage”在图和正文中指代不同概念。

### 2.1 Approximate input depth

- 来自 reads 总碱基量与预设基因组长度的换算，用于核对下采样剂量。
- 图和正文统一写作 **approximate input depth**，不写作 realized genome coverage。
- 10×、30×和50×是嵌套子集，不是三个独立重复。

### 2.2 Reported read Q-score

- `Mean Q`、`Median Q` 和 `Reads with mean Q>20` 来自输入质量字符串经 NanoPlot 汇总的 read-level 指标。
- 跨平台图中统一写作 **reported read Q-score** 或 **read-level Q-score composition**。
- 这些值不直接等同于 truth-based empirical base accuracy；经验错误率应由正式 donor-specific error spectrum 单独回答。

### 2.3 Mean-Q>20 read yield

- 指 **mean read Q>20 的 reads 所携带的总碱基量**。
- 它不同于“所有 individual bases 中 Q≥20 的比例”。后者当前仅 BGI 有 SeqKit 数据，不进入跨平台比较。
- 原始列名虽然含 `(%)`，CSV 中记录的是 0–1 fraction，绘图时乘以100并保留源值。

### 2.4 Reference-base coverage breadth

- `Coverage rate` 对应当前 `samtools coverage` 口径：参考序列中至少被一个比对碱基覆盖的位置比例，即 reference bases covered at ≥1×。
- 它是全局覆盖广度，不是平均深度，也不直接等同于复杂区域可解析能力。
- CSV 中保存为 0–1 fraction，图中转换为百分比。

### 2.5 Primary mapped-read rate

- 表示 primary reads 中成功比对的比例，是 read-level retention 指标。
- 它与 reference-base coverage breadth 回答不同问题：前者关注 reads，后者关注参考基因组位置。

### 2.6 BAM output footprint

- 表示当前统一版本、preset、排序与输出设置下生成的 BAM 文件大小。
- 它可以作为实际存储占用报告，但不替代运行时间、峰值内存、能耗或经济成本。

## 3. Results 的完整科学闭环

### 3.1 建立深度控制的对称比较框架

**实验。** HG002 的 BGI、ONT 和 HiFi 数据采用嵌套下采样，目标深度为10×、30×和50×；后续比对与下游分析复用同一批子集。

**结果。**

- 10×和30×的 approximate input depth 与目标值最大偏差仅0.011×。
- BGI 和 HiFi 的50×数据分别达到49.978×和49.993×。
- ONT 的50×数据受可用产量限制，实际为47.768×。

**推论。** 10×和30×构成最严格的对称比较层级；50×作为 nominal 50×层级透明报告，不能声称三个平台在该层级完全等量。Panel a 只建立这一比较前提，不承担平台性能结论。

### 3.2 匹配产量下仍存在不同的 read profile

30×被选为代表层级，因为它输入严格匹配，也是后续多数主评测的核心深度。嵌套子集中的 summary statistics 高度稳定，因此没有必要把三个深度重复画成三次独立观察。

**Read-length profile。**

- ONT：mean 18.42 kb、median 17.36 kb、N50 29.40 kb，三个长度汇总均最高。
- BGI：mean 16.19 kb、median 12.56 kb、N50 25.95 kb。较高 N50 与较低 median 并存，说明其长度结构不能简化为“全面居中”。
- HiFi：mean 14.02 kb、median 14.60 kb、N50 16.77 kb，N50 最短。

**Reported Q-score profile。**

- HiFi：mean Q 25.8、median Q 30.9、mean-Q>20 reads 占93.2%。
- ONT：mean Q 16.5、median Q 25.5、mean-Q>20 reads 占78.3%。
- BGI：mean Q 16.8、median Q 19.2、mean-Q>20 reads 占33.6%。
- 30×下，mean-Q>20 reads 携带的产量分别为 BGI 38.92 Gb、ONT 80.13 Gb、HiFi 88.53 Gb。

为了同时报告 read fraction 与其实际碱基贡献，增加一个透明派生量：

```text
Q20-read base share = Mean-Q>20 read yield / total yield
```

30×下对应 BGI 40.3%、ONT 83.0%、HiFi 91.7%。这不是“individual bases with Q≥20”，而是由 mean-Q>20 reads 贡献的总碱基比例。

**推论。** ONT 的输入特征主要表现为较长 reads，HiFi 表现为较高的 reported read Q-score 组成；BGI 保留较强的长读段尾部和较高 N50，但 mean-Q>20 read fraction 与其携带的碱基产量较低。上述结果共同描述输入信息结构，不把任一指标转换成平台总分。

### 3.3 Coverage breadth 呈现深度饱和和 reference-specific platform response

**实验。** 三个平台 × 3个深度 × 2个参考基因组 × 2个 aligner，共36个条件。GRCh38 和 T2T-CHM13 均使用 minimap2 与 winnowmap，并为不同数据类型采用对应 preset。

**30×绝对结果。**

- GRCh38 coverage breadth 为92.94–93.33%，全矩阵平台范围仅0.39个百分点。
- T2T-CHM13 coverage breadth 为98.31–99.43%，全矩阵平台范围扩大至1.12个百分点。
- 在 T2T-CHM13 上，BGI/ONT 约为99.33–99.43%，HiFi 为98.31–98.38%。因此不能把两个参考上的结果概括为“三个平台全面收敛”。
- 同一平台、aligner和30×深度下，从GRCh38到T2T-CHM13的变化为5.26–6.31个百分点。

**Aligner response。**

- 在全部 matched platform–depth–reference 组合中，`winnowmap − minimap2` 的 signed median coverage difference 为 −0.025个百分点。
- 若报告差异幅度，median absolute difference 为0.050个百分点，而不是0.025个百分点。
- 最大差异为0.21个百分点；较明显且方向一致的分离主要出现在 HiFi–GRCh38 条件中。

**Depth response。**

- 10×→30×的 coverage breadth 增益为0.51–0.83个百分点，中位数约0.65个百分点。
- 30×→50×的增益仅0.12–0.22个百分点，中位数约0.185个百分点。

**推论。** 全局 reference-base coverage breadth 的主要结构不是简单的平台排名，而是：GRCh38 上平台差异接近收敛，T2T-CHM13 上出现更强的平台分化；大部分深度收益在30×前获得；两种 aligner 总体一致，但并非在所有平台–参考组合上完全等同。Panel c 必须让读者直接从全部36个真实观测中看到这三个层次。

### 3.4 Position-level coverage之外仍保留read-level primary mapping差异

30× primary mapped-read rate 为：

- BGI：99.02–99.69%；
- ONT：97.94–98.34%；
- HiFi：99.92–100.00%。

四个 reference–aligner 条件中的平台顺序均为 HiFi、BGI、ONT。两种aligner之间的同平台差值为−0.36至+0.01个百分点，最大绝对差值为0.36个百分点；因此，30× primary mapping retention中的主要可见结构是跨平台分离，同时保留较小但可直接读取的流程响应。

**推论。** Panel c回答reference positions covered如何随深度变化；Panel d独立报告reads retained as primary alignments在匹配30×条件下的结果。二者分别承担position-level和read-level证据，不在Panel d中重复使用coverage breadth作为坐标或辅助编码。

### 3.5 BAM output footprint 作为可选的流程维度

30× BAM size 为：

- BGI：90.51–109.30 GiB；
- ONT：81.35–102.88 GiB；
- HiFi：34.45–41.01 GiB。

在匹配 reference 和 aligner 时，BGI/ONT BAM 约为 HiFi 的2.36–2.72倍；30×下 winnowmap BAM 较 minimap2 小约6.6–11.5%。

**论文定位。** 该指标具有实际流程价值，但科学优先级低于 read profile、coverage breadth 和 primary mapping。默认作为 Extended Data；只有当正文将存储占用写成独立结果段落、且最终版面仍能保证可读性时，才提升为主图 panel e。

### 3.6 与后续实验衔接

Results 本节建议用以下逻辑收束：

> Together, these results show that matching total sequencing yield equalizes input dosage but not the information structure presented to downstream workflows. Variant calling, phasing and assembly outcomes therefore need to be interpreted in the context of platform-specific read-length and reported Q-score profiles, primary mapping retention and reference-dependent coverage breadth.

这句话只总结本图直接支撑的事实，不提前解释具体下游任务的性能高低。

## 4. 正文主图设计

主图默认由 panel a–d 构成；panel e 单独生成并保留替换位。最终版面采用一个明显的 hero panel，而不是六个等权小图。

### Panel a｜Approximate input depth

- **科学问题**：三个平台的输入剂量是否匹配？
- **数据**：reads QC 全部9个观测。
- **图形**：target depth 与 approximate input depth 的点线图。
- **x轴**：Target depth（10、30、50×）。
- **y轴**：Approximate input depth（0–52×）。
- **参考线**：灰色 `y=x`。
- **标注**：只直接标出 ONT nominal 50×对应的47.77×；其余精确值进入Source Data。
- **编码**：平台颜色；同一平台的三个嵌套层级用细线连接。
- **作用**：建立比较前提，不承担平台优劣结论。

### Panel b｜30× integrated read profile

将原方案中的“读长结构”和“质量/高质量产出”合并为一个横向宽面板，避免在最终183 mm宽度下出现过窄的小分面。

- **数据**：严格使用30×的3个平台观测。
- **布局**：平台固定为 BGI、ONT、HiFi 三行；三个指标区共享行位置、使用独立x轴。

三个指标区依次为：

1. **Read length (kb)**
   - x轴0–32 kb；
   - mean、median、N50使用三种形状；
   - 不连接三个统计量，避免误读为区间或真实分布范围。
2. **Reported read Q**
   - x轴0–35；
   - mean与median使用两种形状；
   - 不使用“empirical accuracy”或“base accuracy”作为轴标题。
3. **Mean-Q>20 composition**
   - x轴0–100%；
   - 同时绘制 Q>20 read fraction 和 Q20-read base share；
   - 两点可用浅灰线连接，因为它们描述同一 read subset 的数量占比与碱基贡献；
   - 绝对 Q20 read yield（Gb）放入图注和Source Data，不强行叠加在狭窄坐标区。

Panel b 应当使读者在同一平台行内完成“长度—reported Q—Q20组成”的横向阅读，而不是在多个独立图之间反复寻找平台颜色。

### Panel c｜Reference-base coverage breadth across depth

- **科学问题**：原始 read 差异经过比对后如何响应 depth、reference 和 aligner？
- **角色**：全图 hero panel，占完整双栏宽度和最大高度。
- **数据**：全部36个观测，不聚合、不筛选。
- **图形**：1×4 独立小图的深度响应线图；顺序固定为
  GRCh38–minimap2、GRCh38–winnowmap、T2T-CHM13–minimap2、
  T2T-CHM13–winnowmap。
- **x轴**：Nominal depth（10、30、50×）；三个深度位于等距类别中心，
  浅灰竖线位于类别边界而不是穿过数据点；ONT 50×的实际值已由panel a交代。
- **y轴**：Reference bases covered ≥1× (%)；GRCh38为92.0–94.5%，
  T2T-CHM13为97.5–100.0%。两个窗口均跨2.5个百分点，使相同的垂直距离
  始终代表相同的百分点差值。
- **平台**：颜色；三个平台均使用同一实线圆点语法，平台图例由整张主图统一给出。
- **Aligner**：使用空间分图表达，不再叠加线型和点型编码。
- **标注**：不逐点标数，不添加“best”、箭头、排名、结论性背景色或inset。
- **作用**：同时呈现GRCh38上的平台收敛、T2T-CHM13上的平台分化、30×后的收益递减以及两种aligner的接近程度。

### Panel d｜30× primary mapped-read rate

- **科学问题**：匹配30×输入后，read-level primary mapping retention是否仍随平台、参考和aligner而变化？
- **角色**：在Panel c的position-level coverage breadth之后，补充不重复的read-level mapping结果。
- **数据**：12个30×观测。
- **图形**：按参考基因组分成GRCh38和T2T-CHM13两个独立小图的categorical condition dot plot。
- **x轴**：Aligner（minimap2、winnowmap）；两个类别位于等距中心，浅灰竖线位于类别边界而不穿过数据点。
- **y轴**：Primary mapped-read rate（97.5–100.10%），两个小图使用同一范围和刻度。
- **平台**：颜色；完全复用Panel c的BGI橙、ONT青、HiFi紫和实心圆点语法。
- **限制**：12个原始点精确定位；不使用coverage breadth、不连线、不抖动、不聚合、不拟合趋势，也不绘制截断柱形。
- **作用**：直接报告四个mapping条件中的平台分离，以及每个平台对reference和aligner变化的响应；与Panel c形成position-level breadth → read-level retention的互补证据链。

### Panel e｜30× BAM output footprint（可替换面板）

- **数据**：12个30×观测。
- **图形与编码**：复用Panel d的两个reference小图、aligner类别x轴和平台颜色编码，不绘制点间连接线。
- **y轴**：BAM size（0–115 GiB）。
- **默认位置**：Extended Data。
- **提升条件**：正文明确设置独立的storage-footprint结果段落，且与panel d并排后最终组图仍能在≤170 mm高度和5–7 pt字号下清晰阅读。

### 推荐组图布局

默认主图：

```text
┌────── a：input depth ──────┬──────────── b：30× read profile ────────────┐
├────────────────────────── c：coverage breadth ───────────────────────────┤
├────────────────────── d：primary mapped-read rate ───────────────────────┤
└───────────────────────────────────────────────────────────────────────────┘
```

- 顶行建议宽度比例约30:70；
- panel c占全图约40–45%的可用高度；
- panel d默认全宽；
- 目标组图尺寸183 mm × 155–165 mm。

若提升BAM面板：

```text
┌────── a ──────┬──────────────────── b ────────────────────┐
├────────────────────────── c ──────────────────────────────┤
├──────────────── d ────────────────┬──────── e ────────────┤
└────────────────────────────────────┴───────────────────────┘
```

当前任务仍分别输出单图，不因规划了组图版式而直接生成组合图。

## 5. Extended Data 与 Source Data 设计

### Extended Data 1｜Mean aligned depth

- 使用全部36个alignment条件。
- x轴优先使用 approximate input depth，而不是只写nominal depth。
- y轴为mean aligned depth，按reference分面，平台和aligner编码与主图一致。
- 作用是核对输入剂量进入比对后的深度实现情况，不与coverage breadth混为同一指标。

### Extended Data 2｜BAM footprint across input yield

- 使用全部36个alignment条件，并匹配9个reads QC输入层级。
- x轴使用实际input yield（Gb），y轴使用BAM size（GiB）。
- 按reference和aligner分面，展示三个嵌套深度的真实轨迹。
- 使用实际Gb可正确处理ONT nominal 50×只有153.68 Gb的情况，也比按nominal depth讨论“线性”更准确。

### Source Data

主图和Extended Data至少提供：

- 完整9行reads QC；
- 完整36行alignment QC；
- 每个panel实际使用的长表；
- fraction-to-percent转换后的字段；
- Q20-read base share及其明确公式；
- 每次筛选的before/after行数和唯一键审计。

不为同一批数据重复绘制密集热图。精确数字和完整矩阵由Source Data承担，正文图负责建立可读的证据结构。

## 6. 视觉与编码规范

### 6.1 平台与条件编码

- 平台固定映射：BGI橙色 `#FFB000`、ONT青色 `#13A4A6`、HiFi紫色 `#9400D3`。
- 颜色只编码平台，不在不同panel中改变语义。
- BGI橙色点通常使用细深色描边；Panel c为匹配四联折线图语法，三个平台统一使用
  无额外形状编码的实心圆点。平台名称和数值标签使用黑色，避免低对比度彩色文字。
- 两种aligner叠加在同一坐标区且必须区分时，minimap2使用实心圆、winnowmap使用空心菱形；只有连线本身代表连续响应或配对位移时才使用线型。
  Panel c已按aligner拆为空间独立小图；Panel d将aligner放在x轴类别位置，因此两图均不重复增加aligner形状或线型编码。
- 在平台已经由固定行位置或直接标签识别的panel中，不增加第二套平台形状编码。

### 6.2 版式层级

- 白色背景，无装饰性网格和面板外框。
- Panel标签由最终主图组版统一添加；Panel c内部四个小图不重复添加子图编号。
- 主图共享一个平台图例；aligner图例放在alignment区域附近。
- Panel c具有最高视觉权重；a只承担设计透明度，不能与hero panel等高。
- 依靠对齐、留白和尺寸层级组织阅读顺序，不使用奖牌、星号、彩色结论框或平台总分。

### 6.3 最终尺寸与导出

- Nature双栏目标宽度183 mm；主图高度目标155–165 mm，最大不超过170 mm。
- 最终尺寸下正文文字5–7 pt，panel label约8 pt，线宽约0.25–1 pt。
- R作为唯一绘图、预览和导出后端。
- 每个独立panel输出可编辑SVG、PDF、600 dpi TIFF和预览PNG。
- SVG/PDF必须保留文本对象并嵌入或正确引用sans-serif字体；不得将文字转曲或把线图整体栅格化。

## 7. 数据转换与完整性规则

### 7.1 允许的转换

```text
platform = remove "_latest" suffix
depth_numeric = remove "x" suffix
q20_read_pct = 100 × Reads with mean Q>20 fraction
q20_read_base_share_pct = 100 × Mean-Q>20 read yield / total yield
coverage_pct = 100 × Coverage rate
primary_mapped_pct = 100 × Primary mapped rate
read_length_kb = read_length_bp / 1000
```

所有转换只在绘图数据副本中进行，不覆盖源CSV。

### 7.2 禁止的处理

- 不把10×/30×/50×当作独立重复；
- 不计算p值、置信区间或跨技术条件的推断统计；
- 不为视觉整齐排除不利点或异常组合；
- 不对三个深度进行平滑、插值或拟合后替代真实值；
- 不把mean、median和N50连接成伪区间；
- 不使用没有read-level源数据支持的violin、density、ECDF或quality–length hexbin；
- 不把单平台存在的per-base Q≥20数据填补给其他平台。

## 8. 图注与正文写作要求

正式图注必须在脱离正文时仍可回答以下问题：

- 样本为HG002；
- 10×、30×和50×是嵌套子集；
- ONT nominal 50×的approximate input depth为47.768×；
- panel b为何选择30×；
- reported read Q与truth-based empirical accuracy的区别；
- Q20-read base share的定义；
- coverage breadth表示reference bases covered at ≥1×；
- minimap2和winnowmap的形状、线型编码；
- 条件不是生物学重复，因此没有误差线或显著性检验。

正文避免以下表达：

- “三平台在所有参考上完全收敛”；
- “T2T-CHM13证明复杂区域恢复能力更强”；
- “reported Q直接证明真实碱基准确率”；
- “BAM更小说明运行更快或成本更低”；
- “某个平台综合最好”。

推荐使用：

- `reported read Q-score profile`；
- `reference-base coverage breadth`；
- `reference-specific platform response`；
- `primary mapped-read rate`；
- `BAM output footprint under the current workflow`。

## 9. 当前明确不纳入的项目

- 30× apparent-error spectrum pilot；
- 仅BGI存在的SeqKit individual bases Q≥20比例；
- BAM路径、修改时间和Status等运行元数据；
- 单独的read count或total bases主图，因为它们与匹配产量和平均读长高度冗余；
- 无read-level源数据支持的分布图；
- 雷达图、饼图、综合评分、平台排名和重复展示同一结果的热图。

正式donor-specific error spectrum完成后，应作为经验准确性证据单独设计，而不是回填到当前reported Q panel中。

## 10. 实现与验收标准

### 10.1 数据完整性

- reads QC完整读取9行；30×代表层恰好包含BGI、ONT和HiFi各1行。
- alignment QC完整读取36行；每个platform–depth–reference–aligner组合恰好1行。
- Panel a使用9行；panel b使用3行；panel c使用36行；panel d和可选panel e各使用12行。
- 派生后确认30× Q>20 read fraction为33.6%、78.3%、93.2%。
- 派生后确认Q20-read base share为40.3%、83.0%、91.7%。
- 复算确认coverage signed median aligner difference为−0.025个百分点，median absolute difference为0.050个百分点。

### 10.2 图形正确性

- Panel a中ONT 47.768×清晰可见。
- Panel b不把summary statistics画成误差区间。
- Panel c两个reference使用不同起点但相同2.5个百分点跨度的y轴窗口，
  四个小图保留全部36个点；深度点位于类别中心，竖线只标记类别边界。
- Panel d恰好保留12个30×原始点，两个reference小图共享97.5–100.10%的y轴；aligner点位于类别中心，竖线只标记类别边界；不复用coverage breadth且不绘制点间连接线。
- 若保留可选Panel e，同样恰好绘制12个原始点，并沿用Panel d的无连接线categorical condition dot plot。
- 百分比轴缩放只用于点线图，不用于截断柱形。
- 所有数值标签均由绘图数据生成，不手工抄成不可追踪常量。

### 10.3 视觉QA

- 每个单图按其未来组图槽位尺寸单独检查，而不是只看放大的工作预览。
- 检查灰度、常见色觉缺陷和低分辨率PDF预览中的平台可辨识度。
- 检查BGI橙色点、ONT青色点、HiFi紫色点、Panel d中相邻但不重叠的观测以及5–7 pt文字是否仍可读。
- 检查SVG/PDF文字可编辑、字体无意外替换、TIFF尺寸和DPI正确。

### 10.4 读者验收问题

读者脱离正文后，应能从主图回答：

1. 三个平台的输入深度是否匹配，50×层级有什么例外？
2. 匹配产量下，三个平台分别提供怎样的read length与reported Q-score profile？
3. Coverage breadth主要如何响应reference、depth和aligner？
4. GRCh38上的平台收敛是否能够直接外推到T2T-CHM13？
5. Coverage breadth接近时，primary mapped-read rate是否仍然不同？
6. 哪些结果可以作为下游任务的输入解释基线，哪些不能被扩展成平台总排名？
