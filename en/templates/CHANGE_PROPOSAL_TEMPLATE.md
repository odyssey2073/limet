# Change proposal — [Capability/change name]

> Use instead of (or alongside) `PLAN_TEMPLATE.md` for larger changes: a new capability, a
> contract/interface change, impact on multiple modules. Describes the *why*. The verifiable
> *what* goes in `SPEC_TEMPLATE.md`; the *how* (if not obvious) goes in `DESIGN_TEMPLATE.md`.

## Metadata

- **Creation date**: [YYYY-MM-DD]
- **Status**: `[DRAFT | APPROVED | IN PROGRESS | COMPLETED | ABANDONED]`
- **Approved by / date**: [who — YYYY-MM-DD] (fill when Status → APPROVED)
- **Linked specs**: [list of `SPEC_TEMPLATE.md` instances created for this proposal]
- **Linked design**: [`DESIGN_TEMPLATE.md` file, if any]

## Why

[What is the problem or opportunity? Why now? What happens if this change is not made?]

## What changes (summary)

[High-level summary — verifiable detail lives in the linked specs.]

- [change 1]
- [change 2]

## Capabilities

### New capabilities
- `[capability-name]`: [short description]

### Modified capabilities
- `[existing-capability-name]`: [which requirement changes and why]

### Removed/deprecated capabilities
- `[capability-name]`: [reason for removal, migration plan if applicable]

## Impact

- **Code/modules affected**: [list]
- **APIs/contracts affected**: [list, noting backward compatibility]
- **External dependencies**: [libraries, third-party services, other teams]
- **Existing data**: [is a migration needed? is it backward-compatible?]

## Open contextual questions

| # | Question | Answer | Date | By whom |
| - | -------- | ------ | ---- | ------- |
| 1 | [...]    | [...]  | [...] | [...]  |

## Verification strategy (mandatory, see `FRAMEWORK_MANUAL.md` §5)

- **Unit tests**: [reference to `TEST_PLAN_TEMPLATE.md`]
- **E2e tests**: [reference to `E2E_VERIFICATION_TEMPLATE.md`]

## Outcome (fill in at closure, before archiving)

- **Date**: [YYYY-MM-DD]
- **Summary**: [...]
- **Deviations from the original proposal**: [...]
