# Spec — Capability: [capability-name]

> Describes the *what* in verifiable form. One spec for each new/modified capability listed in
> the linked `CHANGE_PROPOSAL_TEMPLATE.md`. Tests (unit/e2e) must align to these
> requirements/scenarios.

## Metadata

- **Linked proposal**: [reference to `CHANGE_PROPOSAL_TEMPLATE.md`]
- **Status**: `[DRAFT | APPROVED | IMPLEMENTED]`
- **Version**: [increment if the spec changes after implementation]

## Capability description

[What this capability does, in terms of observable behavior — not implementation.]

## Requirements

> Every requirement must be verifiable: avoid generic phrasing ("must be robust"), use
> observable conditions.

### Requirement 1: [short title]

[Requirement description.]

**Scenarios** (given/when/then):

- **Given** [precondition], **when** [action/event], **then** [expected observable result].
- **Given** [alternative precondition/edge case], **when** [...], **then** [...].

### Requirement 2: [short title]

[...]

## Constraints and edge cases

- [constraint 1: e.g. null values, concurrency conditions, configuration limits]
- [edge case 1]

## Out of spec (explicitly not covered)

- [behavior not guaranteed by this spec, to avoid misunderstandings]

## Traceability to tests

| Requirement | Unit test | E2e test |
| --- | --- | --- |
| Requirement 1 | [reference] | [reference] |
| Requirement 2 | [reference] | [reference] |
