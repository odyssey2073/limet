# LIMET — edizione italiana

> **Da dove iniziare**: consulta [`MASTER_INDEX.md`](MASTER_INDEX.md) per l'ordine di lettura
> consigliato di tutti i documenti di questa cartella, con i percorsi esatti.

Indice della versione italiana del framework LIMET (*Lightweight Iterative Method for
Engineering with Traceability*).

- **[`FRAMEWORK_MANUAL.md`](FRAMEWORK_MANUAL.md)** — il manuale completo: principi, categorie di
  contesto, ciclo di vita a fasi, convenzioni, requisito vincolante di test, anti-pattern,
  adattabilità, appendice di setup opzionale (CEREBRO/Qdrant/Ollama/Graphify).
- **[`ONBOARDING_CHECKLIST.md`](ONBOARDING_CHECKLIST.md)** — checklist rapida da seguire a inizio
  sessione/feature.
- **[`templates/`](templates/)** — i documenti scheletro: 13 template di ciclo di vita (uno per
  fase/artefatto, §8) più 2 template di documentazione della codebase (vedi §A.4).
- **[`guides/workflow.html`](guides/workflow.html)** — guida operativa interattiva (SPA) con 9 casi prova.
- **[`guides/install.html`](guides/install.html)** — guida all'installazione dei componenti.

## Template disponibili

| File | Scopo |
| --- | --- |
| `templates/PLAN_TEMPLATE.md` | Piano per una feature/bug fix non banale |
| `templates/CHANGE_PROPOSAL_TEMPLATE.md` | Proposta di modifica più strutturata (il perché) |
| `templates/SPEC_TEMPLATE.md` | Specifica verificabile di una capability (il cosa) |
| `templates/DESIGN_TEMPLATE.md` | Disegno tecnico opzionale (il come) |
| `templates/TASK_LIST_TEMPLATE.md` | Elenco task granulari tracciabili |
| `templates/TASK_TEMPLATE.md` | Scheda per un task complesso |
| `templates/BUG_REPORT_TEMPLATE.md` | Segnalazione di un difetto |
| `templates/TEST_PLAN_TEMPLATE.md` | Pianificazione unit test |
| `templates/TEST_EXECUTION_TEMPLATE.md` | Registrazione esito reale dei test |
| `templates/E2E_VERIFICATION_TEMPLATE.md` | Checklist di verifica e2e manuale |
| `templates/NON_TECHNICAL_SUMMARY_TEMPLATE.md` | Sintesi per pubblico non tecnico |
| `templates/GLOSSARY_TEMPLATE.md` | Glossario di dominio condiviso |
| `templates/ARCHIVE_ENTRY_TEMPLATE.md` | Registrazione di archiviazione di una modifica conclusa |

**Template di livello workspace** (scenari multi-progetto/multi-modulo — vedi Appendice C del
manuale):

| Template | Uso tipico |
| --- | --- |
| `templates/MODULE_MAP_TEMPLATE.md` | Mappa dei progetti/moduli di un workspace e delle loro dipendenze |
| `templates/CROSS_PROJECT_CHANGE_TEMPLATE.md` | Coordinamento di una modifica che attraversa più progetti/moduli |

**Template di documentazione della codebase** (usati da `limet-index` per generare `docs/`, vedi il
manuale §A.4):

| Template | Uso tipico |
| --- | --- |
| `templates/ARCHITECTURE_TEMPLATE.md` | Panoramica architetturale scritta da umano/agente, complementare al report Graphify |
| `templates/CONVENTIONS_TEMPLATE.md` | Convenzioni di codice distillate dalla codebase |

Vedi anche la versione inglese in [`../en/`](../en/README.md).

## Installazione automatica in un progetto

Per attivare LIMET in un progetto (creazione di `limet/`, blocco istruzioni in `AGENTS.md`,
import in `CLAUDE.md`), usare gli script in [`../scripts/`](../scripts/) — vedi `FRAMEWORK_MANUAL.md`
§9 per il dettaglio:

```powershell
..\scripts\limet.ps1 init -ProjectPath C:\percorso\progetto -Lang it
```

Per scenari con più progetti correlati o un monorepo a moduli, usare in aggiunta il flag
`-Workspace` (`--workspace` in bash) sulla cartella padre/radice — vedi Appendice C del manuale:

```powershell
..\scripts\limet.ps1 init -ProjectPath C:\percorso\workspace -Lang it -Workspace
```

```bash
../scripts/limet.sh init --project-path /percorso/progetto --lang it
```
