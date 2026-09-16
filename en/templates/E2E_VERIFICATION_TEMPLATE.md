# Manual e2e verification — [Feature / bug fix name]

> Step-by-step checklist for an end-to-end verification carried out by a person (not automated),
> typically after deploying to a live environment. Write the steps so that anyone — not just the
> author of the change — can execute them without ambiguity.

## References

- **Linked plan/task**: [...]
- **Verification environment**: [local/test/staging/production]

## Preconditions

- [...]
- [required data/users/roles]

## Verification steps

1. [Step 1 — precise action: where to click/what to call/what to enter]
   - **Expected outcome**: [...]
2. [Step 2]
   - **Expected outcome**: [...]
3. [...]

## Persisted data verification (if applicable)

[How to check that the data was actually saved/updated correctly — e.g. read-only query, API
response inspection, application log.]

## Edge cases to verify

- [...]

## Execution outcome (to be filled in by whoever executes)

- **Date/time**: [YYYY-MM-DD HH:MM]
- **Executed by**: [...]
- **Outcome**: `[OK | KO]`
- **Notes/anomalies**: [...]
