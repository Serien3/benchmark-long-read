#!/usr/bin/env python3
"""Extract caller-tuning result tables directly from the authoritative workbook.

Only Python's standard library is used.  The script preserves workbook sheet/row
provenance and refuses to write partial tables.
"""

from __future__ import annotations

import csv
import math
import re
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
WORKBOOK = ROOT / "最新数据评测.xlsx"
OUTDIR = ROOT / "data" / "caller_tuning_xlsx"
NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
REL_NS = {"r": "http://schemas.openxmlformats.org/package/2006/relationships"}
RID = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"


def col_number(cell_ref: str) -> int:
    letters = re.match(r"[A-Z]+", cell_ref).group(0)
    value = 0
    for letter in letters:
        value = value * 26 + ord(letter) - 64
    return value


def load_sheets(path: Path) -> dict[str, dict[int, dict[int, object]]]:
    with zipfile.ZipFile(path) as archive:
        shared: list[str] = []
        if "xl/sharedStrings.xml" in archive.namelist():
            root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            for item in root.findall("m:si", NS):
                shared.append("".join(node.text or "" for node in item.iterfind(".//m:t", NS)))

        workbook = ET.fromstring(archive.read("xl/workbook.xml"))
        rels = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
        targets = {rel.attrib["Id"]: rel.attrib["Target"] for rel in rels.findall("r:Relationship", REL_NS)}
        sheets: dict[str, dict[int, dict[int, object]]] = {}
        for sheet in workbook.findall(".//m:sheet", NS):
            name = sheet.attrib["name"]
            target = targets[sheet.attrib[RID]].lstrip("/")
            xml_path = target if target.startswith("xl/") else f"xl/{target}"
            root = ET.fromstring(archive.read(xml_path))
            rows: dict[int, dict[int, object]] = {}
            for row in root.findall(".//m:sheetData/m:row", NS):
                row_num = int(row.attrib["r"])
                values: dict[int, object] = {}
                for cell in row.findall("m:c", NS):
                    ref = cell.attrib["r"]
                    column = col_number(ref)
                    cell_type = cell.attrib.get("t")
                    value_node = cell.find("m:v", NS)
                    inline_node = cell.find("m:is", NS)
                    if cell_type == "inlineStr" and inline_node is not None:
                        value: object = "".join(n.text or "" for n in inline_node.iterfind(".//m:t", NS))
                    elif value_node is None:
                        value = None
                    elif cell_type == "s":
                        value = shared[int(value_node.text)]
                    elif cell_type == "b":
                        value = value_node.text == "1"
                    else:
                        raw = value_node.text or ""
                        try:
                            value = float(raw)
                        except ValueError:
                            value = raw
                    values[column] = value
                rows[row_num] = values
            sheets[name] = rows
        return sheets


def value(rows: dict[int, dict[int, object]], row: int, column: int) -> object:
    return rows.get(row, {}).get(column)


def number(x: object, label: str) -> float:
    if x is None or x == "":
        raise ValueError(f"Missing numeric value: {label}")
    return float(x)


def integer(x: object, label: str) -> int:
    return int(round(number(x, label)))


def depth_number(x: object, label: str) -> int:
    match = re.search(r"\d+", str(x))
    if not match:
        raise ValueError(f"Invalid depth at {label}: {x}")
    return int(match.group(0))


def write_csv(name: str, rows: list[dict[str, object]]) -> None:
    if not rows:
        raise ValueError(f"Refusing to write empty table: {name}")
    OUTDIR.mkdir(parents=True, exist_ok=True)
    path = OUTDIR / name
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def assert_metric_triplet(p: float, r: float, f1: float, label: str) -> None:
    expected = 2 * p * r / (p + r)
    if not math.isclose(expected, f1, abs_tol=6e-4):
        raise ValueError(f"F1 inconsistency at {label}: workbook={f1}, calculated={expected}")


def extract_cutesv_round1(sheets: dict[str, dict[int, dict[int, object]]]) -> list[dict[str, object]]:
    sheet = "cutesv调参"
    rows = sheets[sheet]
    output: list[dict[str, object]] = []
    for mapq, row_range in ((10, range(36, 117)), (20, range(117, 198))):
        for row in row_range:
            raw_p, raw_r, raw_f1 = (number(value(rows, row, c), f"{sheet}!row{row}") for c in (7, 8, 9))
            ref_p, ref_r, ref_f1 = (number(value(rows, row, c), f"{sheet}!row{row}") for c in (26, 27, 28))
            assert_metric_triplet(raw_p, raw_r, raw_f1, f"{sheet}!row{row} raw")
            assert_metric_triplet(ref_p, ref_r, ref_f1, f"{sheet}!row{row} refine")
            output.append({
                "platform": "BGI", "depth_x": 50, "reference": "GRCh38", "aligner": "minimap2",
                "min_support": 10, "mapq": mapq,
                "ins_bias": integer(value(rows, row, 3), f"{sheet}!C{row}"),
                "ins_ratio": number(value(rows, row, 4), f"{sheet}!D{row}"),
                "del_bias": integer(value(rows, row, 5), f"{sheet}!E{row}"),
                "del_ratio": number(value(rows, row, 6), f"{sheet}!F{row}"),
                "raw_precision": raw_p, "raw_recall": raw_r, "raw_f1": raw_f1,
                "refine_precision": ref_p, "refine_recall": ref_r, "refine_f1": ref_f1,
                "source_workbook": WORKBOOK.name, "source_sheet": sheet, "source_row": row,
            })
    if len(output) != 162 or len({(r["mapq"], r["ins_bias"], r["ins_ratio"], r["del_bias"], r["del_ratio"]) for r in output}) != 162:
        raise ValueError("cuteSV round-1 is not a complete 2 × 3^4 factorial design")
    return output


def extract_cutesv_round2(sheets: dict[str, dict[int, dict[int, object]]]) -> list[dict[str, object]]:
    sheet = "cutesv调参(结果)"
    rows = sheets[sheet]
    output: list[dict[str, object]] = []
    for row in range(10, 24):
        raw_p, raw_r, raw_f1 = (number(value(rows, row, c), f"{sheet}!row{row}") for c in (13, 14, 15))
        ref_p, ref_r, ref_f1 = (number(value(rows, row, c), f"{sheet}!row{row}") for c in (32, 33, 34))
        assert_metric_triplet(raw_p, raw_r, raw_f1, f"{sheet}!row{row} raw")
        assert_metric_triplet(ref_p, ref_r, ref_f1, f"{sheet}!row{row} refine")
        output.append({
            "order": row - 9, "run_id": value(rows, row, 5), "parameter_group": value(rows, row, 6),
            "min_support": integer(value(rows, row, 7), f"{sheet}!G{row}"),
            "mapq": integer(value(rows, row, 8), f"{sheet}!H{row}"),
            "ins_bias": integer(value(rows, row, 9), f"{sheet}!I{row}"),
            "ins_ratio": number(value(rows, row, 10), f"{sheet}!J{row}"),
            "del_bias": integer(value(rows, row, 11), f"{sheet}!K{row}"),
            "del_ratio": number(value(rows, row, 12), f"{sheet}!L{row}"),
            "raw_precision": raw_p, "raw_recall": raw_r, "raw_f1": raw_f1,
            "refine_precision": ref_p, "refine_recall": ref_r, "refine_f1": ref_f1,
            "source_workbook": WORKBOOK.name, "source_sheet": sheet, "source_row": row,
        })
    if len(output) != 14 or any(not r["run_id"] for r in output):
        raise ValueError("cuteSV round-2 extraction is incomplete")
    return output


def extract_sniffles(sheets: dict[str, dict[int, dict[int, object]]]) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    sheet = "Sniffles2调参"
    rows = sheets[sheet]
    matrix: list[dict[str, object]] = []
    auto_multiplier: float | None = None
    for row in range(20, 29):
        if value(rows, row, 6) not in (None, ""):
            auto_multiplier = number(value(rows, row, 6), f"{sheet}!F{row}")
        if auto_multiplier is None:
            raise ValueError(f"Cannot fill merged multiplier at {sheet}!row{row}")
        vals = [number(value(rows, row, c), f"{sheet}!row{row}") for c in (9, 10, 11, 13, 14, 15, 17, 18, 19)]
        for offset, label in ((0, "raw"), (3, "refine"), (6, "cmrg")):
            assert_metric_triplet(vals[offset], vals[offset + 1], vals[offset + 2], f"{sheet}!row{row} {label}")
        matrix.append({
            "platform": "BGI", "depth_x": 50, "reference": "GRCh38", "aligner": "minimap2",
            "auto_multiplier": auto_multiplier, "mapq": integer(value(rows, row, 7), f"{sheet}!G{row}"),
            "raw_precision": vals[0], "raw_recall": vals[1], "raw_f1": vals[2],
            "refine_precision": vals[3], "refine_recall": vals[4], "refine_f1": vals[5],
            "cmrg_precision": vals[6], "cmrg_recall": vals[7], "cmrg_f1": vals[8],
            "source_workbook": WORKBOOK.name, "source_sheet": sheet, "source_row": row,
        })
    if len(matrix) != 9 or len({(r["auto_multiplier"], r["mapq"]) for r in matrix}) != 9:
        raise ValueError("Sniffles2 50x matrix is not a complete 3 × 3 design")

    depth_rows: list[dict[str, object]] = []
    depth: int | None = None
    for row in range(38, 44):
        if value(rows, row, 4) not in (None, ""):
            depth = depth_number(value(rows, row, 4), f"{sheet}!D{row}")
        if depth is None:
            raise ValueError(f"Cannot fill merged depth at {sheet}!row{row}")
        raw_p = number(value(rows, row, 8), f"{sheet}!H{row}")
        raw_r = number(value(rows, row, 9), f"{sheet}!I{row}")
        raw_f1 = number(value(rows, row, 10), f"{sheet}!J{row}")
        assert_metric_triplet(raw_p, raw_r, raw_f1, f"{sheet}!row{row} raw")
        depth_rows.append({
            "platform": "BGI", "depth_x": depth, "reference": "GRCh38", "aligner": "minimap2",
            "auto_multiplier": 0.10, "mapq": integer(value(rows, row, 7), f"{sheet}!G{row}"),
            "raw_precision": raw_p, "raw_recall": raw_r, "raw_f1": raw_f1,
            "refine_f1": number(value(rows, row, 11), f"{sheet}!K{row}"),
            "cmrg_f1": number(value(rows, row, 12), f"{sheet}!L{row}"),
            "source_workbook": WORKBOOK.name, "source_sheet": sheet, "source_row": row,
        })
    if len(depth_rows) != 6 or len({(r["depth_x"], r["mapq"]) for r in depth_rows}) != 6:
        raise ValueError("Sniffles2 cross-depth validation is incomplete")
    return matrix, depth_rows


def extract_cutesv_hifi(sheets: dict[str, dict[int, dict[int, object]]]) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]], list[dict[str, object]]]:
    sheet = "cuteSV-HiFi"
    rows = sheets[sheet]
    whole: list[dict[str, object]] = []
    for row in range(3, 9):
        p, r, f1 = (number(value(rows, row, c), f"{sheet}!row{row}") for c in (3, 4, 5))
        assert_metric_triplet(p, r, f1, f"{sheet}!row{row}")
        whole.append({
            "depth_x": depth_number(value(rows, row, 1), f"{sheet}!A{row}"),
            "parameter_set": "Previous" if row % 2 == 1 else "HiFi-specific", "precision": p, "recall": r, "f1": f1,
            "benchmark_label_in_workbook": "GIAB v5.0q", "reference": "GRCh38", "aligner": "minimap2",
            "source_workbook": WORKBOOK.name, "source_sheet": sheet, "source_row": row,
        })
    call_count: list[dict[str, object]] = []
    for row in range(23, 26):
        for column, parameter_set in ((2, "Previous"), (3, "HiFi-specific")):
            call_count.append({
                "depth_x": depth_number(value(rows, row, 1), f"{sheet}!A{row}"), "parameter_set": parameter_set,
                "total_calls": integer(value(rows, row, column), f"{sheet}!row{row}"),
                "source_workbook": WORKBOOK.name, "source_sheet": sheet, "source_row": row,
            })
    refine: list[dict[str, object]] = []
    for row in range(17, 20):
        for column, parameter_set in ((2, "Previous"), (3, "HiFi-specific")):
            if not isinstance(value(rows, row, column), (int, float)):
                continue
            refine.append({
                "depth_x": depth_number(value(rows, row, 1), f"{sheet}!A{row}"), "parameter_set": parameter_set,
                "refine_f1": number(value(rows, row, column), f"{sheet}!row{row}"),
                "source_workbook": WORKBOOK.name, "source_sheet": sheet, "source_row": row,
            })
    cmrg: list[dict[str, object]] = []
    for row in range(30, 32):
        for column, parameter_set in ((2, "Previous"), (3, "HiFi-specific")):
            cmrg.append({
                "depth_x": depth_number(value(rows, row, 1), f"{sheet}!A{row}"), "parameter_set": parameter_set,
                "cmrg_f1": number(value(rows, row, column), f"{sheet}!row{row}"),
                "source_workbook": WORKBOOK.name, "source_sheet": sheet, "source_row": row,
            })
    if [len(x) for x in (whole, call_count, refine, cmrg)] != [6, 6, 5, 4]:
        raise ValueError("cuteSV HiFi sensitivity extraction did not match workbook completeness")
    return whole, call_count, refine, cmrg


def main() -> None:
    if not WORKBOOK.exists():
        raise FileNotFoundError(WORKBOOK)
    sheets = load_sheets(WORKBOOK)
    required = {"cutesv调参", "cutesv调参(结果)", "Sniffles2调参", "cuteSV-HiFi"}
    missing = required.difference(sheets)
    if missing:
        raise ValueError(f"Workbook sheets missing: {sorted(missing)}")

    round1 = extract_cutesv_round1(sheets)
    round2 = extract_cutesv_round2(sheets)
    sniffles_matrix, sniffles_depth = extract_sniffles(sheets)
    hifi, hifi_counts, hifi_refine, hifi_cmrg = extract_cutesv_hifi(sheets)
    write_csv("cutesv_round1_fullfactor.csv", round1)
    write_csv("cutesv_round2_targeted.csv", round2)
    write_csv("sniffles2_matrix_50x.csv", sniffles_matrix)
    write_csv("sniffles2_cross_depth.csv", sniffles_depth)
    write_csv("cutesv_hifi_wholegenome.csv", hifi)
    write_csv("cutesv_hifi_callcount.csv", hifi_counts)
    write_csv("cutesv_hifi_refine_incomplete.csv", hifi_refine)
    write_csv("cutesv_hifi_cmrg_incomplete.csv", hifi_cmrg)
    print("Extraction passed: cuteSV round1=162, round2=14; Sniffles2 matrix=9, depth=6; HiFi=6/6/5/4")


if __name__ == "__main__":
    main()
