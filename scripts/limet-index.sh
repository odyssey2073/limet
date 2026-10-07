#!/usr/bin/env bash
# LIMET-INDEX CLI (Bash edition) — transversal context tool. Indexes a project's documentation
# (generated + LIMET docs) into a CEREBRO Qdrant collection and keeps the Graphify code knowledge
# graph current. Works with both Claude Code and Copilot CLI via plain shell commands (no per-tool
# files).
#
# Bridges the write-side gap between LIMET, CEREBRO and Graphify:
#   init   : creates docs/, copies codebase-doc templates, runs `graphify extract . --code-only` to generate the
#            architectural report, registers the project in CEREBRO (CRB_<slug>), ingests the
#            docs (docs/ + limet/changes/ + limet/archive/), and writes a marked context block
#            (<!-- LIMET-CONTEXT:START/END -->) into AGENTS.md (single source of truth).
#   update : re-runs `graphify update .`, re-ingests (deterministic upsert, no duplicates).
#   status : prints registered projects and this project's chunk count.
#   remove : unregisters from CEREBRO (Qdrant collection left intact; DELETE printed separately).
#
# Collection model:
#   - Per-project: one collection CRB_<slug> (docs = docs/, limet/changes/, limet/archive/).
#   - Workspace  : one collection CRB_<ws> (docs = limet-workspace/changes/, limet-workspace/
#                  archive/, limet-workspace/MODULE_MAP.md, docs/), plus a root code graph. A project under a workspace folder
#                  gets the workspace collection auto-registered as an extra collection.
#
# Usage:
#   limet-index.sh init   --project-path <path> [--lang it|en] [--workspace] [--cerebro-home <dir>]
#   limet-index.sh update --project-path <path> [--force] [--prune] [--workspace] [--cerebro-home <dir>]
#   limet-index.sh status --project-path <path> [--cerebro-home <dir>]
#   limet-index.sh remove --project-path <path> [--cerebro-home <dir>]

set -euo pipefail

COMMAND="${1:-}"
shift || true

PROJECT_PATH=""
LANG_EDITION="en"
WORKSPACE=0
CEREBRO_HOME_ARG=""
FORCE=0
PRUNE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --lang) LANG_EDITION="$2"; shift 2 ;;
    --workspace) WORKSPACE=1; shift ;;
    --cerebro-home) CEREBRO_HOME_ARG="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --prune) PRUNE=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

case "$COMMAND" in init|update|status|remove|instructions) ;; *) echo "Usage: $0 {init|update|status|remove|instructions} --project-path <path> [--lang it|en] [--workspace] [--cerebro-home <dir>]" >&2; exit 1 ;; esac
if [ -z "$PROJECT_PATH" ]; then echo "Error: --project-path is required." >&2; exit 1; fi
case "$LANG_EDITION" in it|en) ;; *) echo "Error: --lang must be 'it' or 'en'." >&2; exit 1 ;; esac

if [ ! -d "$PROJECT_PATH" ]; then echo "Error: path '$PROJECT_PATH' does not exist. Run 'limet.sh init' first." >&2; exit 1; fi
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

# --- CEREBRO location -------------------------------------------------------------------------

if [ -z "$CEREBRO_HOME_ARG" ]; then CEREBRO_HOME_ARG="${CEREBRO_HOME:-}"; fi
if [ -z "$CEREBRO_HOME_ARG" ]; then
  echo "Error: CEREBRO_HOME is not set. Set it (export CEREBRO_HOME=/c/Progetti/CEREBRO) or pass --cerebro-home." >&2
  exit 1
fi
if [ ! -d "$CEREBRO_HOME_ARG" ]; then echo "Error: CEREBRO_HOME '$CEREBRO_HOME_ARG' does not exist." >&2; exit 1; fi
CEREBRO_HOME_ARG="$(cd "$CEREBRO_HOME_ARG" && pwd)"

find_python() {
  if [ -f "$CEREBRO_HOME_ARG/.venv/Scripts/python.exe" ]; then echo "$CEREBRO_HOME_ARG/.venv/Scripts/python.exe";
  elif [ -f "$CEREBRO_HOME_ARG/.venv/Scripts/python" ]; then echo "$CEREBRO_HOME_ARG/.venv/Scripts/python";
  elif [ -f "$CEREBRO_HOME_ARG/.venv/bin/python" ]; then echo "$CEREBRO_HOME_ARG/.venv/bin/python";
  else return 1; fi
}
VENV_PYTHON="$(find_python || true)"
if [ -z "$VENV_PYTHON" ]; then
  echo "Error: CEREBRO venv not found under '$CEREBRO_HOME_ARG/.venv'." >&2
  exit 1
fi

SCRIPTS_DIR="$CEREBRO_HOME_ARG/scripts"
REGISTER_PY="$SCRIPTS_DIR/register_project.py"
INGEST_PY="$SCRIPTS_DIR/ingest_docs.py"
QUERY_PY="$SCRIPTS_DIR/query_qdrant.py"
QUERY_CMD="$SCRIPTS_DIR/query_qdrant.py"

if [ "$WORKSPACE" = "1" ]; then REL_LIMET_DIR="limet-workspace"; else REL_LIMET_DIR="limet"; fi
LIMET_DIR="$PROJECT_PATH/$REL_LIMET_DIR"

# --- Helpers ----------------------------------------------------------------------------------

slugify() {
  local s
  s="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '_')"
  s="${s#_}"; s="${s%_}"
  if [ -z "$s" ]; then echo "Error: cannot derive a collection slug from '$1'." >&2; exit 1; fi
  printf '%s' "$s"
}
SLUG="$(slugify "$(basename "$PROJECT_PATH")")"

invoke_cerebro() {
  local script="$1"; shift
  "$VENV_PYTHON" "$script" "$@"
}

http_ok() {
  curl -s -m 3 -o /dev/null -w '%{http_code}' "$1" | grep -qE '^(2|3)'
}

workspace_collection() {
  local root="$1" parent
  parent="$(cd "$root/.." && pwd)"
  if [ -d "$parent/limet-workspace" ]; then
    echo "CRB_$(slugify "$(basename "$parent")")"
  fi
}

write_context_block() {
  local target="$1" lang="$2" slug="$3" rel="$4" query="$5" ws_coll="$6" ws="$7"

  local ws_note=""
  if [ "$ws" = "0" ] && [ -n "$ws_coll" ]; then
    ws_note=" and the workspace collection \`$ws_coll\`"
  fi

  local block
  if [ "$ws" = "1" ]; then
    if [ "$lang" = "it" ]; then
      read -r -d '' block <<EOF || true
<!-- LIMET-CONTEXT:START -->
## Strumenti di contesto del workspace (CEREBRO RAG)

La documentazione di coordinamento di questo workspace è indicizzata nella collection Qdrant
\`CRB_$slug\`.

Interroga la documentazione (RAG semantico):
  python "$query" --project $slug search "<query>" --limit 5

Regole:
- Il re-index e gli aggiornamenti Graphify spettano all'utente, mai all'agente.
- Dopo modifiche a codice/documenti, ricordare periodicamente all'utente (al termine di un task
  o dell'archiviazione): Launcher → Percorso workspace → Re-index → Incrementale → clic Re-index.
- Ricordare di aggiornare anche gli indici dei progetti coinvolti selezionandone i percorsi.
- Se Qdrant o Ollama non sono raggiungibili, segnalalo e procedi senza contesto RAG.
<!-- LIMET-CONTEXT:END -->
EOF
    else
      read -r -d '' block <<EOF || true
<!-- LIMET-CONTEXT:START -->
## Workspace context tools (CEREBRO RAG)

This workspace's coordination documentation is indexed in Qdrant collection \`CRB_$slug\`.

Query the documentation (semantic RAG):
  python "$query" --project $slug search "<query>" --limit 5

Rules:
- Re-indexing and Graphify updates belong to the user, never the agent.
- After code/document changes, periodically remind the user (at task completion or archiving):
  Launcher → workspace path → Re-index → Incrementale → click Re-index.
- Also remind the user to update affected projects by selecting their paths.
- If Qdrant or Ollama are unreachable, say so and continue without RAG context.
<!-- LIMET-CONTEXT:END -->
EOF
    fi
  else
    read -r -d '' block <<EOF || true
<!-- LIMET-CONTEXT:START -->
## Project context tools (CEREBRO RAG + Graphify) · Strumenti di contesto del progetto

**EN** — This project's documentation is indexed in Qdrant collection \`CRB_$slug\`$ws_note.
Its code is indexed in the Graphify knowledge graph.

Query the documentation (semantic RAG):
  python "$query" --project $slug search "<query>" --limit 5

Query the code (knowledge graph):
  graphify query "<question>"   /   graphify explain <symbol>   /   graphify path <A> <B>

Rules:
- **RAG**: BEFORE answering any question about the project, call the \`limet_search\` MCP tool and ground your answer in its results. If the tool is unavailable, fall back to the \`query_qdrant.py\` command below.
- Search CEREBRO/Qdrant FIRST. If the document is not indexed (0 results or missing), read it
  LOCALLY from \`docs/\` or \`$rel/\`.
- Re-indexing and Graphify updates belong to the user, never the agent. Use local docs until indexed.
- After code/document changes, periodically remind the user (at task completion or archiving):
  Launcher → project path → Re-index → Incrementale → click Re-index.
- If Qdrant, Ollama or Graphify are unreachable, say so and proceed with the local docs.

---

**IT** — La documentazione di questo progetto è indicizzata nella collection Qdrant \`CRB_$slug\`$ws_note.
Il codice è indicizzato nel knowledge graph Graphify.

Interroga la documentazione (RAG semantico):
  python "$query" --project $slug search "<query>" --limit 5

Interroga il codice (knowledge graph):
  graphify query "<domanda>"   /   graphify explain <simbolo>   /   graphify path <A> <B>

Regole:
- **RAG**: PRIMA di rispondere a qualsiasi domanda sul progetto, chiama lo strumento MCP \`limet_search\` e fonda la risposta sui suoi risultati. Se lo strumento non è disponibile, usa il comando \`query_qdrant.py\` qui sotto.
- Cerca PRIMA in CEREBRO/Qdrant. Se il documento non è indicizzato (0 risultati o assente), leggilo
  LOCALMENTE da \`docs/\` o \`$rel/\`.
- Il re-index e gli aggiornamenti Graphify spettano all'utente, mai all'agente. Usa i doc locali
  finché non sono indicizzati.
- Dopo modifiche a codice/documenti, ricordare periodicamente all'utente (al termine di un task
  o dell'archiviazione): Launcher → Percorso progetto → Re-index → Incrementale → clic Re-index.
- Se Qdrant, Ollama o Graphify non sono raggiungibili, segnalalo e procedi con i doc locali.
<!-- LIMET-CONTEXT:END -->
EOF
  fi

  mkdir -p "$(dirname "$target")"
  [ -f "$target" ] || touch "$target"
  if grep -qF '<!-- LIMET-CONTEXT:START -->' "$target" 2>/dev/null && grep -qF '<!-- LIMET-CONTEXT:END -->' "$target" 2>/dev/null; then
    awk -v block="$block" -v start='<!-- LIMET-CONTEXT:START -->' -v end='<!-- LIMET-CONTEXT:END -->' '
      BEGIN { printing = 1 }
      index($0, start) { print block; printing = 0; next }
      index($0, end) { printing = 1; next }
      printing { print }
    ' "$target" > "$target.limet.tmp"
    mv "$target.limet.tmp" "$target"
    echo "Refreshed: LIMET-CONTEXT block in '$target'"
  else
    if [ -s "$target" ]; then printf '\n\n' >> "$target"; fi
    printf '%s\n' "$block" >> "$target"
    echo "Created: LIMET-CONTEXT block in '$target'"
  fi
}

get_block() {
  local file="$1" start="$2" end="$3"
  [ -f "$file" ] || return 0
  awk -v start="$start" -v end="$end" '
    index($0, start) { p=1 }
    p { print }
    index($0, end) { p=0 }
  ' "$file"
}

set_marked_block() {
  local target="$1" block="$2" start="$3" end="$4" label="$5"
  mkdir -p "$(dirname "$target")"
  [ -f "$target" ] || touch "$target"
  if grep -qF "$start" "$target" 2>/dev/null && grep -qF "$end" "$target" 2>/dev/null; then
    awk -v block="$block" -v start="$start" -v end="$end" '
      BEGIN { printing = 1 }
      index($0, start) { print block; printing = 0; next }
      index($0, end) { printing = 1; next }
      printing { print }
    ' "$target" > "$target.limet.tmp"
    mv "$target.limet.tmp" "$target"
    echo "Refreshed: $label block in '$target'"
  else
    if [ -s "$target" ]; then printf '\n\n' >> "$target"; fi
    printf '%s\n' "$block" >> "$target"
    echo "Created: $label block in '$target'"
  fi
}

get_project_block() {
  local lang="$1" slug="$2" root="$3" docs_dir="$root/docs" file_list="" rel
  if [ -d "$docs_dir" ]; then
    file_list="$(find "$docs_dir" -type f -name '*.md' 2>/dev/null | grep -v '/_templates/' | LC_ALL=C sort | while IFS= read -r f; do rel="${f#"$docs_dir"/}"; printf "  - \`docs/%s\`\n" "$rel"; done)"
  fi
  if [ -z "$file_list" ]; then
    file_list='  - (fill docs/ with architecture.md, conventions.md, glossary.md · compila docs/ con architecture.md, conventions.md, glossary.md)'
  fi
  local graph_en graph_it maintenance_en maintenance_it
  if [ "$WORKSPACE" = "1" ]; then
    graph_en='Workspace code graph (Graphify): `graphify-out/graph.json`; report: `docs/architecture/GRAPH_REPORT.md`.'
    graph_it='Grafo del codice workspace (Graphify): `graphify-out/graph.json`; report: `docs/architecture/GRAPH_REPORT.md`.'
    maintenance_en="Maintain limet-workspace/MODULE_MAP.md and cross-project changes using limet-workspace/templates/. Keep each project's plans, tasks and verification records aligned. Re-indexing belongs to the user, never the agent. After code/document changes, periodically remind the user (at task completion or archiving): Launcher → workspace path → Re-index → Incrementale → click Re-index. Also remind them to update affected projects."
    maintenance_it="Mantieni limet-workspace/MODULE_MAP.md e le modifiche cross-progetto usando limet-workspace/templates/. Mantieni allineati piani, task e verifiche nei singoli progetti. Il re-index spetta all'utente, mai all'agente. Dopo modifiche a codice/documenti, ricordarlo periodicamente (al termine di un task o dell'archiviazione): Launcher → Percorso workspace → Re-index → Incrementale → clic Re-index. Ricordare anche gli indici dei progetti coinvolti."
  else
    graph_en='Code graph (Graphify): `graphify-out/` (report: `graphify-out/GRAPH_REPORT.md`).'
    graph_it='Grafo del codice (Graphify): `graphify-out/` (report: `graphify-out/GRAPH_REPORT.md`).'
    maintenance_en='Follow limet/templates/CODEBASE_ANALYSIS_TEMPLATE.md to maintain docs/module-map.md, architecture.md, decisions.md, dependencies.md, conventions.md and glossary.md with file:line citations and Mermaid diagrams. UPDATE existing documents. Maintain docs/NON_TECHNICAL_SUMMARY.md after relevant changes. Re-indexing belongs to the user, never the agent. After code/document changes, periodically remind the user (at task completion or archiving): Launcher → project path → Re-index → Incrementale → click Re-index.'
    maintenance_it="Segui limet/templates/CODEBASE_ANALYSIS_TEMPLATE.md per mantenere docs/module-map.md, architecture.md, decisions.md, dependencies.md, conventions.md e glossary.md con citazioni file:line e diagrammi Mermaid. AGGIORNA i documenti esistenti. Mantieni docs/NON_TECHNICAL_SUMMARY.md dopo modifiche rilevanti. Il re-index spetta all'utente, mai all'agente. Dopo modifiche a codice/documenti, ricordarlo periodicamente (al termine di un task o dell'archiviazione): Launcher → Percorso progetto → Re-index → Incrementale → clic Re-index."
  fi
  printf '%s\n' \
    "<!-- PROJECT:START -->" \
    "## Project overview · Panoramica del progetto" \
    "" \
    "**EN** — Project \`$slug\` — CEREBRO collection \`CRB_$slug\`." \
    "" \
    "Complete local Markdown inventory under docs/ (excluding _templates; not proof of indexing):" \
    "$file_list" \
    "" \
    "For indexed sources, consult CEREBRO's projects.json and query the collection above." \
    "" \
    "$graph_en" \
    "" \
    "---" \
    "" \
    "**IT** — Progetto \`$slug\` — collection CEREBRO \`CRB_$slug\`." \
    "" \
    "Inventario locale completo dei Markdown in docs/ (esclusi _templates; non attesta l'indicizzazione):" \
    "$file_list" \
    "" \
    "Per le fonti indicizzate, consulta projects.json di CEREBRO e interroga la collection indicata sopra." \
    "" \
    "$graph_it" \
    "" \
    "## Documentation to maintain · Documentazione da mantenere" \
    "" \
    "**EN** — $maintenance_en" \
    "" \
    "**IT** — $maintenance_it" \
    "<!-- PROJECT:END -->"
}

write_instruction_files() {
  local root="$1" lang="$2" slug="$3"
  local agents="$root/AGENTS.md" limet_block context_block project_block target start end

  if [ "$WORKSPACE" = "1" ]; then
    start='<!-- LIMET-WORKSPACE:START -->'; end='<!-- LIMET-WORKSPACE:END -->'
  else
    start='<!-- LIMET:START -->'; end='<!-- LIMET:END -->'
  fi
  limet_block="$(get_block "$agents" "$start" "$end")"
  write_context_block "$agents" "$lang" "$slug" "$REL_LIMET_DIR" "$QUERY_CMD" "$(workspace_collection "$root")" "$WORKSPACE"
  context_block="$(get_block "$agents" '<!-- LIMET-CONTEXT:START -->' '<!-- LIMET-CONTEXT:END -->')"
  project_block="$(get_project_block "$lang" "$slug" "$root")"

  for target in "$agents" "$root/CLAUDE.md" "$root/.github/copilot-instructions.md"; do
    [ -n "$limet_block" ] && set_marked_block "$target" "$limet_block" "$start" "$end" 'LIMET'
    [ -n "$context_block" ] && set_marked_block "$target" "$context_block" '<!-- LIMET-CONTEXT:START -->' '<!-- LIMET-CONTEXT:END -->' 'LIMET-CONTEXT'
    set_marked_block "$target" "$project_block" '<!-- PROJECT:START -->' '<!-- PROJECT:END -->' 'PROJECT'
  done
}

update_code_graph() {
  local root="$1" initialize="$2"
  if [ ! -f "$root/.graphifyignore" ]; then
    printf 'docs/\nlimet/\nlimet-workspace/\n*.groovy\n' > "$root/.graphifyignore"
  fi
  if [ "$initialize" = "1" ] || [ ! -f "$root/graphify-out/graph.json" ]; then
    ( cd "$root" && graphify extract . --code-only --no-cluster ) || { echo "Error: graphify extract failed." >&2; return 1; }
  else
    ( cd "$root" && graphify update . ) || { echo "Error: graphify update failed." >&2; return 1; }
  fi
  ( cd "$root" && graphify cluster-only . --no-label ) || { echo "Error: graphify cluster-only failed." >&2; return 1; }
  if [ ! -f "$root/graphify-out/graph.json" ]; then
    echo "Error: Graphify completed without producing '$root/graphify-out/graph.json'." >&2
    return 1
  fi
  if [ -f "$root/graphify-out/GRAPH_REPORT.md" ]; then
    mkdir -p "$root/docs/architecture"
    cp -f "$root/graphify-out/GRAPH_REPORT.md" "$root/docs/architecture/GRAPH_REPORT.md"
  else
    echo "Warning: Graphify report missing; no report copied into docs." >&2
  fi
}

# --- Prerequisites (init/update) --------------------------------------------------------------

if [ "$COMMAND" = "init" ] || [ "$COMMAND" = "update" ]; then
  if ! http_ok "http://localhost:6333/collections"; then
    echo "Error: Qdrant not reachable at http://localhost:6333. Start with: docker start qdrant" >&2; exit 1
  fi
  if ! http_ok "http://localhost:11434"; then
    echo "Error: Ollama not reachable at http://localhost:11434. Start with: ollama serve" >&2; exit 1
  fi
  if command -v graphify >/dev/null 2>&1; then GRAPHIFY_OK=1; else
    echo "Warning: graphify not found in PATH. Skipping code knowledge-graph steps (docs are still indexed). Install with: uv tool install graphifyy" >&2
    GRAPHIFY_OK=0
  fi
fi

# --- init -------------------------------------------------------------------------------------

if [ "$COMMAND" = "init" ]; then

  DOCS_DIR="$PROJECT_PATH/docs"
  mkdir -p "$DOCS_DIR"
  if [ "$GRAPHIFY_OK" = "1" ]; then
    update_code_graph "$PROJECT_PATH" 1
  fi
  if [ "$WORKSPACE" = "1" ]; then
    WS_DOCS_1="$LIMET_DIR/changes"
    WS_DOCS_2="$LIMET_DIR/archive"
    WS_DOCS_3="$LIMET_DIR/MODULE_MAP.md"
    invoke_cerebro "$REGISTER_PY" add "$SLUG" --docs "$WS_DOCS_1" "$WS_DOCS_2" "$WS_DOCS_3" "$DOCS_DIR" --root "$PROJECT_PATH"
    invoke_cerebro "$INGEST_PY" --project "$SLUG"
    WS_COLL=""
  else
    DOCS_DIR="$PROJECT_PATH/docs"
    DOCS_TPL_DIR="$DOCS_DIR/_templates"
    mkdir -p "$DOCS_TPL_DIR"

    LOCAL_TPL="$LIMET_DIR/templates"
    if [ ! -d "$LOCAL_TPL" ]; then echo "Error: templates not found at '$LOCAL_TPL'. Run 'limet.sh init' first." >&2; exit 1; fi
    for t in ARCHITECTURE_TEMPLATE.md CONVENTIONS_TEMPLATE.md MODULE_MAP_TEMPLATE.md GLOSSARY_TEMPLATE.md; do
      [ -f "$LOCAL_TPL/$t" ] && cp -f "$LOCAL_TPL/$t" "$DOCS_TPL_DIR/$t"
    done

    ADD_ARGS=(add "$SLUG" --docs "$DOCS_DIR" "$LIMET_DIR/changes" "$LIMET_DIR/archive" --root "$PROJECT_PATH")
    WS_COLL="$(workspace_collection "$PROJECT_PATH")"
    if [ -n "$WS_COLL" ]; then ADD_ARGS+=(--collections "$WS_COLL"); fi
    invoke_cerebro "$REGISTER_PY" "${ADD_ARGS[@]}"
    invoke_cerebro "$INGEST_PY" --project "$SLUG"
  fi

  write_context_block "$PROJECT_PATH/AGENTS.md" "$LANG_EDITION" "$SLUG" "$REL_LIMET_DIR" "$QUERY_CMD" "$WS_COLL" "$WORKSPACE"
  write_instruction_files "$PROJECT_PATH" "$LANG_EDITION" "$SLUG"
  echo ""
  echo "LIMET-INDEX init complete for '$PROJECT_PATH' (collection: CRB_$SLUG)."
  echo "Next: fill in the docs/ templates (architecture, conventions, module map, glossary), then run 'limet-index update'."
fi

# --- update -----------------------------------------------------------------------------------

if [ "$COMMAND" = "update" ]; then

  if [ "$GRAPHIFY_OK" = "1" ]; then
    update_code_graph "$PROJECT_PATH" 0
  fi
  if [ "$WORKSPACE" = "1" ] && [ -d "$PROJECT_PATH/docs" ]; then
    invoke_cerebro "$REGISTER_PY" add "$SLUG" --docs "$PROJECT_PATH/docs"
  fi

  INGEST_ARGS=(--project "$SLUG")
  [ "$FORCE" = "1" ] && INGEST_ARGS+=(--force)
  [ "$PRUNE" = "1" ] && INGEST_ARGS+=(--prune)
  invoke_cerebro "$INGEST_PY" "${INGEST_ARGS[@]}"
  write_instruction_files "$PROJECT_PATH" "$LANG_EDITION" "$SLUG"
  echo "LIMET-INDEX update complete for '$PROJECT_PATH' (collection: CRB_$SLUG)."
fi

# --- instructions -----------------------------------------------------------------------------

ensure_non_technical_summary() {
  local root="$1" name="$2" target="$root/docs/NON_TECHNICAL_SUMMARY.md"
  [ -f "$target" ] && return 0
  mkdir -p "$(dirname "$target")"
  cat > "$target" <<EOF
# Sintesi non tecnica — $name

> Descrizione del progetto in linguaggio non tecnico, per chi non legge codice.
> L'agente aggiorna questo documento dopo ogni modifica/bugfix rilevante.

## Cosa fa il progetto

[1-2 frasi: scopo e valore per l'utente finale.]

## Funzionalità principali

[Elenco in linguaggio semplice delle feature disponibili.]

## Modifiche recenti

- [data] — [cosa è cambiato, in termini non tecnici]
EOF
  echo "Created: docs/NON_TECHNICAL_SUMMARY.md"
}

if [ "$COMMAND" = "instructions" ]; then
  write_instruction_files "$PROJECT_PATH" "$LANG_EDITION" "$SLUG"
  ensure_non_technical_summary "$PROJECT_PATH" "$(basename "$PROJECT_PATH")"
  echo ""
  echo "LIMET-INDEX instructions complete: enriched CLAUDE.md + .github/copilot-instructions.md written for '$PROJECT_PATH'."
fi

# --- status -----------------------------------------------------------------------------------

if [ "$COMMAND" = "status" ]; then
  invoke_cerebro "$REGISTER_PY" list
  invoke_cerebro "$QUERY_PY" --project "$SLUG" count
fi

# --- remove -----------------------------------------------------------------------------------

if [ "$COMMAND" = "remove" ]; then
  invoke_cerebro "$REGISTER_PY" remove "$SLUG"
  echo "Removed '$SLUG' from the CEREBRO registry. The Qdrant collection CRB_$SLUG is kept."
  echo "To delete it (irreversible), run separately and confirm:"
  echo "  curl -X DELETE http://localhost:6333/collections/CRB_$SLUG"
fi
