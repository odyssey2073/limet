# Archive entry — [Feature / bug fix name]

> Freezes the history of a completed and verified change. Move (or link) it into the `archive/`
> folder once the work is finished, tested, and no longer "active". Do not rewrite history: this
> document is a final summary, the detailed documents (plan, tasks, tests) remain linked by
> reference.

## Metadata

- **Change name**: [...]
- **Type**: `[feature | bug fix | refactor | other]`
- **Completion date**: [YYYY-MM-DD HH:MM]
- **Author(s)**: [...]

## Summary

[What was done, in 3-5 lines, understandable even re-reading it months later without context.]

## Linked documents (reference, not a copy)

- **Plan/proposal**: [link]
- **Task list**: [link]
- **Test plan/execution**: [link]
- **Non-technical summary**: [link, if any]
- **Bug report** (if applicable): [link]

## Key decisions made during the work

[List of the most relevant contextual questions and the answers given, so the "why" behind the
choices made is not lost.]

## Final verification outcome

- **Unit tests**: [OK/KO, reference]
- **E2e tests**: [OK/KO, reference]
- **Any residual known issues**: [...]

## Lessons learned (optional)

[What to repeat the same way, what to avoid in the future, to improve the use of the framework
itself.]

## Re-index context

- [ ] After archiving, run `limet/scripts/limet-index.ps1 update` (or `limet-index.sh update`) to
      re-index the project's RAG collection (CEREBRO), so the archived change becomes searchable
      context for future sessions.
