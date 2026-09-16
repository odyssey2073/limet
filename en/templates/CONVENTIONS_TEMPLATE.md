# Code conventions — [Project name]

> Reference document of the project's coding conventions, generated from the codebase (with the
> agent's judgment) and indexed into the project's CEREBRO collection. It is the "single source of
> truth" for how code in this project should be written, so that any AI agent works consistently
> across sessions. Update it whenever a convention changes or a new pattern is adopted.

## Languages, frameworks and versions

| Area | Technology | Version |
| ---- | ---------- | ------- |
| [...] | [...]      | [...]   |

## Naming conventions

| Kind | Convention | Example |
| ---- | ---------- | ------- |
| files | [...]      | [...]   |
| variables | [...]  | [...]   |
| functions | [...] | [...]   |
| classes/types | [...] | [...] |
| constants | [...] | [...]   |

## Structure and organization

[Where things go: folder layout, module boundaries, entry points, what belongs where. Derived from
the actual codebase layout, not from a generic template.]

## Error handling

[How errors are raised/propagated/logged in this project; where exceptions are caught; any
project-specific conventions.]

## Testing conventions

[Test framework, file naming/location, what is unit-tested vs e2e-tested, how fixtures/mocks are
set up. Must stay consistent with the binding verification requirement in `FRAMEWORK_MANUAL.md`
§1.5/§5.]

## Logging and observability

[Log levels, message format, correlation identifiers, if any.]

## Configuration and secrets

[Where configuration lives, how secrets are provided (never hardcoded), environment conventions.]

## Git / branch / commit conventions

[Branch naming, commit message format, PR/review flow, if any.]

## Anti-patterns to avoid

[Project-specific things that look tempting but are known to be wrong in this codebase.]

## Change history

- **[YYYY-MM-DD]**: [convention added/changed and why]
