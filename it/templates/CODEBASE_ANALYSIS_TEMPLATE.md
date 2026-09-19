# Analisi della codebase — playbook avanzato per l'agente

> Guida cross-tool (Claude Code e Copilot la seguono allo stesso modo) per produrre documentazione
> approfondita da una codebase, anche multi-modulo e non documentata. Non è un documento di output:
> è la **procedura** da seguire per generare i documenti. Sintesi delle migliori skill/prompt di
> analisi codice (C4, ADR, reverse-engineering).

## Principi fondamentali

1. **Separa discovery da prose** — discovery (cosa esiste, chi dipende da chi) è deterministico
   (Graphify/filesystem); prose (descrizione, rationale) è giudizio dell'agente.
2. **Recupera l'intent, non trascrivere il codice** — descrivi il *perché* (scopo, decisioni), non il
   *come* riga per riga.
3. **Fatti vs ipotesi** — ogni affermazione ha evidenza `file:line`, oppure è marcata come incerta.
4. **Un bounded context alla volta** — non mescolare moduli; nomina subito i confini "spinosi"
   (auth, job in background, contratti cross-repo, cache).

## Fase 1 — Ricognizione strutturale (discovery deterministico)

1. Interroga il grafo: `graphify query`, `graphify path`, `graphify explain` per moduli, entrypoint, dipendenze.
2. Leggi `graphify-out/GRAPH_REPORT.md` come mappa di partenza.
3. Elenca i moduli/pacchetti **reali** dal filesystem (non dedurre dai nomi).
4. **Codebase grandi**: parallelizza — costruisci prima il grafo dipendenze, poi analizza i moduli ad
   alto valore; dividi i file >2000 righe in range contigui.

## Fase 2 — Architettura (modello C4)

Usa il modello C4 per il livello di dettaglio giusto:

- **L1 System Context** — sempre: il sistema e le sue relazioni con utenti/sistemi esterni.
- **L2 Container** — quando modifichi i confini (app, DB, code esterne).
- **L3 Component** — per servizi nuovi o modificati.
- **L4 Code** — solo per componenti complessi/critici.

Diagrammi in **Mermaid** (testo, renderizzato ovunque). Aggiungi i **flussi end-to-end** principali.

## Fase 3 — Decisioni architetturali (ADR)

Per ogni decisione rilevante crea un **ADR** (Architecture Decision Record):

- Formato: **Status · Context · Decision · Consequences**.
- **Una decisione per ADR**; elenca le **alternative considerate (anche quelle scartate)** e il perché.
- Registra i **trade-off** accettati.
- **Immutabili**: sostituisci un ADR con uno nuovo, non modificarlo.

## Fase 4 — Convenzioni e glossario

- Naming, struttura, pattern, gestione errori, testing — generali e **per-modulo** se divergono.
- Termini di dominio, concetti tecnici, acronimi.

## Fase 5 — Artefatti (doc suite)

Genera in `docs/`:

| Documento | Contenuto |
|---|---|
| `module-map.md` | moduli, responsabilità, dipendenze, ordine di build/deploy |
| `architecture.md` | C4 L1–L3, diagrammi Mermaid, flussi cross-modulo |
| `decisions.md` | ADR (una decisione per sezione) |
| `dependencies.md` | grafo dipendenze (import, chiamate, servizi esterni) |
| `conventions.md` | convenzioni di codice (generali + per-modulo) |
| `glossary.md` | termini di dominio, concetti, acronimi |

Per progetti **multi-modulo**, `module-map.md` e `dependencies.md` sono obbligatori.

## Regole ferree

1. **Cita `file:line`** per ogni affermazione non ovvia (es. `src/main/App.java:42`).
2. **Fatti vs ipotesi**: se non lo vedi nel codice/grafo, scrivilo come incerto
   (`[non verificato]`, `[da confermare]`), non inventarlo.
3. **Business context / design rationale NON sono deducibili dal codice**: se mancano, marca
   `[da chiedere al team]` invece di inventarli.
4. **Incrementale**: se un documento esiste, **AGGIORNALO** (solo le parti cambiate), non riscriverlo.
5. **Mermaid** per diagrammi di flussi/dipendenze.
6. **Rileva il drift**: se esistono spec/doc, segnala divergenze codice↔doc (Gap, Stale, Uncovered, Orphaned).
7. **Requisiti verificabili**: usa RFC 2119 (SHALL/MUST/SHOULD/MAY) e Given/When/Then.
8. **Chunk per modulo/funzione**: non inondare l'analisi con file enormi (rischi omissioni/allucinazioni).
9. **Cerca prima in CEREBRO/Qdrant**: se il documento non è ancora indicizzato, leggilo localmente da `docs/` (fallback).
