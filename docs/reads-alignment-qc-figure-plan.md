# Reads 与比对 QC 正文结果图及科研叙事方案

> 状态：增强确认版  
> 确认日期：2026-08-08
> 论文角色：开篇主结果图，用于建立后续变异检测、相位与组装分析的输入基线  
> 适用范围：HG002 三平台 reads QC、GRCh38/T2T-CHM13 双参考比对 QC  
> Extended Data：30×表观 alignment-error spectrum pilot
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
| Pilot validation evidence | GRCh38/GIAB-masked apparent alignment-error spectrum，Extended Data |
| 统计定位 | 单个 HG002 的技术条件矩阵；描述性比较，不做群体推断 |
| 最终组图尺寸 | 183 mm 宽，目标高度 155–165 mm，绝不超过 170 mm |
| 单图后端 | R / ggplot2；SVG、PDF、TIFF 和预览 PNG |

证据阅读顺序固定为：

1. **比较是否公平**：输入剂量是否匹配；
2. **输入是什么**：匹配产量下的 read length 与 reported Q-score profile；
3. **比对后发生什么**：coverage breadth 如何响应 depth、reference 和 aligner；
4. **哪些差异仍保留**：primary mapped-read rate，以及可选的 BAM footprint；
5. **局部高质量比对中残留什么**：apparent mismatch、insertion 和 deletion spectrum；
6. **为什么影响后文**：相同总碱基量不等于相同的信息结构或分析输入。

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

### 2.7 Apparent alignment-error spectrum

- 使用GRCh38上chr1/2/3各约1 Mb pilot窗口与GIAB high-confidence regions的交集，并屏蔽已知truth variant sites。
- 只统计primary、MAPQ≥20、BQ≥20比对中的mismatch bases、insertion bases和deletion bases；三类碱基数以aligned Q20 bases为共同分母并标准化为每1,000 bases。
- 该指标报告当前参考、mask、区域和比对流程下的alignment residual，不写作平台本征错误率或全基因组经验准确性。

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

四个 reference–aligner 条件中的平台顺序均为 BGI、ONT、HiFi。在匹配 reference 和 aligner 时，BGI/ONT BAM 约为 HiFi 的2.36–2.72倍；30×下六个 platform–reference 配对中，winnowmap BAM 均小于 minimap2，降幅约6.6–11.5%；六个 platform–aligner 配对中，T2T-CHM13 BAM 也均小于 GRCh38。Panel e 因而需要同时保留平台、aligner 和 reference 三个可直接读取的比较方向，而不是只画其中一组配对差值。

**论文定位。** 该指标具有实际流程价值，但科学优先级低于 read profile、coverage breadth 和 primary mapping。默认作为 Extended Data；只有当正文将存储占用写成独立结果段落、且最终版面仍能保证可读性时，才提升为主图 panel e。

### 3.6 GIAB-masked pilot regions 中保留平台特异的表观错误组成

**实验。** 对三个平台的30× GRCh38 BAM分别使用minimap2和winnowmap结果，在2,981,290个pilot-region bases中屏蔽6,488个GIAB truth sites，并以aligned Q20 bases为分母统计mismatch、insertion和deletion bases。

**结果。** 两个aligner中的total apparent-error burden均保持BGI、ONT、HiFi的顺序：BGI为17.239–17.552、ONT为6.351–6.436、HiFi为1.101–1.117 errors per 1,000 aligned Q20 bases。Deletion bases占BGI总量的85.4–85.7%、ONT的84.5–84.6%，在HiFi中为57.3–58.6%。Winnowmap相对minimap2的总量变化为BGI −1.78%、ONT −1.32%、HiFi +1.47%，未改变主要平台结构。

**论文定位。** 这组结果作为Extended Data报告局部GIAB-masked条件下的表观alignment residual及组成，连接reported read Q与下游variant calling；正式donor-specific mat/pat error spectrum仍承担平台经验准确性的主结论。

### 3.7 与后续实验衔接

Results 本节建议用以下逻辑收束：

> Together, these results show that matching total sequencing yield equalizes input dosage but not the information structure presented to downstream workflows. Variant calling, phasing and assembly outcomes therefore need to be interpreted in the context of platform-specific read-length and reported Q-score profiles, primary mapping retention and reference-dependent coverage breadth.

这句话只总结本图直接支撑的事实，不提前解释具体下游任务的性能高低。

## 4. 正文主图设计

主图默认由 panel a–d 构成；panel e 单独生成并保留替换位。最终版面采用一个明显的 hero panel，而不是六个等权小图。

### Panel a｜Approximate input depth

- **科学问题**：三个平台的输入剂量是否匹配？
- **数据**：reads QC 全部9个观测。
- **图形**：三行nested-depth ruler；每个平台占据独立一行，不再使用点、折线或图例。
- **水平标尺**：共享0–50×深度范围；浅灰竖线标记10×、30×和50×目标位置，浅灰底轨道延伸至50×。
- **嵌套结构**：每条平台色带的三个连续区段依次终止于实际10×、30×和最高深度；内部白色切口对应前两个实际子集边界，色带终点对应最高深度。
- **标注**：9个approximate input depth全部由绘图数据生成并直接写入相应区段；ONT末段在47.768×停止，其后到50×的灰色缺口保持可见。
- **编码**：BGI橙、ONT青、HiFi紫；平台使用固定行位置和直接标签，不再依赖叠加轨迹或独立图例。
- **尺寸**：60 × 34 mm，匹配主图顶行约30%宽度的紧凑槽位。
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
- **图形**：紧凑的3×4 annotated heatmap；行是BGI、ONT、HiFi，列按GRCh38和T2T-CHM13分组，每组依次为minimap2、winnowmap。
- **填色**：统一的97.9–100.0%顺序蓝灰色标表示primary mapped-read rate；每格叠加两位小数的原始百分比，使精确值不依赖颜色估读。
- **平台**：行名旁保留Panel c的BGI橙、ONT青、HiFi紫圆点，平台色不参与数值填色。
- **尺寸**：89 mm单栏宽度；12个单元格占据主体画布，避免把稀疏观测摊成宽幅点图。
- **限制**：12个原始值逐格呈现；不使用coverage breadth、不连线、不聚合、不增加“best”或排名标记。
- **作用**：直接报告四个mapping条件中的平台分离，以及每个平台对reference和aligner变化的响应；与Panel c形成position-level breadth → read-level retention的互补证据链。

### Panel e｜30× BAM output footprint（可替换面板）

- **科学问题**：匹配30×输入后，统一流程产生的BAM存储占用如何随平台、参考基因组和aligner变化？
- **角色**：在Panel d报告read-level retention之后，补充同一12条件矩阵中的实际输出规模；二者共享实验骨架，但回答不同问题。
- **数据**：12个30×观测。
- **图形**：紧凑的3×4 in-cell horizontal-bar matrix；行与列顺序完全复用Panel d，保持两个单栏面板可无缝并排。
- **长度编码**：每格先画相同长度的浅灰0–115 GiB轨道，再由同一起点绘制平台色水平条；所有12格共享真实零基线和相同上限，因此条长可跨格直接比较。
- **精确值**：每格直接标注两位小数的BAM size；BGI和ONT数值置于条内末端，HiFi数值置于短条右侧，避免遮挡且不依赖颜色估读。
- **平台与条件**：BGI橙、ONT青、HiFi紫沿用全文语义；reference用上方分组标题，aligner用列标签表达，不增加点型、线型或图例。
- **尺寸与限制**：89 × 54 mm；不使用哑铃图、点图、连接线、热图色阶、聚合、排序或“best”标记。
- **作用**：一张图同时显示稳定的平台层级、同平台的aligner变化以及同平台–aligner的reference变化；统一零基线保留BAM size作为绝对量的正确视觉语义。
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

### Extended Data 3｜30× apparent alignment-error spectrum pilot

- 使用`error_spectrum_pilot.csv`全部6个platform–aligner条件。
- 采用3×2 stacked horizontal-bar matrix；每格共享0–18 errors per 1,000 aligned Q20 bases的真实零基线。
- Mismatch、insertion和deletion以可加的error bases rate堆叠；条末直接标注total apparent-error burden。
- 平台以固定行和全文统一色圆点识别，aligner以空间列区分，error component使用独立的低饱和度色组。
- 事件数、reads seen和aligned Q20 bases保留在Source Data，不与标准化error-base rate混入同一视觉尺度。
- 最终尺寸89 × 54 mm；不使用误差线、配对连接线、排名或第二张重复热图。

### Source Data

主图和Extended Data至少提供：

- 完整9行reads QC；
- 完整36行alignment QC；
- 完整6行apparent-error pilot及重算后的component rates；
- 每个panel实际使用的长表；
- fraction-to-percent转换后的字段；
- Q20-read base share及其明确公式；
- 每次筛选的before/after行数和唯一键审计。

不为同一批数据重复绘制密集热图。精确数字和完整矩阵由Source Data承担，正文图负责建立可读的证据结构。

## 6. 视觉与编码规范

### 6.1 平台与条件编码

- 平台固定映射：BGI橙色 `#FFB000`、ONT青色 `#13A4A6`、HiFi紫色 `#9400D3`。
- 平台身份固定使用BGI橙、ONT青、HiFi紫，不在不同panel中改变语义。
- Panel d等定量热图使用独立的顺序蓝灰色标编码连续指标；平台固定色只出现在行标记中，不用于热图填色。
- BGI橙色点通常使用细深色描边；Panel c为匹配四联折线图语法，三个平台统一使用
  无额外形状编码的实心圆点。平台名称和数值标签使用黑色，避免低对比度彩色文字。
- 两种aligner叠加在同一坐标区且必须区分时，minimap2使用实心圆、winnowmap使用空心菱形；只有连线本身代表连续响应或配对位移时才使用线型。
  Panel c已按aligner拆为空间独立小图；Panel d将aligner放在热图列位置，因此两图均不重复增加aligner形状或线型编码。
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
- Apparent-error Extended Data使用全部6行，恰好覆盖3平台×2 aligner；不筛除任何条件。
- 派生后确认30× Q>20 read fraction为33.6%、78.3%、93.2%。
- 派生后确认Q20-read base share为40.3%、83.0%、91.7%。
- 复算确认coverage signed median aligner difference为−0.025个百分点，median absolute difference为0.050个百分点。

### 10.2 图形正确性

- Panel a包含3条空间独立的平台标尺、9个连续嵌套区段和9个实际深度标签；任何平台均不得被另一平台覆盖，ONT 47.768×后的目标缺口清晰可见。
- Panel b不把summary statistics画成误差区间。
- Panel c两个reference使用不同起点但相同2.5个百分点跨度的y轴窗口，
  四个小图保留全部36个点；深度点位于类别中心，竖线只标记类别边界。
- Panel d恰好保留12个30×原始单元格，行列键与platform–reference–aligner一一对应；统一填色色标为97.9–100.0%，每格数值直接来自绘图数据，不复用coverage breadth。
- 若保留可选Panel e，同样恰好绘制12个原始单元格；每格为共同0–115 GiB尺度的零基线条形轨道，行列键与Panel d完全一致，但不复用热图编码。
- Apparent-error Extended Data恰好绘制6个共同0–18尺度的堆叠条形；18个component segments从原始碱基数重算，三段之和逐条件恢复total error rate。
- 百分比轴缩放只用于点线图，不用于截断柱形。
- 所有数值标签均由绘图数据生成，不手工抄成不可追踪常量。

### 10.3 视觉QA

- 每个单图按其未来组图槽位尺寸单独检查，而不是只看放大的工作预览。
- 检查灰度、常见色觉缺陷和低分辨率PDF预览中的平台可辨识度。
- 检查Panel a的9个区段内数值、白色嵌套边界、灰色目标标尺和ONT最高深度缺口在60 × 34 mm最终尺寸下是否清晰。
- 检查BGI橙色、ONT青色、HiFi紫色语义，Panel d深浅单元格中的黑/白数值文字，Panel e长条内和短条外数值文字，以及5–7 pt标签在89 mm最终宽度下是否仍可读。
- 检查apparent-error图中的细小mismatch段仍可见、六个total标签不与堆叠边界冲突、两个aligner共享相同0–18尺度且component legend在89 mm宽度下可读。
- 检查SVG/PDF文字可编辑、字体无意外替换、TIFF尺寸和DPI正确。

### 10.4 读者验收问题

读者脱离正文后，应能从主图回答：

1. 三个平台的输入深度是否匹配，50×层级有什么例外？
2. 匹配产量下，三个平台分别提供怎样的read length与reported Q-score profile？
3. Coverage breadth主要如何响应reference、depth和aligner？
4. GRCh38上的平台收敛是否能够直接外推到T2T-CHM13？
5. Coverage breadth接近时，primary mapped-read rate是否仍然不同？
6. 哪些结果可以作为下游任务的输入解释基线，哪些不能被扩展成平台总排名？

Extended Data还应独立回答：在GIAB-masked pilot regions中，三个平台的total apparent-error burden与mismatch/insertion/deletion组成是否在两个aligner下保持相同主要结构？
