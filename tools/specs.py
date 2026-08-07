"""Per-table extraction specs for 最新数据评测.xlsx.

One Spec == one output CSV. Row/column numbers are 1-based and match what you
see in Excel, so every entry here is checkable by eye against the workbook.

Column names keep the workbook's original Chinese/English wording. Where the
source header is blank (key columns hidden under a vertical merge), the name is
supplied here and recorded in meta/index.json.
"""

from extract import Block, Spec

# ---------------------------------------------------------------- SV benchmark
# A-D are key columns with no header text (vertical merges); E-S are the base
# Truvari metrics; T-Z are the same benchmark after Truvari refine.
SV_KEYS = ["评测模式", "SV Caller", "平台", "深度"]

# E-S: Truvari base metrics. T-Z: the same call set after Truvari refine.
# tp-base/tp-call/fp/fn/precision/recall/F1 appear in both groups, so the refine
# group is prefixed. Names are otherwise verbatim from the workbook header row.
SV_BASE_METRICS = [
    "precision", "recall", "F1", "concordance",
    "gt-precision", "gt-recall", "gt-F1",
    "tp-base", "tp-call", "fp", "fn",
    "TP-call-TP", "TP-call-FP", "TP-base-TP", "TP-base-FP",
]
SV_REFINE_METRICS = [
    "refine tp-base", "refine tp-call", "refine fp", "refine fn",
    "refine precision", "refine recall", "refine F1",
]
SV_COL_NAMES = SV_KEYS + SV_BASE_METRICS + SV_REFINE_METRICS
assert len(SV_COL_NAMES) == 26, len(SV_COL_NAMES)


def _sv_spec(sheet: str, out: str, blocks: list[Block], title: str,
             note: str = "") -> Spec:
    return Spec(
        sheet=sheet,
        out=out,
        blocks=blocks,
        first_col=1,
        last_col=26,
        ffill_cols=[1, 2, 3],
        col_names=SV_COL_NAMES,
        const_order=["比对工具", "参考基因组"],
        title=title,
        note=note,
    )


SPECS: list[Spec] = []

SPECS.append(_sv_spec(
    sheet="SV-T2T结果",
    out="sv_benchmark_T2TQ100",
    blocks=[
        Block(first_row=4, last_row=57, header_rows=[2, 3],
              consts={"比对工具": "minimap2", "参考基因组": "GRCh38"},
              banner_cells=["E2", "T2"]),
        Block(first_row=65, last_row=118, header_rows=[63, 64],
              consts={"比对工具": "winnowmap", "参考基因组": "GRCh38"},
              banner_cells=["E63", "T63"]),
    ],
    title="SV 评测 - 真值 HG002 T2T-Q100 v1.1 全基因组",
    note="E-S 列为 Truvari 基础评测，T-Z 列为 Truvari refine 后结果（列名带 refine 前缀）。",
))

SPECS.append(_sv_spec(
    sheet="SV-GIAB5.0q",
    out="sv_benchmark_GIAB5.0q",
    blocks=[
        Block(first_row=3, last_row=56, header_rows=[1, 2],
              consts={"比对工具": "minimap2", "参考基因组": "GRCh38"},
              banner_cells=["E1", "T1"]),
        Block(first_row=64, last_row=117, header_rows=[62, 63],
              consts={"比对工具": "winnowmap", "参考基因组": "GRCh38"},
              banner_cells=["E62", "T62"]),
        # T2T-CHM13 block: 30x only, and the last four caller rows are empty
        # placeholders in the source (deBreak/SVDSS not yet run).
        Block(first_row=122, last_row=133, header_rows=[120, 121],
              consts={"比对工具": "minimap2", "参考基因组": "T2T_CHM13"},
              banner_cells=["E120", "T120"]),
    ],
    title="SV 评测 - 真值 GIAB v5.0q",
    note="含三块：minimap2/GRCh38、winnowmap/GRCh38、minimap2/T2T_CHM13（仅 30x）。"
         "T2T_CHM13 块末尾 4 行（deBreak/SVDSS 各平台）在源文件中只有键列、无指标，为未完成项。",
))

SPECS.append(_sv_spec(
    sheet="SV-CMRG结果",
    out="sv_benchmark_CMRG",
    blocks=[
        Block(first_row=3, last_row=38, header_rows=[1, 2],
              consts={"比对工具": "minimap2", "参考基因组": "GRCh38"},
              banner_cells=["A1", "E1", "T1"]),
        Block(first_row=46, last_row=81, header_rows=[44, 45],
              consts={"比对工具": "winnowmap", "参考基因组": "GRCh38"},
              banner_cells=["A44", "E44", "T44"]),
    ],
    title="SV 评测 - 真值 GIAB CMRG（困难医学相关基因）",
    note="CMRG 为 challenging medically relevant genes 子集，位点数量远小于全基因组评测。",
))

# ------------------------------------------------------------ 流程与原始数据
SPECS.append(Spec(
    sheet="实验设计",
    out="experiment_design",
    blocks=[Block(first_row=5, last_row=24, header_rows=[4])],
    first_col=1, last_col=10,
    ffill_cols=[2],
    title="实验设计总表：模块 / 核心实验 / 真值 / 指标 / 当前阶段",
    note="r27 起为『评测边界与统一规则』条目，为键值式说明文字，见 meta/notes.csv。",
))

SPECS.append(Spec(
    sheet="工具及参数",
    out="tools_and_parameters",
    blocks=[Block(first_row=5, last_row=47, header_rows=[4])],
    first_col=1, last_col=15,
    ffill_cols=[2, 4, 5, 6],
    title="实验流程与参数核对表：工具版本、关键参数、输入输出路径、脚本与状态",
    note="核对时间见 meta/notes.csv 中该表 r2 说明。B/D/E/F 列在源文件中为纵向合并，已向下填充。",
))

SPECS.append(Spec(
    sheet="表观错误谱预评估",
    out="error_spectrum_pilot",
    blocks=[Block(first_row=5, last_row=10, header_rows=[4])],
    first_col=1, last_col=19,
    title="表观错误谱预评估（pilot）：GRCh38 + GIAB truth-site mask，30x",
    note="源文件明确标注此为流程验证 pilot，不等于正式 donor-specific 真实错误谱。"
         "MAPQ>=20、BQ>=20；GIAB v5.0q 高置信区间与 chr1/2/3 1Mb 窗口交集。",
))

SPECS.append(Spec(
    sheet="比对结果",
    out="alignment_qc",
    blocks=[
        Block(first_row=2, last_row=19, header_rows=[1],
              consts={"参考基因组": "GRCh38"}, banner_cells=["A2"]),
        Block(first_row=24, last_row=41, header_rows=[23],
              consts={"参考基因组": "T2T-CHM13"}, banner_cells=["A23"]),
    ],
    first_col=2, last_col=10,
    ffill_cols=[2, 3],
    const_order=["参考基因组"],
    title="比对与参考偏差：coverage、mean depth、primary mapped rate、BAM 体积与路径",
    note="A 列在源文件中是参考基因组横幅（A2=GRCh38、A23=T2T-CHM13），已提为『参考基因组』列。",
))

# NanoPlot_Result and its 副本 describe the same 9 runs. The copy adds three
# Q>20 columns and drops "SeqKit check", so they are kept as two files rather
# than force-merged; index.json cross-references them.
SPECS.append(Spec(
    sheet="NanoPlot_Result",
    out="reads_qc_nanoplot",
    blocks=[Block(first_row=2, last_row=10, header_rows=[1])],
    first_col=1, last_col=13,
    ffill_cols=[1],
    col_names=[
        "Dataset", "Depth", "Reads", "Total bases", "Yield (Gb)",
        "Approx coverage", "Mean length", "Median length", "Read N50",
        "Mean Q", "Median Q", "SeqKit check", "Status",
    ],
    title="原始/下采样 reads QC（NanoPlot + SeqKit）",
    note="A1 在源文件中为空（Dataset 列无表头），列名此处补齐。",
))

SPECS.append(Spec(
    sheet="NanoPlot_Result(副本)",
    out="reads_qc_nanoplot_q20",
    blocks=[Block(first_row=2, last_row=10, header_rows=[1])],
    first_col=1, last_col=15,
    ffill_cols=[1],
    title="原始/下采样 reads QC（含 Q>20 读段比例与产量）",
    note="与 reads_qc_nanoplot 同为 9 条运行；本表多 Q>20 三列、无 SeqKit check 列。"
         "BGI Mean-Q>20 读段比例 0.335，ONT 0.783，HiFi 0.932。",
))

# ------------------------------------------------------------------ 小变异 / STR
SPECS.append(Spec(
    sheet="SNV结果",
    out="snv_benchmark",
    blocks=[Block(first_row=5, last_row=58, header_rows=[3, 4])],
    first_col=1, last_col=11,
    ffill_cols=[1, 2, 3],
    col_names=[
        "Caller", "Aligner", "Dataset", "Depth", "Status",
        "SNP Recall", "SNP Precision", "SNP F1",
        "INDEL Recall", "INDEL Precision", "INDEL F1",
    ],
    title="小变异评测：GIAB v5.0q / GRCh38 masked",
    note="Longshot 行 INDEL 三列为字面值 NA（Longshot 不检出 indel），与空值含义不同。"
         "L 列的行内批注已移入 meta/notes.csv。",
))

SPECS.append(Spec(
    sheet="STR（短串联重复变异）结果",
    out="str_trgt",
    blocks=[
        Block(first_row=9, last_row=17, header_rows=[7, 8],
              consts={"比对工具": "minimap2"}, banner_cells=["A7", "C7"]),
        Block(first_row=29, last_row=37, header_rows=[27, 28],
              consts={"比对工具": "winnowmap"}, banner_cells=["A27", "C27"]),
    ],
    first_col=1, last_col=10,
    ffill_cols=[1],
    const_order=["比对工具"],
    col_names=[
        "Dataset", "Depth", "Total loci", "Call rate", "Median support",
        "Non-ref rate", "Exact vs HiFi30", "Within5 vs HiFi30",
        "Exact vs HiFi50", "Within5 vs HiFi50",
    ],
    title="STR / TRGT 评测：full catalog 171,146 loci",
    note="两块分别为 minimap2 与 winnowmap（源文件 r24 说明 winnowmap 结果）。"
         "Exact/Within5 vs HiFi30/HiFi50 为与 HiFi 对应深度的等位长度一致性。"
         "另有 pathogenic catalog 56 loci 单独运行，9 样本 100% callable，见 notes。",
))

# ------------------------------------------------------------ ME / Mosaic / 组装
SPECS.append(Spec(
    sheet="ME（移动元件插入）结果",
    out="mobile_element_xtea",
    blocks=[Block(first_row=2, last_row=7, header_rows=[1])],
    first_col=1, last_col=14,
    ffill_cols=[1, 3, 4],
    title="移动元件插入（xTEA-long）：ALU / LINE1 / SVA / HERV 分类计数",
    note="Notes 列说明部分运行残留 .failed 标记但 Slurm 与 xTea 退出码均为 0，结果有效。",
))

SPECS.append(Spec(
    sheet="Mosaic pilot",
    out="mosaic_sv_pilot",
    blocks=[Block(first_row=4, last_row=9, header_rows=[3])],
    first_col=1, last_col=15,
    ffill_cols=[1],
    title="低频/嵌合 SV pilot：Sniffles2 mosaic 模式，30x",
    note="参数 --mosaic --mosaic-af-min 0.05 --mosaic-af-max 0.20 --minsvlen 50 "
         "--mapq 20 --max-svlen-mosaic 50000。源文件标注为 candidate/VAF pilot，"
         "无充分 truth，不作为正式嵌合变异结论。",
))

SPECS.append(Spec(
    sheet="Merqury 结果",
    out="assembly_merqury",
    blocks=[Block(first_row=3, last_row=11, header_rows=[1, 2])],
    first_col=1, last_col=11,
    ffill_cols=[1],
    title="de novo 组装质量（Merqury）：QV / Completeness / Error rate × 三装配器",
    note="宽表：QV、Completeness (%)、Error rate 三组各含 hifiasm / flye / verkko。"
         "NA 为该组合未运行（区别于空值）。50x 行与多数 verkko 列尚未完成。",
))

# ------------------------------------------------------------------- phasing
# The two blocks in this sheet describe different tools with different column
# sets (LongPhase 18 cols, WhatsHap+Clair3 21 cols), so they become two files.
SPECS.append(Spec(
    sheet="phasing-SNP_Block_Stats",
    out="phasing_block_stats_longphase",
    blocks=[Block(first_row=8, last_row=25, header_rows=[7])],
    first_col=1, last_col=18,
    ffill_cols=[1, 2, 3],
    title="LongPhase SNP phase-block 统计（18 组合，限 GIAB v5.0q 自体染色体 SNP BED）",
    note="phased SNP rate = phased SNPs / benchmark SNPs；block length = to - from + 1；"
         "median/mean/longest 仅统计非单例 block（>=2 变异）。"
         "NG50 以 chr1-22 总长 2,875,001,522 bp 为分母。",
))

SPECS.append(Spec(
    sheet="phasing-SNP_Block_Stats",
    out="phasing_block_stats_whatshap",
    blocks=[Block(first_row=40, last_row=57, header_rows=[39])],
    first_col=1, last_col=21,
    ffill_cols=[1, 2, 3],
    title="WhatsHap + Clair3 phase-block 统计（18 组合，全变异口径）",
    note="与 phasing_block_stats_longphase 同为 18 组合，但口径不同："
         "本表统计全部变异/杂合变异，不限于 GIAB benchmark BED。",
))

SPECS.append(Spec(
    sheet="phasing_SNP_Compare_GIAB",
    out="phasing_accuracy_longphase",
    blocks=[Block(first_row=8, last_row=25, header_rows=[7])],
    first_col=1, last_col=17,
    ffill_cols=[1, 2, 3],
    title="LongPhase SNP 相位准确性 vs GIAB v5.0q（WhatsHap compare v2.8）",
    note="自体染色体汇总为 chr1-22 计数求和（非比率平均）。"
         "switch error rate = switch errors / assessed adjacent pairs；"
         "switch errors = switch events + 2 × flip events；"
         "Hamming rate = blockwise Hamming errors / covered variants。越低越好。",
))

SPECS.append(Spec(
    sheet="phasing_SNP_Compare_GIAB",
    out="phasing_accuracy_whatshap",
    blocks=[Block(first_row=34, last_row=51, header_rows=[33])],
    first_col=1, last_col=18,
    ffill_cols=[1, 2, 3],
    title="WhatsHap SNP 相位准确性 vs GIAB v5.0q",
    note="比 LongPhase 表多 Chromosomes 列。比率由各染色体分子/分母求和后计算。",
))

SPECS.append(Spec(
    sheet="Longphase_SV_Benchmark",
    out="phasing_sv_longphase",
    blocks=[Block(first_row=8, last_row=25, header_rows=[7])],
    first_col=1, last_col=22,
    ffill_cols=[1, 2, 3],
    title="LongPhase SV 相位覆盖 + Truvari 评测（真值 T2TQ100 v1.1）",
    note="SV phased rate = phased 杂合 SV / 全部杂合 SV；phased 指杂合 GT 使用 '|'，"
         "纯合与缺失基因型不计入分母。该比率由本表计算，非 LongPhase 直接输出。"
         "Truvari v5.1.1 --passonly，TP 取 TP-base。",
))

SPECS.append(Spec(
    sheet="Whatshap-Phasing",
    out="phasing_compare_whatshap_callers",
    blocks=[Block(first_row=5, last_row=28, header_rows=[4])],
    first_col=1, last_col=24,
    ffill_cols=[1, 2, 3],
    title="WhatsHap phasing compare vs GIAB v5.0q masked het SNV（Clair3 与 DeepVariant）",
    note="compare 使用 --only-snvs；比率按各染色体分子/分母求和后全基因组汇总。"
         "Caller=Clair3 行来自原工作簿，Caller=DeepVariant 行为后续补充。"
         "mask 排除 chr3:16902750-16903050。",
))

SPECS.append(Spec(
    sheet="Whatshap-Phasing-haplotag",
    out="phasing_haplotag_whatshap",
    blocks=[Block(first_row=8, last_row=25, header_rows=[7])],
    first_col=1, last_col=18,
    ffill_cols=[1, 2, 3],
    title="WhatsHap haplotag：reads 可分配到 haplotype 的比例",
    note="taggable rate = 可标记的 alignment / 处理的 alignment 总数；"
         "tagged = H1 + H2；H1/H2 百分比以 tagged 为分母。"
         "haplotag 只写 HP/PS 标签，本身不是对真值集的准确性评测。",
))

# ------------------------------------------------------------ 深度梯度与调参
SPECS.append(Spec(
    sheet="BGI最适深度探究",
    out="sv_depth_gradient_bgi",
    blocks=[Block(first_row=6, last_row=65, header_rows=[4, 5])],
    first_col=1, last_col=17,
    ffill_cols=[1, 2, 3, 4],
    col_names=[
        "评测模式", "平台/样本", "参考/比对", "SV Caller", "深度",
        "Precision", "Recall", "F1", "ΔF1/5x",
        "refine FP", "refine FN",
        "refine Precision", "refine Recall", "refine F1", "refine ΔF1/5x",
        "状态", "备注",
    ],
    title="BGI SV 深度梯度：5x-90x × 四个 caller（GRCh38 / minimap2）",
    note="源文件表头分组 F4:I4='Truvari基础评测'（Precision/Recall/F1/ΔF1/5x）、"
         "J4:O4='Truvari refine'（FP/FN/Precision/Recall/F1/ΔF1/5x）——"
         "注意 FP/FN 按合并范围归属 refine 组，故列名为 refine FP / refine FN。"
         "ΔF1/5x 为相对上一个深度档的 F1 斜率，定义见 meta/notes.csv 中 r68。"
         "sawfish 60x 与 SVDSS 90x 为失败/进行中，指标列为空、状态列已保留原因。",
))

# cuteSV-HiFi：四个形状不同的小表，各自单独成文件
_CUTESV_HIFI_NOTE = (
    "对照实验：cuteSV 官方 HiFi 推荐参数（--max_cluster_bias_INS 1000 "
    "--diff_ratio_merging_INS 0.9 --max_cluster_bias_DEL 1000 "
    "--diff_ratio_merging_DEL 0.5，表内简记 1000/0.9/1000）与本研究"
    "沿用的旧参数（100/0.3/100/0.3）对比。平台=HiFi，参考=GRCh38，比对=minimap2。"
    "结论性文字见 meta/notes.csv 中 cuteSV-HiFi 的 r10-r13、r15、r21、r26、r28、r32-r35。"
)

SPECS.append(Spec(
    sheet="cuteSV-HiFi",
    out="cutesv_hifi_param_giab",
    blocks=[Block(first_row=3, last_row=8, header_rows=[2],
                  consts={"真值集": "GIAB v5.0q", "参考基因组": "GRCh38"},
                  banner_cells=["A1"])],
    first_col=1, last_col=6,
    const_order=["真值集", "参考基因组"],
    title="cuteSV HiFi 推荐参数 vs 旧参数：GIAB v5.0q 全基因组基础指标",
    note=_CUTESV_HIFI_NOTE + " F1变化 列为 HiFi 参数相对同深度旧参数的 F1 差值，旧参数行记 '—'。",
))

SPECS.append(Spec(
    sheet="cuteSV-HiFi",
    out="cutesv_hifi_param_giab_refine",
    blocks=[Block(first_row=17, last_row=19, header_rows=[16])],
    first_col=1, last_col=3,
    title="cuteSV HiFi 推荐参数 vs 旧参数：GIAB v5.0q refine 后 F1",
    note=_CUTESV_HIFI_NOTE + " 50x HiFi 参数一列为文字 '新结果尚未完成 refine'，按原样保留。",
))

SPECS.append(Spec(
    sheet="cuteSV-HiFi",
    out="cutesv_hifi_param_callcount",
    blocks=[Block(first_row=23, last_row=25, header_rows=[22],
                  banner_cells=["A21"])],
    first_col=1, last_col=4,
    title="cuteSV HiFi 推荐参数 vs 旧参数：VCF 调用数量",
    note=_CUTESV_HIFI_NOTE + " '减少' 列为 HiFi 参数相对旧参数的调用数变化百分比（负号表示减少）。",
))

SPECS.append(Spec(
    sheet="cuteSV-HiFi",
    out="cutesv_hifi_param_cmrg",
    blocks=[Block(first_row=30, last_row=31, header_rows=[29],
                  banner_cells=["A28"])],
    first_col=1, last_col=3,
    title="cuteSV HiFi 推荐参数 vs 旧参数：CMRG 困难医学基因 F1",
    note=_CUTESV_HIFI_NOTE + " 与全基因组结论相反：CMRG 上 HiFi 参数更好，故不能一概而论。",
))

# ------------------------------------------------------------ Sniffles2 调参
_SNF_NOTE = (
    "Sniffles2 对 BGI_latest 的参数调优；目标是寻找稳健参数，"
    "不用于与 ONT/HiFi 横向比较（源文件 A2 明确声明）。"
    "结论文字见 meta/notes.csv 中 Sniffles2调参 的 r1-r2、r9、r15-r17、r30、r33-r35、r45。"
)

SPECS.append(Spec(
    sheet="Sniffles2调参",
    out="sniffles2_tuning_conclusions",
    blocks=[Block(first_row=4, last_row=7, header_rows=[],
                  banner_cells=["A1", "A2"])],
    first_col=1, last_col=3,
    col_names=["结论条目", "_合并占位", "推荐参数"],
    title="Sniffles2 调参结论：四种口径下的最优参数取值",
    note=_SNF_NOTE + " 源文件 A4:B4 等为横向合并，故 B 列在此为合并占位（内容与 A 列相同）。"
                     "无表头行，条目名即行标签。",
))

SPECS.append(Spec(
    sheet="Sniffles2调参",
    out="sniffles2_mapq_delta_by_depth",
    blocks=[Block(first_row=11, last_row=13, header_rows=[10],
                  banner_cells=["A9"])],
    first_col=1, last_col=5,
    title="Sniffles2 MAPQ 10 vs 20：跨深度 ΔF1（q10 − q20）",
    note=_SNF_NOTE + " ΔF1 为 MAPQ 10 减 MAPQ 20，正值表示 q10 更好；"
                     "三个口径分别是 Raw 全基因组、Refine 全基因组、CMRG。",
))

SPECS.append(Spec(
    sheet="Sniffles2调参",
    out="sniffles2_param_matrix_50x",
    blocks=[Block(first_row=20, last_row=28, header_rows=[18, 19],
                  banner_cells=["A15", "A16", "A17", "C17", "E17"])],
    first_col=1, last_col=20,
    col_names=[
        "SV Caller", "数据集", "参考/比对", "深度", "Support", "Auto multiplier",
        "MAPQ", "参数角色",
        "Raw Precision", "Raw Recall", "Raw F1", "Raw GT concordance",
        "Refine Precision", "Refine Recall", "Refine F1", "Refine GT concordance",
        "CMRG Precision", "CMRG Recall", "CMRG F1", "CMRG GT concordance",
    ],
    title="Sniffles2 50x 参数矩阵：auto multiplier × MAPQ 的 3×3 网格",
    note=_SNF_NOTE + " 源文件 r17 为配色图例：黄色=该列最高 F1，浅绿=综合推荐参数行；"
                     "对应关系见 meta/highlights.csv。参数角色列只在被标注的行有值，"
                     "空白表示该组合无特殊角色，未做前向填充。",
))

SPECS.append(Spec(
    sheet="Sniffles2调参",
    out="sniffles2_recommended_across_depth",
    blocks=[Block(first_row=38, last_row=43, header_rows=[36, 37],
                  banner_cells=["A33", "A34", "A35", "H35", "M35"])],
    first_col=1, last_col=16,
    col_names=[
        "SV Caller", "数据集", "参考/比对", "深度", "Support", "Auto multiplier",
        "MAPQ",
        "Raw Precision", "Raw Recall", "Raw F1", "Refine F1", "CMRG F1",
        "Raw ΔF1", "Refine ΔF1", "CMRG ΔF1", "判断",
    ],
    title="Sniffles2 推荐参数跨深度验证：10x/30x/50x × MAPQ 10 vs 20",
    note=_SNF_NOTE + " 固定 minsupport auto、multiplier 0.1，只变 MAPQ。"
                     "ΔF1 三列按深度合并（q10 − q20），故 MAPQ 20 行的 ΔF1 与同深度 MAPQ 10 行相同。",
))
