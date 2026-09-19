# Task sheet — [Task title]

> Use for a task complex enough to deserve dedicated analysis: when the solution is not obvious,
> multiple context sources are needed, or there are decisions to make explicit before writing
> code.

## 0. Summary

### Purpose (non-technical)

[What this task does and why, in plain language for people who don't read code.]

### Changes (technical)

> Files created/modified, with path and project; brief indication of what code was
> inserted/changed and why. Fill in (or refine) once the work is done.

| Project | File (path) | Created/Modified | What changes and why |
| ------- | ----------- | ---------------- | -------------------- |
| ...     | `src/...`   | created          | [...]                |

## Metadata

- **Reference**: task #[N] of `TASK_LIST_TEMPLATE.md` (or associated plan/proposal)
- **Status**: `[pending | in_progress | blocked | done]`
- **Last update date**: [YYYY-MM-DD]

## 1. Task description

[What needs to be done, in concrete, verifiable terms — not a generic goal.]

## 2. Context gathered

> List the sources consulted before acting, and what was found. Always distinguish a verified
> fact from an assumption.

- **Source 1** ([type: code / documentation / real data]): [what it says, with a precise
  reference]
- **Source 2**: [...]

## 3. Contextual question (if any)

> If information is missing to proceed with confidence, make it explicit here **instead of
> assuming**. Do not proceed further until answered, unless an assumption is declared in
> section 4.

- **Question**: [...]
- **Why it matters**: [what would change in the solution depending on the answer]
- **Answer received**: [...] — **Date**: [YYYY-MM-DD] — **From**: [who answered]

> If you had to proceed with a justified assumption, state it explicitly here, along with the
> associated risk.

## 4. Proposed/applied solution

[Technical description of the change: files touched, logic introduced/modified, rationale.]

- **File 1**: [path] — [what changes and why]

### Discarded alternatives

- [alternative] — discarded because [reason]

## 5. Test strategy (mandatory)

> Do not omit. If truly not applicable, explain explicitly why.

### 5.1 Unit tests

- **Do tests already cover this area?** [yes/no — reference]
- **New unit tests planned**: [list of cases, or "none because..."]
- **Where detailed**: [reference to `TEST_PLAN_TEMPLATE.md`]

### 5.2 E2e tests

- **Needed?** [yes/no + justification]
- **Reference**: [link to `E2E_VERIFICATION_TEMPLATE.md` filled in for this task]

## 6. Risks/impacts on other parts of the system

[What else could be affected, and how it was verified.]

## 7. Outcome (fill in once work is finished)

- **Date**: [YYYY-MM-DD]
- **Final status**: [done/blocked — if blocked, reason]
- **Test outcome**: [summary, with reference to `TEST_EXECUTION_TEMPLATE.md`]
- **Notes for future readers**: [...]
