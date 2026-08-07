# QA record

- Source: `data/mobile_element_xtea.csv` (6/6 rows retained).
- Design completeness: 3 platforms × 2 aligners, one row per combination.
- Common conditions: HG002, GRCh38, 30×, xTEA-long.
- Result basis: all rows use `merged_* final` outputs.
- Arithmetic check: `Total merged ME = ALU + LINE1 + SVA + HERV` for every row.
- Status check: all workflows are completed. Three rows retain a documented old
  `.failed` marker inconsistency, but Slurm/xTEA exit codes are zero and final
  merged outputs are present.
- Exclusions: none.
- Transformation: wide-to-long reshape only; no aggregation, smoothing, or
  interpolation.
- Statistics: no error bars or significance tests because these workflows are not
  biological/technical replicates and the table contains no uncertainty estimate.
- Interpretation boundary: candidate counts and family composition only; the plot
  does not establish sensitivity, precision, or truth-set accuracy.
- Accessibility: exact totals are directly labeled; segment boundaries have thin
  outlines; family colors are low-saturation and ordered consistently.
- Low-abundance visibility: HERV remains encoded at its exact 6–8-candidate
  height. A purple leader and direct `HERV n` label improve discoverability; no
  minimum display height, axis break, or geometric exaggeration is used.
- Static preflight: all substantive checks pass. The validator emits its generic R
  syntax warning because it only performs a delimiter check; an actual
  `Rscript parse()` check passes before delivery.

## Composition version

- Each family count is divided by the matching workflow's `Total merged ME`;
  proportions sum to exactly 100% for all six bars.
- Absolute yield is retained as a direct `n=` label rather than encoded by bar
  height.
- The six bars share one continuous axis; x-position gaps encode platform groups
  and do not alter values.
- HERV retains its true 0.3–0.4% height and is read through a linked direct label.
- The supplied example influenced spacing and the 100% composition grammar only;
  its dense hatch and overlapping labels were not inherited.
- Final standalone canvas is 105 × 75 mm so the full aligner labels remain
  separated and the two-level x-axis hierarchy does not collide with the legend;
  it can be scaled uniformly during later manuscript assembly.
