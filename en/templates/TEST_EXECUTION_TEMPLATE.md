# Test execution — [Feature / bug fix / task name]

> Records the **actual outcome** of a test run (not the planning — see `TEST_PLAN_TEMPLATE.md`
> for that). To be filled in by whoever actually runs the build/tests, pasting real logs, not
> summarized from memory.

## References

- **Linked test plan**: [link to `TEST_PLAN_TEMPLATE.md`]
- **Linked task(s)**: [reference to `TASK_LIST_TEMPLATE.md` / `TASK_TEMPLATE.md`]

## Execution metadata

- **Execution date/time**: [YYYY-MM-DD HH:MM]
- **Executed by**: [...]
- **Environment**: [local/CI/other]
- **Command run**: [exact command used to launch the tests]

## Unit test outcome

- **Total**: [N] — **Passed**: [N] — **Failed**: [N] — **Skipped**: [N]
- **Relevant log/excerpt**:

```
[paste the actual test runner output here, or just the relevant part]
```

## E2e test outcome

| # | Scenario (ref. test plan) | Outcome (OK / KO / not run) | Notes |
| - | ---------------------------- | ------------------------------ | ----- |
| 1 | [...]                         | [...]                           | [...] |

## Anomalies found

> If something failed or was unexpected, describe it here and link it to a new
> `BUG_REPORT_TEMPLATE.md` if it is a defect separate from the task at hand.

- [...]

## Conclusion

- **Overall outcome**: `[OK | KO | PARTIAL]`
- **Can the task move to `done`?**: [yes/no + justification]
