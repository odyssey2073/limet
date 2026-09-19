# LIMET — Framework Manual

> **LIMET** (*Lightweight Iterative Method for Engineering with Traceability*) is a spec-driven
> working method for advanced use of AI command-line agents (Copilot CLI, Claude Code, or
> equivalent tools) on bug fixing and new feature development. It is **tool-agnostic**: it does
> not assume any specific product for documentation retrieval, static code analysis, or data
> access — see §2 for the generic categories and Appendix A for an optional concrete setup.

---

## 1. General principles

### 1.1 Spec-driven, not vibe-driven

Before making a non-trivial code change, write a document describing **what** you want to
achieve, **why**, and **how** (at design level) — do not proceed by trial and error relying only
on the conversation's implicit context. The document is the shared source of truth between user
and agent.

### 1.2 Traceability of decisions

Every ambiguous choice encountered during the work must be made explicit as a **contextual
question**, with the answer obtained and the date — never assumed silently. If you must proceed
anyway (no answer available in time), the assumption must be explicitly stated together with the
risk it carries.

### 1.3 Separation between writing and executing

The agent proposes/writes changes and commands; the execution of build/test/deploy can remain
under the user's or pipeline's control, with logs pasted back for later debugging. Never run
commands with persistent effects (commit, push, migrations, deploy) without explicit
authorization.

### 1.4 Retroactive documentation updates

After implementation, plan/task documents are updated with a dated "Implementation outcome"
section describing what was actually done (including any deviation from the plan) — the history
is not rewritten, it is completed.

### 1.5 No task is considered closed without a verification strategy (binding)

> This is a **non-negotiable** principle of the framework: every task, unless already covered by
> existing tests, **must** include dedicated unit tests **and** a thorough end-to-end test plan
> with step-by-step execution instructions (even if manual). A task can only be marked `done` if
> this section is filled in — even "not applicable" must be explicitly justified, not simply
> omitted. Full details in §5.

---

## 2. "Context provider" categories (generic)

An agent works better when it can draw on context sources beyond the conversation alone. Three
generic categories are distinguished, each implementable with different tools:

### 2.1 Documentary context (semantic RAG)

A system that indexes project documentation (specifications, architectural notes, past
decisions) in a semantically queryable form, to retrieve the most relevant fragments for a
natural-language question. Useful for: "why was it done this way", "what does the spec say
about X", "what is the project convention for Y".

### 2.2 Structural code context (static knowledge graph)

A tool that statically analyzes source code and builds a graph of relationships between
symbols/modules/calls, queryable in natural language or by path between two nodes. Useful for:
"where is X implemented", "what depends on Y", "what is the impact of changing Z" — at minimal
computational cost (no external model call needed for the analysis itself).

### 2.3 Access to real data (read-only)

A read-only access channel to the system's real data (application database, logs, observability
APIs), used to verify hypotheses about the actual system state instead of assuming it from code
alone. It must always be kept strictly **read-only** in non-destructive work contexts.

### 2.4 Combination criterion

1. Question about "where/how is it implemented in code" → structural context (2.2) first,
   near-zero cost.
2. Question about "why/what is the spec" → documentary context (2.1).
3. For cross-module analysis or understanding an end-to-end flow: use 2.2 first, then 2.1, cross
   the results before writing a plan.
4. To verify a hypothesis about the real system state → 2.3, always read-only.
5. Do not repeat a search if relevant context was already retrieved in a previous turn of the
   same session (avoid wasting time/tokens).
6. If no advanced tool is available, see §7 (adaptability/controlled degradation).

---

## 3. Lifecycle of a change (feature or bug fix)

LIMET adopts a fluid-phase lifecycle (not rigid: you can go back to a previous phase if new
information emerges), inspired by the spec-driven *change proposal* workflows popularized by
tools such as OpenSpec, but made tool-agnostic and with an explicit verification phase added.

| Phase | Purpose | Reference template |
| --- | --- | --- |
| 0. Exploration (optional) | Gather context, clarify the problem before formalizing | — (free use of §2 context providers) |
| 1. Proposal | Describe why, what changes, how (at a high level) | `PLAN_TEMPLATE.md` + (for more structured changes) `CHANGE_PROPOSAL_TEMPLATE.md`, `SPEC_TEMPLATE.md`, `DESIGN_TEMPLATE.md` |
| 2. Review | Validate the proposal with the user before writing code | contextual questions resolved (§1.2), plan approved |
| 3. Task breakdown | Translate the proposal into granular, trackable activities | `TASK_LIST_TEMPLATE.md`, `TASK_TEMPLATE.md` for complex tasks |
| 4. Apply | Implement following the tasks, updating their status | — (no dedicated template, update the task list) |
| 5. Verification (mandatory) | Unit tests + e2e tests as planned in phase 1/3 | `TEST_PLAN_TEMPLATE.md`, `TEST_EXECUTION_TEMPLATE.md`, `E2E_VERIFICATION_TEMPLATE.md` |
| 6. Communication | Summarize the outcome for a non-technical audience, if relevant | `NON_TECHNICAL_SUMMARY_TEMPLATE.md` |
| 7. Archive | Freeze the change's history, update permanent documentation | `ARCHIVE_ENTRY_TEMPLATE.md`, retroactive update (§1.4) |

### 3.1 When to use the full "change proposal" variant (extended phase 1)

For small/isolated changes, `PLAN_TEMPLATE.md` alone is sufficient. For larger changes (a new
capability, a change to a contract/interface between components, impact on multiple modules), it
is worth splitting phase 1 into three separate documents, each with a precise responsibility:

- **`CHANGE_PROPOSAL_TEMPLATE.md`** — the *why*: motivation, new/modified/removed capabilities,
  expected impact. Conceptually analogous to a "proposal" document in spec-driven workflows.
- **`SPEC_TEMPLATE.md`** — the *what*: requirements in verifiable form (given/when/then
  scenarios), one per capability touched. This is the "specification" tests will align to.
- **`DESIGN_TEMPLATE.md`** (optional) — the *how*: technical design decisions, discarded
  alternatives, when the "how" is not obvious from the spec alone.

This separation makes explicit that a specification can remain stable even if the technical
design changes, and vice versa — useful for significant changes or when multiple people (or
different agent sessions) collaborate on the same proposal over time.

### 3.2 Archive phase

Once a change is complete and verified, the work should be "frozen": the decision history should
not be lost, but also not left mixed in with active work. Use `ARCHIVE_ENTRY_TEMPLATE.md` to
record, in a single dated entry, the reference to the original proposal/plan, the final outcome,
and the permanent documents that were updated as a result (e.g. glossary, current specs). This
prevents the project's "living" documentation from accumulating indefinitely with work that is
already finished, while still preserving traceability.

---

## 4. Naming and status conventions

- **Document status**: `DRAFT` → `APPROVED` → `IN PROGRESS` → `COMPLETED` (or `ABANDONED`).
- **Task status**: `pending` → `in_progress` → `done` (or `blocked`, with an explicit reason).
- **Dates**: always in `YYYY-MM-DD` format, attached to every significant decision/update.
- **Date and time when moving to `done`**: when a task moves to `done`, record **date and time**
  in `YYYY-MM-DD HH:MM` format (not just the date), both in the task table
  (`TASK_LIST_TEMPLATE.md`) and in the "Outcome" section of `TASK_TEMPLATE.md`. This ensures a
  precise chronological ordering when multiple tasks/subtasks are completed on the same day
  (e.g. to understand in what order they were verified, or which change made another one
  obsolete). For other statuses/documents a date alone remains sufficient, unless you are
  already working with multiple updates on the same day, in which case the same rule applies.
- **Retroactive updates**: add a dated section ("Implementation outcome (YYYY-MM-DD)"), do not
  silently edit the original plan text.
- **File names**: use the template names as provided (in English) as a base; for concrete
  instances, add a descriptive identifier (e.g. `PLAN_TEMPLATE.md` → `PLAN_<slug>.md`).

---

## 5. Binding requirement: unit tests + e2e tests for every task

> See also §1.5. This section describes **how** to satisfy the requirement, not whether to apply
> it: it always applies, unless explicitly justified as an exception (§5.3).

### 5.1 Unit tests

For every task that introduces or modifies behavior (not just comments/documentation):
- check whether tests already cover the touched area; if so, extend them instead of duplicating;
- if none exist, write new ones targeted at the modified behavior (not just "make the build
  pass" — they must fail if the bug/defect returns);
- document the planned cases in `TEST_PLAN_TEMPLATE.md` before or during implementation, and the
  actual outcome in `TEST_EXECUTION_TEMPLATE.md` after execution (which can be performed by the
  user, not necessarily by the agent — see §1.3).

### 5.2 Thorough e2e tests

Required when unit tests alone do not provide enough confidence (external integrations, side
effects on real systems, behavior dependent on configuration/environment, user interfaces,
timing/concurrency). The e2e verification document (`E2E_VERIFICATION_TEMPLATE.md`) must always
include:
- **Preconditions** (environment, required test data, starting state);
- **Numbered steps** executable by a human with no prior knowledge of the task;
- **Expected result for each step** (not just at the end — this allows pinpointing where
  something deviates);
- **How to verify the outcome** objectively (check queries, expected logs, expected response) —
  avoid "verify that it works" without measurable criteria;
- **Rollback/cleanup** if the test leaves residual state in the system.

It does not need to be automated: it can be a manual checklist, as long as it is detailed enough
to be repeatable by anyone, not just by whoever wrote it.

### 5.3 When omission is acceptable

Only for purely non-behavioral changes (e.g. comments, reformatting with no functional effect,
renaming internal variables without contract changes) — and this must still be explicitly stated
in the task document, not left implicit.

---

## 6. Anti-patterns to avoid

- **Assuming instead of asking**: proceeding on an ambiguity without recording it as a contextual
  question (§1.2).
- **Running operations with persistent effects without permission**: commits, pushes, migrations,
  destructive commands not explicitly requested.
- **Documentation diverging from the real code**: plans/tasks not updated after the actual
  implementation deviated from what was planned.
- **Task marked `done` without verification**: writing code does not equal a completed task; the
  verification strategy of §5 must be completed (or explicitly justified as not applicable).
- **Accumulation of "living" documentation never archived**: plans finished months ago that
  remain mixed in with active work, instead of being frozen with `ARCHIVE_ENTRY_TEMPLATE.md`.
- **Exclusively intuition-driven (vibe-driven) work on non-trivial changes**: skipping the
  proposal/spec phase for changes that would deserve a written plan.

---

## 7. Adaptability: working without advanced tools (controlled degradation)

The framework remains valid even without semantic documentary context or a code knowledge graph:
- documentary context (2.1) is replaced by manual text/full-text search in existing
  documentation;
- structural context (2.2) is replaced by manual text search in the code (grep/symbol search)
  and manual exploration of references;
- access to real data (2.3) remains valid only if a read-only channel exists at all (even a
  simple manual query is fine, as long as it is read-only).

What **never** changes, regardless of the available tools, is the traceability principle (§1.2)
and the verification requirement (§1.5/§5): these are methodological principles, not tied to any
specific tool.

---

## 8. Index of available templates

| Template | When to use it |
| --- | --- |
| `templates/PLAN_TEMPLATE.md` | Before starting a non-trivial feature/bug fix (single use, small/medium changes) |
| `templates/CHANGE_PROPOSAL_TEMPLATE.md` | For larger changes: the *why* and the expected impact |
| `templates/SPEC_TEMPLATE.md` | The *what*: verifiable requirements for a touched capability |
| `templates/DESIGN_TEMPLATE.md` | The *how* (optional): technical decisions not obvious from the spec alone |
| `templates/TASK_LIST_TEMPLATE.md` | To break down the plan/proposal into trackable tasks |
| `templates/TASK_TEMPLATE.md` | For a complex task requiring explicit analysis/questions |
| `templates/BUG_REPORT_TEMPLATE.md` | When isolating a defect to fix |
| `templates/TEST_PLAN_TEMPLATE.md` | To plan the unit tests (and e2e criteria) of a task |
| `templates/TEST_EXECUTION_TEMPLATE.md` | To record the actual outcome of a test run |
| `templates/E2E_VERIFICATION_TEMPLATE.md` | For a manual end-to-end verification checklist |
| `templates/NON_TECHNICAL_SUMMARY_TEMPLATE.md` | To communicate the outcome to a non-technical audience |
| `templates/GLOSSARY_TEMPLATE.md` | To fix shared domain terminology/concepts |
| `templates/ARCHIVE_ENTRY_TEMPLATE.md` | To freeze the history of a completed change |

**Workspace-level templates** (for multi-project/multi-module scenarios, see Appendix C —
installed under `limet-workspace/templates/`, not under the single project's `limet/templates/`):

| Template | When to use it |
| --- | --- |
| `templates/MODULE_MAP_TEMPLATE.md` | To map the projects/modules of a workspace, their roles, and the dependencies/contracts between them |
| `templates/CROSS_PROJECT_CHANGE_TEMPLATE.md` | To coordinate a change (feature or bug fix) that spans multiple projects/modules |

**Codebase documentation templates** (scaffolded into `docs/_templates/` by `limet-index`, see
§A.4 — they document the codebase itself, not a single change):

| Template | When to use it |
| --- | --- |
| `templates/ARCHITECTURE_TEMPLATE.md` | To write the architecture overview that complements the Graphify report |
| `templates/CONVENTIONS_TEMPLATE.md` | To distill the project's coding conventions from the codebase |

See also `ONBOARDING_CHECKLIST.md` for a quick operational checklist to follow at the start of a
session, and `scripts/limet.ps1` / `scripts/limet.sh` for automatic installation (§9).

For concrete setup of supporting tools (documentation RAG, code knowledge graph) see
**Appendix A**; for complete step-by-step operational examples (project setup, new project, bug
fix, new feature) see **Appendix B**; for multi-project/multi-module (workspace) scenarios see
**Appendix C**. For the recommended reading order of the whole LIMET folder, see
`MASTER_INDEX.md`.

---

## 9. Practical activation: getting Copilot CLI / Claude Code to actually follow LIMET

Having these documents written is not enough: the agent must be **instructed to consult and
apply them** in every session, not only when explicitly asked. LIMET uses **a single,
cross-tool activation mechanism**, not a different solution per tool — because skill/plugin
conventions differ from tool to tool, and maintaining N custom variants would be fragile and
prone to drifting out of sync.

### 9.1 The mechanism: `AGENTS.md` as the single source + import in `CLAUDE.md`

- **`AGENTS.md`** at the project root is the single source of truth. It is the open "agents.md"
  standard, read natively by Copilot CLI and by most modern agentic CLI tools that support it.
- **Claude Code** reads `CLAUDE.md` by default, not `AGENTS.md`. The officially documented way to
  make it also load `AGENTS.md` is a single `@AGENTS.md` import line at the top of `CLAUDE.md` —
  a native Claude Code feature (file import), not a LIMET-specific workaround.
- Result: **one piece of content, written once** (the LIMET block in `AGENTS.md`), read by both
  tools. No duplicated content, no per-tool logic to maintain.

### 9.2 Installation via script

The `scripts/limet.ps1` (PowerShell) and `scripts/limet.sh` (Bash, also runnable from WSL/Linux/
macOS) scripts automate activation, following the `init`/`update` pattern of similar tools:

```powershell
# PowerShell
.\scripts\limet.ps1 init -ProjectPath C:\path\to\project -Lang en
.\scripts\limet.ps1 update -ProjectPath C:\path\to\project -Lang en
```

```bash
# Bash
./scripts/limet.sh init --project-path /path/to/project --lang en
./scripts/limet.sh update --project-path /path/to/project --lang en
```

What `init` does:

1. Copies the manual, the onboarding checklist, and the templates (IT or EN edition) into
   `<project>/limet/`, along with `limet/changes/` (work in progress) and `limet/archive/`
   (completed work).
2. Writes/refreshes a marked block (`<!-- LIMET:START -->` / `<!-- LIMET:END -->`) in `AGENTS.md`
   at the project root, with the binding principles and template references.
3. Creates `CLAUDE.md` with the `@AGENTS.md` line (if the file does not exist), or prepends it if
   missing (without touching the rest of the existing content).

`update` repeats the same steps **idempotently**: it regenerates the `limet/` content from the
source edition and replaces the marked block in `AGENTS.md` in place, without duplicating it; if
`CLAUDE.md` already contains the import, it is left untouched.

### 9.3 Verification after installation

- At the start of a session, explicitly ask the agent to confirm it knows the location of the
  manual and templates (do not assume it has read them just because the block is present).
- Re-run `init`/`update` on a scratch folder to check that blocks are not duplicated
  (`grep -c 'LIMET:START' AGENTS.md` must return `1`).

### 9.4 What is NOT enough

- Just saving the documents under `limet/` without referencing them from `AGENTS.md`/`CLAUDE.md`:
  an agent does not "discover" on its own a framework not mentioned in its session instructions.
- Mentioning the framework once in a chat message: without a persistent block in the instruction
  files, the indication is lost in the next session.
- Assuming the agent applies §1.5/§5 (mandatory tests) "because it's written in the manual": it
  is explicitly called out in the block generated by the script, because it is the rule most
  easily forgotten under delivery pressure.
- Creating different solutions per tool (separate skills, parallel instruction folders): this
  goes against this section's "single source" principle.

---

## Appendix A — Reference setup with concrete tools (optional)

> The body of the manual (§1-8) is deliberately agnostic of specific products, because the
> categories in §2 can be implemented with different tools. This appendix documents a **concrete
> reference setup**, actually usable, for those who want to start right away without having to
> choose/evaluate alternatives. It maps to the categories in §2 as follows:
> - §2.1 (documentary/RAG context) → **CEREBRO** + **Qdrant** + **Ollama**
> - §2.2 (structural code context) → **Graphify**
> - §2.3 (real data access) → left to each project's choice (e.g. a read-only MCP connector to
>   the application database), not covered here because it is too specific to each project's
>   infrastructure.

### A.1 CEREBRO (local, multi-project documentary RAG)

Repository: <https://github.com/odyssey2073/cerebro>

**What it is**: a local, multi-project RAG system. It indexes a project's documentation (`.md`,
`.txt`, `.pdf`, `.docx`, `.xlsx`, `.pptx`, `.html`) into a vector database, and automatically
generates the instruction blocks (`CLAUDE.md` / `copilot-instructions.md`) that teach the agent
how to query it. Each project has an isolated collection (`CRB_<slug>`) — no cross-contamination
between projects. It runs **100% locally**: no cloud calls, no API keys, documents never leave
the machine.

**Prerequisites**: Python 3.10+, Docker Desktop (for Qdrant), Ollama (for embeddings).

**One-time setup**:

```powershell
# 1. Qdrant (vector database) — requires Docker Desktop running
docker pull qdrant/qdrant
docker run -d --name qdrant -p 6333:6333 -p 6334:6334 -v qdrant_storage:/qdrant/storage qdrant/qdrant
curl http://localhost:6333/collections   # check: JSON response with an (initially empty) collection list

# 2. Ollama + embedding model
#    install Ollama from https://ollama.com, then:
ollama pull nomic-embed-text
curl http://localhost:11434   # check: "Ollama is running"

# 3. Clone the CEREBRO repo + virtualenv
git clone https://github.com/odyssey2073/cerebro.git
cd cerebro
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
# default .env is already correct for a standard local install
# (QDRANT_URL=http://localhost:6333, OLLAMA_URL=http://localhost:11434, EMBEDDING_MODEL=nomic-embed-text)
```

**Setting up a new project** (example with project `myapp` in `C:\Projects\myapp`):

```powershell
# 1. Register the project (where the docs are, where the root is)
python scripts\register_project.py add myapp --docs "C:\Projects\myapp\docs" --root "C:\Projects\myapp"

# 2. Index the documents (creates the CRB_myapp collection)
python scripts\ingest_docs.py --project myapp

# 3. Generate the agent instructions (CLAUDE.md and/or copilot-instructions.md)
python scripts\register_project.py instructions myapp --tool both

# 4. Verify
python scripts\query_qdrant.py --project myapp count
python scripts\query_qdrant.py --project myapp search "architecture" --limit 3
```

**Maintenance**:
- Docs changed → re-run `ingest_docs.py` (incremental per file, no duplicates).
- New docs folder → `register_project.py add` with the updated list, then ingest.
- Document deleted → `remove_doc.py --project myapp --source "<relative path>"`.
- Retiring a project → `register_project.py remove myapp` (the Qdrant collection stays, delete it
  separately if needed: `curl -X DELETE http://localhost:6333/collections/CRB_myapp`).

**Manual query**: `python scripts\query_qdrant.py --project myapp search "<question>" --limit 5`

**Web launcher (recommended)**: CEREBRO ships a local web SPA
(`python scripts\cerebro-launcher.py`) that manages new project, re-index, status, removal and
query from the browser — a single interface for both Claude Code and GitHub Copilot. See
`INSTALL.md` in the CEREBRO repo for how to launch and use it.

**MCP server (transparent RAG)**: `scripts\limet_mcp.py` in CEREBRO exposes a single tool
`limet_search` (embed query via Ollama → search Qdrant) so Claude Code and Copilot CLI query the
docs without typing the manual command. Register once per tool:

- Claude Code: `.mcp.json` in the project, or `claude mcp add limet -- python <path-to-limet_mcp.py>`.
- Copilot CLI: `copilot mcp add limet -- python <path-to-limet_mcp.py>`, or `.github/mcp.json` in
  the project.

Claude Code can additionally auto-inject RAG on every prompt with a `UserPromptSubmit` hook
(`scripts\limet_rag.py`, configured in `.claude/settings.json`). Copilot CLI has no equivalent
hook: it relies on the `limet_search` tool + the instruction in `AGENTS.md`.

**Quick troubleshooting**:

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `Connection refused :6333` | Qdrant not running | `docker start qdrant` |
| `Connection refused :11434` | Ollama not running | `ollama serve` |
| `Collection doesn't exist` | never ingested | run step 2 of the project setup |
| Stale results | docs changed, not re-indexed | re-run `ingest_docs.py` |

### A.2 Graphify (static code knowledge graph)

**What it is**: a tool that statically analyzes (AST) a project's source code and builds a
knowledge graph of relationships between symbols/modules/calls, queryable in natural language.
Complementary to CEREBRO: CEREBRO covers documentation, Graphify covers the actual code structure
(useful to check that documentation is not out of sync).

**Installation (CLI)**:

```powershell
# recommended option (via uv, https://github.com/astral-sh/uv)
uv tool install graphifyy

# alternatives
pipx install graphifyy
pip install graphifyy
```

**Registering the skill for the AI assistant in use** (one-time, at user or project level):

```powershell
graphify install                # auto-detects the assistant in use
graphify install --project      # or, for the current project only
```

**Generating the graph** (run in the root of the project/codebase to analyze):

```powershell
graphify .
```

Generates in the `graphify-out/` folder:
- `graph.json` — machine-readable graph representation;
- `graph.html` — interactive visualization, browsable in the browser;
- `GRAPH_REPORT.md` — natural-language architectural report, useful for a high-level review
  without exploring the interactive graph.

**Querying the graph**:

```powershell
graphify query "what connects ClassA to ClassB?"
graphify explain "ClassName"
graphify path "ClassA" "ClassB"
```

**Updating after code changes** (AST analysis only, no external model calls, negligible cost):

```powershell
graphify update .
```

**Note on scope**: if the project also has a documentation folder indexed by CEREBRO (e.g.
`docs/`), it is good practice to exclude it from Graphify's analysis via a `.graphifyignore` file
in the project root, to keep responsibilities separated (Graphify = code only, CEREBRO =
documentation only) and avoid duplicating information between the two sources.

### A.3 Practical combination CEREBRO + Graphify (operational summary)

Consistent with the general criterion in §2.4:

1. Question about "where is X implemented/how does it work in code" → `graphify query`/`graphify
   explain`/`graphify path` first (near-zero cost, no external model call).
2. Question about "why was it done this way"/"what does the spec say" → CEREBRO query
   (`query_qdrant.py search`) on indexed documentation.
3. For cross-module analysis or understanding an end-to-end flow: run 1 first, then 2, cross the
   results before writing a plan or proposing a solution.
4. Do not repeat a CEREBRO search if relevant context was already retrieved in a previous turn of
   the same session (avoid wasting time/tokens).

### A.4 Keeping the indexes current (write-side): `limet-index`

A.1-A.3 cover setup and *retrieval* (query the index/graph). They do not tell you **when to
rebuild** them. That is the role of the transversal script `scripts/limet-index.ps1` (and
`limet-index.sh`), installed into every project's `limet/scripts/` by `limet init`.

`limet-index` bridges the three tools on the **write** side:

| Command | Effect |
| --- | --- |
| `limet/scripts/limet-index.ps1 init -ProjectPath .` | creates `docs/` + codebase-doc templates, runs `graphify .` (architectural report → `docs/architecture/GRAPH_REPORT.md`), registers the project in CEREBRO (`CRB_<slug>`), ingests the docs, and writes the `<!-- LIMET-CONTEXT:START/END -->` block into `AGENTS.md` |
| `limet/scripts/limet-index.ps1 update -ProjectPath .` | re-runs `graphify update .` and re-ingests (deterministic upsert, no duplicates) |
| `limet/scripts/limet-index.ps1 status -ProjectPath .` | prints registered projects and this project's chunk count |
| `limet/scripts/limet-index.ps1 remove -ProjectPath .` | unregisters from CEREBRO (the Qdrant collection is left intact; the DELETE command is printed for a deliberate, double-confirmed removal) |

**What gets indexed** (the project's `CRB_<slug>` collection):
- `docs/` — the generated codebase documentation: `architecture/GRAPH_REPORT.md` (auto, Graphify)
  plus the agent-written `architecture/ARCHITECTURE.md`, `conventions.md`, `module-map.md`,
  `glossary.md` (from the templates in `docs/_templates/`).
- `limet/changes/` and `limet/archive/` — the LIMET documents produced over the lifecycle (§3).

Indexing is **recursive**: every subfolder of the registered folders is ingested, so
`docs/features/` or `docs/bugfixes/` are indexed exactly like `docs/` root. Only two paths are
skipped: `docs/_templates/` (template scaffolding) and `.obsidian/` (editor state).

**Adding documents via launcher**: the web UI `scripts/limet-launcher.py` offers a
"Documentazione → Aggiungi documenti" action that copies the selected files into `docs/`
(optionally into the subfolder chosen in "Sotto-cartella": `features`, `bugfixes`, or none) and
then runs `limet-index update` — so the files are written to disk **and** indexed into Qdrant
(`graphify update` re-runs too).

**Workspace / multi-project**: running `limet-index init -Workspace` on the parent folder creates a
`CRB_<ws>` collection for `limet-workspace/changes/`, `limet-workspace/archive/` and
`MODULE_MAP.md`. Each project under the workspace auto-detects it and registers `CRB_<ws>` as an
extra collection, so `query_qdrant.py --project <slug>` searches both. See Appendix C.

**Cross-tool**: `limet-index` is a plain CLI with no per-tool files; the query/maintenance commands
are written once in the `AGENTS.md` block, read by Copilot natively and by Claude Code via the
`@AGENTS.md` import (§9).

**Lifecycle hook**: after archiving a change (phase 7 / `ARCHIVE_ENTRY_TEMPLATE.md`), run
`limet-index update` so the archived documents become searchable context. This is the write-side
counterpart of the read-side routing in §2.4 / A.3, and it degrades gracefully (§7): without
CEREBRO/Graphify the documents remain on disk and full-text searchable.

---

## Appendix B — Operational guide: concrete step-by-step examples

> The sections below use a **fictional** example project ("TaskFlow", a generic task-management
> web app — no reference to any real project) to show, command by command and document by
> document, how LIMET is applied in four typical operational scenarios. Paths and examples can be
> adapted to any real project.

### Folder convention for work in progress

Every change (bug fix or feature) lives in a dedicated subfolder of `limet/changes/`, named
`NNNN-short-slug` (4-digit sequence number + descriptive slug), to keep chronological order and
uniqueness:

```
<project>/limet/changes/0001-change-name/
  PLAN.md               (or CHANGE_PROPOSAL.md + SPEC.md + DESIGN.md)
  TASK_LIST.md
  TEST_PLAN.md
  TEST_EXECUTION.md
  ...
```

Once the change is complete, the whole subfolder is summarized with `ARCHIVE_ENTRY_TEMPLATE.md`
and moved (or linked) into `limet/archive/0001-change-name/`.

### B.1 Setting up LIMET on an existing project

**Scenario**: the repository `C:\Projects\TaskFlow` already exists and you want to activate
LIMET.

1. From the LIMET source folder, run the install script pointing at the target project and the
   desired language edition:

   ```powershell
   cd C:\Projects\LIMET
   .\scripts\limet.ps1 init -ProjectPath C:\Projects\TaskFlow -Lang en
   ```

2. The script:
   - copies the manual, checklist, and templates into `C:\Projects\TaskFlow\limet\` (with empty
     `changes\` and `archive\`, ready to use);
   - writes the marked block into `C:\Projects\TaskFlow\AGENTS.md` (creates it if missing);
   - creates `C:\Projects\TaskFlow\CLAUDE.md` with the `@AGENTS.md` line (or prepends it if the
     file already exists without that line).

3. **Manual check**: open `C:\Projects\TaskFlow\AGENTS.md` and confirm the block is present
   between `<!-- LIMET:START -->` and `<!-- LIMET:END -->`; open `CLAUDE.md` and confirm the
   `@AGENTS.md` line is at the top.

4. **First session start**: open and follow
   `C:\Projects\TaskFlow\limet\ONBOARDING_CHECKLIST.md`.

5. **Future updates** (new LIMET version, added/changed templates): re-run the same command with
   `update` instead of `init` — it is idempotent, nothing is duplicated.

   ```powershell
   .\scripts\limet.ps1 update -ProjectPath C:\Projects\TaskFlow -Lang en
   ```

### B.2 Creating a new project with LIMET (from scratch)

**Scenario**: starting the "TaskFlow" project from zero, with LIMET active from the very first
commit.

1. Create the project folder and initialize the repository:

   ```powershell
   New-Item -ItemType Directory -Path C:\Projects\TaskFlow
   cd C:\Projects\TaskFlow
   git init
   ```

2. Install LIMET (also creates the folder if it doesn't exist yet):

   ```powershell
   C:\Projects\LIMET\scripts\limet.ps1 init -ProjectPath C:\Projects\TaskFlow -Lang en
   ```

3. Before writing the first line of code, create the first plan by copying the template:

   ```powershell
   New-Item -ItemType Directory -Path C:\Projects\TaskFlow\limet\changes\0001-initial-setup
   Copy-Item C:\Projects\TaskFlow\limet\templates\PLAN_TEMPLATE.md `
     C:\Projects\TaskFlow\limet\changes\0001-initial-setup\PLAN.md
   ```

   Fill in `PLAN.md`: scope of the first iteration (e.g. "minimal application skeleton, no domain
   features yet"), basic technical decisions, any open contextual questions.

4. Derive the task list from the plan by copying `TASK_LIST_TEMPLATE.md` into the same subfolder
   and filling it with granular tasks (e.g. "initialize repo structure", "configure build
   pipeline", "first health-check endpoint").

5. For each non-trivial task, fill in `TEST_PLAN_TEMPLATE.md` **before** implementing, then
   implement, then record the outcome in `TEST_EXECUTION_TEMPLATE.md` (see B.3 for the detail of
   the full cycle, identical also for this initial setup).

6. At the end of the iteration, archive with `ARCHIVE_ENTRY_TEMPLATE.md` as described in B.3/B.4.

### B.3 Fixing a bug on a project with LIMET (concrete example)

**Scenario**: it has been reported that in the TaskFlow app, the "Export CSV" button produces a
file that does not include the task's "status" column.

1. **Consult the onboarding checklist** (`limet/ONBOARDING_CHECKLIST.md`) at the start of the
   session.

2. **Create the change folder and the bug report**:

   ```powershell
   New-Item -ItemType Directory -Path C:\Projects\TaskFlow\limet\changes\0002-fix-export-csv-status
   Copy-Item C:\Projects\TaskFlow\limet\templates\BUG_REPORT_TEMPLATE.md `
     C:\Projects\TaskFlow\limet\changes\0002-fix-export-csv-status\BUG_REPORT.md
   ```

   Fill in `BUG_REPORT.md`: observed behavior (column missing), expected behavior (column present
   with the current value), reproduction steps, and — after investigating the code — the root
   cause (e.g. "the function that generates the CSV headers was not updated when the 'status'
   field was introduced").

3. **Task list**: for a targeted fix like this, a minimal `TASK_LIST.md` (1-2 rows) is enough —
   copy `TASK_LIST_TEMPLATE.md` into the same subfolder, with one row pointing to
   `BUG_REPORT.md`.

4. **Test plan — before writing the fix**: copy `TEST_PLAN_TEMPLATE.md` and define the regression
   unit test (must fail with the bug present): e.g. "generate a CSV export for a task with status
   'completed' and verify that the 'status' column header and value are present in the output".

5. **Implement the minimal fix** in the code, following exactly the root cause identified in step
   2 (not a cosmetic fix of the symptom).

6. **Run the tests and record the actual outcome** in `TEST_EXECUTION.md` (copied from
   `TEST_EXECUTION_TEMPLATE.md`): command run, log/excerpt, PASS/FAIL outcome.

7. **Mark the task as `done`** in `TASK_LIST.md`, with date and time (`YYYY-MM-DD HH:MM`), only
   after the test is green.

8. **Manual e2e verification**: copy `E2E_VERIFICATION_TEMPLATE.md`, fill in the steps (e.g.
   "export CSV from a real task in the test environment, open the file, check the column"), run
   them and record the outcome.

9. **Close and archive**: copy `ARCHIVE_ENTRY_TEMPLATE.md`, summarize the change, move/link the
   subfolder into `limet/archive/0002-fix-export-csv-status/`.

### B.4 Adding a new feature to a project with LIMET (concrete example)

**Scenario**: adding to TaskFlow the ability to export tasks as PDF as well (in addition to the
existing CSV export).

1. **Consult the onboarding checklist**, as always at the start of the work.

2. **Create the change folder and the proposal**:

   ```powershell
   New-Item -ItemType Directory -Path C:\Projects\TaskFlow\limet\changes\0003-export-pdf
   Copy-Item C:\Projects\TaskFlow\limet\templates\CHANGE_PROPOSAL_TEMPLATE.md `
     C:\Projects\TaskFlow\limet\changes\0003-export-pdf\CHANGE_PROPOSAL.md
   ```

   Fill in the *why* (e.g. "recurring user request to share non-editable reports") and the
   expected impact.

3. **Spec** (`SPEC.md`, from `SPEC_TEMPLATE.md`): the *what* in verifiable terms — e.g. "given a
   filtered list of tasks, the user can generate a PDF with the same columns as the CSV export,
   laid out on A4, with a header containing the date and the applied filter".

4. **Technical design** (optional, `DESIGN.md` from `DESIGN_TEMPLATE.md`): decisions not obvious
   from the spec alone — e.g. choice of PDF generation library, pagination handling for long
   lists, error handling during generation.

5. **Task list** (`TASK_LIST.md` from `TASK_LIST_TEMPLATE.md`): break down into granular tasks,
   e.g. "backend PDF generation endpoint", "'Export PDF' button in UI", "export permission
   handling", "generation test with an empty list (edge case)".

6. **For each task**: `TEST_PLAN.md` before implementing (unit tests on the generated PDF's
   content/structure, e2e tests on the UI button), implementation, then `TEST_EXECUTION.md` with
   the actual outcome, then `done` with date/time in `TASK_LIST.md`.

7. **Non-technical summary** (`NON_TECHNICAL_SUMMARY.md` from `NON_TECHNICAL_SUMMARY_TEMPLATE.md`):
   once the feature is complete, summarize for a non-technical audience what changes for the user
   (new "Export PDF" button), without implementation details.

8. **Final e2e verification** (`E2E_VERIFICATION.md`): manual end-to-end checklist on a
   test/staging environment before release.

9. **Close and archive**: `ARCHIVE_ENTRY.md`, move/link the subfolder into
   `limet/archive/0003-export-pdf/`.

## Appendix C — Multi-project scenarios: workspace with multiple correlated projects/modules

This appendix covers the case where the work does not concern a single isolated project, but:

- **two or more separate, correlated repositories**, worked on in parallel (e.g. a backend and a
  frontend in distinct repos, or a main service and a satellite service that consumes it);
- or **a single repository (monorepo) made of multiple modules**, each of which is treated as a
  standalone "project" for LIMET purposes (its own `limet/`, its own change lifecycle).

In both cases a **workspace-level coordination layer** is introduced, distinct from and superior
to each individual project's `limet/`, whose purpose is to map the relationships between
projects/modules and to coordinate changes that span across them.

Recurring example used in this appendix: the fictional "TaskFlow" project (introduced in
Appendix B) is extended with a second, correlated project, **"TaskFlow-Notifications"** (a
satellite service that sends notifications when a card changes status), which consumes a
contract (API/event) exposed by TaskFlow.

### C.0 — The "workspace" level in brief

- It is installed with the same install script (`limet.ps1` / `limet.sh`), adding the
  `-Workspace` flag (PowerShell) or `--workspace` flag (Bash), pointed at the **parent** folder
  that contains the various projects (or at the monorepo root).
- It creates a `limet-workspace/` folder (a sibling of, not nested inside, each project's own
  `limet/`) containing:
  - `MODULE_MAP.md` — the inventory of projects/modules, their roles, the dependencies/contracts
    between them, the recommended build/deploy order (from `MODULE_MAP_TEMPLATE.md`, filled in
    manually once and then kept up to date — it is **never overwritten automatically** by script
    updates, so as not to lose the work already done);
  - `templates/MODULE_MAP_TEMPLATE.md` and `templates/CROSS_PROJECT_CHANGE_TEMPLATE.md` (only
    these two, not the full set of 13 per-project templates, because at the workspace level you
    coordinate, you don't implement);
  - `changes/`, `archive/` for cross-project changes (same logic as `limet/changes/`, but at the
    workspace level);
  - a marked block `<!-- LIMET-WORKSPACE:START/END -->` in the workspace folder's `AGENTS.md`
    (distinct from the `<!-- LIMET:START/END -->` block used in individual projects), plus a
    `CLAUDE.md` with `@AGENTS.md`.
- Each project/module keeps **its own local `limet/`**, installed normally (without `-Workspace`)
  at its own root. The standard block written into every project's `AGENTS.md` already includes a
  reminder for the agent: check whether a `limet-workspace/` folder exists one level up and, if
  so, consult `MODULE_MAP.md` before changes that might affect other projects.
- It **does not replace** per-project documents (`PLAN.md`, `TASK_LIST.md`, etc.): it
  **coordinates** them. The detailed work (plan, tasks, tests) always stays in the `limet/` of the
  individual project involved.

### C.1 — Setting up a new workspace with multiple correlated projects

Case: you want to manage two already-existing, correlated repositories with LIMET,
`taskflow-backend/` and `taskflow-notifications/`, both inside a common parent folder
`taskflow-suite/`.

```
taskflow-suite/
  taskflow-backend/          (git repo 1, already existing)
  taskflow-notifications/    (git repo 2, already existing)
```

Steps:

1. Install the workspace level on the parent folder:
   ```powershell
   .\limet\scripts\limet.ps1 init -ProjectPath C:\...\taskflow-suite -Lang en -Workspace
   ```
   (or, from bash/WSL: `./limet/scripts/limet.sh init --project-path /path/taskflow-suite --lang en --workspace`)

2. Open `taskflow-suite/limet-workspace/MODULE_MAP.md` and fill it in: list the two projects, the
   role of each ("taskflow-backend: REST API + persistence", "taskflow-notifications: event
   consumer, email/push sending"), the relationship between them ("taskflow-backend publishes a
   `CardStatusChanged` event; taskflow-notifications consumes it"), and the recommended
   build/deploy order (backend first, since it exposes the contract consumed by the other one).

3. Install LIMET normally (without `-Workspace`) in each project:
   ```powershell
   .\limet\scripts\limet.ps1 init -ProjectPath C:\...\taskflow-suite\taskflow-backend -Lang en
   .\limet\scripts\limet.ps1 init -ProjectPath C:\...\taskflow-suite\taskflow-notifications -Lang en
   ```

4. Verify that each project has its own local `limet/` and `AGENTS.md`, and that the parent folder
   has `limet-workspace/` with `MODULE_MAP.md` filled in. From this point on, opening a CLI agent
   in either project will read its own local `AGENTS.md` (which reminds it to check
   `limet-workspace/` when relevant); opening the agent in the parent `taskflow-suite/` folder will
   instead read the `LIMET-WORKSPACE` block.

**Monorepo variant**: if instead of two repositories you have a single repository with multiple
modules (e.g. `taskflow-mono/backend/` and `taskflow-mono/notifications/` in the same git repo),
the procedure is identical: install `-Workspace` at the monorepo root (`taskflow-mono/`) and
install LIMET normally in each module subfolder (`taskflow-mono/backend/`,
`taskflow-mono/notifications/`). The only practical difference is that git commands (branches,
commits) concern a single shared repository, so it's worth noting in `MODULE_MAP.md` any
additional constraints per module (e.g. "modify backend and notifications in the same commit if
the contract changes, to avoid inconsistent intermediate states in the monorepo").

### C.2 — Bug fix spanning multiple projects

Case: a bug where the card in TaskFlow-backend correctly changes status, but
TaskFlow-Notifications never sends the corresponding notification. The root cause could be in
either project (or in the contract between them) — it isn't clear upfront.

1. **Open the cross-project change**: in the workspace folder, create
   `limet-workspace/changes/0001-missing-status-change-notification/`, copy
   `CROSS_PROJECT_CHANGE_TEMPLATE.md` as `CROSS_PROJECT_CHANGE.md` and fill in the initial
   section: observed symptom, potentially involved projects (both, in this case), status
   "under analysis".

2. **Analysis driven from wherever it's needed**: use the "context provider" categories (§2) to
   figure out in which of the two projects the root cause lies — e.g. check in
   taskflow-backend's knowledge graph/RAG whether the `CardStatusChanged` event is actually
   published, and in taskflow-notifications whether the consumer receives/processes it. Update
   `MODULE_MAP.md` if it turns out the documented contract no longer matches reality (e.g. event
   name changed without updating the map).

3. **Once the cause is isolated** (e.g. the event isn't published for a code branch not covered
   in taskflow-backend): open, **in the affected project**
   (`taskflow-backend/limet/changes/0007-event-not-published/`), a normal `BUG_REPORT.md` (from
   `BUG_REPORT_TEMPLATE.md`) with root cause, impact, proposed fix — exactly like a single-project
   bug fix (see B.3). If the root cause touches **both** projects (e.g. an ambiguous contract on
   both sides), open a `BUG_REPORT.md` in each of the two, linked from the cross-project document.

4. **Tasks and implementation per project**: proceed as in B.3 inside each involved project
   (`TASK_LIST.md`, `TASK.md` if needed, `TEST_PLAN.md`/`TEST_EXECUTION.md`, unit tests + e2e
   verification for every task, per the binding requirement in §5).

5. **Close the cross-project document**: in the workspace's `CROSS_PROJECT_CHANGE.md`, record
   which project actually contained the root cause (for future reference and to correct any wrong
   assumptions in `MODULE_MAP.md`), the order in which the fixes were applied (usually: contract/
   event producer first, consumer second, to avoid testing a consumer fix against a not-yet-fixed
   producer), and the results of the overall e2e verification (see C.5).

6. **Archive**: `ARCHIVE_ENTRY.md` in each involved project (as in B.3) **plus**
   `ARCHIVE_ENTRY.md` at the `limet-workspace/archive/0001-.../` level, summarizing the whole
   cross-project story and linking the detailed archives of the individual projects.

### C.3 — New feature spanning multiple projects

Case: adding a new type of notification ("card deadline reminder") which requires both a backend
change (new `deadline` field on the card, new `CardDeadlineApproaching` event) and a change to the
notification service (new consumer + new email template).

1. **Coordination document**: create
   `limet-workspace/changes/0002-card-deadline-notification/CROSS_PROJECT_CHANGE.md` from
   `CROSS_PROJECT_CHANGE_TEMPLATE.md`. Fill in: the feature's goal (in functional, not technical,
   terms), the list of involved projects with each one's role in this feature
   ("taskflow-backend: producer of the new event", "taskflow-notifications: consumer"), the
   **recommended implementation order** (here: backend first, to have the contract/event available
   before implementing the consumer), and the description of the shared contract (exact shape of
   the `CardDeadlineApproaching` event: fields, date format, delivery guarantees).

2. **For the "producer" project (taskflow-backend)**: proceed as in B.4 inside
   `taskflow-backend/limet/changes/0011-deadline-event/` — `CHANGE_PROPOSAL.md`/`SPEC.md` if the
   feature is big enough to warrant them, `DESIGN.md` if an explicit design decision is needed
   (e.g. how "approaching deadline" is computed), `TASK_LIST.md` with granular tasks,
   implementation with test plan/execution and unit tests + e2e verification for every task (§5).

3. **For the "consumer" project (taskflow-notifications)**: **only after** the contract has been
   implemented (or at least "frozen" in its final shape) in the producer, similarly open
   `taskflow-notifications/limet/changes/0004-deadline-consumer/` with the same document cycle.
   Refer to the workspace's `CROSS_PROJECT_CHANGE.md` for the exact shape of the contract, instead
   of redefining it locally.

4. **If the contract changes mid-flight** (e.g. while implementing the consumer it turns out an
   extra field is needed in the event): update **first** the workspace's `CROSS_PROJECT_CHANGE.md`
   with the new version of the contract (decision traceability, §1.4), then the producer project's
   `DESIGN.md`/`TASK_LIST.md`, then propagate to the consumer. Never change the contract silently
   in just one project.

5. **Single non-technical summary**: for a cross-project feature it's best to write **a single**
   `NON_TECHNICAL_SUMMARY.md` at the `limet-workspace/changes/0002-.../` level (not one per
   project), because the non-technical stakeholder cares about the overall functional outcome
   ("users receive a reminder before the deadline"), not about how the work is split across the
   two repositories.

6. **Cross-project e2e verification** (see C.5) and then archiving, analogous to C.2 step 6.

### C.4 — Notes on the "monorepo with multiple modules" variant

When the "projects" are actually modules of the same repository (instead of separate
repositories), everything described in C.1-C.3 still applies, with these practical differences:

- The workspace (`limet-workspace/`) is installed at the **monorepo root**, not in a parent folder
  outside version control.
- Each module's own `limet/` lives under its respective subfolder
  (`<monorepo>/<module>/limet/`), exactly as with separate repositories.
- Since it's a single repository, a contract change between two modules **can** be applied in a
  single commit/PR touching both modules — in that case the workspace's `CROSS_PROJECT_CHANGE.md`
  is still useful to document the rationale and the logical order (even though the commit is
  physically a single one), but opening two separate Pull Requests is not mandatory.
- Pay attention so that the monorepo's build/CI (if it builds everything together) doesn't hide
  sequencing problems: even if the commit is a single one, the logical order "who produces the
  contract, who consumes it" still matters for review and for testing (verify the producer in
  isolation first, then the consumer).

### C.5 — Cross-project e2e verification

When a change spans multiple projects, the `E2E_VERIFICATION_TEMPLATE.md` checklist should be
filled in **for each involved project** (local verification: "the backend correctly publishes the
event") **plus** an additional checklist, at the workspace level, verifying the end-to-end flow
across the boundary between the projects (e.g. "creating a card with a near deadline in the
backend, does the reminder email actually arrive from the notification service, in an environment
with both services running"). This additional checklist can be noted directly in the workspace's
`CROSS_PROJECT_CHANGE.md`, in a dedicated section, instead of creating a separate file, unless the
complexity of the flow justifies a dedicated `E2E_VERIFICATION.md` at the workspace level too.

## Sources of inspiration

The phased lifecycle (§3) and the proposal/spec/design separation (§3.1) generalize concepts
found in the spec-driven workflows of some open-source tools dedicated to managing *change
proposals* for AI agents (e.g. proposal → spec → design → tasks → archive), adapted here to be
independent of any specific tool and to make test coverage binding (§1.5/§5), which is not an
explicit requirement in all of those reference workflows.
