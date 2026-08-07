"""Generic block extractor.

A sheet in 最新数据评测.xlsx is not a table. It is a page: banner rows, one or
more stacked sub-tables each with its own two-row header, key columns collapsed
into vertical merges, and prose annotations parked in whatever cell was free.

This module turns a declarative Spec (see specs.py) into rows, and reports back
exactly which source cells it consumed. convert.py sweeps every cell nobody
consumed into meta/notes.csv, so no text can be silently dropped.
"""

from __future__ import annotations

from dataclasses import dataclass, field

from xlsx_read import Sheet, index_to_col

SEP = " · "


@dataclass
class Block:
    """One contiguous sub-table inside a sheet."""

    first_row: int
    last_row: int
    # Rows holding header text, top-level group header first.
    header_rows: list[int] = field(default_factory=list)
    # Extra columns with a fixed value for every row of this block, typically
    # recovered from a banner row (e.g. "minimap2 - GRCh38" -> aligner+reference).
    consts: dict[str, object] = field(default_factory=dict)
    # Cells whose whole meaning is already captured by `consts`; claimed so the
    # leftover sweep does not file them as notes.
    banner_cells: list[str] = field(default_factory=list)
    # Data rows to leave to the note sweep (mid-block prose).
    skip_rows: list[int] = field(default_factory=list)


@dataclass
class Spec:
    """One output CSV."""

    sheet: str
    out: str
    blocks: list[Block]
    first_col: int = 1
    last_col: int = 1
    # Columns whose vertical merges / blank runs mean "same as above".
    ffill_cols: list[int] = field(default_factory=list)
    # Explicit column names, length must equal last_col - first_col + 1.
    # Overrides header inference; used where the source header is ambiguous.
    col_names: list[str] | None = None
    # Order of const columns in the output, before the sheet's own columns.
    const_order: list[str] = field(default_factory=list)
    title: str = ""
    note: str = ""


def _txt(v: object) -> str:
    return "" if v is None else str(v).strip()


def infer_col_names(sheet: Sheet, block: Block, first_col: int,
                    last_col: int) -> list[str]:
    """Join a multi-row header into one name per column.

    Horizontal merges in a group-header row are resolved via Sheet.get, so a
    span like E2:S2 = "raw" labels every column it covers.
    """
    names = []
    for c in range(first_col, last_col + 1):
        parts = []
        for hr in block.header_rows:
            t = _txt(sheet.get(hr, c))
            if t and t not in parts:
                parts.append(t)
        names.append(SEP.join(parts) if parts else index_to_col(c))
    return names


def dedupe(names: list[str]) -> list[str]:
    """Make column names unique, preserving order and first occurrence."""
    seen: dict[str, int] = {}
    out = []
    for n in names:
        if n in seen:
            seen[n] += 1
            out.append(f"{n}_{seen[n]}")
        else:
            seen[n] = 1
            out.append(n)
    return out


@dataclass
class Extracted:
    out: str
    columns: list[str]
    rows: list[dict]
    # Source cells consumed, as "SheetName!C12" strings.
    claimed: set[str]
    provenance: list[dict]


def extract(sheet: Sheet, spec: Spec) -> Extracted:
    claimed: set[str] = set()
    all_rows: list[dict] = []
    provenance: list[dict] = []
    columns: list[str] | None = None

    def claim(r: int, c: int) -> None:
        """Mark (r, c) consumed. If it is covered by a merge, the anchor holds
        the value, so claim the anchor too."""
        claimed.add(f"{sheet.name}!{index_to_col(c)}{r}")
        anchor = sheet.merge_anchor.get((r, c))
        if anchor:
            ar, ac = anchor
            claimed.add(f"{sheet.name}!{index_to_col(ac)}{ar}")

    for block in spec.blocks:
        names = spec.col_names or infer_col_names(
            sheet, block, spec.first_col, spec.last_col
        )
        if spec.col_names is None and all(
            name == index_to_col(c)
            for name, c in zip(names, range(spec.first_col, spec.last_col + 1))
        ):
            raise ValueError(
                f"{spec.out}: configured header rows {block.header_rows} are empty; "
                "refusing to emit fallback A/B/C column names"
            )
        if len(names) != spec.last_col - spec.first_col + 1:
            raise ValueError(
                f"{spec.out}: {len(names)} names for "
                f"{spec.last_col - spec.first_col + 1} columns"
            )

        const_names = spec.const_order or list(block.consts)
        block_cols = dedupe(const_names + names)
        if columns is None:
            columns = block_cols
        elif columns != block_cols:
            raise ValueError(
                f"{spec.out}: block header mismatch\n  {columns}\n  {block_cols}"
            )

        # Header cells are consumed by the column names.
        for hr in block.header_rows:
            for c in range(spec.first_col, spec.last_col + 1):
                if sheet.get(hr, c) is not None:
                    claim(hr, c)
        for ref in block.banner_cells:
            claimed.add(f"{sheet.name}!{ref}")

        carry: dict[int, object] = {}
        for r in range(block.first_row, block.last_row + 1):
            if r in block.skip_rows:
                continue

            values: dict[int, object] = {}
            for c in range(spec.first_col, spec.last_col + 1):
                v = sheet.get(r, c)
                if v is not None:
                    claim(r, c)
                if c in spec.ffill_cols:
                    if v is not None and _txt(v) != "":
                        carry[c] = v
                    else:
                        v = carry.get(c)
                values[c] = v

            if all(v is None or _txt(v) == "" for v in values.values()):
                continue  # spacer row inside a block

            row = dict(block.consts)
            for name, c in zip(names, range(spec.first_col, spec.last_col + 1)):
                row[name] = values[c]
            ordered = {k: row.get(k) for k in block_cols}
            all_rows.append(ordered)
            provenance.append({"sheet": sheet.name, "source_row": r})

    return Extracted(spec.out, columns or [], all_rows, claimed, provenance)
