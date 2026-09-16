#!/usr/bin/env bash
# LIMET-INDEX CLI (Bash edition) — transversal context tool. Indexes a project's documentation
# (generated + LIMET docs) into a CEREBRO Qdrant collection and keeps the Graphify code knowledge
# graph current. Works with both Claude Code and Copilot CLI via plain shell commands (no per-tool
# files).
#
# Bridges the write-side gap between LIMET, CEREBRO and Graphify:
#   init   : creates docs/, copies codebase-doc templates, runs `graphify .` to generate the
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
#                  archive/, limet-workspace/MODULE_MAP.md). A project under a workspace folder
#                  gets the workspace collection auto-registered as an extra collection.
#
# Usage:
#   limet-index.sh init   --project-path <path> [--lang it|en] [--workspace] [--cerebro-home <dir>]
#   limet-index.sh update --project-path <path> [--workspace] [--cerebro-home <dir>]
#   limet-index.sh status --project-path <path> [--cerebro-home <dir>]
#   limet-index.sh remove --project-path <path> [--cerebro-home <dir>]

set -euo pipefail

COMMAND="${1:-}"
shift || true

PROJECT_PATH=""
LANG_EDITION="en"
WORKSPACE=0
CEREBRO_HOME_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --lang) LANG_EDITION="$2"; shift 2 ;;
    --workspace) WORKSPACE=1; shift ;;
    --cerebro-home) CEREBRO_HOME_ARG="$2"; shift 2 ;;
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

Mantieni l'indice aggiornato (dopo aver archiviato modifiche cross-progetto):
  $rel/scripts/limet-index.ps1 update -ProjectPath .    (oppure .../limet-index.sh update)

Regole:
- Dopo aver archiviato una modifica cross-progetto in $rel/archive/, esegui \`limet-index update\`.
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

Keep the index current (after archiving cross-project changes):
  $rel/scripts/limet-index.ps1 update -ProjectPath .    (or .../limet-index.sh update)

Rules:
- After archiving a cross-project change into $rel/archive/, run \`limet-index update\`.
- If Qdrant or Ollama are unreachable, say so and continue without RAG context.
<!-- LIMET-CONTEXT:END -->
EOF
    fi
  else
    if [ "$lang" = "it" ]; then
      read -r -d '' block <<EOF || true
<!-- LIMET-CONTEXT:START -->
## Strumenti di contesto del progetto (CEREBRO RAG + Graphify)

La documentazione di questo progetto è indicizzata nella collection Qdrant \`CRB_$slug\`$ws_note.
Il codice è indicizzato nel knowledge graph Graphify.

Interroga la documentazione (RAG semantico):
  python "$query" --project $slug search "<query>" --limit 5

Interroga il codice (knowledge graph):
  graphify query "<domanda>"   /   graphify explain <simbolo>   /   graphify path <A> <B>

Mantieni gli indici aggiornati (dopo aver prodotto o archiviato documenti, o dopo modifiche al codice):
  $rel/scripts/limet-index.ps1 update -ProjectPath .    (oppure .../limet-index.sh update)
  graphify update .

Regole:
- Dopo aver archiviato una modifica in $rel/archive/, esegui \`limet-index update\` per re-indicizzare.
- Se Qdrant, Ollama o Graphify non sono raggiungibili, segnalalo e procedi senza contesto RAG/graph.
<!-- LIMET-CONTEXT:END -->
EOF
    else
      read -r -d '' block <<EOF || true
<!-- LIMET-CONTEXT:START -->
## Project context tools (CEREBRO RAG + Graphify)

This project's documentation is indexed in Qdrant collection \`CRB_$slug\`$ws_note.
Its code is indexed in the Graphify knowledge graph.

Query the documentation (semantic RAG):
  python "$query" --project $slug search "<query>" --limit 5

Query the code (knowledge graph):
  graphify query "<question>"   /   graphify explain <symbol>   /   graphify path <A> <B>

Keep the indexes current (after producing or archiving documents, or after code changes):
  $rel/scripts/limet-index.ps1 update -ProjectPath .    (or .../limet-index.sh update)
  graphify update .

Rules:
- After archiving a change into $rel/archive/, run \`limet-index update\` to re-index the collection.
- If Qdrant, Ollama or Graphify are unreachable, say so and continue without RAG/graph context.
<!-- LIMET-CONTEXT:END -->
EOF
    fi
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
    file_list="$(find "$docs_dir" -type f -name '*.md' 2>/dev/null | grep -v '/_templates/' | head -8 | while read -r f; do rel="${f#"$docs_dir"/}"; printf "  - \`docs/%s\`\n" "$rel"; done)"
  fi
  if [ -z "$file_list" ]; then
    if [ "$lang" = "it" ]; then file_list='  - (compila docs/ con architecture.md, conventions.md, glossary.md)'; else file_list='  - (fill docs/ with architecture.md, conventions.md, glossary.md)'; fi
  fi
  if [ "$lang" = "it" ]; then
    printf '%s\n' "<!-- PROJECT:START -->" "## Panoramica del progetto" "" "Progetto \`$slug\` — collection CEREBRO \`CRB_$slug\`." "" "Documentazione approfondita (indicizzata in CEREBRO — interroga con il comando sopra):" "$file_list" "" "Grafo del codice (Graphify): \`graphify-out/\` (report: \`graphify-out/GRAPH_REPORT.md\`)." "Prima di modifiche strutturali, consulta la documentazione in \`docs/\` e il grafo." "<!-- PROJECT:END -->"
  else
    printf '%s\n' "<!-- PROJECT:START -->" "## Project overview" "" "Project \`$slug\` — CEREBRO collection \`CRB_$slug\`." "" "In-depth documentation (indexed in CEREBRO — query it with the command above):" "$file_list" "" "Code graph (Graphify): \`graphify-out/\` (report: \`graphify-out/GRAPH_REPORT.md\`)." "Before structural changes, consult the docs in \`docs/\` and the graph." "<!-- PROJECT:END -->"
  fi
}

write_instruction_files() {
  local root="$1" lang="$2" slug="$3"
  local agents="$root/AGENTS.md" limet_block context_block project_block target

  limet_block="$(get_block "$agents" '<!-- LIMET:START -->' '<!-- LIMET:END -->')"
  context_block="$(get_block "$agents" '<!-- LIMET-CONTEXT:START -->' '<!-- LIMET-CONTEXT:END -->')"
  project_block="$(get_project_block "$lang" "$slug" "$root")"

  for target in "$root/CLAUDE.md" "$root/.github/copilot-instructions.md"; do
    [ -n "$limet_block" ] && set_marked_block "$target" "$limet_block" '<!-- LIMET:START -->' '<!-- LIMET:END -->' 'LIMET'
    [ -n "$context_block" ] && set_marked_block "$target" "$context_block" '<!-- LIMET-CONTEXT:START -->' '<!-- LIMET-CONTEXT:END -->' 'LIMET-CONTEXT'
    set_marked_block "$target" "$project_block" '<!-- PROJECT:START -->' '<!-- PROJECT:END -->' 'PROJECT'
  done
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

  if [ "$WORKSPACE" = "1" ]; then
    WS_DOCS_1="$LIMET_DIR/changes"
    WS_DOCS_2="$LIMET_DIR/archive"
    WS_DOCS_3="$LIMET_DIR/MODULE_MAP.md"
    invoke_cerebro "$REGISTER_PY" add "$SLUG" --docs "$WS_DOCS_1" "$WS_DOCS_2" "$WS_DOCS_3" --root "$PROJECT_PATH"
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

    if [ ! -f "$PROJECT_PATH/.graphifyignore" ]; then
      printf 'docs/\nlimet/\nlimet-workspace/\n' > "$PROJECT_PATH/.graphifyignore"
    fi

    if [ "$GRAPHIFY_OK" = "1" ]; then
      ( cd "$PROJECT_PATH" && graphify . ) || echo "Warning: graphify . failed." >&2
      ( cd "$PROJECT_PATH" && graphify cluster-only . ) || echo "Warning: graphify cluster-only failed." >&2
      if [ -f "$PROJECT_PATH/graphify-out/GRAPH_REPORT.md" ]; then
        mkdir -p "$DOCS_DIR/architecture"
        cp -f "$PROJECT_PATH/graphify-out/GRAPH_REPORT.md" "$DOCS_DIR/architecture/GRAPH_REPORT.md"
      fi
    fi

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

  if [ "$GRAPHIFY_OK" = "1" ] && [ "$WORKSPACE" = "0" ]; then
    ( cd "$PROJECT_PATH" && graphify update . ) || echo "Warning: graphify update . failed." >&2
    if [ -f "$PROJECT_PATH/graphify-out/GRAPH_REPORT.md" ]; then
      mkdir -p "$PROJECT_PATH/docs/architecture"
      cp -f "$PROJECT_PATH/graphify-out/GRAPH_REPORT.md" "$PROJECT_PATH/docs/architecture/GRAPH_REPORT.md"
    fi
  fi

  invoke_cerebro "$INGEST_PY" --project "$SLUG"
  write_instruction_files "$PROJECT_PATH" "$LANG_EDITION" "$SLUG"
  echo "LIMET-INDEX update complete for '$PROJECT_PATH' (collection: CRB_$SLUG)."
fi

# --- instructions -----------------------------------------------------------------------------

if [ "$COMMAND" = "instructions" ]; then
  write_instruction_files "$PROJECT_PATH" "$LANG_EDITION" "$SLUG"
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
