# SV Results 科研叙事与主图设计

> 状态：实现前确认版  
> 确认日期：2026-08-05  
> 适用范围：alignment-based SV 主评测、CMRG 评测与 BGI 深度梯度

## 1. 已确认的数据口径

- 全基因组 SV 主真值统一为 **HG002 T2T-Q100 v1.1 SV truth**。
- 困难医学相关基因区域使用 **GIAB CMRG** 评测集。
- 此前标为“SV-GIAB v5.0q”的 GRCh38 raw Precision、Recall 和 F1 实际是被误标的 T2T-Q100 重复实验结果，不作为第二套独立证据，也不在正文中以 GIAB v5.0q SV truth 报告。
- 全基因组主图以 `data/sv_benchmark_T2TQ100.csv` 为唯一数据源；CMRG 使用 `data/sv_benchmark_CMRG.csv`；BGI 密集深度实验使用 `data/sv_depth_gradient_bgi.csv`。
- 仅保留 GRCh38、BGI/ONT/HiFi、minimap2/winnowmap、10×/30×/50×以及 cuteSV/Sniffles2/sawfish/SVDSS。
- 不报告 T2T-CHM13、deBreak 和 Svision-pro。
- 对称平台主评测采用 raw Precision、Recall 和 F1；BGI 密集深度梯度按实验流程采用 Truvari refine Recall 与 refine F1。其他 refine 敏感性和参数调优仍作为 Extended Data 或 Supplementary evidence。

## 2. 核心科学结论

在 HG002、匹配深度和统一参考基因组条件下，SV 检测不存在脱离分析流程的“平台绝对排名”；性能同时受测序平台、caller–aligner 组合、评测区域和测序深度影响。主要深度收益集中在约 30–40× 之前，且 CMRG 可暴露全基因组评测中不可见的流程失稳。

这一结论回答的不是“哪个平台永远最好”，而是三个更具实际价值的问题：

1. 在对称实验条件下，三个平台分别呈现怎样的 Precision–Recall 权衡？
2. 全基因组表现能否迁移到困难医学相关基因区域？
3. 增加测序深度何时仍有实际收益，这种收益是否依赖 caller？

## 3. Results 叙事结构

### 3.1 建立对称的 SV 比较框架

- 在 HG002、GRCh38 和嵌套下采样条件下，比较 BGI、ONT 和 HiFi 的 10×、30×和 50×数据。
- 采用 minimap2 与 winnowmap 两种 aligner，以及 cuteSV、Sniffles2、sawfish 和 SVDSS 四种 caller。
- 使用 T2T-Q100 v1.1 进行全基因组评测，并使用 CMRG 检验困难医学相关基因区域中的可迁移性。
- 该段只交代公平性和矩阵结构，不提前宣布平台胜负。

### 3.2 报告全基因组性能与平台权衡

- 30×下，8种 caller–aligner 工作流的描述性中位 F1 约为 BGI 0.810、ONT 0.829、HiFi 0.825。
- 同一口径下，HiFi 的 Precision 较高，ONT 的 Recall 较高；BGI 与另外两个平台的主要差距更多来自 Recall，而不是单纯的 Precision 损失。
- 10×到 30×的中位 F1 增益明显大于 30×到 50×：BGI 约为 +0.050 与 +0.008，ONT 约为 +0.028 与 +0.003，HiFi 约为 +0.037 与 +0.006。
- T2T-Q100 中，winnowmap 相对 minimap2 的中位 ΔF1 约为 BGI −0.006、ONT −0.007、HiFi −0.019，但该差异仍依赖具体 caller 和深度。
- 不将单个最高 F1 写成平台总体排名；最高值只能作为一个明确的 platform–depth–aligner–caller 组合报告。

### 3.3 用 CMRG 检验困难区域中的工作流可迁移性

- CMRG 中 caller 排序发生改变，sawfish 在多个组合中表现突出，而 SVDSS 出现明显的平台特异性失稳。
- BGI–minimap2–SVDSS 的 F1 从 10×的 0.671 降至 30×的 0.405 和 50×的 0.266。
- 同一组合的 Recall 从 0.747 升至 0.834 和 0.857，但 Precision 从 0.609 降至 0.268 和 0.157，因此 F1 下降直接来自 Precision 损失，而非检出不足。
- CMRG 中，winnowmap 相对 minimap2 的中位 ΔF1 对 BGI 和 ONT 转为约 +0.008，而 HiFi 约为 −0.005，说明 aligner 效应也依赖评测区域。
- 该部分的结论限定为 **workflow–benchmark interaction**。CMRG 不应被简单描述为“普遍更难”，也不在没有额外证据时解释 SVDSS 失稳的算法机制。

### 3.4 用 BGI 密集深度梯度完成压力测试

- 分别展示 BGI、GRCh38/minimap2 下 cuteSV 与 Sniffles2 在 5×–90×范围内的 refine Recall 与 refine F1。
- 深度增加主要通过提升敏感度推动 refine F1；约 30–40×后，两项指标逐渐趋于平台期。
- Sniffles2 较早饱和；cuteSV 的收益延续到约 35–40×，之后仅有小幅波动。
- sawfish 与 SVDSS 因梯度实验存在残缺而不进入正文可视化或结果叙述；该排除必须在过滤审计中明确记录。

### 3.5 收束结论与研究边界

- 平台选择必须与 caller、aligner、目标区域和测序预算共同决定。
- 更高深度不能保证所有工作流持续改善，也不能修复 caller–platform 不兼容。
- 结论限定于 HG002 基因组 DNA、GRCh38、T2T-Q100 v1.1、CMRG、当前工具版本及当前分析生态，不外推到其他样本、参考基因组、所有 SV 类型或未来工具版本。

## 4. 主文组图设计

建议图题：

> **Workflow- and depth-dependent structural variant detection across long-read sequencing platforms**

整体采用纵向全页 quantitative grid，约 183 mm 宽。现有 F1 图保留其数据、caller–aligner 横轴、平台颜色和深度轨迹编码；组图时只移除重复标题、合并图例并校正真值名称。

### a｜全基因组 SV 检测

- 数据：T2T-Q100 v1.1 raw F1，共 72 个完整观测。
- x轴为四个 caller，并按 minimap2/winnowmap 分块；平台使用固定颜色，深度使用透明度和轨迹表示。
- 作为 hero panel，回答“对称条件下总体性能如何”。
- 当前 `sv_detection_f1_GIAB5` 的数据源、标题、文件名和说明必须统一更正为 T2T-Q100 v1.1，不得仅替换标题而继续读取误标表。

### b｜CMRG 困难医学相关基因

- 数据：CMRG raw F1，共 72 个完整观测。
- 完全复用 panel a 的坐标语义和视觉编码。
- 不聚合、不裁剪 SVDSS 低值，使读者能够识别具体 workflow 的失稳。
- 回答“全基因组结论能否迁移到困难医学相关基因区域”。

### c｜30× Precision–Recall landscape

- T2T-Q100 与 CMRG 并列分面；每个分面保留 24 个真实工作流点。
- x轴为 Precision，y轴为 Recall；平台颜色与 a/b 一致，caller 使用形状，aligner 使用实心/空心符号。
- 添加少量等 F1 参考线，帮助解释相同 F1 背后的不同错误权衡。
- 30×作为统一代表深度。工作流不是实验重复，因此不绘制置信区间或显著性检验。

### d｜BGI 密集深度响应

- cuteSV 与 Sniffles2 分别形成独立单图；上部灰蓝柱显示 refine Recall，灰线棕色菱形显示 refine F1。
- 下部对齐显示 refine ΔF1/5×，即相邻深度的 refine F1 变化按每5×标准化；5×因无前序深度而不绘制差值点。
- 深度使用数值轴，正确保留70×到90×的20×间隔；上部柱形从零开始并固定0–1纵轴，下部保留零基线。
- 两个 caller 的差值纵轴分别按其观测范围显示，服务于 caller 内部的收益衰减判断，不将其设计为 caller 排名图。
- 不使用平滑曲线、插值或聚合，两个纳入caller均使用全部15个完整深度结果。
- 回答“增加深度何时仍有实际收益，以及这种收益是否依赖 caller”。

### 推荐布局

- a、b 两个全宽主面板上下排列。
- c、d 位于底部左右，其中 d 可包含上下对齐的 F1 与 ΔF1 子区域。
- 全图共享平台图例；panel 标签使用小写粗体 a–d。
- 平台颜色在所有 panel 中保持一致；其他颜色仅用于有明确语义的正负变化或辅助参考线。

## 5. Extended Data 与补充材料

### Extended Data 1｜Benchmark-dependent change

- 展示 CMRG 相对 T2T-Q100 的配对 ΔF1，保留全部 72 个匹配组合。
- 用于完整呈现 benchmark-dependent rank changes，不以平均值掩盖极端工作流。

### Extended Data 2｜Truvari refine 敏感性

- 对所有核心组合绘制 raw F1 与 refine F1 的配对比较。
- refine 是结果敏感性和后处理影响的验证，不与 raw 混合为一个主指标。

### Extended Data 3｜参数敏感性控制

- 报告 HiFi–cuteSV 参数敏感性及 BGI–Sniffles2 调参和跨深度验证。
- 其作用是回应 caller 参数公平性和流程依赖性的审稿问题，而不是替代统一参数下的主平台比较。

## 6. 实现与验收标准

### 数据完整性

- panel a 和 b 各包含 72 个观测。
- panel d 使用 cuteSV 与 Sniffles2 的30个完整观测；sawfish 与 SVDSS 不进入正文图，并在过滤审计中记录排除范围与原因。
- 绘图输出必须附带 source-data、过滤审计和渲染清单。
- 所有正文数字均应由脚本从结构化 CSV 重新计算，不手工抄录为不可追踪常量。

### 统计与表述

- 不使用生物学重复、误差线或显著性检验措辞。
- 跨 workflow 中位数只能标为描述性汇总，不能作为重复实验统计推断。
- 不把 CMRG 的 F1 高低直接解释成区域“更容易”或“更困难”。
- 不把具体 caller 失败外推为平台固有缺陷。

### 可视化与导出

- 不连接缺失深度，不裁剪 CMRG 异常低值，不隐藏不利结果。
- 在最终组图尺寸下检查标题、坐标、低值点、图例和颜色辨识度。
- SVG/PDF 保留可编辑文本；TIFF 按 600 dpi 导出；PNG 仅作预览。
- R 为唯一绘图、预览和导出后端。

### 读者验收问题

读者脱离正文后，应能从主图回答：

1. 三个平台在匹配深度下是否存在稳定的绝对排名？
2. caller 和 aligner 是否会改变平台比较结论？
3. 全基因组表现是否能预测 CMRG 表现？
4. BGI 的主要深度收益发生在哪个区间，何时开始趋于平台期？
