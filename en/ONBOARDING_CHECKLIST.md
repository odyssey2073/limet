# Onboarding checklist — start of session/feature (LIMET)

> Consult at the start of a session or before starting a new feature/bug fix with an AI agent.
> Check off each item; if an item does not apply, note it explicitly instead of silently
> skipping it.

## 1. Before starting

- [ ] I have read/recalled the relevant project context (existing documentation, agent
      instructions, if any).
- [ ] I have checked whether a plan/proposal for this work already exists (avoid duplication).
- [ ] I am clear on whether the work is small enough to skip a formal plan document (see
      `FRAMEWORK_MANUAL.md` §3) or whether `PLAN_TEMPLATE.md`/`CHANGE_PROPOSAL_TEMPLATE.md` is
      needed.

## 2. Context gathering

- [ ] I have used the available context sources (documentary/structural/real data — see §2 of
      the manual) following the combination criterion (§2.4), not at random.
- [ ] Every ambiguity found has been recorded as a contextual question (§1.2), not assumed.

## 3. Planning

- [ ] The plan/proposal explicitly describes what is in/out of scope.
- [ ] Alternatives considered and discarded are documented (if relevant).
- [ ] The verification strategy (unit + e2e) is already sketched at this stage, not postponed
      until after implementation.

## 4. Implementation

- [ ] Changes stay within the declared scope (or the deviation has been flagged and possibly
      approved).
- [ ] No command with persistent effects (commit, push, migration, deploy) has been run without
      explicit authorization.

## 5. Verification (mandatory — see manual §1.5/§5)

- [ ] Unit tests have been written/extended for the modified behavior.
- [ ] It has been assessed whether a thorough e2e test is needed; if so, it has been documented
      with `E2E_VERIFICATION_TEMPLATE.md` (preconditions, numbered steps, expected result per
      step, objective verification criteria, rollback).
- [ ] If a test was not planned, the justification is explicit in the task document (§5.3).
- [ ] The actual test outcome (not just the planned one) has been recorded in
      `TEST_EXECUTION_TEMPLATE.md`.

## 6. Closing

- [ ] Plan/task documents have been retroactively updated with the implementation outcome (date,
      deviations from the plan).
- [ ] If relevant, a non-technical summary has been produced
      (`NON_TECHNICAL_SUMMARY_TEMPLATE.md`).
- [ ] Completed work has been frozen with `ARCHIVE_ENTRY_TEMPLATE.md`, if the project separates
      active documentation from archived documentation.
- [ ] Leftover tasks that are no longer needed have been removed/flagged.
- [ ] The project's RAG collection has been re-indexed (`limet/scripts/limet-index.ps1 update`),
      so the archived change is searchable context for future sessions.
