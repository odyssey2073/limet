# LIMET

**L**ightweight **I**terative **M**ethod for **E**ngineering with **T**raceability — a
spec-driven framework for working effectively with AI coding agents (Copilot CLI, Claude Code,
and similar tools) on bug fixing and new feature development.

LIMET is **tool-agnostic**: it does not assume any specific product for documentation retrieval,
code knowledge graphs, or database access. Each language edition includes an optional appendix
with a concrete, ready-to-use setup for one possible toolchain.

## Two parallel editions

This repository ships the **same framework** in two independent, fully self-contained document
trees — pick the one you need, or use both:

- **[`it/`](it/README.md)** — versione italiana completa (manuale, template, checklist, indice
  master di lettura in [`it/MASTER_INDEX.md`](it/MASTER_INDEX.md)).
- **[`en/`](en/README.md)** — full English edition (manual, templates, checklist, master reading
  index in [`en/MASTER_INDEX.md`](en/MASTER_INDEX.md)).

The two trees are kept conceptually aligned (same lifecycle, same templates, same mandatory
testing principle) but are maintained as separate documents, not machine-translated mirrors —
each can evolve independently as long as the core methodology stays consistent.

## Quick orientation

| I want to... | Go to |
| --- | --- |
| Know exactly what to read, in order | `it/MASTER_INDEX.md` or `en/MASTER_INDEX.md` |
| Understand the full methodology | `it/FRAMEWORK_MANUAL.md` or `en/FRAMEWORK_MANUAL.md` |
| Start a new session/feature quickly | `it/ONBOARDING_CHECKLIST.md` or `en/ONBOARDING_CHECKLIST.md` |
| Get a blank document to fill in | `it/templates/` or `en/templates/` |
| Activate LIMET in a project (AGENTS.md + CLAUDE.md) | `scripts/limet.ps1` / `scripts/limet.sh` (see manual §9) |
| Work across multiple correlated projects or a multi-module monorepo | `scripts/limet.ps1 -Workspace` / `scripts/limet.sh --workspace` (see manual Appendix C) |

## Origins

LIMET generalizes recurring patterns observed across real agent-assisted engineering sessions
(planning documents, granular task tracking, bug reports, test plans/execution logs, non-technical
summaries) and incorporates ideas from the spec-driven change-proposal workflow popularized by
tools such as OpenSpec (proposal → spec → design → tasks → archive), adapted here to be
tool-agnostic and to make test coverage (unit + e2e) a non-negotiable part of every task.

