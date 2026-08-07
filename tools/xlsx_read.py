"""Raw-XML xlsx reader for 最新数据评测.xlsx.

openpyxl cannot open this workbook (its styles.xml trips a Fill descriptor bug),
so we parse the OOXML parts directly. This gives us three things the pandas /
calamine path cannot:

  * merged-cell ranges  -> needed to forward-fill the key columns
  * per-cell fill color -> carries meaning in cutesv调参 / Sniffles2调参
  * a complete cell inventory -> lets verify.py prove nothing was dropped

Coordinates are 1-based throughout (row 1 == spreadsheet row 1) so that every
provenance reference in meta/ matches what you see in Excel.
"""

from __future__ import annotations

import datetime as _dt
import re
import zipfile
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from functools import cached_property

MAIN = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
RELNS = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"

WORKBOOK = "最新数据评测.xlsx"

# Excel serial-date epoch (1900 system, with the historical leap-year bug).
_EPOCH = _dt.datetime(1899, 12, 30)


def col_to_index(col: str) -> int:
    """'A' -> 1, 'Z' -> 26, 'AA' -> 27."""
    n = 0
    for ch in col:
        n = n * 26 + (ord(ch) - 64)
    return n


def index_to_col(idx: int) -> str:
    """1 -> 'A', 27 -> 'AA'."""
    out = ""
    while idx:
        idx, rem = divmod(idx - 1, 26)
        out = chr(65 + rem) + out
    return out


def split_ref(ref: str) -> tuple[int, int]:
    """'C12' -> (12, 3)  i.e. (row, col), both 1-based."""
    m = re.match(r"([A-Z]+)(\d+)", ref)
    if not m:
        raise ValueError(f"bad cell ref: {ref}")
    return int(m.group(2)), col_to_index(m.group(1))


@dataclass
class MergeRange:
    ref: str
    r1: int
    c1: int
    r2: int
    c2: int

    @property
    def is_vertical(self) -> bool:
        return self.r2 > self.r1 and self.c2 == self.c1

    @property
    def is_horizontal(self) -> bool:
        return self.c2 > self.c1 and self.r2 == self.r1


@dataclass
class Sheet:
    name: str
    index: int
    # (row, col) -> value, values are str | float | int | bool | None
    cells: dict[tuple[int, int], object] = field(default_factory=dict)
    # (row, col) -> ARGB hex string, only for cells with a solid non-white fill
    fills: dict[tuple[int, int], str] = field(default_factory=dict)
    merges: list[MergeRange] = field(default_factory=list)

    @cached_property
    def max_row(self) -> int:
        return max((r for r, _ in self.cells), default=0)

    @cached_property
    def max_col(self) -> int:
        return max((c for _, c in self.cells), default=0)

    @cached_property
    def merge_anchor(self) -> dict[tuple[int, int], tuple[int, int]]:
        """Every covered cell -> the top-left anchor holding the real value."""
        out: dict[tuple[int, int], tuple[int, int]] = {}
        for m in self.merges:
            for r in range(m.r1, m.r2 + 1):
                for c in range(m.c1, m.c2 + 1):
                    out[(r, c)] = (m.r1, m.c1)
        return out

    def get(self, row: int, col: int, unmerge: bool = True):
        """Value at (row, col). With unmerge=True, cells covered by a merge
        report the anchor's value rather than blank."""
        key = (row, col)
        if key in self.cells:
            return self.cells[key]
        if unmerge:
            anchor = self.merge_anchor.get(key)
            if anchor is not None:
                return self.cells.get(anchor)
        return None

    def row_values(self, row: int, unmerge: bool = True) -> list:
        return [self.get(row, c, unmerge) for c in range(1, self.max_col + 1)]

    def nonempty_cells(self) -> list[tuple[int, int, object]]:
        """Every cell that actually holds a value, in reading order.
        This is the denominator for the information-loss audit."""
        return [(r, c, v) for (r, c), v in sorted(self.cells.items())
                if v is not None and str(v).strip() != ""]


# Number-format ids / codes that mean "this serial number is a date".
_BUILTIN_DATE_IDS = set(range(14, 23)) | set(range(45, 48)) | {27, 30, 36, 50, 57}


def _is_date_format(code: str | None, numfmt_id: int | None) -> bool:
    if code:
        stripped = re.sub(r"\[[^\]]*\]|\"[^\"]*\"", "", code)
        if re.search(r"[yhsm]", stripped, re.IGNORECASE) and re.search(
            r"[ymdhs]", stripped, re.IGNORECASE
        ):
            return bool(re.search(r"y{2,}|d{1,2}|h{1,2}", stripped, re.IGNORECASE))
    if numfmt_id is not None:
        return numfmt_id in _BUILTIN_DATE_IDS
    return False


class Workbook:
    def __init__(self, path: str = WORKBOOK):
        self.path = path
        self._zip = zipfile.ZipFile(path)
        self._shared = self._read_shared_strings()
        self._fill_by_xf, self._is_date_xf = self._read_styles()
        self.sheets = self._read_sheets()

    # ---------- OOXML parts ----------

    def _read_shared_strings(self) -> list[str]:
        try:
            raw = self._zip.read("xl/sharedStrings.xml")
        except KeyError:
            return []
        root = ET.fromstring(raw)
        out = []
        for si in root.findall(f"{MAIN}si"):
            # Concatenate all text runs; rich text is flattened to plain text.
            out.append("".join(t.text or "" for t in si.iter(f"{MAIN}t")))
        return out

    def _read_styles(self) -> tuple[list[str | None], list[bool]]:
        root = ET.fromstring(self._zip.read("xl/styles.xml"))

        custom: dict[int, str] = {}
        numfmts = root.find(f"{MAIN}numFmts")
        if numfmts is not None:
            for nf in numfmts.findall(f"{MAIN}numFmt"):
                custom[int(nf.get("numFmtId"))] = nf.get("formatCode") or ""

        fill_colors: list[str | None] = []
        fills = root.find(f"{MAIN}fills")
        for f in fills.findall(f"{MAIN}fill") if fills is not None else []:
            pf = f.find(f"{MAIN}patternFill")
            rgb = None
            if pf is not None and pf.get("patternType") == "solid":
                fg = pf.find(f"{MAIN}fgColor")
                if fg is not None:
                    rgb = fg.get("rgb")
                    if rgb is None and fg.get("theme") is not None:
                        rgb = f"theme{fg.get('theme')}"
            fill_colors.append(rgb)

        fill_by_xf: list[str | None] = []
        is_date_xf: list[bool] = []
        cell_xfs = root.find(f"{MAIN}cellXfs")
        for xf in cell_xfs.findall(f"{MAIN}xf") if cell_xfs is not None else []:
            fid = xf.get("fillId")
            colour = None
            if fid is not None and int(fid) < len(fill_colors):
                colour = fill_colors[int(fid)]
            fill_by_xf.append(colour)

            nid = xf.get("numFmtId")
            nid_int = int(nid) if nid is not None else None
            is_date_xf.append(
                _is_date_format(custom.get(nid_int) if nid_int is not None else None,
                                nid_int)
            )
        return fill_by_xf, is_date_xf

    def _read_sheets(self) -> list[Sheet]:
        wb = ET.fromstring(self._zip.read("xl/workbook.xml"))
        rels = {
            r.get("Id"): r.get("Target")
            for r in ET.fromstring(self._zip.read("xl/_rels/workbook.xml.rels"))
        }

        out = []
        for i, sh in enumerate(wb.find(f"{MAIN}sheets"), start=1):
            target = rels[sh.get(f"{RELNS}id")].lstrip("/")
            if not target.startswith("xl/"):
                target = "xl/" + target
            out.append(self._read_sheet(sh.get("name"), i, target))
        return out

    def _read_sheet(self, name: str, index: int, part: str) -> Sheet:
        root = ET.fromstring(self._zip.read(part))
        sheet = Sheet(name=name, index=index)

        for c in root.iter(f"{MAIN}c"):
            ref = c.get("r")
            if ref is None:
                continue
            rc = split_ref(ref)

            style = c.get("s")
            xf = int(style) if style is not None else None
            if xf is not None and xf < len(self._fill_by_xf):
                colour = self._fill_by_xf[xf]
                # Plain white / near-white backgrounds are cosmetic, not semantic.
                if colour and colour not in ("FFFFFFFF", "FFFFFF", "00000000"):
                    sheet.fills[rc] = colour

            value = self._cell_value(c, xf)
            if value is not None:
                sheet.cells[rc] = value

        for m in root.iter(f"{MAIN}mergeCell"):
            ref = m.get("ref")
            start, end = ref.split(":")
            r1, c1 = split_ref(start)
            r2, c2 = split_ref(end)
            sheet.merges.append(MergeRange(ref, r1, c1, r2, c2))

        return sheet

    def _cell_value(self, c: ET.Element, xf: int | None):
        ctype = c.get("t")

        if ctype == "inlineStr":
            is_el = c.find(f"{MAIN}is")
            if is_el is None:
                return None
            text = "".join(t.text or "" for t in is_el.iter(f"{MAIN}t"))
            return text or None

        v = c.find(f"{MAIN}v")
        if v is None or v.text is None:
            return None
        raw = v.text

        if ctype == "s":  # shared string
            idx = int(raw)
            return self._shared[idx] if idx < len(self._shared) else None
        if ctype == "str":  # formula result, cached as text
            return raw
        if ctype == "e":  # error value, e.g. #DIV/0! — keep it visible
            return raw
        if ctype == "b":
            return raw == "1"

        # Numeric (t absent or t="n").
        try:
            num = float(raw)
        except ValueError:
            return raw

        if xf is not None and xf < len(self._is_date_xf) and self._is_date_xf[xf]:
            try:
                dt = _EPOCH + _dt.timedelta(days=num)
            except OverflowError:
                return num
            if dt.time() == _dt.time(0, 0):
                return dt.strftime("%Y-%m-%d")
            return dt.strftime("%Y-%m-%d %H:%M:%S")

        if num.is_integer() and abs(num) < 1e15:
            return int(num)
        return num

    # ---------- lookup ----------

    def __getitem__(self, name: str) -> Sheet:
        for s in self.sheets:
            if s.name == name:
                return s
        raise KeyError(name)

    @property
    def sheet_names(self) -> list[str]:
        return [s.name for s in self.sheets]
