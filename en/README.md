# LIMET — English edition

> **Where to start**: see [`MASTER_INDEX.md`](MASTER_INDEX.md) for the recommended reading order
> of every document in this folder, with exact paths.

Index of the English edition of the LIMET framework (*Lightweight Iterative Method for
Engineering with Traceability*).

- **[`FRAMEWORK_MANUAL.md`](FRAMEWORK_MANUAL.md)** — the full manual: principles, context
  categories, phased lifecycle, conventions, binding test requirement, anti-patterns,
  adaptability, optional setup appendix (CEREBRO/Qdrant/Ollama/Graphify).
- **[`ONBOARDING_CHECKLIST.md`](ONBOARDING_CHECKLIST.md)** — quick checklist to follow at the
  start of a session/feature.
- **[`templates/`](templates/)** — the skeleton documents: 13 lifecycle templates (one per
  phase/artifact, §8) plus 2 codebase-documentation templates (see §A.4).
- **[`guides/workflow.html`](guides/workflow.html)** — interactive step-by-step guide (SPA) with 9 test cases.
- **[`guides/install.html`](guides/install.html)** — component installation guide.

## Available templates

| File | Purpose |
| --- | --- |
| `templates/PLAN_TEMPLATE.md` | Plan for a non-trivial feature/bug fix |
| `templates/CHANGE_PROPOSAL_TEMPLATE.md` | More structured change proposal (the why) |
| `templates/SPEC_TEMPLATE.md` | Verifiable specification of a capability (the what) |
| `templates/DESIGN_TEMPLATE.md` | Optional technical design (the how) |
| `templates/TASK_LIST_TEMPLATE.md` | Trackable granular task list |
| `templates/TASK_TEMPLATE.md` | Sheet for a complex task |
| `templates/BUG_REPORT_TEMPLATE.md` | Defect report |
| `templates/TEST_PLAN_TEMPLATE.md` | Unit test planning |
| `templates/TEST_EXECUTION_TEMPLATE.md` | Recording the actual test outcome |
| `templates/E2E_VERIFICATION_TEMPLATE.md` | Manual e2e verification checklist |
| `templates/NON_TECHNICAL_SUMMARY_TEMPLATE.md` | Summary for a non-technical audience |
| `templates/GLOSSARY_TEMPLATE.md` | Shared domain glossary |
| `templates/ARCHIVE_ENTRY_TEMPLATE.md` | Archive record for a completed change |

**Workspace-level templates** (multi-project/multi-module scenarios — see Appendix C of the
manual):

| Template | Typical use |
| --- | --- |
| `templates/MODULE_MAP_TEMPLATE.md` | Map of a workspace's projects/modules and their dependencies |
| `templates/CROSS_PROJECT_CHANGE_TEMPLATE.md` | Coordinating a change that spans multiple projects/modules |

**Codebase documentation templates** (used by `limet-index` to scaffold `docs/`, see the manual
§A.4):

| Template | Typical use |
| --- | --- |
| `templates/ARCHITECTURE_TEMPLATE.md` | Human/agent-written architecture overview, complementing the Graphify report |
| `templates/CONVENTIONS_TEMPLATE.md` | Coding conventions distilled from the codebase |

See also the Italian edition in [`../it/`](../it/README.md).

## Automatic installation into a project

To activate LIMET in a project (creating `limet/`, the instructions block in `AGENTS.md`, the
import in `CLAUDE.md`), use the scripts in [`../scripts/`](../scripts/) — see `FRAMEWORK_MANUAL.md`
§9 for details:

```powershell
..\scripts\limet.ps1 init -ProjectPath C:\path\to\project -Lang en
```

For scenarios with multiple correlated projects or a multi-module monorepo, additionally use the
`-Workspace` flag (`--workspace` in bash) on the parent/root folder — see Appendix C of the manual:

```powershell
..\scripts\limet.ps1 init -ProjectPath C:\path\to\workspace -Lang en -Workspace
```

```bash
../scripts/limet.sh init --project-path /path/to/project --lang en
```
