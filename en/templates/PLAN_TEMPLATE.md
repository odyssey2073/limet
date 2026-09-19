# Plan — [Feature / bug fix name]

> Fill in before making non-trivial code changes (touches multiple files/modules, requires
> non-obvious decisions, or the outcome is not a given). For trivial micro-fixes this document
> can be skipped — see `FRAMEWORK_MANUAL.md` §3. For larger changes, consider
> `CHANGE_PROPOSAL_TEMPLATE.md` + `SPEC_TEMPLATE.md` (+ `DESIGN_TEMPLATE.md`) instead of this
> single document.

## Metadata

- **Creation date**: [YYYY-MM-DD]
- **Author/agent**: [name]
- **Status**: `[DRAFT | APPROVED | IN PROGRESS | COMPLETED | ABANDONED]`
- **Approved by / date**: [who — YYYY-MM-DD] (fill when Status → APPROVED)
- **Original request reference**: [issue/ticket/user message, if any]

## 1. Objective

[2-4 sentences: what you want to achieve and why. Not yet *how*.]

## 2. Scope

### In scope
- [item 1]

### Out of scope (explicitly excluded)
- [item 1 — reason for exclusion]

## 3. Current state (preliminary analysis)

[What already exists today, verified as fact (not assumed). List the components involved.]

- [component 1]: [what it does today]

## 4. Open contextual questions

| # | Question | Answer | Date | By whom |
| - | -------- | ------ | ---- | ------- |
| 1 | [...]    | [...]  | [...] | [...]  |

## 5. Proposed approach

[Design of the solution: components touched, logic introduced/modified.]

### Alternatives considered and discarded

- **Alternative A**: [description] — discarded because [reason].

## 6. Todo/activity list

> Granular detail goes in `TASK_LIST_TEMPLATE.md`. **Always** generate the
> separate `TASK_LIST.md` from this section — never ask whether to create it.

1. [activity 1]

## 7. Verification strategy (mandatory)

- **Unit tests planned**: [yes/no + where — typically `TEST_PLAN_TEMPLATE.md`] — if "no",
  explicitly justify.
- **E2e tests planned**: [yes/no + reference to `E2E_VERIFICATION_TEMPLATE.md`] — if "no",
  explicitly justify.
- **Always** produce `TEST_PLAN.md` (from `TEST_PLAN_TEMPLATE.md`),
  `E2E_VERIFICATION.md` (from `E2E_VERIFICATION_TEMPLATE.md`), and, after execution,
  `TEST_EXECUTION.md` (from `TEST_EXECUTION_TEMPLATE.md`), each with exact re-runnable commands
  and test descriptions. Archive all three in `limet/archive/<date-slug>/`.

## 8. Risks and impacts

- **Risk 1**: [description] — mitigation: [...]
- **Impact on other components**: [list or "none, verified because..."]
- **Backward compatibility**: [legacy behavior unchanged? how was it verified?]

## 9. Operational notes

- Commit/push: [who runs them]
- Environment/permissions needed for build/test: [...]

---

## Plan update history

| Date | Change | Reason |
| ---- | ------ | ------ |
| [YYYY-MM-DD] | [...] | [...] |
