# LIMET — Indice master di lettura

> Questo documento indica **in quale ordine leggere** i file di questa edizione del framework, con
> il percorso esatto di ciascuno. Usarlo come primo file da aprire quando ci si avvicina a LIMET
> per la prima volta, o come riferimento rapido per ritrovare un documento specifico.

## 1. Prima di tutto: orientamento generale

| # | Documento | Percorso | Perché leggerlo prima |
| - | --------- | -------- | ------------------------ |
| 1 | Indice generale del repository (bilingue) | `..\README.md` | Panoramica delle due edizioni (IT/EN) e mappa rapida "voglio fare X → vai a Y" |
| 2 | Indice di questa edizione | `README.md` | Elenco dei template disponibili e comando di installazione rapido |
| 3 | Manuale completo del framework | `FRAMEWORK_MANUAL.md` | Metodologia completa: principi (§1), categorie di contesto (§2), ciclo di vita (§3), convenzioni (§4), anti-pattern (§5), adattabilità (§6), naming/glossario (§7), indice template (§8), attivazione pratica (§9), Appendice A (setup CEREBRO/Graphify), Appendice B (esempi operativi passo-passo), Appendice C (scenari multi-progetto/workspace) |
| 4 | Checklist rapida di onboarding | `ONBOARDING_CHECKLIST.md` | Da consultare a **ogni** inizio sessione/feature, dopo aver letto il manuale la prima volta |

## 2. Setup tecnico (una tantum per macchina/progetto)

| # | Cosa fare | Riferimento | Percorso |
| - | --------- | ----------- | -------- |
| 1 | Installare LIMET in un progetto | `FRAMEWORK_MANUAL.md` §9 | `..\scripts\limet.ps1` / `..\scripts\limet.sh` |
| 2 | (Opzionale) Setup strumenti di contesto concreti (RAG documentale, knowledge graph codice) | `FRAMEWORK_MANUAL.md` Appendice A | — |
| 3 | (Se si lavora su più progetti correlati o un monorepo a moduli) Installare il livello workspace | `FRAMEWORK_MANUAL.md` Appendice C | `..\scripts\limet.ps1 -Workspace` / `..\scripts\limet.sh --workspace` |

## 3. Ordine dei template durante il lavoro reale

> Non tutti i template si usano sempre: l'ordine seguente è quello **tipico** per una feature
> completa (piano ampio). Per un bug fix puntuale il flusso è più corto — vedi `FRAMEWORK_MANUAL.md`
> Appendice B.3 per l'esempio completo passo-passo, B.4 per una feature.

| # | Fase | Template | Percorso |
| - | ---- | -------- | -------- |
| 1 | Pianificazione (uso singolo/piccole modifiche) | Piano | `templates\PLAN_TEMPLATE.md` |
| 1bis | Pianificazione (modifiche ampie, alternativa a 1) | Proposta di modifica | `templates\CHANGE_PROPOSAL_TEMPLATE.md` |
| 2 | Specifica (il *cosa*, segue 1bis) | Specifica | `templates\SPEC_TEMPLATE.md` |
| 3 | Disegno tecnico (opzionale, il *come*) | Disegno | `templates\DESIGN_TEMPLATE.md` |
| 4 | Scomposizione in task | Elenco task | `templates\TASK_LIST_TEMPLATE.md` |
| 5 | Task complesso singolo (opzionale, per un task che richiede analisi dedicata) | Task singolo | `templates\TASK_TEMPLATE.md` |
| 6 | Se si parte da un difetto invece che da una richiesta di feature | Bug report | `templates\BUG_REPORT_TEMPLATE.md` |
| 7 | Pianificazione dei test (prima di scrivere il codice) | Piano di test | `templates\TEST_PLAN_TEMPLATE.md` |
| 8 | *(implementazione del codice — nessun template, fase di scrittura)* | — | — |
| 9 | Registrazione esito reale dei test eseguiti | Esecuzione test | `templates\TEST_EXECUTION_TEMPLATE.md` |
| 10 | Verifica manuale end-to-end | Verifica e2e | `templates\E2E_VERIFICATION_TEMPLATE.md` |
| 11 | Comunicazione a pubblico non tecnico (se rilevante) | Sintesi non tecnica | `templates\NON_TECHNICAL_SUMMARY_TEMPLATE.md` |
| 12 | Aggiornamento terminologia condivisa (se emersa ambiguità) | Glossario | `templates\GLOSSARY_TEMPLATE.md` |
| 13 | Chiusura e congelamento storico | Voce di archivio | `templates\ARCHIVE_ENTRY_TEMPLATE.md` |

> **Template di livello workspace** (solo per scenari multi-progetto, vedi §4bis e Appendice C):
> `templates\MODULE_MAP_TEMPLATE.md` (mappa progetti/moduli e dipendenze) e
> `templates\CROSS_PROJECT_CHANGE_TEMPLATE.md` (coordinamento di una modifica cross-progetto).

## 4. Percorsi generati nel progetto target (dopo `limet.ps1`/`limet.sh init`)

| Cosa | Percorso nel progetto target |
| ---- | ------------------------------- |
| Copia locale del manuale | `<progetto>\limet\FRAMEWORK_MANUAL.md` |
| Copia locale della checklist | `<progetto>\limet\ONBOARDING_CHECKLIST.md` |
| Copia locale dei template | `<progetto>\limet\templates\` |
| Lavoro in corso (modifiche attive) | `<progetto>\limet\changes\NNNN-slug\` |
| Lavoro concluso e archiviato | `<progetto>\limet\archive\NNNN-slug\` |
| Fonte unica di istruzioni per l'agente | `<progetto>\AGENTS.md` (blocco marcato `<!-- LIMET:START/END -->`) |
| Import per Claude Code | `<progetto>\CLAUDE.md` (riga `@AGENTS.md`) |

## 4bis. Percorsi generati a livello workspace (dopo `limet.ps1`/`limet.sh init -Workspace`)

> Solo per scenari multi-progetto: più repository correlati sotto una cartella padre comune,
> oppure un monorepo con più moduli. Vedi `FRAMEWORK_MANUAL.md` Appendice C per la guida completa.

| Cosa | Percorso nella cartella workspace (padre o radice monorepo) |
| ---- | ------------------------------------------------------------- |
| Copia locale del manuale | `<workspace>\limet-workspace\FRAMEWORK_MANUAL.md` |
| Copia locale della checklist | `<workspace>\limet-workspace\ONBOARDING_CHECKLIST.md` |
| Mappa progetti/moduli e dipendenze (compilata manualmente, mai sovrascritta da `update`) | `<workspace>\limet-workspace\MODULE_MAP.md` |
| Template di coordinamento (solo 2, non l'intero set per-progetto) | `<workspace>\limet-workspace\templates\` |
| Modifiche cross-progetto in corso | `<workspace>\limet-workspace\changes\NNNN-slug\` |
| Modifiche cross-progetto archiviate | `<workspace>\limet-workspace\archive\NNNN-slug\` |
| Fonte unica di istruzioni per l'agente a livello workspace | `<workspace>\AGENTS.md` (blocco marcato `<!-- LIMET-WORKSPACE:START/END -->`, distinto dal blocco `LIMET` per-progetto) |
| Import per Claude Code a livello workspace | `<workspace>\CLAUDE.md` (riga `@AGENTS.md`) |

## 5. Riferimento rapido per scenario

- **Nuovo progetto da zero** → `FRAMEWORK_MANUAL.md` Appendice B.2
- **Attivare LIMET su un progetto esistente** → `FRAMEWORK_MANUAL.md` Appendice B.1
- **Correggere un bug** → `FRAMEWORK_MANUAL.md` Appendice B.3
- **Aggiungere una feature** → `FRAMEWORK_MANUAL.md` Appendice B.4
- **Setup di un workspace con più progetti/moduli correlati** → `FRAMEWORK_MANUAL.md` Appendice C.1
- **Bug fix che attraversa più progetti** → `FRAMEWORK_MANUAL.md` Appendice C.2
- **Feature che attraversa più progetti** → `FRAMEWORK_MANUAL.md` Appendice C.3
- **Monorepo con più moduli (variante)** → `FRAMEWORK_MANUAL.md` Appendice C.4
