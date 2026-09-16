# LIMET — Master reading index

> This document indicates the **order in which to read** the files of this framework edition,
> with the exact path to each. Use it as the first file to open when approaching LIMET for the
> first time, or as a quick reference to find a specific document.

## 1. First things first: general orientation

| # | Document | Path | Why read it first |
| - | -------- | ---- | -------------------- |
| 1 | Repository-wide index (bilingual) | `..\README.md` | Overview of the two editions (IT/EN) and a quick "I want to do X → go to Y" map |
| 2 | Index of this edition | `README.md` | List of available templates and quick install command |
| 3 | Full framework manual | `FRAMEWORK_MANUAL.md` | Full methodology: principles (§1), context categories (§2), lifecycle (§3), conventions (§4), anti-patterns (§5), adaptability (§6), naming/glossary (§7), template index (§8), practical activation (§9), Appendix A (CEREBRO/Graphify setup), Appendix B (step-by-step operational examples), Appendix C (multi-project/workspace scenarios) |
| 4 | Quick onboarding checklist | `ONBOARDING_CHECKLIST.md` | To consult at **every** session/feature start, after having read the manual once |

## 2. Technical setup (one-time per machine/project)

| # | What to do | Reference | Path |
| - | ---------- | --------- | ---- |
| 1 | Install LIMET into a project | `FRAMEWORK_MANUAL.md` §9 | `..\scripts\limet.ps1` / `..\scripts\limet.sh` |
| 2 | (Optional) Set up concrete context tools (documentation RAG, code knowledge graph) | `FRAMEWORK_MANUAL.md` Appendix A | — |
| 3 | (If working across multiple correlated projects or a multi-module monorepo) Install the workspace level | `FRAMEWORK_MANUAL.md` Appendix C | `..\scripts\limet.ps1 -Workspace` / `..\scripts\limet.sh --workspace` |

## 3. Template order during actual work

> Not every template is always used: the order below is the **typical** one for a full feature
> (large plan). For a targeted bug fix the flow is shorter — see `FRAMEWORK_MANUAL.md` Appendix
> B.3 for the full step-by-step example, B.4 for a feature.

| # | Phase | Template | Path |
| - | ----- | -------- | ---- |
| 1 | Planning (single use/small changes) | Plan | `templates\PLAN_TEMPLATE.md` |
| 1bis | Planning (larger changes, alternative to 1) | Change proposal | `templates\CHANGE_PROPOSAL_TEMPLATE.md` |
| 2 | Spec (the *what*, follows 1bis) | Spec | `templates\SPEC_TEMPLATE.md` |
| 3 | Technical design (optional, the *how*) | Design | `templates\DESIGN_TEMPLATE.md` |
| 4 | Breakdown into tasks | Task list | `templates\TASK_LIST_TEMPLATE.md` |
| 5 | Single complex task (optional, for a task requiring dedicated analysis) | Single task | `templates\TASK_TEMPLATE.md` |
| 6 | If starting from a defect instead of a feature request | Bug report | `templates\BUG_REPORT_TEMPLATE.md` |
| 7 | Test planning (before writing the code) | Test plan | `templates\TEST_PLAN_TEMPLATE.md` |
| 8 | *(code implementation — no template, writing phase)* | — | — |
| 9 | Recording the actual outcome of the tests run | Test execution | `templates\TEST_EXECUTION_TEMPLATE.md` |
| 10 | Manual end-to-end verification | E2e verification | `templates\E2E_VERIFICATION_TEMPLATE.md` |
| 11 | Communication to a non-technical audience (if relevant) | Non-technical summary | `templates\NON_TECHNICAL_SUMMARY_TEMPLATE.md` |
| 12 | Shared terminology update (if ambiguity emerged) | Glossary | `templates\GLOSSARY_TEMPLATE.md` |
| 13 | Closure and history freeze | Archive entry | `templates\ARCHIVE_ENTRY_TEMPLATE.md` |

> **Workspace-level templates** (only for multi-project scenarios, see §4bis and Appendix C):
> `templates\MODULE_MAP_TEMPLATE.md` (maps projects/modules and dependencies) and
> `templates\CROSS_PROJECT_CHANGE_TEMPLATE.md` (coordinates a cross-project change).

## 4. Paths generated in the target project (after `limet.ps1`/`limet.sh init`)

| What | Path in the target project |
| ---- | ------------------------------ |
| Local copy of the manual | `<project>\limet\FRAMEWORK_MANUAL.md` |
| Local copy of the checklist | `<project>\limet\ONBOARDING_CHECKLIST.md` |
| Local copy of the templates | `<project>\limet\templates\` |
| Work in progress (active changes) | `<project>\limet\changes\NNNN-slug\` |
| Completed and archived work | `<project>\limet\archive\NNNN-slug\` |
| Single source of agent instructions | `<project>\AGENTS.md` (marked block `<!-- LIMET:START/END -->`) |
| Import for Claude Code | `<project>\CLAUDE.md` (`@AGENTS.md` line) |

## 4bis. Paths generated at the workspace level (after `limet.ps1`/`limet.sh init -Workspace`)

> Only for multi-project scenarios: multiple correlated repositories under a common parent folder,
> or a monorepo with multiple modules. See `FRAMEWORK_MANUAL.md` Appendix C for the full guide.

| What | Path in the workspace folder (parent folder or monorepo root) |
| ---- | ----------------------------------------------------------------- |
| Local copy of the manual | `<workspace>\limet-workspace\FRAMEWORK_MANUAL.md` |
| Local copy of the checklist | `<workspace>\limet-workspace\ONBOARDING_CHECKLIST.md` |
| Project/module map and dependencies (filled in manually, never overwritten by `update`) | `<workspace>\limet-workspace\MODULE_MAP.md` |
| Coordination templates (only 2, not the full per-project set) | `<workspace>\limet-workspace\templates\` |
| Cross-project changes in progress | `<workspace>\limet-workspace\changes\NNNN-slug\` |
| Archived cross-project changes | `<workspace>\limet-workspace\archive\NNNN-slug\` |
| Single source of agent instructions at the workspace level | `<workspace>\AGENTS.md` (marked block `<!-- LIMET-WORKSPACE:START/END -->`, distinct from the per-project `LIMET` block) |
| Import for Claude Code at the workspace level | `<workspace>\CLAUDE.md` (`@AGENTS.md` line) |

## 5. Quick reference by scenario

- **New project from scratch** → `FRAMEWORK_MANUAL.md` Appendix B.2
- **Activate LIMET on an existing project** → `FRAMEWORK_MANUAL.md` Appendix B.1
- **Fix a bug** → `FRAMEWORK_MANUAL.md` Appendix B.3
- **Add a feature** → `FRAMEWORK_MANUAL.md` Appendix B.4
- **Set up a workspace with multiple correlated projects/modules** → `FRAMEWORK_MANUAL.md` Appendix C.1
- **Bug fix spanning multiple projects** → `FRAMEWORK_MANUAL.md` Appendix C.2
- **Feature spanning multiple projects** → `FRAMEWORK_MANUAL.md` Appendix C.3
- **Monorepo with multiple modules (variant)** → `FRAMEWORK_MANUAL.md` Appendix C.4
