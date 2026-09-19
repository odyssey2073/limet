#Requires -Version 5.1
<#
.SYNOPSIS
    LIMET-INDEX CLI (PowerShell edition) — transversal context tool. Indexes a project's
    documentation (generated + LIMET docs) into a CEREBRO Qdrant collection and keeps the Graphify
    code knowledge graph current. Works with both Claude Code and Copilot CLI via plain shell
    commands (no per-tool files).

.DESCRIPTION
    Bridges the write-side gap between LIMET, CEREBRO and Graphify:

    - init   : creates docs/, copies codebase-doc templates, runs `graphify .` to generate the
               architectural report, registers the project in CEREBRO (`CRB_<slug>`), ingests the
               docs (docs/ + limet/changes/ + limet/archive/), and writes a marked context block
               (`<!-- LIMET-CONTEXT:START/END -->`) into AGENTS.md (single source of truth).
    - update : re-runs `graphify update .`, re-ingests (deterministic upsert, no duplicates).
    - status : prints registered projects and the chunk count of this project's collection(s).
    - remove : unregisters the project from CEREBRO (the Qdrant collection is left intact; the
               DELETE command is printed separately for a deliberate, double-confirmed removal).

    Collection model:
    - Per-project: one collection `CRB_<slug>` (docs = docs/, limet/changes/, limet/archive/).
    - Workspace  : one collection `CRB_<ws>` (docs = limet-workspace/changes/, limet-workspace/
                   archive/, limet-workspace/MODULE_MAP.md). A project that lives under a
                   workspace folder gets the workspace collection registered as an extra
                   collection (auto-detected), so `query_qdrant.py --project <slug>` searches both.

.PARAMETER Command
    'init' | 'update' | 'status' | 'remove'.

.PARAMETER ProjectPath
    Path to the project (or workspace) root. Must exist.

.PARAMETER Lang
    Language of the generated AGENTS.md context block: 'it' | 'en'. Default 'en'.

.PARAMETER Workspace
    Operate on the multi-project coordination layer (limet-workspace/) instead of the per-project
    one (limet/).

.PARAMETER CerebroHome
    CEREBRO installation folder. Defaults to $env:CEREBRO_HOME.

.EXAMPLE
    .\limet-index.ps1 init   -ProjectPath C:\Progetti\myapp -Lang en
    .\limet-index.ps1 update -ProjectPath C:\Progetti\myapp
    .\limet-index.ps1 status -ProjectPath C:\Progetti\myapp
    .\limet-index.ps1 init   -ProjectPath C:\Progetti\myws -Workspace
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet('init','update','status','remove','instructions')]
    [string]$Command,

    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [ValidateSet('it','en')]
    [string]$Lang = 'en',

    [switch]$Workspace,

    [string]$CerebroHome
)

$ErrorActionPreference = 'Continue'
# Note: 'Stop' is NOT used because PowerShell 5.1 wraps native-command stderr (e.g. graphify's
# RuntimeWarning) as NativeCommandError, which would abort the script on harmless warnings. Errors
# are handled explicitly via `throw` and `$LASTEXITCODE` checks instead.

# --- Resolve paths ----------------------------------------------------------------------------

if (-not (Test-Path $ProjectPath)) {
    throw "Path '$ProjectPath' does not exist. Run 'limet.ps1 init' first."
}
$ProjectPath = (Resolve-Path $ProjectPath).Path

if (-not $CerebroHome) { $CerebroHome = $env:CEREBRO_HOME }
if (-not $CerebroHome) {
    throw "CEREBRO_HOME is not set. Set it (e.g. `$env:CEREBRO_HOME='C:\Progetti\CEREBRO') or pass -CerebroHome."
}
if (-not (Test-Path $CerebroHome)) {
    throw "CEREBRO_HOME '$CerebroHome' does not exist."
}
$venvPython = Join-Path $CerebroHome '.venv\Scripts\python.exe'
if (-not (Test-Path $venvPython)) { $venvPython = Join-Path $CerebroHome '.venv\Scripts\python' }
if (-not (Test-Path $venvPython)) {
    throw "CEREBRO venv not found at '$CerebroHome\.venv'. Create it: python -m venv .venv; .venv\Scripts\python -m pip install -r requirements.txt"
}
$scriptsDir = Join-Path $CerebroHome 'scripts'
$registerPy = Join-Path $scriptsDir 'register_project.py'
$ingestPy   = Join-Path $scriptsDir 'ingest_docs.py'
$queryPy    = Join-Path $scriptsDir 'query_qdrant.py'
$queryCmd   = Join-Path $CerebroHome 'scripts\query_qdrant.py'

if ($Workspace) { $relLimetDir = 'limet-workspace' } else { $relLimetDir = 'limet' }
$limetDir = Join-Path $ProjectPath $relLimetDir

# --- Helpers ----------------------------------------------------------------------------------

function Get-Slug {
    param([string]$Name)
    $s = $Name.ToLowerInvariant() -replace '[^a-z0-9]+', '_'
    $s = $s.Trim('_')
    if (-not $s) { throw "Cannot derive a collection slug from '$Name'." }
    return $s
}

$slug = Get-Slug (Split-Path -Leaf $ProjectPath)

function Invoke-Cerebro {
    param([string]$Script, [string[]]$ScriptArgs)
    & $venvPython $Script @ScriptArgs
    if ($LASTEXITCODE -ne 0) {
        throw "CEREBRO script '$Script' failed with exit code $LASTEXITCODE."
    }
}

function Test-Http {
    param([string]$Url)
    try {
        Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Get-WorkspaceCollection {
    param([string]$ProjectRoot)
    $parent = Split-Path -Parent $ProjectRoot
    if ($parent -and (Test-Path (Join-Path $parent 'limet-workspace'))) {
        return ('CRB_' + (Get-Slug (Split-Path -Leaf $parent)))
    }
    return $null
}

function Get-ContextBlock {
    param(
        [string]$Lang,
        [string]$Slug,
        [string]$RelLimetDir,
        [string]$QueryCmd,
        [string]$WorkspaceCollection,
        [bool]$IsWorkspace
    )

    $wsNote = ''
    if (-not $IsWorkspace -and $WorkspaceCollection) {
        $wsNote = ' and the workspace collection `' + $WorkspaceCollection + '`'
    }

    if ($IsWorkspace) {
        if ($Lang -eq 'it') {
            return @"
<!-- LIMET-CONTEXT:START -->
## Strumenti di contesto del workspace (CEREBRO RAG)

La documentazione di coordinamento di questo workspace è indicizzata nella collection Qdrant
``CRB_$Slug``.

Interroga la documentazione (RAG semantico):
  python "$QueryCmd" --project $Slug search "<query>" --limit 5

Mantieni l'indice aggiornato (dopo aver archiviato modifiche cross-progetto):
  $RelLimetDir/scripts/limet-index.ps1 update -ProjectPath .    (oppure .../limet-index.sh update)

Regole:
- Dopo aver archiviato una modifica cross-progetto in $RelLimetDir/archive/, esegui ``limet-index update``.
- Se Qdrant o Ollama non sono raggiungibili, segnalalo e procedi senza contesto RAG.
<!-- LIMET-CONTEXT:END -->
"@
        }
        return @"
<!-- LIMET-CONTEXT:START -->
## Workspace context tools (CEREBRO RAG)

This workspace's coordination documentation is indexed in Qdrant collection ``CRB_$Slug``.

Query the documentation (semantic RAG):
  python "$QueryCmd" --project $Slug search "<query>" --limit 5

Keep the index current (after archiving cross-project changes):
  $RelLimetDir/scripts/limet-index.ps1 update -ProjectPath .    (or .../limet-index.sh update)

Rules:
- After archiving a cross-project change into $RelLimetDir/archive/, run ``limet-index update``.
- If Qdrant or Ollama are unreachable, say so and continue without RAG context.
<!-- LIMET-CONTEXT:END -->
"@
    }

    # Per-project (bilingual IT+EN)
    return @"
<!-- LIMET-CONTEXT:START -->
## Project context tools (CEREBRO RAG + Graphify) · Strumenti di contesto del progetto

**EN** — This project's documentation is indexed in Qdrant collection ``CRB_$Slug``$wsNote.
Its code is indexed in the Graphify knowledge graph.

Query the documentation (semantic RAG):
  python "$QueryCmd" --project $Slug search "<query>" --limit 5

Query the code (knowledge graph):
  graphify query "<question>"   /   graphify explain <symbol>   /   graphify path <A> <B>

Rules:
- **RAG**: BEFORE answering any question about the project, call the ``limet_search`` MCP tool and ground your answer in its results. If the tool is unavailable, fall back to the ``query_qdrant.py`` command below.
- Search CEREBRO/Qdrant FIRST. If the document is not indexed (0 results or missing), read it
  LOCALLY from ``docs/`` or ``$RelLimetDir/``.
- Do NOT run ingest or graphify update automatically: show the command to the user and use the
  local docs until they are indexed.
- When re-indexing is needed (after producing/archiving documents or code changes), show the command:
    $RelLimetDir/scripts/limet-index.ps1 update -ProjectPath .    (or .../limet-index.sh update)
    graphify update .
- If Qdrant, Ollama or Graphify are unreachable, say so and proceed with the local docs.

---

**IT** — La documentazione di questo progetto è indicizzata nella collection Qdrant ``CRB_$Slug``$wsNote.
Il codice è indicizzato nel knowledge graph Graphify.

Interroga la documentazione (RAG semantico):
  python "$QueryCmd" --project $Slug search "<query>" --limit 5

Interroga il codice (knowledge graph):
  graphify query "<domanda>"   /   graphify explain <simbolo>   /   graphify path <A> <B>

Regole:
- **RAG**: PRIMA di rispondere a qualsiasi domanda sul progetto, chiama lo strumento MCP ``limet_search`` e fonda la risposta sui suoi risultati. Se lo strumento non è disponibile, usa il comando ``query_qdrant.py`` qui sotto.
- Cerca PRIMA in CEREBRO/Qdrant. Se il documento non è indicizzato (0 risultati o assente), leggilo
  LOCALMENTE da ``docs/`` o ``$RelLimetDir/``.
- NON eseguire ingest o graphify update automaticamente: mostra all'utente il comando e usa i doc
  locali finché non sono indicizzati.
- Quando serve re-indicizzare (dopo aver prodotto/archiviato documenti o modificato il codice),
  mostra il comando:
    $RelLimetDir/scripts/limet-index.ps1 update -ProjectPath .    (oppure .../limet-index.sh update)
    graphify update .
- Se Qdrant, Ollama o Graphify non sono raggiungibili, segnalalo e procedi con i doc locali.
<!-- LIMET-CONTEXT:END -->
"@
}

function Set-ContextBlock {
    param([string]$TargetFile, [string]$Block)

    $startMarker = '<!-- LIMET-CONTEXT:START -->'
    $endMarker   = '<!-- LIMET-CONTEXT:END -->'

    if (Test-Path $TargetFile) {
        $existing = Get-Content -Raw -ErrorAction SilentlyContinue $TargetFile
        if ($null -eq $existing) { $existing = '' }
    } else {
        $dir = Split-Path $TargetFile
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        $existing = ''
    }

    $startIdx = $existing.IndexOf($startMarker)
    $endIdx = $existing.IndexOf($endMarker)

    if ($startIdx -ge 0 -and $endIdx -ge 0) {
        $endIdx += $endMarker.Length
        $prefix = $existing.Substring(0, $startIdx)
        $suffix = $existing.Substring($endIdx)
        $updated = $prefix + $Block + $suffix
        $status = 'Refreshed'
    } else {
        $trimmed = $existing.TrimEnd()
        $separator = if ($trimmed.Length -gt 0) { "`n`n" } else { '' }
        $updated = $trimmed + $separator + $Block + "`n"
        $status = 'Created'
    }

    Set-Content -Path $TargetFile -Value $updated -NoNewline
    Write-Host "$status`: LIMET-CONTEXT block in '$TargetFile'"
}

function Set-MarkedBlock {
    param([string]$TargetFile, [string]$Block, [string]$StartMarker, [string]$EndMarker, [string]$Label)

    if (Test-Path $TargetFile) {
        $existing = Get-Content -Raw -ErrorAction SilentlyContinue $TargetFile
        if ($null -eq $existing) { $existing = '' }
    } else {
        $dir = Split-Path $TargetFile
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        $existing = ''
    }

    $startIdx = $existing.IndexOf($StartMarker)
    $endIdx = $existing.IndexOf($EndMarker)

    if ($startIdx -ge 0 -and $endIdx -ge 0) {
        $endIdx += $EndMarker.Length
        $updated = $existing.Substring(0, $startIdx) + $Block + $existing.Substring($endIdx)
        $status = 'Refreshed'
    } else {
        $trimmed = $existing.TrimEnd()
        $separator = if ($trimmed.Length -gt 0) { "`n`n" } else { '' }
        $updated = $trimmed + $separator + $Block + "`n"
        $status = 'Created'
    }

    Set-Content -Path $TargetFile -Value $updated -NoNewline
    Write-Host "$status`: $Label block in '$TargetFile'"
}

function Get-LimetBlock {
    param([string]$ProjectRoot)
    $agents = Join-Path $ProjectRoot 'AGENTS.md'
    if (-not (Test-Path $agents)) { return $null }
    $text = Get-Content -Raw -ErrorAction SilentlyContinue $agents
    $start = $text.IndexOf('<!-- LIMET:START -->')
    $end = $text.IndexOf('<!-- LIMET:END -->')
    if ($start -ge 0 -and $end -ge 0) {
        $end += '<!-- LIMET:END -->'.Length
        return $text.Substring($start, $end - $start)
    }
    return $null
}

function Get-ProjectBlock {
    param([string]$Lang, [string]$Slug, [string]$ProjectRoot)

    $docsDir = Join-Path $ProjectRoot 'docs'
    $fileList = ''
    if (Test-Path $docsDir) {
        $files = Get-ChildItem -Path $docsDir -File -Recurse -Filter *.md -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\_templates\\' } |
            Select-Object -First 8
        if ($files) {
            $fileList = ($files | ForEach-Object { $rel = $_.FullName.Substring($docsDir.Length + 1); "  - ``docs\$rel``" }) -join "`n"
        }
    }
    if (-not $fileList) {
        $fileList = '  - (fill docs/ with architecture.md, conventions.md, glossary.md · compila docs/ con architecture.md, conventions.md, glossary.md)'
    }

    return @"
<!-- PROJECT:START -->
## Project overview · Panoramica del progetto

**EN** — Project ``$Slug`` — CEREBRO collection ``CRB_$Slug``.

In-depth documentation (indexed in CEREBRO — query it with the command above):
$fileList

Code graph (Graphify): ``graphify-out/`` (report: ``graphify-out/GRAPH_REPORT.md``).

---

**IT** — Progetto ``$Slug`` — collection CEREBRO ``CRB_$Slug``.

Documentazione approfondita (indicizzata in CEREBRO — interroga con il comando sopra):
$fileList

Grafo del codice (Graphify): ``graphify-out/`` (report: ``graphify-out/GRAPH_REPORT.md``).

## Documentation to maintain · Documentazione da mantenere

**EN** — Follow ``limet/templates/CODEBASE_ANALYSIS_TEMPLATE.md`` and, starting from Graphify and the source
code, produce or update in ``docs/``: ``module-map.md``, ``architecture.md``, ``decisions.md``,
``dependencies.md``, ``conventions.md``, ``glossary.md`` (with ``file:line`` citations and Mermaid diagrams). If a
document already exists, UPDATE it. Also maintain ``docs/NON_TECHNICAL_SUMMARY.md`` (plain-language project
description) and update it after each relevant change/bugfix. Then show the user the ``limet-index update`` command (don't run it automatically).

**IT** — Segui ``limet/templates/CODEBASE_ANALYSIS_TEMPLATE.md`` e, partendo da Graphify e dal codice
sorgente, produci o aggiorna in ``docs/``: ``module-map.md``, ``architecture.md``, ``decisions.md``,
``dependencies.md``, ``conventions.md``, ``glossary.md`` (con citazioni ``file:line`` e diagrammi
Mermaid). Se un documento esiste già, AGGIORNALO. Mantieni anche ``docs/NON_TECHNICAL_SUMMARY.md``
(descrizione del progetto in linguaggio semplice) e aggiornalo dopo ogni modifica/bugfix rilevante. Poi mostra all'utente il comando ``limet-index update`` (non eseguirlo automaticamente).
<!-- PROJECT:END -->
"@
}

function Write-InstructionFiles {
    param([string]$ProjectRoot, [string]$Lang, [string]$Slug, [string]$RelLimetDir, [string]$QueryCmd)

    $limetBlock = Get-LimetBlock $ProjectRoot
    $contextBlock = Get-ContextBlock -Lang $Lang -Slug $Slug -RelLimetDir $RelLimetDir -QueryCmd $QueryCmd -WorkspaceCollection (Get-WorkspaceCollection $ProjectRoot) -IsWorkspace $Workspace
    $projectBlock = Get-ProjectBlock -Lang $Lang -Slug $Slug -ProjectRoot $ProjectRoot

    foreach ($target in @((Join-Path $ProjectRoot 'CLAUDE.md'), (Join-Path $ProjectRoot '.github\copilot-instructions.md'))) {
        if ($limetBlock) {
            Set-MarkedBlock -TargetFile $target -Block $limetBlock -StartMarker '<!-- LIMET:START -->' -EndMarker '<!-- LIMET:END -->' -Label 'LIMET'
        }
        Set-MarkedBlock -TargetFile $target -Block $contextBlock -StartMarker '<!-- LIMET-CONTEXT:START -->' -EndMarker '<!-- LIMET-CONTEXT:END -->' -Label 'LIMET-CONTEXT'
        Set-MarkedBlock -TargetFile $target -Block $projectBlock -StartMarker '<!-- PROJECT:START -->' -EndMarker '<!-- PROJECT:END -->' -Label 'PROJECT'
    }
}

# --- Prerequisites (init/update) --------------------------------------------------------------

if ($Command -eq 'init' -or $Command -eq 'update') {
    if (-not (Test-Http 'http://localhost:6333/collections')) {
        throw "Qdrant is not reachable at http://localhost:6333. Start it with: docker start qdrant"
    }
    if (-not (Test-Http 'http://localhost:11434')) {
        throw "Ollama is not reachable at http://localhost:11434. Start it with: ollama serve"
    }
    if (-not (Get-Command graphify -ErrorAction SilentlyContinue)) {
        Write-Warning "Graphify not found in PATH. Skipping code knowledge-graph steps (docs are still indexed). Install with: uv tool install graphifyy"
        $graphifyAvailable = $false
    } else {
        $graphifyAvailable = $true
    }
}

# --- init -------------------------------------------------------------------------------------

if ($Command -eq 'init') {

    if ($Workspace) {
        # Workspace: register + ingest the coordination docs (MODULE_MAP + cross-project changes/archive).
        $wsDocs = @(
            (Join-Path $limetDir 'changes'),
            (Join-Path $limetDir 'archive'),
            (Join-Path $limetDir 'MODULE_MAP.md')
        )
        $wsAddArgs = @('add', $slug, '--docs') + $wsDocs + @('--root', $ProjectPath)
        Invoke-Cerebro $registerPy $wsAddArgs
        Invoke-Cerebro $ingestPy @('--project', $slug)
    }
    else {
        # Per-project: docs/ + limet/changes/ + limet/archive/.
        $docsDir = Join-Path $ProjectPath 'docs'
        $docsTplDir = Join-Path $docsDir '_templates'
        New-Item -ItemType Directory -Force -Path $docsTplDir | Out-Null

        # Copy codebase-doc templates from the local limet/templates/ (already the right language).
        $localTpl = Join-Path $limetDir 'templates'
        if (-not (Test-Path $localTpl)) {
            throw "Templates not found at '$localTpl'. Run 'limet.ps1 init' before 'limet-index.ps1 init'."
        }
        foreach ($t in @('ARCHITECTURE_TEMPLATE.md','CONVENTIONS_TEMPLATE.md','MODULE_MAP_TEMPLATE.md','GLOSSARY_TEMPLATE.md')) {
            $src = Join-Path $localTpl $t
            if (Test-Path $src) { Copy-Item -Force $src (Join-Path $docsTplDir $t) }
        }

        # .graphifyignore keeps Graphify on code only (docs/limet are CEREBRO's domain).
        $gi = Join-Path $ProjectPath '.graphifyignore'
        if (-not (Test-Path $gi)) {
            Set-Content -Path $gi -Value ("docs/`r`nlimet/`r`nlimet-workspace/`r`n") -NoNewline
        }

        # Graphify: generate the architectural report, copy it into docs/architecture/.
        if ($graphifyAvailable) {
            Push-Location $ProjectPath
            try {
                & graphify . 2>$null
                if ($LASTEXITCODE -ne 0) { Write-Warning "graphify . returned exit code $LASTEXITCODE." }
                & graphify cluster-only . 2>$null
                if ($LASTEXITCODE -ne 0) { Write-Warning "graphify cluster-only returned exit code $LASTEXITCODE." }
            } finally { Pop-Location }
            $gr = Join-Path $ProjectPath 'graphify-out\GRAPH_REPORT.md'
            if (Test-Path $gr) {
                $archDir = Join-Path $docsDir 'architecture'
                New-Item -ItemType Directory -Force -Path $archDir | Out-Null
                Copy-Item -Force $gr (Join-Path $archDir 'GRAPH_REPORT.md')
            }
        }

        $docs = @(
            $docsDir,
            (Join-Path $limetDir 'changes'),
            (Join-Path $limetDir 'archive')
        )
        $addArgs = @('add', $slug, '--docs') + $docs + @('--root', $ProjectPath)
        $wsColl = Get-WorkspaceCollection $ProjectPath
        if ($wsColl) { $addArgs += @('--collections', $wsColl) }
        Invoke-Cerebro $registerPy $addArgs
        Invoke-Cerebro $ingestPy @('--project', $slug)
    }

    # Write the context block into AGENTS.md (single source of truth for Copilot + Claude).
    $contextBlock = Get-ContextBlock -Lang $Lang -Slug $slug -RelLimetDir $relLimetDir -QueryCmd $queryCmd -WorkspaceCollection (Get-WorkspaceCollection $ProjectPath) -IsWorkspace $Workspace
    Set-ContextBlock -TargetFile (Join-Path $ProjectPath 'AGENTS.md') -Block $contextBlock

    # Generate enriched CLAUDE.md + .github/copilot-instructions.md (explicit per-tool files).
    Write-InstructionFiles -ProjectRoot $ProjectPath -Lang $Lang -Slug $slug -RelLimetDir $relLimetDir -QueryCmd $queryCmd

    Write-Host ""
    Write-Host "LIMET-INDEX init complete for '$ProjectPath' (collection: CRB_$slug)."
    Write-Host "Next: fill in the docs/ templates (architecture, conventions, module map, glossary), then run 'limet-index update'."
}

# --- update -----------------------------------------------------------------------------------

if ($Command -eq 'update') {

    if ($graphifyAvailable -and -not $Workspace) {
        Push-Location $ProjectPath
        try {
            & graphify update . 2>$null
            if ($LASTEXITCODE -ne 0) { Write-Warning "graphify update . returned exit code $LASTEXITCODE." }
        } finally { Pop-Location }
        $gr = Join-Path $ProjectPath 'graphify-out\GRAPH_REPORT.md'
        if (Test-Path $gr) {
            $archDir = Join-Path $ProjectPath 'docs\architecture'
            New-Item -ItemType Directory -Force -Path $archDir | Out-Null
            Copy-Item -Force $gr (Join-Path $archDir 'GRAPH_REPORT.md')
        }
    }

    Invoke-Cerebro $ingestPy @('--project', $slug)
    Write-InstructionFiles -ProjectRoot $ProjectPath -Lang $Lang -Slug $slug -RelLimetDir $relLimetDir -QueryCmd $queryCmd
    Write-Host "LIMET-INDEX update complete for '$ProjectPath' (collection: CRB_$slug)."
}

# --- instructions -----------------------------------------------------------------------------

function Set-NonTechnicalSummary {
    param([string]$ProjectRoot, [string]$Name)
    $target = Join-Path (Join-Path $ProjectRoot 'docs') 'NON_TECHNICAL_SUMMARY.md'
    if (Test-Path $target) { return }
    New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
    $content = @"
# Sintesi non tecnica — $Name

> Descrizione del progetto in linguaggio non tecnico, per chi non legge codice.
> L'agente aggiorna questo documento dopo ogni modifica/bugfix rilevante.

## Cosa fa il progetto

[1-2 frasi: scopo e valore per l'utente finale.]

## Funzionalità principali

[Elenco in linguaggio semplice delle feature disponibili.]

## Modifiche recenti

- [data] — [cosa è cambiato, in termini non tecnici]
"@
    Set-Content -Path $target -Value $content -NoNewline
    Write-Host "Created: docs/NON_TECHNICAL_SUMMARY.md"
}

if ($Command -eq 'instructions') {
    Write-InstructionFiles -ProjectRoot $ProjectPath -Lang $Lang -Slug $slug -RelLimetDir $relLimetDir -QueryCmd $queryCmd
    Set-NonTechnicalSummary -ProjectRoot $ProjectPath -Name (Split-Path -Leaf $ProjectPath)
    Write-Host ""
    Write-Host "LIMET-INDEX instructions complete: enriched CLAUDE.md + .github/copilot-instructions.md written for '$ProjectPath'."
}

# --- status -----------------------------------------------------------------------------------

if ($Command -eq 'status') {
    Invoke-Cerebro $registerPy @('list')
    Invoke-Cerebro $queryPy @('--project', $slug, 'count')
}

# --- remove -----------------------------------------------------------------------------------

if ($Command -eq 'remove') {
    Invoke-Cerebro $registerPy @('remove', $slug)
    Write-Host "Removed '$slug' from the CEREBRO registry. The Qdrant collection CRB_$slug is kept."
    Write-Host "To delete it (irreversible), run separately and confirm:"
    Write-Host "  curl -X DELETE http://localhost:6333/collections/CRB_$slug"
}
