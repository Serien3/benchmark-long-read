"""Convert 最新数据评测.xlsx into per-table CSVs plus metadata.

Run from the repository root:

    .venv/bin/python tools/convert.py

Outputs:
    data/*.csv            one logical table per file
    meta/notes.csv        every source cell not consumed by a data table
    meta/highlights.csv   cell fill colours that carry meaning
    meta/coverage.csv     per-sheet audit of consumed vs. total cells
    meta/index.json       table registry, field list, provenance

The workbook is never modified. Re-running is idempotent.
"""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from extract import extract  # noqa: E402
from specs import SPECS  # noqa: E402
from xlsx_read import WORKBOOK, Workbook, index_to_col  # noqa: E402

DATA = ROOT / "data"
META = ROOT / "meta"


def fmt(v: object) -> str:
    """Render a cell for CSV without inventing or losing precision."""
    if v is None:
        return ""
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        if v != v:
            return ""
        if v.is_integer() and abs(v) < 1e15:
            return str(int(v))
        return repr(v)
    return str(v)


def write_csv(path: Path, columns: list[str], rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    # utf-8-sig so Excel on Windows opens Chinese headers correctly.
    with path.open("w", encoding="utf-8-sig", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(columns)
        for row in rows:
            w.writerow([fmt(row.get(c)) for c in columns])


# Fill colours whose meaning is documented inside the workbook itself.
FILL_MEANING = {
    "FF5B9BD5": "cutesv调参：-q 10 组内该列指标最优（源文件 r200 蓝色图例）",
    "FFF4B183": "cutesv调参：-q 20 组内该列指标最优（源文件 r201 橙色图例）",
    "FFFFF2CC": "Sniffles2调参：该列最高 F1（源文件 r17 黄色图例）",
    "FFD9EAD3": "Sniffles2调参：综合推荐参数行（源文件 r17 浅绿图例）",
}


def main() -> int:
    wb = Workbook(str(ROOT / WORKBOOK))
    DATA.mkdir(exist_ok=True)
    META.mkdir(exist_ok=True)

    claimed: set[str] = set()
    registry: list[dict] = []
    provenance_rows: list[dict] = []

    for spec in SPECS:
        sheet = wb[spec.sheet]
        res = extract(sheet, spec)
        write_csv(DATA / f"{res.out}.csv", res.columns, res.rows)
        claimed |= res.claimed

        registry.append({
            "file": f"data/{res.out}.csv",
            "title": spec.title,
            "source_sheet": spec.sheet,
            "source_blocks": [
                {"rows": f"{b.first_row}-{b.last_row}",
                 "header_rows": b.header_rows,
                 "constants": {k: v for k, v in b.consts.items()}}
                for b in spec.blocks
            ],
            "rows": len(res.rows),
            "columns": res.columns,
            "note": spec.note,
        })
        for r, p in zip(res.rows, res.provenance):
            provenance_rows.append({"file": f"{res.out}.csv", **p})
        print(f"  {res.out:34s} {len(res.rows):4d} rows x {len(res.columns):2d} cols")

    # ---- leftover sweep: any cell no table consumed becomes a note ----
    notes: list[dict] = []
    coverage: list[dict] = []
    for sheet in wb.sheets:
        cells = sheet.nonempty_cells()
        unclaimed = []
        for r, c, v in cells:
            ref = f"{sheet.name}!{index_to_col(c)}{r}"
            if ref not in claimed:
                unclaimed.append((r, c, v))
                notes.append({
                    "sheet": sheet.name,
                    "cell": f"{index_to_col(c)}{r}",
                    "row": r,
                    "col": index_to_col(c),
                    "text": v,
                })
        coverage.append({
            "sheet": sheet.name,
            "cells_total": len(cells),
            "cells_in_tables": len(cells) - len(unclaimed),
            "cells_in_notes": len(unclaimed),
        })

    write_csv(META / "notes.csv",
              ["sheet", "cell", "row", "col", "text"], notes)
    write_csv(META / "coverage.csv",
              ["sheet", "cells_total", "cells_in_tables", "cells_in_notes"],
              coverage)

    highlights = []
    for sheet in wb.sheets:
        for (r, c), colour in sorted(sheet.fills.items()):
            if colour in FILL_MEANING:
                highlights.append({
                    "sheet": sheet.name,
                    "cell": f"{index_to_col(c)}{r}",
                    "fill_argb": colour,
                    "meaning": FILL_MEANING[colour],
                    "value": sheet.get(r, c),
                })
    write_csv(META / "highlights.csv",
              ["sheet", "cell", "fill_argb", "meaning", "value"], highlights)

    write_csv(META / "row_provenance.csv",
              ["file", "sheet", "source_row"], provenance_rows)

    (META / "index.json").write_text(
        json.dumps({"source_workbook": WORKBOOK, "tables": registry},
                   ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    tot = sum(c["cells_total"] for c in coverage)
    in_tbl = sum(c["cells_in_tables"] for c in coverage)
    in_note = sum(c["cells_in_notes"] for c in coverage)
    print(f"\n{len(SPECS)} tables written")
    print(f"cells: {tot} total = {in_tbl} in tables + {in_note} in notes")
    if in_tbl + in_note != tot:
        print("ERROR: cell accounting does not balance")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
