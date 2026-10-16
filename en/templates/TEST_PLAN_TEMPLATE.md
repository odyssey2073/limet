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

### Quality self-review (mandatory — see `FRAMEWORK_MANUAL.md` §5.1)

> To be filled in before declaring the test work complete. This is not a formality: a test can be
> present and tracked and still not fail when the defect comes back.

- **Mental sabotage**: which single plausible alteration of the production code would NOT make
  any test fail? [answer, or "none" — if one exists, a test is missing]
- [ ] Every assert can fail **for the reason stated** (no assert that cannot fail on its own)
- [ ] The expected value is **not derived** from the object under test
- [ ] No arbitrary sample: complete set, or written selection criterion
- [ ] The method contract is verified (absent/empty/invalid input), not just the happy path
- [ ] Any redundancy between tests is declared and justified
- [ ] What the unit test cannot cover is written down, pointing to what does cover it
- [ ] No shared-state mutation (the outcome does not depend on execution order)

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

## Re-runnable test commands

> Exact command to re-run each test, with a short description — so anyone (or a future session)
> can reproduce the verification without re-deriving it.

Command forms (Surefire/JUnit):

- Whole class: `./mvnw test -Dtest=MyClassTest`
- Single method: `./mvnw test -Dtest=MyClassTest#myMethod`

For each test: the state to check **before** (pre-test) and **after** (post-test) — e.g. DB rows
via SQL, a file on disk, a config value, cache content, an external service — plus the two
commands. Omit pre/post when not applicable.

### Test 1 — [short description]

- **Pre-test** (expected state before):
  ```sql
  SELECT count(*) FROM employee;  -- expected 0
  ```
- **Command — whole class**: `./mvnw test -Dtest=MyClassTest`
- **Command — single method**: `./mvnw test -Dtest=MyClassTest#myMethod`
- **Post-test** (expected state after):
  ```sql
  SELECT count(*) FROM employee;  -- expected 5
  ```

### Test 2 — [...]

- **Pre-test**: [...]
- **Command — whole class**: `./mvnw test -Dtest=...`
- **Command — single method**: `./mvnw test -Dtest=...#...`
- **Post-test**: [...]
