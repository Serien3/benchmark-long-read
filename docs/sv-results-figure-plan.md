# SV Results 科研叙事与正文大组图设计

> 状态：依据现有可视化产物校核后的正文组图版
>
> 修订日期：2026-08-08
>
> 适用范围：alignment-based SV 主评测、30×误差构成、BGI深度梯度、低频/嵌合SV与移动元件检测
>
> 组图约束：上述结果全部进入**同一张正文大组图**；GT-F1、其它深度PR、深度增量和caller调参进入支持材料

## 1. 不可混淆的数据口径

### 1.1 真值集与主评测

- 全基因组SV主真值为 **HG002 T2T-Q100 v1.1**。
- 困难医学相关基因区域使用 **GIAB CMRG**。
- 此前标为“SV-GIAB v5.0q”的GRCh38 SV结果不是第二套独立SV证据，不能作为GIAB v5.0q SV truth报告。
- 全基因组正文结果必须来自 `data/sv_benchmark_T2TQ100.csv`；CMRG来自 `data/sv_benchmark_CMRG.csv`。
- `figures/SV_benchmark/sv_f1_caller_aligner/sv_detection_f1_GIAB5.*` **不能原样进入论文**，也不能只替换标题；必须从T2T-Q100源表重新绘制。

### 1.2 公平比较矩阵

正文对称比较固定为：

- 样本：HG002；
- 参考基因组：GRCh38；
- 平台：BGI、ONT、HiFi；
- 深度：10×、30×、50×；
- aligner：minimap2、winnowmap；
- caller：cuteSV、Sniffles2、sawfish、SVDSS；
- 主指标：raw Precision、Recall和detection F1。

不报告T2T-CHM13、deBreak、Svision-pro，也不把缺失组合连接或补齐。

### 1.3 指标层级

- 总体平台比较与30×PR图使用raw指标，保持对称主评测口径。
- BGI密集深度实验按已完成流程报告Truvari refine Recall和refine F1；它是**BGI流程压力测试**，不与上方raw F1作绝对数值横向比较。
- GT-F1是独立终点，不与detection F1、PR和候选计数混在正文hero panel中，完整结果进入支持材料。
- TP-base/FN与TP-call/FP分别使用不同分母：外环描述truth accounting，内环描述call accounting；两环面积不能互相解释为同一组成比例。

### 1.4 特殊SV结果的边界

- 低频/嵌合SV结果没有mosaic truth set，只能报告候选数量、SV类型组成和VAF区间组成。
- xTEA-long移动元件结果没有独立truth benchmark，只能报告最终合并候选数量和ALU、LINE1、SVA、HERV组成。
- 候选数更多或更少均不等价于灵敏度、精确率或生物学负荷高低。
- 当前数据没有SVTYPE或size分层的truth-based TP/FN/FP矩阵；正文不得暗示环图扇区代表SVTYPE或size stratification。

## 2. 现有可视化产物审计与正文去向

| 现有目录 | 实际内容 | 数据完整性 | 正文去向与必要修改 |
|---|---|---:|---|
| `sv_f1_caller_aligner` | 每套benchmark 72个workflow观测，同时画detection F1与GT-F1，共144个点 | CMRG完整；现有GIAB5面板口径不可用 | 从T2T-Q100重绘；正文组图版只画detection F1，T2T与CMRG分别作为panel a、b；完整GT-F1版转支持材料 |
| `sv_pr_30x_landscape` | T2T-Q100与CMRG各24个30× PR点，含inset | 完整 | 两张inset图分别作为panel c、d；组图版统一外层坐标语义和图例 |
| `sv_benchmark_accounting_donut` | T2T-Q100、30×、minimap2，cuteSV/Sniffles2 × 3平台，共6个workflow | 完整 | 作为panel e；保留全部TP-base、FN、TP-call、FP原始计数，压缩为2×3环图矩阵 |
| `sv_depth_gradient_bgi` | cuteSV与Sniffles2各14个5–70×完整深度点 | 28/28完整 | 两个score-only结果分别作为panel f、g；正文不画ΔF1/5× |
| `mosaic_sv_dual_track` | 3平台×2 aligner的30×候选数量、5类SV组成及2个VAF区间组成 | 6/6完整 | 作为panel h；明确为candidate landscape，不使用accuracy措辞 |
| `me_xtea` | 3平台×2 aligner的ME候选数和4类家族组成 | 6/6完整 | 100% composition版本作为panel i，并保留绝对总数 `n=`；绝对数量堆叠版进入支持材料 |
| `caller_tuning` | cuteSV 162个第一轮组合、14个第二轮实验；Sniffles2 3×3矩阵与跨深度验证 | 相应设计完整；HiFi refine有缺失 | 全部进入支持材料，不进入正文大组图 |

**重要：**正文组图必须由原始数据重新生成“组图专用版本”。当前183 mm宽的单图不能直接缩到半栏，否则文字、caller标签和数值会低于可读尺寸。

## 3. SV Results 的核心科学问题

正文SV结果回答四个递进问题：

1. 在匹配深度和统一分析矩阵下，平台差异是否独立于caller和aligner？
2. 检测F1差异具体来自Precision还是Recall，并对应多少TP、FN和FP记录？
3. 增加测序深度能否持续改善结果，这种响应是否依赖caller？
4. 当分析扩展到低频/嵌合SV和移动元件时，不同平台–aligner workflow实际产生怎样的候选谱？

由此形成一个闭合而不过度解释的证据链：

> **总体检测表现（a–b） → 30×误差几何与原始计数（c–e） → 深度压力测试（f–g） → 特殊SV任务中的候选输出（h–i）**

前七个panel回答benchmark performance；最后两个panel回答specialized-calling output。二者属于同一SV结果模块，但解释边界必须通过行标题、panel标题和图注明确分开。

## 4. Results 叙事结构

### 4.1 对称workflow矩阵揭示平台差异依赖caller与aligner

- 首先报告T2T-Q100和CMRG的全部detection F1，不使用平台均值替代workflow数据。
- T2T-Q100 30×下，8个caller–aligner workflow的描述性中位F1为：BGI 0.810、ONT 0.829、HiFi 0.825。
- T2T-Q100中，winnowmap相对minimap2的配对中位ΔF1为：BGI −0.0056、ONT −0.0068、HiFi −0.0190；该结果是workflow描述，不是aligner总体显著性检验。
- CMRG中排序和轨迹发生改变。BGI–minimap2–SVDSS的F1由10×的0.671降至30×的0.405和50×的0.266，是必须保留的真实失稳结果。
- 该组合Recall由0.746升至0.834和0.857，但Precision由0.609降至0.268和0.157；因此F1下降来自FP负担增加所导致的Precision损失，而非检出不足。
- 结论限定为platform–caller–aligner–benchmark interaction，不将单一失败workflow外推为平台固有缺陷。

### 4.2 30× PR与原始benchmark accounting解释F1构成

- 30×是三平台、两aligner、四caller均完整的中间深度，也是10×不足与50×趋稳之间的预设代表深度，不是按结果挑选。
- T2T-Q100和CMRG各保留24个真实PR点；平台映射颜色、caller映射形状、aligner映射实心/空心。
- PR外层主坐标必须对称且在两benchmark间具有可比较语义；inset只放大密集区域，inset范围必须明确标注。
- T2T环图进一步展示预先限定的minimap2、cuteSV/Sniffles2、三平台六个workflow的TP-base、FN、TP-call和FP绝对计数。
- 环图不是caller排名图，也不代表全部四个caller或两个aligner；它用于把PR比例还原为直接benchmark记录规模。

### 4.3 BGI密集深度梯度检验流程响应

- panel f、g分别保留cuteSV和Sniffles2在5×–70×的全部14个观测深度。
- cuteSV refine F1由5×的0.794升至30×的0.877、50×的0.900和70×的0.904；refine Recall相应由0.681升至0.799、0.840和0.845。
- Sniffles2 refine F1由5×的0.632升至30×的0.892，40×后维持约0.896–0.898；refine Recall由0.468升至30×的0.827，之后约为0.833–0.835。
- 正文只画每个深度的直接refine Recall和refine F1，不画“平台期”“收益衰减”文字、箭头、最优深度阴影或ΔF1。
- “主要收益集中在较低至中等深度、且caller响应不同”由读者根据轨迹推断，在正文中再作限定性表述。
- sawfish、SVDSS和90×不进入该panel；排除规则必须保留在source-data audit中。

### 4.4 特殊SV任务扩展结果范围，但不等价于准确率验证

- 低频/嵌合SV panel直接展示六个workflow的绝对候选总数、DEL/INS/DUP/INV/BND组成和VAF 5–10%/10–20%组成。
- 当前候选总数范围为1,185–4,098；这种差异只能描述workflow输出负担。
- ME panel展示六个workflow的ALU、LINE1、SVA和HERV组成，最终候选总数为1,962–2,011；ALU约占81.5–82.7%。
- ME家族组成相近不等于事件级重叠或召回一致；没有事件交集数据时不得使用“高度一致检出”措辞。
- h–i共同支持“分析任务改变可见的变异输出谱”，不支持“某平台在mosaic/ME检测中更准确”。

## 5. 唯一正文大组图设计

建议图题：

> **Workflow- and depth-dependent structural variant detection and candidate profiles across long-read platforms**

建议整图尺寸：双栏宽183 mm，高度目标约245–250 mm。若目标期刊最终允许高度更低，必须重新排版或删减嵌入标题，不能整体等比例缩小到文字低于5 pt。

### 5.1 组图结构

```text
┌──────────────────────────────────────────────────────────────┐
│ a  T2T-Q100 detection F1      │ b  CMRG detection F1         │
│    caller × aligner workflows │    caller × aligner workflows│
├──────────────────┬──────────────────┬────────────────────────┤
│ c  T2T-Q100 PR   │ d  CMRG PR       │ e  TP/FN/FP accounting │
│    30× + inset   │    30× + inset   │    2 callers × 3 plats │
├───────────────────────────────┬──────────────────────────────┤
│ f  BGI depth: cuteSV          │ g  BGI depth: Sniffles2      │
├──────────────────────────────────────┬───────────────────────┤
│ h  Low-VAF/mosaic SV candidate       │ i  MEI composition    │
│    counts + SV type + VAF pies       │    + absolute totals  │
└──────────────────────────────────────┴───────────────────────┘
```

建议面板占位：

- a、b：各约89 ×62–66 mm；
- c、d：各约52 ×52 mm；
- e：约75 ×52 mm；
- f、g：各约89 ×52–56 mm；
- h：约118 ×66–70 mm；
- i：约62 ×66–70 mm。

这是一张a–i正文图，不拆分为第二张SV正文图。

### 5.2 panel a–b｜总体detection F1

- a为T2T-Q100，b为CMRG；两张图在第一行等宽并列。
- 每个panel仅画72个detection F1点；GT-F1不进入a、b。
- caller按固定顺序cuteSV、Sniffles2、sawfish、SVDSS；深度按10×、30×、50×连接。
- 平台颜色固定为BGI橙、ONT青、HiFi紫；深度同时由点透明度或明度冗余编码。
- T2T和CMRG使用相同F1纵轴范围，不裁掉CMRG低值，也不分别自动缩放制造视觉幅度差。
- 不标“best”、排名、均值线、显著性或异常箭头。

### 5.3 panel c–d｜30× PR landscape

- c使用 `sv_pr_30x_T2TQ100_inset` 的数据；d使用 `sv_pr_30x_CMRG_inset` 的数据。
- x轴为Recall，y轴为Precision；两轴在每个panel内严格对称、1:1比例。
- 为支持c/d直接对照，组图版外层主坐标应使用共同范围；各自inset保留不同放大范围并明确刻度。
- 每个panel保留24个点；不抖动、不聚合、不改变坐标。
- F1等值线是读取辅助，不承担结论编码；仅保留少量共同水平。

### 5.4 panel e｜TP/FN/FP环图

- 2行caller（cuteSV、Sniffles2）×3列平台（BGI、ONT、HiFi）。
- 条件固定为T2T-Q100、30×、GRCh38、minimap2。
- 外环：TP-base与FN；内环：TP-call与FP；全部四类绝对数直接标注。
- 组图版移除重复总标题和大图例，保留一个紧凑局部图例。
- 不增加比例差、召回损失、FP倍率或“最佳caller”标签。

### 5.5 panel f–g｜BGI深度响应

- f为cuteSV，g为Sniffles2；两张图在第三行等宽并列，共享0–1纵轴和5×–70×数值深度轴。
- 每个caller保留14个refine Recall柱和14个refine F1点/线。
- 正文采用score-only版本，不放ΔF1/5×下部区域。
- 组图版不必给14个深度全部印数值；可以按预设锚点5×、10×、30×、50×、70×标值，但所有14个观测标记必须存在。
- 面板标题必须写明“BGI · GRCh38/minimap2 · Truvari refine”，避免与a–d的raw指标混读。

### 5.6 panel h｜低频/嵌合SV候选谱

- 保留六个workflow的五类SV绝对堆叠柱和六个等面积VAF饼图。
- bar从零开始，所有总候选数直接标注；饼图只编码每个workflow内部的两个VAF比例。
- 组图版可减少过密的小分段百分比文字，但不能删除任何SV类型段或改变其高度。
- 标题使用“Low-VAF SV candidate landscape”，避免使用mosaic sensitivity/performance。

### 5.7 panel i｜移动元件候选组成

- 正文使用100% composition版本，以便在较窄panel中读取ALU/LINE1/SVA/HERV构成。
- 六个workflow全部保留，绝对总数以 `n=` 标在柱顶。
- HERV保持真实0.3–0.4%高度，用引线和原始数量读取，不人为放大。
- aligner可在窄panel中缩写为MM2与WM，但图例或图注明确定义。

## 6. 整图的视觉一致性

### 6.1 全局编码

- 平台颜色全文固定：BGI橙、ONT青、HiFi紫。
- a–b使用固定caller顺序；c–d使用caller形状，并保持cuteSV、Sniffles2、sawfish、SVDSS映射一致。
- aligner在a–d中统一使用分面或实心/空心；h–i中使用x轴层级，不再发明新颜色。
- 深度在a–b中使用10×/30×/50×透明度，在f–g中使用连续数值轴；两个编码不合并成含混图例。
- 灰蓝、棕、紫灰等局部调色仅用于refine指标、SV类型、VAF和ME家族，不与平台颜色竞争。

### 6.2 图例策略

- a–d共用一个紧凑图例区：平台颜色全局共享；a–b另示深度，c–d另示caller形状和aligner实心/空心。
- e保留独立的truth/call accounting图例。
- f、g共享refine Recall/refine F1图例。
- h、i分别保留紧凑的SV类型/VAF与ME家族图例；不建立跨h/i的伪统一分类图例。
- 全图不重复嵌入九个大标题；panel标签a–i与简短行标题承担层级。

### 6.3 逻辑分区

- a–g上方或左侧使用小型组标题：**Benchmark performance**。
- h–i使用小型组标题：**Specialized candidate profiles**。
- 两个组标题只说明数据类别，不写“plateau”“failure”“superior”等结论词。
- 可用一条细灰分隔线区分g与h–i，避免读者把候选数量当作benchmark accuracy的延续。

## 7. 支持材料安排

除上述a–i外，其余SV可视化全部进入支持材料：

### Supplementary/Extended Data 1｜SV genotyping agreement

- T2T-Q100与CMRG的完整GT-F1 workflow轨迹。
- 可与detection F1并列用于说明“检测到事件”与“基因型一致”是不同终点。
- 现有GIAB5版本必须改为T2T-Q100数据后才能使用。

### Supplementary/Extended Data 2｜其它深度PR与完整视图

- T2T-Q100和CMRG的10×、50× PR图。
- 30×无inset原图可作为坐标审计版本。
- 所有图保留各自真实坐标范围和source-data表。

### Supplementary/Extended Data 3｜深度增量视图

- cuteSV与Sniffles2的完整with-delta版本。
- ΔF1/5×是相邻观测的派生量，只用于补充解释深度收益变化，不进入正文主图。

### Supplementary/Extended Data 4｜benchmark accounting与特殊任务补充

- 环图的独立全尺寸版本。
- MEI绝对候选数量堆叠版。
- mosaic与ME的完整source-data、过滤审计和状态说明。

### Supplementary/Extended Data 5｜caller调参

- cuteSV第一轮四张81格参数空间图。
- cuteSV第二轮14个定向精调实验。
- Sniffles2 raw、refined、CMRG三张3×3矩阵及跨深度验证。
- cuteSV HiFi参数PR图只有6个点，因为数据设计为2套参数×3个深度；它是参数敏感性验证，不是完整调参空间。
- `cuteSV-HiFi`工作表的“GIAB v5.0q”来源标签在引用前必须确认；50× HiFi-specific refine F1缺失，不得插补。

## 8. 正文数字与表述校验

正文可以报告但必须由脚本重新计算的描述性数字包括：

- T2T-Q100 30×各平台跨8个workflow的中位F1；
- 10×→30×与30×→50×的描述性中位F1变化：BGI约+0.0566与+0.0027，ONT约+0.0339与+0.0020，HiFi约+0.0444与+0.0064；
- CMRG中特定workflow的Precision、Recall和F1轨迹；
- BGI深度梯度中每个caller的直接refine Recall和refine F1。

表述限制：

- workflow不是生物学重复，不使用误差线、置信区间、p值或显著性语言；
- 跨workflow中位数是描述性汇总，不是平台总体推断；
- CMRG不能仅因F1不同而被概括为“普遍更难”；
- mosaic/ME候选数不能写成召回率、准确率或真实生物学事件负荷；
- 不把某个caller–platform失稳解释为尚未验证的算法机制。

## 9. 实现与验收标准

### 9.1 数据完整性

- a、b：各72个detection F1点；
- c、d：各24个30× PR点；
- e：6个workflow，每个保留TP-base、FN、TP-call、FP；
- f、g：各14个caller–depth观测，同时显示refine Recall与refine F1；
- h：6个workflow、5类SV计数和2个VAF边际组成；
- i：6个workflow、4类ME家族计数及绝对总数；
- 每个panel附source-data、过滤审计和渲染清单。

### 9.2 可视化

- 最终183 mm宽成图中，正文/刻度/图例文字不得低于5 pt，优先5.5–7 pt；
- 不把当前全宽单图机械缩小；必须按上述panel占位重新排版；
- 不裁剪CMRG低值，不移动重合点，不平滑或插值深度轨迹；
- c/d外层坐标语义一致，inset坐标明确；
- f/g保留真实数值深度间距；
- h/i保留零基线或100%组成的正确分母；
- SVG/PDF文字可编辑，TIFF 600 dpi，PNG仅作预览；
- R是唯一绘图、预览、组图和导出后端。

### 9.3 投稿尺寸风险

该设计已经接近双栏全页信息上限。最终组图后必须在100%打印尺寸检查：

- a、b中caller、aligner和深度是否仍可区分；
- e中四类计数是否仍完整可读；
- h的VAF饼图和小SV类型段是否可辨；
- i的HERV引线和绝对数量是否清楚；
- 全图高度是否符合目标期刊当期规格。

如果任一项失败，应优先减少重复标题、冗余图例和非必要数值标签；不得通过删数据、合并类别或把字体压到5 pt以下解决。

## 10. 读者验收问题

读者脱离正文后，应能从这一张a–i大图回答：

1. 三个平台在匹配深度下是否存在脱离caller、aligner和benchmark的稳定绝对排名？
2. 30×下，相近或不同F1分别对应怎样的Precision–Recall位置以及TP/FN/FP规模？
3. BGI在不同caller下随深度增加呈现怎样的直接Recall和F1响应？
4. 低频/嵌合SV和ME流程分别输出怎样的候选数量与组成？
5. 哪些panel是truth-based performance，哪些panel只能解释为candidate profiles？

只有这五个问题都能被正确回答，且读者不会把h–i误读为准确率比较，正文大组图才算完成逻辑闭环。
