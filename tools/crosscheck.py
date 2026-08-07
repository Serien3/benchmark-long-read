"""Cross-check the raw-XML reader against calamine, cell by cell.

Guards against a silent parsing bug in xlsx_read.py before we build anything
on top of it.
"""
import sys

import pandas as pd

sys.path.insert(0, "tools")
from xlsx_read import Workbook, WORKBOOK  # noqa: E402


def norm(v):
    if v is None:
        return ""
    if isinstance(v, bool):
        return str(v)
    if isinstance(v, (int, float)):
        if isinstance(v, float) and v != v:  # NaN
            return ""
        return f"{float(v):.10g}"
    s = str(v).strip()
    if s == "":
        return ""
    try:
        return f"{float(s):.10g}"
    except ValueError:
        return s


wb = Workbook()
xl = pd.ExcelFile(WORKBOOK, engine="calamine")

total = 0
mismatch = 0
for sheet in wb.sheets:
    df = xl.parse(sheet.name, header=None)
    for (r, c), v in sorted(sheet.cells.items()):
        total += 1
        if r - 1 >= len(df) or c - 1 >= df.shape[1]:
            other = None
        else:
            other = df.iat[r - 1, c - 1]
        a, b = norm(v), norm(other)
        if a != b:
            # Dates: calamine yields datetime objects, we yield ISO strings.
            if b.startswith(a[:10]) and len(a) >= 10:
                continue
            mismatch += 1
            if mismatch <= 200:
                print(f"DIFF {sheet.name} r{r}c{c}: ours={v!r} calamine={other!r}")

print(f"\ncompared {total} cells, {mismatch} mismatches")
sys.exit(1 if mismatch else 0)
