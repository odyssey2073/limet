# Task list — [Feature / bug fix name]

> Derived from `PLAN_TEMPLATE.md` §6 (or from the task lists in `CHANGE_PROPOSAL_TEMPLATE.md`).
> Each row is a granular, trackable task, with explicit status and dependencies. For a complex
> task, create a dedicated sheet with `TASK_TEMPLATE.md` and link it from the "Detail" column.

## Status legend

- `pending` — not started yet
- `in_progress` — in progress
- `blocked` — blocked (justify in the Notes column)
- `done` — completed **and verified** ("written" is not enough — it must also be verified per
  the Test strategy section below). **When a task moves to `done`, record the date and time**
  (`YYYY-MM-DD HH:MM`) in the Notes column, not just the date — see `FRAMEWORK_MANUAL.md` §4.

## Task table

| # | Title | Non-technical purpose | Status | Depends on | Detail | Notes |
| - | ----- | --------------------- | ------ | ---------- | ------ | ----- |
| 1 | [...] | [one line: what it does] | pending | — | [link to task sheet, if any] | |
| 2 | [...] | [...] | pending | #1 | | |

---

## Test strategy — mandatory for every task (not omissible without explicit justification)

> See `FRAMEWORK_MANUAL.md` §1.5 and §5. For **each task** in the table above, fill in the
> corresponding row below. A task cannot move to `done` if this section is not filled in (even
> just with a "not applicable because...").

| Task # | Unit tests planned/existing | E2e tests planned (ref. `E2E_VERIFICATION_TEMPLATE.md`) | If omitted, explicit justification |
| ------ | ----------------------------- | --------------------------------------------------------- | ------------------------------------ |
| 1      | [yes: short description / no] | [yes: link / no]                                           | [mandatory if either is "no"]        |
| 2      |                                |                                                             |                                       |

## Implementation outcome (fill in once work is finished)

> Retroactive update: do not rewrite history, add a dated section describing what was actually
> done, any deviations from the original plan, and why.

- **Date**: [YYYY-MM-DD]
- **Outcome summary**: [...]
- **Deviations from the plan**: [...]
- **Test outcome** (reference to `TEST_EXECUTION_TEMPLATE.md` if any): [...]
- **Completion date/time for each task** (`YYYY-MM-DD HH:MM`): record it in the task table above,
  Notes column, not only here in the summary.
