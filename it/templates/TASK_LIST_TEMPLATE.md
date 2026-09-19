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

## Esito implementazione (da compilare a lavoro concluso)

> Aggiornamento a ritroso: non riscrivere la storia, aggiungere una sezione con data che descrive
> cosa è stato effettivamente fatto, eventuali scostamenti dal piano originale e perché.

- **Data**: [YYYY-MM-DD]
- **Sintesi esito**: [...]
- **Scostamenti rispetto al piano**: [...]
- **Esito test** (riferimento a `TEST_EXECUTION_TEMPLATE.md` se presente): [...]
- **Data/ora di completamento di ciascun task** (`YYYY-MM-DD HH:MM`): riportare nella tabella dei
  task sopra, colonna Note, non solo qui in sintesi.
