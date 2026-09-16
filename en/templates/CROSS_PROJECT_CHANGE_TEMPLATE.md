# Cross-project change — [Change name]

> "Umbrella" document for a change (feature or bug fix) that **spans multiple projects/modules**
> in the same workspace. It does not replace each project's own documents (plan, proposal, task
> list, etc.), it **coordinates** them: every involved project still keeps its own documents in
> its own `limet/changes/NNNN-slug/` folder. It lives in
> `limet-workspace/changes/NNNN-slug/CROSS_PROJECT_CHANGE.md`.

## References

- **Project map**: [link to `MODULE_MAP.md`]
- **Reason for the change**: [why it is needed, briefly — detail in each project's own proposal
  document(s)]

## Involved projects/modules and implementation order

> Essential when there is a contract (API/schema/event) between projects: the contract producer
> should normally be implemented and verified **before** the consumers.

| Order | Project/module | Role in this change | Linked local document | Status |
| ----- | ----------------- | ---------------------- | -------------------------- | ------ |
| 1     | [project name]     | [contract producer / consumer / both] | [link to `<project>/limet/changes/NNNN-slug/PLAN.md` or `TASK_LIST.md`] | `pending` |
| 2     | [project name]     | [...]                    | [...]                        | `pending` |

## Shared contract/interface (if applicable)

[Description of the new interface/field/event shared between projects — e.g. new field in an
API response, new asynchronous event, new shared configuration entry. Must be consistent across
all involved projects.]

## Risks of this cross-project change

- **Risk of misalignment between projects**: [e.g. one project released before another may cause
  temporary incompatibility — describe mitigation, e.g. backward/forward contract compatibility
  during the transition]
- **Risk of wrong deploy order**: [...]
- **Other**: [...]

## Overall closure criterion

> The cross-project change is considered complete only when **all** involved projects have their
> tasks at `done` (with date/time) and the cross-project end-to-end integration verification has
> passed — a single project being complete is not enough.

- [ ] All projects in the table have status `done`
- [ ] Cross-project integration e2e verification performed (see section below)
- [ ] `MODULE_MAP.md` updated if the contract/relationships between projects changed

## Cross-project integration e2e verification

[Manual checklist covering the entire flow across the involved projects, not just a single
project — e.g. "create data in project A, verify project B receives it correctly and processes
it as expected". Can reference the `E2E_VERIFICATION_TEMPLATE.md` filled in by each individual
project as sub-steps.]

## Final outcome (fill in at closure)

- **Overall closure date/time**: [YYYY-MM-DD HH:MM]
- **Summary**: [...]
- **Linked archive entry**: [link to `limet-workspace/archive/NNNN-slug/ARCHIVE_ENTRY.md`,
  possibly summarizing each project's individual `ARCHIVE_ENTRY.md`]
