#Requires -Version 5.1
<#
.SYNOPSIS
    LIMET CLI (PowerShell edition) — installs/updates the LIMET spec-driven framework in a
    project (or in a multi-project workspace) using a single cross-tool mechanism, mirroring the
    init/update pattern of tools such as OpenSpec.

.DESCRIPTION
    LIMET uses ONE integration mechanism, not a different custom setup per AI tool:

    - `AGENTS.md` at the project (or workspace) root is the single source of truth. It is read
      natively by Copilot CLI (documented instruction-file location) and by most other agentic
      CLI tools that follow the open agents.md convention.
    - Claude Code specifically reads `CLAUDE.md`, not `AGENTS.md`, by default. The officially
      documented way to make it load `AGENTS.md` is a single `@AGENTS.md` import line at the top
      of `CLAUDE.md` — this is a standard Claude Code feature (file import), not a LIMET-specific
      workaround. This script adds that one line to `CLAUDE.md` (creating it if missing) and
      never duplicates content across files.

    Two modes:

    - **Per-project mode (default)**: `init` copies the chosen language edition (manual +
      templates) into `<project>/limet/`, creates `limet/changes/` and `limet/archive/`,
      writes/refreshes the marked LIMET block in `AGENTS.md`, and ensures `CLAUDE.md` imports it.
      `update` re-copies the framework files and refreshes the block/import, without touching
      anything else.
    - **Workspace mode** (`-Workspace` switch): for a parent folder containing several correlated
      projects/repositories (or a monorepo with several modules, each treated as its own
      "project"). `init` creates `<path>/limet-workspace/` with `MODULE_MAP.md` (only if missing —
      never overwritten on update) and the two coordination templates
      (`MODULE_MAP_TEMPLATE.md`, `CROSS_PROJECT_CHANGE_TEMPLATE.md`), and writes/refreshes a
      separate marked block (`LIMET-WORKSPACE`) in the workspace-level `AGENTS.md`/`CLAUDE.md`.
      This does NOT replace per-project installation: each individual project/module listed in
      `MODULE_MAP.md` should still get its own `init` (without `-Workspace`) in its own root.

    Both actions are idempotent in both modes.

.PARAMETER Command
    'init' or 'update'.

.PARAMETER ProjectPath
    Path to the target project or workspace root. Created if missing (init only).

.PARAMETER Lang
    Language edition to install: 'it' or 'en'. Default: 'en'.

.PARAMETER Workspace
    Install the multi-project/multi-module coordination layer (`limet-workspace/`) instead of
    the standard per-project one (`limet/`). See DESCRIPTION.

.EXAMPLE
    .\limet.ps1 init -ProjectPath C:\Progetti\myapp -Lang it

.EXAMPLE
    .\limet.ps1 update -ProjectPath C:\Progetti\myapp

.EXAMPLE
    # Coordination layer for a parent folder containing several correlated repos/modules
    .\limet.ps1 init -ProjectPath C:\Progetti\myworkspace -Lang it -Workspace
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet('init','update')]
    [string]$Command,

    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [ValidateSet('it','en')]
    [string]$Lang = 'en',

    [switch]$Workspace
)

$ErrorActionPreference = 'Stop'

# --- Resolve paths ----------------------------------------------------------------------------

$LimetRoot = Split-Path -Parent $PSScriptRoot   # scripts/ -> LIMET root
$SourceLangDir = Join-Path $LimetRoot $Lang
if (-not (Test-Path $SourceLangDir)) {
    throw "Language edition '$Lang' not found under '$LimetRoot'. Expected folder '$SourceLangDir'."
}

if (-not (Test-Path $ProjectPath)) {
    if ($Command -eq 'update') {
        throw "Path '$ProjectPath' does not exist. Run 'init' first."
    }
    New-Item -ItemType Directory -Force -Path $ProjectPath | Out-Null
}
$ProjectPath = (Resolve-Path $ProjectPath).Path

if ($Workspace) {
    $relLimetDir = 'limet-workspace'
} else {
    $relLimetDir = 'limet'
}
$LimetProjectDir = Join-Path $ProjectPath $relLimetDir

# --- Step 1: copy files into <path>/limet/ or <path>/limet-workspace/ --------------------------

$isRefresh = Test-Path $LimetProjectDir
New-Item -ItemType Directory -Force -Path $LimetProjectDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $LimetProjectDir 'templates') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $LimetProjectDir 'changes') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $LimetProjectDir 'archive') | Out-Null

# The transversal context tool (CEREBRO RAG + Graphify) is copied alongside the framework files so
# each project is self-contained: the agent can always run `<limetDir>/scripts/limet-index.ps1`.
New-Item -ItemType Directory -Force -Path (Join-Path $LimetProjectDir 'scripts') | Out-Null
foreach ($tool in @('limet-index.ps1', 'limet-index.sh')) {
    Copy-Item -Force (Join-Path $PSScriptRoot $tool) (Join-Path $LimetProjectDir "scripts\$tool")
}

foreach ($item in @('FRAMEWORK_MANUAL.md', 'ONBOARDING_CHECKLIST.md', 'MASTER_INDEX.md')) {
    Copy-Item -Force (Join-Path $SourceLangDir $item) (Join-Path $LimetProjectDir $item)
}

if ($Workspace) {
    # Workspace mode: only the two coordination templates, not the full per-project template set.
    foreach ($tpl in @('MODULE_MAP_TEMPLATE.md', 'CROSS_PROJECT_CHANGE_TEMPLATE.md')) {
        Copy-Item -Force (Join-Path $SourceLangDir "templates\$tpl") (Join-Path $LimetProjectDir "templates\$tpl")
    }
    # MODULE_MAP.md is a working document the user fills in — create it only if missing, never
    # overwrite it on 'update' (that would wipe out real workspace data).
    $moduleMapFile = Join-Path $LimetProjectDir 'MODULE_MAP.md'
    if (-not (Test-Path $moduleMapFile)) {
        Copy-Item -Force (Join-Path $SourceLangDir 'templates\MODULE_MAP_TEMPLATE.md') $moduleMapFile
        Write-Host "Created: '$moduleMapFile' (fill it in with your projects/modules)"
    }
} else {
    Copy-Item -Force -Recurse (Join-Path $SourceLangDir 'templates\*') (Join-Path $LimetProjectDir 'templates')
}

foreach ($keepDir in @('changes','archive')) {
    $gitkeep = Join-Path (Join-Path $LimetProjectDir $keepDir) '.gitkeep'
    if (-not (Test-Path $gitkeep)) { New-Item -ItemType File -Path $gitkeep -Force | Out-Null }
}

Write-Host "$(if ($isRefresh) {'Refreshed'} else {'Created'}): $relLimetDir/ ($Lang edition) in '$ProjectPath'"

# --- Step 2: build the LIMET block ---------------------------------------------------------------

$blockByLang = @{
    'it' = @"
<!-- LIMET:START -->
## LIMET — metodo di lavoro spec-driven per questo progetto

Questo progetto segue il framework **LIMET** per bug fixing e sviluppo di nuove feature con
agenti AI. Documentazione locale in ``$relLimetDir/`` (manuale: ``$relLimetDir/FRAMEWORK_MANUAL.md``,
checklist: ``$relLimetDir/ONBOARDING_CHECKLIST.md``, template: ``$relLimetDir/templates/``,
lavoro in corso: ``$relLimetDir/changes/``, lavoro concluso: ``$relLimetDir/archive/``).

Regole vincolanti (vedi il manuale per il dettaglio):
- Prima di modificare codice non banale, creare/consultare un documento di piano o proposta in
  ``$relLimetDir/changes/`` usando ``templates/PLAN_TEMPLATE.md`` o, per modifiche ampie,
  ``templates/CHANGE_PROPOSAL_TEMPLATE.md`` + ``templates/SPEC_TEMPLATE.md``.
- Ogni ambiguità va registrata come domanda contestuale (con risposta e data), mai assunta in
  silenzio.
- **Nessun task può essere marcato ``done`` senza una strategia di verifica**: unit test dedicati
  e/o test e2e approfonditi con istruzioni passo-passo, salvo motivazione esplicita di omissione.
  Quando un task passa a ``done``, annotare anche l'ora (``YYYY-MM-DD HH:MM``).
- **Approvazione umana**: prima di implementare, chiedi all'utente l'approvazione del piano/proposta e registrala nel documento (chi ha approvato + data).
- **Tracciabilità e comunicazione**: a fine task, per ogni file creato/modificato riporta nella scheda task il test collegato e comunica all'utente l'elenco delle modifiche (file, cosa è cambiato, perché).
- Non eseguire comandi con effetti persistenti (commit, push, migrazioni, deploy) senza
  autorizzazione esplicita dell'utente.
- A inizio sessione/feature, consultare ``$relLimetDir/ONBOARDING_CHECKLIST.md``.
- A modifica conclusa e verificata, spostare/archiviare i documenti in ``$relLimetDir/archive/``
  usando ``templates/ARCHIVE_ENTRY_TEMPLATE.md``.
- Dopo l'archiviazione, eseguire ``$relLimetDir/scripts/limet-index.ps1 update`` (o
  ``limet-index.sh update``) per re-indicizzare la collection RAG del progetto (CEREBRO).
- Se questo progetto fa parte di un workspace multi-progetto (più repository correlati o più
  moduli), verificare se esiste una cartella ``limet-workspace/`` nella cartella padre condivisa:
  in tal caso consultare ``limet-workspace/MODULE_MAP.md`` prima di modifiche che potrebbero
  toccare altri progetti, e usare ``limet-workspace/templates/CROSS_PROJECT_CHANGE_TEMPLATE.md``
  per coordinare modifiche cross-progetto — vedi ``FRAMEWORK_MANUAL.md`` Appendice C.
- Per aggiornare questa cartella locale a una nuova versione di LIMET, rieseguire lo script di
  installazione (``scripts/limet.ps1 update`` o ``scripts/limet.sh update``) dal repository
  sorgente del framework.
<!-- LIMET:END -->
"@
    'en' = @"
<!-- LIMET:START -->
## LIMET — spec-driven working method for this project

This project follows the **LIMET** framework for bug fixing and new feature development with AI
agents. Local documentation in ``$relLimetDir/`` (manual: ``$relLimetDir/FRAMEWORK_MANUAL.md``,
checklist: ``$relLimetDir/ONBOARDING_CHECKLIST.md``, templates: ``$relLimetDir/templates/``,
work in progress: ``$relLimetDir/changes/``, completed work: ``$relLimetDir/archive/``).

Binding rules (see the manual for full detail):
- Before making a non-trivial code change, create/consult a plan or proposal document in
  ``$relLimetDir/changes/`` using ``templates/PLAN_TEMPLATE.md`` or, for larger changes,
  ``templates/CHANGE_PROPOSAL_TEMPLATE.md`` + ``templates/SPEC_TEMPLATE.md``.
- Every ambiguity must be recorded as a contextual question (with answer and date), never
  silently assumed.
- **No task can be marked ``done`` without a verification strategy**: dedicated unit tests
  and/or thorough e2e tests with step-by-step instructions, unless explicitly justified as
  omitted. When a task moves to ``done``, also record the time (``YYYY-MM-DD HH:MM``).
- **Human approval**: before implementing, ask the user to approve the plan/proposal and record it in the document (who approved + date).
- **Traceability and communication**: at the end of a task, for each created/modified file record the linked test in the task sheet and tell the user the list of changes (file, what changed, why).
- Do not run commands with persistent effects (commit, push, migrations, deploy) without the
  user's explicit authorization.
- At the start of a session/feature, consult ``$relLimetDir/ONBOARDING_CHECKLIST.md``.
- Once a change is complete and verified, move/archive its documents into
  ``$relLimetDir/archive/`` using ``templates/ARCHIVE_ENTRY_TEMPLATE.md``.
- After archiving a change, run ``$relLimetDir/scripts/limet-index.ps1 update`` (or
  ``limet-index.sh update``) to re-index the project's RAG collection (CEREBRO).
- If this project is part of a multi-project workspace (several correlated repositories or
  several modules), check whether a ``limet-workspace/`` folder exists in the shared parent
  folder: if so, consult ``limet-workspace/MODULE_MAP.md`` before changes that might touch other
  projects, and use ``limet-workspace/templates/CROSS_PROJECT_CHANGE_TEMPLATE.md`` to coordinate
  cross-project changes — see ``FRAMEWORK_MANUAL.md`` Appendix C.
- To update this local copy to a newer LIMET version, re-run the install script
  (``scripts/limet.ps1 update`` or ``scripts/limet.sh update``) from the framework's source repo.
<!-- LIMET:END -->
"@
}

$workspaceBlockByLang = @{
    'it' = @"
<!-- LIMET-WORKSPACE:START -->
## LIMET — coordinamento multi-progetto (workspace)

Questa cartella è la radice di un **workspace LIMET** che coordina più progetti/repository
correlati (o più moduli di uno stesso repository, ciascuno trattato come progetto a sé). Non
sostituisce l'installazione LIMET dei singoli progetti (ciascuno ha il proprio ``AGENTS.md`` +
``limet/`` nella propria root) — aggiunge solo un livello di coordinamento condiviso.

Documentazione locale in ``$relLimetDir/``:
- ``$relLimetDir/MODULE_MAP.md`` — elenco progetti/moduli, ruoli, dipendenze/contratti tra loro.
  **Consultarla prima di qualunque modifica che potrebbe toccare più di un progetto.**
- ``$relLimetDir/templates/CROSS_PROJECT_CHANGE_TEMPLATE.md`` — documento ombrello per
  coordinare una modifica che attraversa più progetti (ordine di implementazione, contratto
  condiviso, criterio di chiusura complessivo).
- ``$relLimetDir/changes/`` — modifiche cross-progetto in corso; ``$relLimetDir/archive/`` —
  concluse.

Regole vincolanti:
- Prima di iniziare una modifica che coinvolge più di un progetto elencato in
  ``$relLimetDir/MODULE_MAP.md``, creare un documento da ``templates/CROSS_PROJECT_CHANGE_TEMPLATE.md``
  in ``$relLimetDir/changes/`` con l'ordine di implementazione (di norma: produttore del contratto
  prima dei consumatori).
- Ogni progetto coinvolto mantiene comunque i propri documenti (piano/task/test) nella propria
  cartella ``limet/changes/``: il documento cross-progetto **collega**, non duplica.
- La modifica cross-progetto si chiude solo quando tutti i progetti coinvolti sono a ``done`` **e**
  la verifica di integrazione end-to-end tra progetti è stata eseguita con esito positivo.
- Vedi ``FRAMEWORK_MANUAL.md`` Appendice C per gli scenari operativi completi (nuovo workspace,
  bug fix cross-progetto, nuova feature cross-progetto).
- Dopo l'archiviazione di una modifica cross-progetto, eseguire
  ``$relLimetDir/scripts/limet-index.ps1 update`` per re-indicizzare la collection RAG del
  workspace.
<!-- LIMET-WORKSPACE:END -->
"@
    'en' = @"
<!-- LIMET-WORKSPACE:START -->
## LIMET — multi-project coordination (workspace)

This folder is the root of a **LIMET workspace** coordinating several correlated
projects/repositories (or several modules of the same repository, each treated as its own
project). It does not replace each project's own LIMET installation (each has its own
``AGENTS.md`` + ``limet/`` in its own root) — it only adds a shared coordination layer.

Local documentation in ``$relLimetDir/``:
- ``$relLimetDir/MODULE_MAP.md`` — list of projects/modules, roles, dependencies/contracts
  between them. **Consult it before any change that might touch more than one project.**
- ``$relLimetDir/templates/CROSS_PROJECT_CHANGE_TEMPLATE.md`` — umbrella document to coordinate
  a change spanning multiple projects (implementation order, shared contract, overall closure
  criterion).
- ``$relLimetDir/changes/`` — cross-project changes in progress; ``$relLimetDir/archive/`` —
  completed ones.

Binding rules:
- Before starting a change involving more than one project listed in
  ``$relLimetDir/MODULE_MAP.md``, create a document from
  ``templates/CROSS_PROJECT_CHANGE_TEMPLATE.md`` in ``$relLimetDir/changes/`` with the
  implementation order (normally: contract producer before consumers).
- Every involved project still keeps its own documents (plan/task/test) in its own
  ``limet/changes/`` folder: the cross-project document **links**, it does not duplicate.
- The cross-project change is closed only once all involved projects are at ``done`` **and** the
  cross-project end-to-end integration verification has passed.
- See ``FRAMEWORK_MANUAL.md`` Appendix C for the full operational scenarios (new workspace,
  cross-project bug fix, cross-project feature).
- After archiving a cross-project change, run ``$relLimetDir/scripts/limet-index.ps1 update`` to
  re-index the workspace RAG collection.
<!-- LIMET-WORKSPACE:END -->
"@
}

if ($Workspace) {
    $block = $workspaceBlockByLang[$Lang]
    $startMarker = '<!-- LIMET-WORKSPACE:START -->'
    $endMarker = '<!-- LIMET-WORKSPACE:END -->'
} else {
    $block = $blockByLang[$Lang]
    $startMarker = '<!-- LIMET:START -->'
    $endMarker = '<!-- LIMET:END -->'
}

# --- Step 3: install/refresh the block into the single source of truth: AGENTS.md --------------

function Set-LimetBlock {
    param([string]$TargetFile, [string]$Block, [string]$StartMarker, [string]$EndMarker)

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
    Write-Host "$status`: LIMET block in '$TargetFile'"
}

$agentsFile = Join-Path $ProjectPath 'AGENTS.md'
Set-LimetBlock -TargetFile $agentsFile -Block $block -StartMarker $startMarker -EndMarker $endMarker

# --- Step 4: ensure CLAUDE.md imports AGENTS.md (standard Claude Code file-import feature) ------
# Copilot CLI reads AGENTS.md natively (documented instruction-file location). Claude Code reads
# CLAUDE.md by default; the officially documented way to make it also load AGENTS.md is a single
# "@AGENTS.md" import line. This is the ONE cross-tool mechanism LIMET relies on — no separate
# per-tool content is generated or duplicated. Same mechanism in workspace mode.

$importLine = '@AGENTS.md'
$claudeFile = Join-Path $ProjectPath 'CLAUDE.md'

if (-not (Test-Path $claudeFile)) {
    Set-Content -Path $claudeFile -Value ($importLine + "`n") -NoNewline
    Write-Host "Created: '$claudeFile' with '$importLine' import"
} else {
    $claudeContent = Get-Content -Raw $claudeFile
    if ($claudeContent -match [regex]::Escape($importLine)) {
        Write-Host "Already present: '$importLine' import in '$claudeFile'"
    } else {
        $updated = $importLine + "`n`n" + $claudeContent
        Set-Content -Path $claudeFile -Value $updated -NoNewline
        Write-Host "Updated: prepended '$importLine' import to '$claudeFile' (existing content preserved below)"
    }
}

Write-Host ""
Write-Host "LIMET $Command complete for '$ProjectPath' (edition: $Lang$(if ($Workspace) {', workspace mode'}))."
if ($Command -eq 'init') {
    if ($Workspace) {
        Write-Host "Next: fill in '$relLimetDir/MODULE_MAP.md', then run 'limet.ps1 init' (without -Workspace) in each individual project/module root."
    } else {
        Write-Host "Next: open '$relLimetDir/ONBOARDING_CHECKLIST.md' and start your first change in '$relLimetDir/changes/'."
    }
}
