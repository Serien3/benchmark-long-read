"""Print the structural skeleton of a sheet: which rows look like headers,
data, or prose. Used while writing specs.py."""
import sys

sys.path.insert(0, "tools")
from xlsx_read import Workbook, index_to_col  # noqa: E402

WIDTH = 18
wb = Workbook()

for name in sys.argv[1:]:
    s = wb[name]
    print("=" * 100)
    print(f"SHEET {name}  rows={s.max_row} cols={s.max_col}")
    hmerges = [m for m in s.merges if m.is_horizontal]
    if hmerges:
        print("  horizontal merges:",
              ", ".join(f"{m.ref}={s.cells.get((m.r1, m.c1))!r}" for m in hmerges))
    vmerges = [m for m in s.merges if m.is_vertical]
    if vmerges:
        print("  vertical merges:", ", ".join(m.ref for m in vmerges))
    for r in range(1, s.max_row + 1):
        filled = [(c, s.cells.get((r, c))) for c in range(1, s.max_col + 1)
                  if s.cells.get((r, c)) is not None]
        if not filled:
            continue
        span = f"{index_to_col(filled[0][0])}-{index_to_col(filled[-1][0])}"
        cells = " | ".join(
            f"{index_to_col(c)}:{str(v).replace(chr(10), ' ')[:WIDTH]}"
            for c, v in filled
        )
        print(f"  r{r:<4} n={len(filled):<3} {span:<8} {cells}")
