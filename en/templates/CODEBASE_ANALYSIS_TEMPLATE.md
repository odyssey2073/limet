# Codebase analysis — advanced agent playbook

> Cross-tool guide (Claude Code and Copilot follow it the same way) to produce in-depth
> documentation from a codebase, even a multi-module, undocumented one. This is not an output
> document: it is the **procedure** to follow to generate the documents. A synthesis of the best
> code-analysis skills/prompts (C4, ADR, reverse-engineering).

## Core principles

1. **Separate discovery from prose** — discovery (what exists, what depends on what) is deterministic
   (Graphify/filesystem); prose (description, rationale) is the agent's judgment.
2. **Recover intent, don't transcribe code** — describe the *why* (purpose, decisions), not the *how*
   line by line.
3. **Facts vs hypotheses** — every claim has `file:line` evidence, or is flagged as uncertain.
4. **One bounded context at a time** — don't mix modules; name the tricky boundaries early
   (auth, background jobs, cross-repo contracts, caching).

## Phase 1 — Structural reconnaissance (deterministic discovery)

1. Query the graph: `graphify query`, `graphify path`, `graphify explain` for modules, entrypoints,
   dependencies. Use `graphify affected "<symbol>"` (reverse traversal) to see what a change would
   impact, and `graphify god-nodes` to find the most-connected nodes (architectural hubs) for the
   module map.
2. Read `graphify-out/GRAPH_REPORT.md` as the starting map.
3. List the **real** modules/packages from the filesystem (do not infer from names).
4. **Large codebases**: parallelize — build the dependency graph first, then analyze high-value
   modules; split files over 2000 lines into contiguous ranges.

## Phase 2 — Architecture (C4 model)

Use the C4 model for the right level of detail:

- **L1 System Context** — always: the system and its relations with users/external systems.
- **L2 Container** — when modifying boundaries (apps, DB, external code).
- **L3 Component** — for new or changed services.
- **L4 Code** — only for complex/critical components.

Diagrams in **Mermaid** (text, rendered everywhere). Add the main **end-to-end flows**. Validate
every Mermaid/C4 diagram renders (syntax check) before finalizing — a broken diagram is worse than
none.

## Phase 3 — Architectural decisions (ADR)

For each relevant decision create an **ADR** (Architecture Decision Record):

- Format: **Status · Context · Decision · Consequences**.
- **One decision per ADR**; list the **alternatives considered (including rejected)** and why.
- Record the accepted **trade-offs**.
- **Immutable**: supersede an ADR with a new one, don't edit it.

## Phase 4 — Conventions and glossary

- Naming, structure, patterns, error handling, testing — general and **per-module** if they diverge.
- Domain terms, technical concepts, acronyms.

## Phase 5 — Artifacts (doc suite)

Generate in `docs/`:

| Document | Content |
|---|---|
| `module-map.md` | modules, responsibilities, dependencies, build/deploy order |
| `architecture.md` | C4 L1–L3, Mermaid diagrams, cross-module flows |
| `decisions.md` | ADRs (one decision per section) |
| `dependencies.md` | dependency graph (imports, calls, external services) |
| `conventions.md` | coding conventions (general + per-module) |
| `glossary.md` | domain terms, concepts, acronyms |

For **multi-module** projects, `module-map.md` and `dependencies.md` are mandatory.

## Hard rules

1. **Cite `file:line`** for every non-obvious claim (e.g. `src/main/App.java:42`).
2. **Facts vs hypotheses**: if you don't see it in the code/graph, write it as uncertain
   (`[unverified]`, `[to confirm]`), don't invent it.
3. **Business context / design rationale are NOT derivable from code**: if missing, mark
   `[ask the team]` instead of inventing them.
4. **Incremental**: if a document exists, **UPDATE** it (only the changed parts), don't rewrite it.
5. **Mermaid** for flow/dependency diagrams.
6. **Detect drift**: if specs/docs exist, flag code↔doc divergences (Gap, Stale, Uncovered, Orphaned).
7. **Verifiable requirements**: use RFC 2119 (SHALL/MUST/SHOULD/MAY) and Given/When/Then.
8. **Chunk per module/function**: don't flood the analysis with huge files (risk of omissions/hallucinations).
9. **Search CEREBRO/Qdrant first**: if the document is not indexed yet, read it locally from `docs/` (fallback).
