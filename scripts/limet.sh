#!/usr/bin/env bash
# LIMET CLI (Bash edition) — installs/updates the LIMET spec-driven framework in a project (or in
# a multi-project workspace) using a single cross-tool mechanism, mirroring the init/update
# pattern of tools such as OpenSpec.
#
# LIMET uses ONE integration mechanism, not a different custom setup per AI tool:
#   - AGENTS.md at the project (or workspace) root is the single source of truth. It is read
#     natively by Copilot CLI (documented instruction-file location) and by most other agentic
#     CLI tools that follow the open agents.md convention.
#   - Claude Code reads CLAUDE.md by default, not AGENTS.md. The officially documented way to
#     make it also load AGENTS.md is a single "@AGENTS.md" import line at the top of CLAUDE.md —
#     a standard Claude Code feature (file import), not a LIMET-specific workaround. This script
#     adds that one line to CLAUDE.md (creating it if missing) and never duplicates content.
#
# Two modes:
#   - Per-project mode (default): init copies the manual+templates into <project>/limet/,
#     creates limet/changes/ and limet/archive/, writes/refreshes the LIMET block in AGENTS.md,
#     ensures CLAUDE.md imports it.
#   - Workspace mode (--workspace): for a parent folder containing several correlated
#     projects/repositories (or a monorepo with several modules, each treated as its own
#     "project"). init creates <path>/limet-workspace/ with MODULE_MAP.md (only if missing —
#     never overwritten on update) and the two coordination templates
#     (MODULE_MAP_TEMPLATE.md, CROSS_PROJECT_CHANGE_TEMPLATE.md), and writes/refreshes a separate
#     marked block (LIMET-WORKSPACE) in the workspace-level AGENTS.md/CLAUDE.md. This does NOT
#     replace per-project installation: each individual project/module should still get its own
#     init (without --workspace) in its own root.
#
# Usage:
#   limet.sh init   --project-path <path> [--lang it|en] [--workspace]
#   limet.sh update --project-path <path> [--lang it|en] [--workspace]
#
# Both actions are idempotent in both modes.

set -euo pipefail

COMMAND="${1:-}"
shift || true

PROJECT_PATH=""
LANG_EDITION="en"
WORKSPACE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --lang) LANG_EDITION="$2"; shift 2 ;;
    --workspace) WORKSPACE=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [ "$COMMAND" != "init" ] && [ "$COMMAND" != "update" ]; then
  echo "Usage: $0 {init|update} --project-path <path> [--lang it|en] [--workspace]" >&2
  exit 1
fi
if [ -z "$PROJECT_PATH" ]; then
  echo "Error: --project-path is required." >&2
  exit 1
fi
case "$LANG_EDITION" in it|en) ;; *) echo "Error: --lang must be 'it' or 'en'." >&2; exit 1 ;; esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIMET_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_LANG_DIR="$LIMET_ROOT/$LANG_EDITION"

if [ ! -d "$SOURCE_LANG_DIR" ]; then
  echo "Error: language edition '$LANG_EDITION' not found under '$LIMET_ROOT'." >&2
  exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
  if [ "$COMMAND" = "update" ]; then
    echo "Error: path '$PROJECT_PATH' does not exist. Run 'init' first." >&2
    exit 1
  fi
  mkdir -p "$PROJECT_PATH"
fi
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

if [ "$WORKSPACE" = "1" ]; then
  REL_LIMET_DIR="limet-workspace"
else
  REL_LIMET_DIR="limet"
fi
LIMET_PROJECT_DIR="$PROJECT_PATH/$REL_LIMET_DIR"

# --- Step 1: copy files into <path>/limet/ or <path>/limet-workspace/ --------------------------

if [ -d "$LIMET_PROJECT_DIR" ]; then STATUS_DIR="Refreshed"; else STATUS_DIR="Created"; fi
mkdir -p "$LIMET_PROJECT_DIR/templates" "$LIMET_PROJECT_DIR/changes" "$LIMET_PROJECT_DIR/archive"

# The transversal context tool (CEREBRO RAG + Graphify) is copied alongside the framework files so
# each project is self-contained: the agent can always run <limetDir>/scripts/limet-index.sh.
mkdir -p "$LIMET_PROJECT_DIR/scripts"
cp -f "$SCRIPT_DIR/limet-index.ps1" "$LIMET_PROJECT_DIR/scripts/limet-index.ps1"
cp -f "$SCRIPT_DIR/limet-index.sh" "$LIMET_PROJECT_DIR/scripts/limet-index.sh"

cp -f "$SOURCE_LANG_DIR/FRAMEWORK_MANUAL.md" "$LIMET_PROJECT_DIR/FRAMEWORK_MANUAL.md"
cp -f "$SOURCE_LANG_DIR/ONBOARDING_CHECKLIST.md" "$LIMET_PROJECT_DIR/ONBOARDING_CHECKLIST.md"
cp -f "$SOURCE_LANG_DIR/MASTER_INDEX.md" "$LIMET_PROJECT_DIR/MASTER_INDEX.md"

if [ "$WORKSPACE" = "1" ]; then
  # Workspace mode: only the two coordination templates, not the full per-project template set.
  cp -f "$SOURCE_LANG_DIR/templates/MODULE_MAP_TEMPLATE.md" "$LIMET_PROJECT_DIR/templates/MODULE_MAP_TEMPLATE.md"
  cp -f "$SOURCE_LANG_DIR/templates/CROSS_PROJECT_CHANGE_TEMPLATE.md" "$LIMET_PROJECT_DIR/templates/CROSS_PROJECT_CHANGE_TEMPLATE.md"
  # MODULE_MAP.md is a working document the user fills in — create it only if missing, never
  # overwrite it on 'update' (that would wipe out real workspace data).
  MODULE_MAP_FILE="$LIMET_PROJECT_DIR/MODULE_MAP.md"
  if [ ! -f "$MODULE_MAP_FILE" ]; then
    cp -f "$SOURCE_LANG_DIR/templates/MODULE_MAP_TEMPLATE.md" "$MODULE_MAP_FILE"
    echo "Created: '$MODULE_MAP_FILE' (fill it in with your projects/modules)"
  fi
else
  cp -f "$SOURCE_LANG_DIR"/templates/*.md "$LIMET_PROJECT_DIR/templates/"
fi

for keep_dir in changes archive; do
  touch "$LIMET_PROJECT_DIR/$keep_dir/.gitkeep"
done

echo "$STATUS_DIR: $REL_LIMET_DIR/ ($LANG_EDITION edition) in '$PROJECT_PATH'"

# --- Step 2: build the LIMET block ---------------------------------------------------------------

read -r -d '' BLOCK_IT <<EOF || true
<!-- LIMET:START -->
## LIMET — metodo di lavoro spec-driven per questo progetto

Questo progetto segue il framework **LIMET** per bug fixing e sviluppo di nuove feature con
agenti AI. Documentazione locale in \`$REL_LIMET_DIR/\` (manuale: \`$REL_LIMET_DIR/FRAMEWORK_MANUAL.md\`,
checklist: \`$REL_LIMET_DIR/ONBOARDING_CHECKLIST.md\`, template: \`$REL_LIMET_DIR/templates/\`,
lavoro in corso: \`$REL_LIMET_DIR/changes/\`, lavoro concluso: \`$REL_LIMET_DIR/archive/\`).

Regole vincolanti (vedi il manuale per il dettaglio):
- Prima di modificare codice non banale, creare/consultare un documento di piano o proposta in
  \`$REL_LIMET_DIR/changes/\` usando \`templates/PLAN_TEMPLATE.md\` o, per modifiche ampie,
  \`templates/CHANGE_PROPOSAL_TEMPLATE.md\` + \`templates/SPEC_TEMPLATE.md\`.
- Ogni ambiguità va registrata come domanda contestuale (con risposta e data), mai assunta in
  silenzio.
- **Nessun task può essere marcato \`done\` senza una strategia di verifica**: unit test dedicati
  e/o test e2e approfonditi con istruzioni passo-passo, salvo motivazione esplicita di omissione.
  Quando un task passa a \`done\`, annotare anche l'ora (\`YYYY-MM-DD HH:MM\`).
- **Approvazione umana**: prima di implementare, chiedi all'utente l'approvazione del piano/proposta e registrala nel documento (chi ha approvato + data).
- **Tracciabilità e comunicazione**: a fine task, per ogni file creato/modificato riporta nella scheda task il test collegato e comunica all'utente l'elenco delle modifiche (file, cosa è cambiato, perché).
- **MAI eseguire build o test**: non lanciare MAI build (\`./mvnw package\`) né test (\`./mvnw test\`) in autonomia — l'output riempie il contesto di rumore. Quando serve, dai all'utente il comando, chiedi di eseguirlo e di comunicare l'esito, e resta in standby finché non arriva.
- Non eseguire comandi con effetti persistenti (commit, push, migrazioni, deploy) senza
  autorizzazione esplicita dell'utente.
- A inizio sessione/feature, consultare \`$REL_LIMET_DIR/ONBOARDING_CHECKLIST.md\`.
- A modifica conclusa e verificata, spostare/archiviare i documenti in \`$REL_LIMET_DIR/archive/\`
  usando \`templates/ARCHIVE_ENTRY_TEMPLATE.md\`.
- Dopo l'archiviazione, eseguire \`$REL_LIMET_DIR/scripts/limet-index.ps1 update\` (o
  \`limet-index.sh update\`) per re-indicizzare la collection RAG del progetto (CEREBRO).
- Se questo progetto fa parte di un workspace multi-progetto (più repository correlati o più
  moduli), verificare se esiste una cartella \`limet-workspace/\` nella cartella padre condivisa:
  in tal caso consultare \`limet-workspace/MODULE_MAP.md\` prima di modifiche che potrebbero
  toccare altri progetti, e usare \`limet-workspace/templates/CROSS_PROJECT_CHANGE_TEMPLATE.md\`
  per coordinare modifiche cross-progetto — vedi \`FRAMEWORK_MANUAL.md\` Appendice C.
- Per aggiornare questa cartella locale a una nuova versione di LIMET, rieseguire lo script di
  installazione (\`scripts/limet.ps1 update\` o \`scripts/limet.sh update\`) dal repository
  sorgente del framework.
<!-- LIMET:END -->
EOF

read -r -d '' BLOCK_EN <<EOF || true
<!-- LIMET:START -->
## LIMET — spec-driven working method for this project

This project follows the **LIMET** framework for bug fixing and new feature development with AI
agents. Local documentation in \`$REL_LIMET_DIR/\` (manual: \`$REL_LIMET_DIR/FRAMEWORK_MANUAL.md\`,
checklist: \`$REL_LIMET_DIR/ONBOARDING_CHECKLIST.md\`, templates: \`$REL_LIMET_DIR/templates/\`,
work in progress: \`$REL_LIMET_DIR/changes/\`, completed work: \`$REL_LIMET_DIR/archive/\`).

Binding rules (see the manual for full detail):
- Before making a non-trivial code change, create/consult a plan or proposal document in
  \`$REL_LIMET_DIR/changes/\` using \`templates/PLAN_TEMPLATE.md\` or, for larger changes,
  \`templates/CHANGE_PROPOSAL_TEMPLATE.md\` + \`templates/SPEC_TEMPLATE.md\`.
- Every ambiguity must be recorded as a contextual question (with answer and date), never
  silently assumed.
- **No task can be marked \`done\` without a verification strategy**: dedicated unit tests
  and/or thorough e2e tests with step-by-step instructions, unless explicitly justified as
  omitted. When a task moves to \`done\`, also record the time (\`YYYY-MM-DD HH:MM\`).
- **Human approval**: before implementing, ask the user to approve the plan/proposal and record it in the document (who approved + date).
- **Traceability and communication**: at the end of a task, for each created/modified file record the linked test in the task sheet and tell the user the list of changes (file, what changed, why).
- **NEVER run builds or tests**: never run a build (\`./mvnw package\`) or tests (\`./mvnw test\`) on your own — the output floods the context with noise. When needed, give the user the command, ask them to run it and report the outcome, and stay on standby until it arrives.
- Do not run commands with persistent effects (commit, push, migrations, deploy) without the
  user's explicit authorization.
- At the start of a session/feature, consult \`$REL_LIMET_DIR/ONBOARDING_CHECKLIST.md\`.
- Once a change is complete and verified, move/archive its documents into
  \`$REL_LIMET_DIR/archive/\` using \`templates/ARCHIVE_ENTRY_TEMPLATE.md\`.
- After archiving a change, run \`$REL_LIMET_DIR/scripts/limet-index.ps1 update\` (or
  \`limet-index.sh update\`) to re-index the project's RAG collection (CEREBRO).
- If this project is part of a multi-project workspace (several correlated repositories or
  several modules), check whether a \`limet-workspace/\` folder exists in the shared parent
  folder: if so, consult \`limet-workspace/MODULE_MAP.md\` before changes that might touch other
  projects, and use \`limet-workspace/templates/CROSS_PROJECT_CHANGE_TEMPLATE.md\` to coordinate
  cross-project changes — see \`FRAMEWORK_MANUAL.md\` Appendix C.
- To update this local copy to a newer LIMET version, re-run the install script
  (\`scripts/limet.ps1 update\` or \`scripts/limet.sh update\`) from the framework's source repo.
<!-- LIMET:END -->
EOF

read -r -d '' WORKSPACE_BLOCK_IT <<EOF || true
<!-- LIMET-WORKSPACE:START -->
## LIMET — coordinamento multi-progetto (workspace)

Questa cartella è la radice di un **workspace LIMET** che coordina più progetti/repository
correlati (o più moduli di uno stesso repository, ciascuno trattato come progetto a sé). Non
sostituisce l'installazione LIMET dei singoli progetti (ciascuno ha il proprio \`AGENTS.md\` +
\`limet/\` nella propria root) — aggiunge solo un livello di coordinamento condiviso.

Documentazione locale in \`$REL_LIMET_DIR/\`:
- \`$REL_LIMET_DIR/MODULE_MAP.md\` — elenco progetti/moduli, ruoli, dipendenze/contratti tra loro.
  **Consultarla prima di qualunque modifica che potrebbe toccare più di un progetto.**
- \`$REL_LIMET_DIR/templates/CROSS_PROJECT_CHANGE_TEMPLATE.md\` — documento ombrello per
  coordinare una modifica che attraversa più progetti (ordine di implementazione, contratto
  condiviso, criterio di chiusura complessivo).
- \`$REL_LIMET_DIR/changes/\` — modifiche cross-progetto in corso; \`$REL_LIMET_DIR/archive/\` —
  concluse.

Regole vincolanti:
- Prima di iniziare una modifica che coinvolge più di un progetto elencato in
  \`$REL_LIMET_DIR/MODULE_MAP.md\`, creare un documento da \`templates/CROSS_PROJECT_CHANGE_TEMPLATE.md\`
  in \`$REL_LIMET_DIR/changes/\` con l'ordine di implementazione (di norma: produttore del contratto
  prima dei consumatori).
- Ogni progetto coinvolto mantiene comunque i propri documenti (piano/task/test) nella propria
  cartella \`limet/changes/\`: il documento cross-progetto **collega**, non duplica.
- La modifica cross-progetto si chiude solo quando tutti i progetti coinvolti sono a \`done\` **e**
  la verifica di integrazione end-to-end tra progetti è stata eseguita con esito positivo.
- Vedi \`FRAMEWORK_MANUAL.md\` Appendice C per gli scenari operativi completi (nuovo workspace,
  bug fix cross-progetto, nuova feature cross-progetto).
- Dopo l'archiviazione di una modifica cross-progetto, eseguire
  \`$REL_LIMET_DIR/scripts/limet-index.ps1 update\` per re-indicizzare la collection RAG del
  workspace.
<!-- LIMET-WORKSPACE:END -->
EOF

read -r -d '' WORKSPACE_BLOCK_EN <<EOF || true
<!-- LIMET-WORKSPACE:START -->
## LIMET — multi-project coordination (workspace)

This folder is the root of a **LIMET workspace** coordinating several correlated
projects/repositories (or several modules of the same repository, each treated as its own
project). It does not replace each project's own LIMET installation (each has its own
\`AGENTS.md\` + \`limet/\` in its own root) — it only adds a shared coordination layer.

Local documentation in \`$REL_LIMET_DIR/\`:
- \`$REL_LIMET_DIR/MODULE_MAP.md\` — list of projects/modules, roles, dependencies/contracts
  between them. **Consult it before any change that might touch more than one project.**
- \`$REL_LIMET_DIR/templates/CROSS_PROJECT_CHANGE_TEMPLATE.md\` — umbrella document to coordinate
  a change spanning multiple projects (implementation order, shared contract, overall closure
  criterion).
- \`$REL_LIMET_DIR/changes/\` — cross-project changes in progress; \`$REL_LIMET_DIR/archive/\` —
  completed ones.

Binding rules:
- Before starting a change involving more than one project listed in
  \`$REL_LIMET_DIR/MODULE_MAP.md\`, create a document from
  \`templates/CROSS_PROJECT_CHANGE_TEMPLATE.md\` in \`$REL_LIMET_DIR/changes/\` with the
  implementation order (normally: contract producer before consumers).
- Every involved project still keeps its own documents (plan/task/test) in its own
  \`limet/changes/\` folder: the cross-project document **links**, it does not duplicate.
- The cross-project change is closed only once all involved projects are at \`done\` **and** the
  cross-project end-to-end integration verification has passed.
- See \`FRAMEWORK_MANUAL.md\` Appendix C for the full operational scenarios (new workspace,
  cross-project bug fix, cross-project feature).
- After archiving a cross-project change, run \`$REL_LIMET_DIR/scripts/limet-index.ps1 update\` to
  re-index the workspace RAG collection.
<!-- LIMET-WORKSPACE:END -->
EOF

if [ "$WORKSPACE" = "1" ]; then
  if [ "$LANG_EDITION" = "it" ]; then BLOCK="$WORKSPACE_BLOCK_IT"; else BLOCK="$WORKSPACE_BLOCK_EN"; fi
  START_MARKER="<!-- LIMET-WORKSPACE:START -->"
  END_MARKER="<!-- LIMET-WORKSPACE:END -->"
else
  if [ "$LANG_EDITION" = "it" ]; then BLOCK="$BLOCK_IT"; else BLOCK="$BLOCK_EN"; fi
  START_MARKER="<!-- LIMET:START -->"
  END_MARKER="<!-- LIMET:END -->"
fi

# --- Step 3: install/refresh the block into the single source of truth: AGENTS.md --------------

set_limet_block() {
  local target_file="$1"
  local block="$2"
  local start_marker="$3"
  local end_marker="$4"

  mkdir -p "$(dirname "$target_file")"
  if [ ! -f "$target_file" ]; then
    touch "$target_file"
  fi

  if grep -qF "$start_marker" "$target_file" 2>/dev/null && grep -qF "$end_marker" "$target_file" 2>/dev/null; then
    awk -v block="$block" -v start="$start_marker" -v end="$end_marker" '
      BEGIN { printing = 1 }
      index($0, start) { print block; printing = 0; next }
      index($0, end) { printing = 1; next }
      printing { print }
    ' "$target_file" > "$target_file.limet.tmp"
    mv "$target_file.limet.tmp" "$target_file"
    echo "Refreshed: LIMET block in '$target_file'"
  else
    if [ -s "$target_file" ]; then printf '\n\n' >> "$target_file"; fi
    printf '%s\n' "$block" >> "$target_file"
    echo "Created: LIMET block in '$target_file'"
  fi
}

AGENTS_FILE="$PROJECT_PATH/AGENTS.md"
set_limet_block "$AGENTS_FILE" "$BLOCK" "$START_MARKER" "$END_MARKER"

# --- Step 4: ensure CLAUDE.md imports AGENTS.md (standard Claude Code file-import feature) ------

IMPORT_LINE="@AGENTS.md"
CLAUDE_FILE="$PROJECT_PATH/CLAUDE.md"

if [ ! -f "$CLAUDE_FILE" ]; then
  printf '%s\n' "$IMPORT_LINE" > "$CLAUDE_FILE"
  echo "Created: '$CLAUDE_FILE' with '$IMPORT_LINE' import"
else
  if grep -qF "$IMPORT_LINE" "$CLAUDE_FILE"; then
    echo "Already present: '$IMPORT_LINE' import in '$CLAUDE_FILE'"
  else
    { printf '%s\n\n' "$IMPORT_LINE"; cat "$CLAUDE_FILE"; } > "$CLAUDE_FILE.limet.tmp"
    mv "$CLAUDE_FILE.limet.tmp" "$CLAUDE_FILE"
    echo "Updated: prepended '$IMPORT_LINE' import to '$CLAUDE_FILE' (existing content preserved below)"
  fi
fi

echo ""
if [ "$WORKSPACE" = "1" ]; then
  echo "LIMET $COMMAND complete for '$PROJECT_PATH' (edition: $LANG_EDITION, workspace mode)."
  if [ "$COMMAND" = "init" ]; then
    echo "Next: fill in '$REL_LIMET_DIR/MODULE_MAP.md', then run 'limet.sh init' (without --workspace) in each individual project/module root."
  fi
else
  echo "LIMET $COMMAND complete for '$PROJECT_PATH' (edition: $LANG_EDITION)."
  if [ "$COMMAND" = "init" ]; then
    echo "Next: open '$REL_LIMET_DIR/ONBOARDING_CHECKLIST.md' and start your first change in '$REL_LIMET_DIR/changes/'."
  fi
fi
