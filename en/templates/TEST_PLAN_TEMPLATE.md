# Test plan — [Feature / bug fix / task name]

> To be filled in **before** writing production code (or in any case before considering a task
> ready to be marked `done`). See `FRAMEWORK_MANUAL.md` §1.5 and §5: every task requires unit
> tests **and** thorough e2e tests, unless explicitly justified otherwise.

## References

- **Linked plan/proposal**: [link to `PLAN_TEMPLATE.md` or `CHANGE_PROPOSAL_TEMPLATE.md`]
- **Linked task(s)**: [reference to `TASK_LIST_TEMPLATE.md` / `TASK_TEMPLATE.md`]

## Verification scope

[What this test plan must guarantee — functionality, regressions to avoid, known edge cases.]

## Planned unit tests

| # | What it verifies | Test file/class | Case (happy path / edge case / regression) |
| - | ------------------ | ----------------- | --------------------------------------------- |
| 1 | [...]               | [...]              | [...]                                          |

## Planned e2e tests

> See also `E2E_VERIFICATION_TEMPLATE.md` for the step-by-step manual execution checklist.

| # | Scenario | Preconditions | Main steps | Expected outcome |
| - | -------- | --------------- | ------------ | ------------------- |
| 1 | [...]    | [...]           | [...]        | [...]                |

## Required test data

[Fixtures, domain data, users/roles, particular states to prepare.]

## Cases excluded from testing (and why)

> If something is not tested, it must be explicitly justified here — not left implicit.

- [...]

## Who executes

> "Write vs execute" principle (`FRAMEWORK_MANUAL.md` §1.3): whoever writes the code does not
> necessarily run the build/tests. Note here who is responsible for execution.

- **Test authoring**: [...]
- **Execution**: [...]
