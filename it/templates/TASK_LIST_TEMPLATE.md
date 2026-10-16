# Elenco task — [Nome feature / bug fix]

> Deriva da `PLAN_TEMPLATE.md` §6 (o dai task list nella `CHANGE_PROPOSAL_TEMPLATE.md`). Ogni riga
> è un task granulare, tracciabile, con stato e dipendenze esplicite. Per un task complesso,
> creare una scheda dedicata con `TASK_TEMPLATE.md` e linkarla dalla colonna "Dettaglio".

## Legenda stato

- `pending` — non ancora iniziato
- `in_progress` — in corso
- `blocked` — bloccato (motivare nella colonna Note)
- `done` — completato **e verificato** (non basta "scritto", va anche verificato secondo quanto
  dichiarato nella sezione Strategia di test). **Quando un task passa a `done`, annotare data e
  ora** (`YYYY-MM-DD HH:MM`) nella colonna Note, non solo la data — vedi `FRAMEWORK_MANUAL.md` §4.

## Tabella task

| # | Titolo | Scopo (non tecnico) | Stato | Dipende da | Dettaglio | Note |
| - | ------ | ------------------- | ----- | ---------- | --------- | ---- |
| 1 | [...]  | [una riga: cosa fa] | pending | — | [link a scheda task singolo, se presente] | |
| 2 | [...]  | [...] | pending | #1 | | |

---

## Strategia di test — obbligatoria per ogni task (non omissibile senza motivazione esplicita)

> Vedi `FRAMEWORK_MANUAL.md` §1.5 e §5. Per **ciascun task** della tabella sopra, compilare la
> riga corrispondente qui sotto. Un task non può passare a `done` se questa sezione non è
> compilata (anche solo con un "non applicabile perché...").

| # task | Unit test previsti/esistenti | Test e2e previsti (rif. `E2E_VERIFICATION_TEMPLATE.md`) | Se omesso, motivazione esplicita |
| ------ | ----------------------------- | --------------------------------------------------------- | --------------------------------- |
| 1      | [sì: descrizione breve / no]   | [sì: link / no]                                            | [obbligatorio se uno dei due è "no"] |
| 2      |                                |                                                             |                                    |

## Registro modifiche — una riga per file toccato

> Vedi `FRAMEWORK_MANUAL.md` §1.4 e §4. Per **ogni file creato/modificato** aggiungere una riga,
> **al momento della modifica** e non a fine feature. Serve a rispondere senza rileggere il diff
> a: cosa è stato toccato, perché, e come lo si verifica. La sezione "Esito implementazione" qui
> sotto resta la sintesi finale; questa è il dettaglio file per file.
>
> Se un task tocca file che vivono in un **altro modulo** (libreria condivisa, modulo di script),
> il dettaglio va nel registro di quel modulo: qui si lascia solo una riga di rimando, per non
> duplicare la traccia.

| Task | File | Tipo | Cosa è cambiato | Perché | Verifica collegata |
| ---- | ---- | ---- | --------------- | ------ | ------------------ |
| 1    | `[percorso relativo alla root del modulo]` | creato / modificato / eliminato | [sintesi puntuale, non "varie modifiche"] | [quale requisito/task lo richiede] | [unit test, verifica e2e o controllo manuale] |
| 2    |      |      |                 |        |                    |

## Esito implementazione (da compilare a lavoro concluso)

> Aggiornamento a ritroso: non riscrivere la storia, aggiungere una sezione con data che descrive
> cosa è stato effettivamente fatto, eventuali scostamenti dal piano originale e perché.

- **Data**: [YYYY-MM-DD]
- **Sintesi esito**: [...]
- **Scostamenti rispetto al piano**: [...]
- **Esito test** (riferimento a `TEST_EXECUTION_TEMPLATE.md` se presente): [...]
- **Data/ora di completamento di ciascun task** (`YYYY-MM-DD HH:MM`): riportare nella tabella dei
  task sopra, colonna Note, non solo qui in sintesi.
