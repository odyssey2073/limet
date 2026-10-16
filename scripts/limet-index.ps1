#Requires -Version 5.1
<#
.SYNOPSIS
    LIMET-INDEX CLI (PowerShell edition) — transversal context tool. Indexes a project's
    documentation (generated + LIMET docs) into a CEREBRO Qdrant collection and keeps the Graphify
    code knowledge graph current. Works with both Claude Code and Copilot CLI via plain shell
    commands (no per-tool files).

.DESCRIPTION
    Bridges the write-side gap between LIMET, CEREBRO and Graphify:

    - init   : creates docs/, copies codebase-doc templates, runs `graphify extract . --code-only` to generate the
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
                   archive/, limet-workspace/MODULE_MAP.md, docs/), plus a root code graph. A project that lives under a
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

.PARAMETER Force
    (update only) Ignore ingest_docs.py's local cache and re-embed every file, even if unchanged.

.PARAMETER Prune
    (update only, off by default) Also remove indexed chunks for files deleted/moved since the
    last run. Nothing is ever deleted from Qdrant unless this switch is passed.

.EXAMPLE
    .\limet-index.ps1 init   -ProjectPath C:\Progetti\myapp -Lang en
    .\limet-index.ps1 update -ProjectPath C:\Progetti\myapp
    .\limet-index.ps1 update -ProjectPath C:\Progetti\myapp -Force
    .\limet-index.ps1 update -ProjectPath C:\Progetti\myapp -Prune
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

    [string]$CerebroHome,

    [switch]$Force,

    [switch]$Prune,

    [switch]$SkipGraph
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

# --- LIMET docs folder resolution ---------------------------------------------------------------
# LIMET needs a folder it owns: everything in it is indexed into the vector DB and listed in the
# PROJECT block. That folder is 'docs-limet' and is not configurable -- projects very often already
# use docs/ for their own material (API specs, build files, binaries) that must NOT be indexed, so
# LIMET simply stays out of docs/ and never touches it.
#
# Resolution order (project mode):
#   1. the folder already registered in CEREBRO's projects.json for this slug, so projects created
#      before this convention keep working untouched
#   2. an existing 'docs-limet' folder
#   3. an existing 'docs' folder that looks LIMET-owned (templates / graph report / summary), for
#      projects set up before this convention but never registered in CEREBRO
#   4. 'docs-limet'
# Workspace mode always uses 'docs': the workspace root is a LIMET-owned coordination tree, not a
# project tree, so there is no foreign docs/ to stay clear of.
$DefaultDocsDir = 'docs-limet'

function Get-RegisteredDocsDir {
    param([string]$CerebroHome, [string]$Slug, [string]$ProjectPath)

    $reg = Join-Path $CerebroHome 'projects.json'
    if (-not (Test-Path $reg)) { return $null }
    try {
        $entry = (Get-Content $reg -Raw -ErrorAction Stop | ConvertFrom-Json).$Slug
    } catch { return $null }
    if (-not $entry -or -not $entry.docs) { return $null }

    $rootFull = (Resolve-Path $ProjectPath).Path.TrimEnd('\')
    foreach ($d in $entry.docs) {
        if (-not $d) { continue }
        $p = $d.TrimEnd('\')
        # Keep only direct children of the project root, skipping LIMET's own folders.
        if ($p -like "$rootFull\*") {
            $rel = $p.Substring($rootFull.Length + 1)
            if ($rel -notmatch '[\\/]' -and $rel -notin @('limet','limet-workspace')) { return $rel }
        }
    }
    return $null
}

# Tells a LIMET-generated docs/ apart from a project's own docs/, for pre-convention setups that
# were never registered in CEREBRO. Only LIMET writes these.
function Test-LimetOwnedDocs {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    foreach ($marker in @('_templates', 'architecture\GRAPH_REPORT.md', 'NON_TECHNICAL_SUMMARY.md')) {
        if (Test-Path (Join-Path $Path $marker)) { return $true }
    }
    return $false
}

if ($Workspace) {
    $relDocsDir = 'docs'
} else {
    $registered = Get-RegisteredDocsDir -CerebroHome $CerebroHome -Slug $slug -ProjectPath $ProjectPath
    if ($registered) {
        $relDocsDir = $registered
    } elseif (Test-Path (Join-Path $ProjectPath $DefaultDocsDir)) {
        $relDocsDir = $DefaultDocsDir
    } elseif (Test-LimetOwnedDocs (Join-Path $ProjectPath 'docs')) {
        $relDocsDir = 'docs'
    } else {
        $relDocsDir = $DefaultDocsDir
    }
}
$docsRoot = Join-Path $ProjectPath $relDocsDir

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

Regole:
- Il re-index e gli aggiornamenti Graphify spettano all'utente, mai all'agente.
- **Domande sul codice** (dov'è implementato X, chi usa Y, come funziona il flusso Z): PRIMA
  interroga il grafo con ``graphify query "<domanda>" --graph graphify-out/graph.json`` (oppure
  ``graphify explain <simbolo>`` / ``graphify path <A> <B>``, stesso ``--graph``); POI conferma
  righe e usi esatti con una ricerca testuale mirata per modulo (grep). Non partire direttamente da grep.
- Dopo modifiche a codice/documenti, ricordare periodicamente all'utente (al termine di un task
  o dell'archiviazione): Launcher -> Percorso workspace -> Re-index -> Incrementale -> clic Re-index.
- Ricordare di aggiornare anche gli indici dei progetti coinvolti selezionandone i percorsi.
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

Rules:
- Re-indexing and Graphify updates belong to the user, never the agent.
- **Code questions** (where is X implemented, who uses Y, how does flow Z work): FIRST query the
  graph with ``graphify query "<question>" --graph graphify-out/graph.json`` (or
  ``graphify explain <symbol>`` / ``graphify path <A> <B>``, same ``--graph``); THEN confirm exact
  lines and usages with a targeted text search per module (grep). Do not start directly from grep.
- After code/document changes, periodically remind the user (at task completion or archiving):
  Launcher -> workspace path -> Re-index -> Incrementale -> click Re-index.
- Also remind the user to update affected projects by selecting their paths.
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
  LOCALLY from ``$relDocsDir/`` or ``$RelLimetDir/``.
- Re-indexing and Graphify updates belong to the user, never the agent. Use local docs until indexed.
- **Code questions** (where is X implemented, who uses Y, how does flow Z work): FIRST use
  ``graphify query`` / ``graphify explain`` / ``graphify path``; THEN confirm exact lines and usages
  with a targeted text search (grep). Do not start directly from grep.
- After code/document changes, periodically remind the user (at task completion or archiving):
  Launcher -> project path -> Re-index -> Incrementale -> click Re-index.
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
  LOCALMENTE da ``$relDocsDir/`` o ``$RelLimetDir/``.
- Il re-index e gli aggiornamenti Graphify spettano all'utente, mai all'agente. Usa i doc locali
  finché non sono indicizzati.
- **Domande sul codice** (dov'è implementato X, chi usa Y, come funziona il flusso Z): PRIMA usa
  ``graphify query`` / ``graphify explain`` / ``graphify path``; POI conferma righe e usi esatti con
  una ricerca testuale mirata (grep). Non partire direttamente da grep.
- Dopo modifiche a codice/documenti, ricordare periodicamente all'utente (al termine di un task
  o dell'archiviazione): Launcher -> Percorso progetto -> Re-index -> Incrementale -> clic Re-index.
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
    if ($null -eq $text) { return $null }
    $startMarker = if ($Workspace) { '<!-- LIMET-WORKSPACE:START -->' } else { '<!-- LIMET:START -->' }
    $endMarker = if ($Workspace) { '<!-- LIMET-WORKSPACE:END -->' } else { '<!-- LIMET:END -->' }
    $start = $text.IndexOf($startMarker)
    $end = $text.IndexOf($endMarker)
    if ($start -ge 0 -and $end -ge 0) {
        $end += $endMarker.Length
        return $text.Substring($start, $end - $start)
    }
    return $null
}

function Get-ProjectBlock {
    param([string]$Lang, [string]$Slug, [string]$ProjectRoot)

    $docsDir = Join-Path $ProjectRoot $relDocsDir
    $fileList = ''
    if (Test-Path $docsDir) {
        $files = Get-ChildItem -Path $docsDir -File -Recurse -Filter *.md -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\_templates\\' } |
            Sort-Object FullName
        if ($files) {
            $fileList = ($files | ForEach-Object { $rel = $_.FullName.Substring($docsDir.Length + 1); "  - ``$relDocsDir\$rel``" }) -join "`n"
        }
    }
    if (-not $fileList) {
        $fileList = "  - (fill $relDocsDir/ with architecture.md, conventions.md, glossary.md · compila $relDocsDir/ con architecture.md, conventions.md, glossary.md)"
    }
    if ($Workspace) {
        $graphEn = 'Workspace code graph (Graphify): `graphify-out/graph.json`; report: `docs/architecture/GRAPH_REPORT.md`.'
        $graphIt = 'Grafo del codice workspace (Graphify): `graphify-out/graph.json`; report: `docs/architecture/GRAPH_REPORT.md`.'
        $maintenanceEn = 'Maintain limet-workspace/MODULE_MAP.md and cross-project changes using limet-workspace/templates/. Keep each project''s plans, tasks and verification records aligned. Re-indexing belongs to the user, never the agent. After code/document changes, periodically remind the user (at task completion or archiving): Launcher -> workspace path -> Re-index -> Incrementale -> click Re-index. Also remind them to update affected projects.'
        $maintenanceIt = 'Mantieni limet-workspace/MODULE_MAP.md e le modifiche cross-progetto usando limet-workspace/templates/. Mantieni allineati piani, task e verifiche nei singoli progetti. Il re-index spetta all''utente, mai all''agente. Dopo modifiche a codice/documenti, ricordarlo periodicamente (al termine di un task o dell''archiviazione): Launcher -> Percorso workspace -> Re-index -> Incrementale -> clic Re-index. Ricordare anche gli indici dei progetti coinvolti.'
    } else {
        $graphEn = 'Code graph (Graphify): `graphify-out/` (report: `graphify-out/GRAPH_REPORT.md`).'
        $graphIt = 'Grafo del codice (Graphify): `graphify-out/` (report: `graphify-out/GRAPH_REPORT.md`).'
        $maintenanceEn = "Follow limet/templates/CODEBASE_ANALYSIS_TEMPLATE.md to maintain $relDocsDir/module-map.md, architecture.md, decisions.md, dependencies.md, conventions.md and glossary.md with file:line citations and Mermaid diagrams. UPDATE existing documents. Maintain $relDocsDir/NON_TECHNICAL_SUMMARY.md after relevant changes. Re-indexing belongs to the user, never the agent. After code/document changes, periodically remind the user (at task completion or archiving): Launcher -> project path -> Re-index -> Incrementale -> click Re-index."
        $maintenanceIt = "Segui limet/templates/CODEBASE_ANALYSIS_TEMPLATE.md per mantenere $relDocsDir/module-map.md, architecture.md, decisions.md, dependencies.md, conventions.md e glossary.md con citazioni file:line e diagrammi Mermaid. AGGIORNA i documenti esistenti. Mantieni $relDocsDir/NON_TECHNICAL_SUMMARY.md dopo modifiche rilevanti. Il re-index spetta all'utente, mai all'agente. Dopo modifiche a codice/documenti, ricordarlo periodicamente (al termine di un task o dell'archiviazione): Launcher -> Percorso progetto -> Re-index -> Incrementale -> clic Re-index."
    }

    return @"
<!-- PROJECT:START -->
## Project overview · Panoramica del progetto

**EN** — Project ``$Slug`` — CEREBRO collection ``CRB_$Slug``.

Complete local Markdown inventory under $relDocsDir/ (excluding _templates; not proof of indexing):
$fileList

For indexed sources, consult CEREBRO's projects.json and query the collection above.

$graphEn

---

**IT** — Progetto ``$Slug`` — collection CEREBRO ``CRB_$Slug``.

Inventario locale completo dei Markdown in $relDocsDir/ (esclusi _templates; non attesta l'indicizzazione):
$fileList

Per le fonti indicizzate, consulta projects.json di CEREBRO e interroga la collection indicata sopra.

$graphIt

## Documentation to maintain · Documentazione da mantenere

**EN** — $maintenanceEn

**IT** — $maintenanceIt
<!-- PROJECT:END -->
"@
}

function Write-InstructionFiles {
    param([string]$ProjectRoot, [string]$Lang, [string]$Slug, [string]$RelLimetDir, [string]$QueryCmd)

    $limetBlock = Get-LimetBlock $ProjectRoot
    $contextBlock = Get-ContextBlock -Lang $Lang -Slug $Slug -RelLimetDir $RelLimetDir -QueryCmd $QueryCmd -WorkspaceCollection (Get-WorkspaceCollection $ProjectRoot) -IsWorkspace $Workspace
    $projectBlock = Get-ProjectBlock -Lang $Lang -Slug $Slug -ProjectRoot $ProjectRoot

    $startMarker = if ($Workspace) { '<!-- LIMET-WORKSPACE:START -->' } else { '<!-- LIMET:START -->' }
    $endMarker = if ($Workspace) { '<!-- LIMET-WORKSPACE:END -->' } else { '<!-- LIMET:END -->' }
    foreach ($target in @((Join-Path $ProjectRoot 'AGENTS.md'), (Join-Path $ProjectRoot 'CLAUDE.md'), (Join-Path $ProjectRoot '.github\copilot-instructions.md'))) {
        if ($limetBlock) {
            Set-MarkedBlock -TargetFile $target -Block $limetBlock -StartMarker $startMarker -EndMarker $endMarker -Label 'LIMET'
        }
        Set-MarkedBlock -TargetFile $target -Block $contextBlock -StartMarker '<!-- LIMET-CONTEXT:START -->' -EndMarker '<!-- LIMET-CONTEXT:END -->' -Label 'LIMET-CONTEXT'
        Set-MarkedBlock -TargetFile $target -Block $projectBlock -StartMarker '<!-- PROJECT:START -->' -EndMarker '<!-- PROJECT:END -->' -Label 'PROJECT'
    }
}

function Update-CodeGraph {
    param([string]$ProjectRoot, [bool]$Initialize)

    $ignore = Join-Path $ProjectRoot '.graphifyignore'
    if (-not (Test-Path $ignore)) {
        $ignoreDirs = @($relDocsDir)
        if ($relDocsDir -ne 'docs') { $ignoreDirs += 'docs' }
        $ignoreBody = (($ignoreDirs + @('limet','limet-workspace') | ForEach-Object { "$_/" }) + @('*.groovy')) -join "`r`n"
        Set-Content -Path $ignore -Value ($ignoreBody + "`r`n") -NoNewline -ErrorAction Stop
    }
    $graph = Join-Path $ProjectRoot 'graphify-out\graph.json'
    Push-Location $ProjectRoot
    try {
        if ($Initialize -or -not (Test-Path $graph)) {
            & graphify extract . --code-only --no-cluster
            if ($LASTEXITCODE -ne 0) { throw "graphify extract failed with exit code $LASTEXITCODE." }
        } else {
            & graphify update .
            if ($LASTEXITCODE -ne 0) { throw "graphify update failed with exit code $LASTEXITCODE." }
        }
        & graphify cluster-only . --no-label
        if ($LASTEXITCODE -ne 0) { throw "graphify cluster-only failed with exit code $LASTEXITCODE." }
    } finally { Pop-Location }
    if (-not (Test-Path $graph)) {
        throw "Graphify completed without producing '$graph'."
    }
    $report = Join-Path $ProjectRoot 'graphify-out\GRAPH_REPORT.md'
    if (Test-Path $report) {
        $archDir = Join-Path $ProjectRoot (Join-Path $relDocsDir 'architecture')
        New-Item -ItemType Directory -Force -Path $archDir -ErrorAction Stop | Out-Null
        Copy-Item -Force $report (Join-Path $archDir 'GRAPH_REPORT.md') -ErrorAction Stop
    } else {
        Write-Warning "Graphify report not found at '$report'; no report copied into docs."
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

    # LIMET owns $relDocsDir: everything inside is indexed into the vector DB. New projects get
    # 'docs-limet', which is LIMET's alone; this only triggers for pre-existing setups whose
    # registry entry still points at a folder the project also uses for its own material.
    if (-not $Workspace -and (Test-Path $docsRoot)) {
        $foreign = Get-ChildItem -Path $docsRoot -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -notin @('.md','.markdown') } |
            Select-Object -First 5
        if ($foreign) {
            $sample = ($foreign | ForEach-Object { $_.FullName.Substring($docsRoot.Length + 1) }) -join ', '
            Write-Warning @"
'$relDocsDir/' also holds non-Markdown project files (e.g. $sample).
LIMET indexes the WHOLE folder into CEREBRO, so those files would be ingested too.
LIMET's own folder is '$DefaultDocsDir/': this project is using '$relDocsDir/' because that is what
is registered in CEREBRO. To switch, move LIMET's documents into '$DefaultDocsDir/', drop the
'$relDocsDir' entry from projects.json, and re-run init followed by 'update -Prune'.
"@
        }
    }

    $docsDir = $docsRoot
    New-Item -ItemType Directory -Force -Path $docsDir | Out-Null
    if ($graphifyAvailable) {
        Update-CodeGraph -ProjectRoot $ProjectPath -Initialize $true
    }
    if ($Workspace) {
        # Workspace: register + ingest the coordination docs (MODULE_MAP + cross-project changes/archive).
        $wsDocs = @(
            (Join-Path $limetDir 'changes'),
            (Join-Path $limetDir 'archive'),
            (Join-Path $limetDir 'MODULE_MAP.md'),
            $docsDir
        )
        $wsAddArgs = @('add', $slug, '--docs') + $wsDocs + @('--root', $ProjectPath)
        Invoke-Cerebro $registerPy $wsAddArgs
        Invoke-Cerebro $ingestPy @('--project', $slug)
    }
    else {
        # Per-project: docs/ + limet/changes/ + limet/archive/.
        $docsDir = $docsRoot
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

        $docs = @(
            $docsDir,
            (Join-Path $limetDir 'changes'),
            (Join-Path $limetDir 'archive')
        )
        $addArgs = @('add', $slug, '--docs') + $docs + @('--root', $ProjectPath)
        $wsColl = Get-WorkspaceCollection $ProjectPath
        Invoke-Cerebro $registerPy $addArgs
        # Merge (never replace) the workspace collection: 'add --collections' would drop related-project links.
        if ($wsColl) {
            Invoke-Cerebro (Join-Path $PSScriptRoot 'limet_related.py') @('add-extra', '--cerebro-home', $CerebroHome, '--slug', $slug, '--collection', $wsColl)
        }
        Invoke-Cerebro $ingestPy @('--project', $slug)
    }

    # Write the context block into AGENTS.md (single source of truth for Copilot + Claude).
    $contextBlock = Get-ContextBlock -Lang $Lang -Slug $slug -RelLimetDir $relLimetDir -QueryCmd $queryCmd -WorkspaceCollection (Get-WorkspaceCollection $ProjectPath) -IsWorkspace $Workspace
    Set-ContextBlock -TargetFile (Join-Path $ProjectPath 'AGENTS.md') -Block $contextBlock

    # Generate enriched CLAUDE.md + .github/copilot-instructions.md (explicit per-tool files).
    Write-InstructionFiles -ProjectRoot $ProjectPath -Lang $Lang -Slug $slug -RelLimetDir $relLimetDir -QueryCmd $queryCmd

    Write-Host ""
    Write-Host "LIMET-INDEX init complete for '$ProjectPath' (collection: CRB_$slug)."
    Write-Host "Next: fill in the $relDocsDir/ templates (architecture, conventions, module map, glossary), then run 'limet-index update'."
}

# --- update -----------------------------------------------------------------------------------

if ($Command -eq 'update') {

    if ($graphifyAvailable -and -not $SkipGraph) {
        Update-CodeGraph -ProjectRoot $ProjectPath -Initialize $false
    }
    $docsDir = $docsRoot
    if (Test-Path $docsDir) {
        Invoke-Cerebro $registerPy @('add', $slug, '--docs', $docsDir)
    }

    $ingestArgs = @('--project', $slug)
    if ($Force) { $ingestArgs += '--force' }
    if ($Prune) { $ingestArgs += '--prune' }
    Invoke-Cerebro $ingestPy $ingestArgs
    Write-InstructionFiles -ProjectRoot $ProjectPath -Lang $Lang -Slug $slug -RelLimetDir $relLimetDir -QueryCmd $queryCmd
    Write-Host "LIMET-INDEX update complete for '$ProjectPath' (collection: CRB_$slug)."
}

# --- instructions -----------------------------------------------------------------------------

function Set-NonTechnicalSummary {
    param([string]$ProjectRoot, [string]$Name)
    $target = Join-Path (Join-Path $ProjectRoot $relDocsDir) 'NON_TECHNICAL_SUMMARY.md'
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
    Write-Host "Created: $relDocsDir/NON_TECHNICAL_SUMMARY.md"
}

if ($Command -eq 'instructions') {
    Write-InstructionFiles -ProjectRoot $ProjectPath -Lang $Lang -Slug $slug -RelLimetDir $relLimetDir -QueryCmd $queryCmd
    Set-NonTechnicalSummary -ProjectRoot $ProjectPath -Name (Split-Path -Leaf $ProjectPath)
    Write-Host ""
    Write-Host "LIMET-INDEX instructions complete: enriched CLAUDE.md + .github/copilot-instructions.md written for '$ProjectPath'."
}

# --- status -----------------------------------------------------------------------------------

if ($Command -eq 'status') {
    Write-Host "LIMET docs folder: $relDocsDir/ ($docsRoot)"
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
