# Architecture overview — [Project name]

> Human/agent-written complement to the automatically generated `architecture/GRAPH_REPORT.md`
> (produced by Graphify via `graphify .`). The report holds the machine-readable/visual graph of
> symbols, modules and calls; this document adds the *why*: the decisions, boundaries and
> invariants that a static analysis cannot infer. Both are indexed into the project's CEREBRO
> collection. Keep the two consistent — if the code changes, re-run `limet-index update`.

## High-level picture

[One paragraph + a bulleted map of the main modules/components and their responsibilities. Link to
`architecture/GRAPH_REPORT.md` for the full graph.]

## Key components and responsibilities

| Component | Responsibility | Key files / entry points |
| --------- | -------------- | ------------------------- |
| [...]     | [...]          | [...]                     |

## Main flows and data paths

[End-to-end flows: what happens on the important actions, in order. Refer to the graph for
call/type-level detail.]

## Architectural decisions (ADR-style)

| Decision | Alternatives considered | Rationale | Consequences |
| -------- | ------------------------ | --------- | ------------ |
| [...]    | [...]                    | [...]     | [...]        |

## Boundaries and invariants

[What must never be violated: layering rules, dependency direction, single-writer constraints,
transaction boundaries.]

## External dependencies and integrations

| Dependency | Purpose | Interface |
| ---------- | ------- | --------- |
| [...]      | [...]   | [...]     |

## Known debt / risks

[Areas that deviate from the ideal structure, with why and what to do about them.]

## Change history

- **[YYYY-MM-DD]**: [architectural change and why]
