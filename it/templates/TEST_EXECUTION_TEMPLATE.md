# Esecuzione test — [Nome feature / bug fix / task]

> Registra l'**esito reale** di un'esecuzione di test (non la pianificazione — vedi
> `TEST_PLAN_TEMPLATE.md` per quella). Da compilare da chi esegue effettivamente build/test,
> incollando log reali, non riassunti a memoria.

## Riferimenti

- **Piano di test collegato**: [link a `TEST_PLAN_TEMPLATE.md`]
- **Task collegato/i**: [riferimento a `TASK_LIST_TEMPLATE.md` / `TASK_TEMPLATE.md`]

## Metadati esecuzione

- **Data/ora esecuzione**: [YYYY-MM-DD HH:MM]
- **Eseguito da**: [...]
- **Ambiente**: [locale/CI/altro]
- **Comando eseguito**: [comando esatto usato per lanciare i test]

## Esito unit test

- **Totale**: [N] — **Passati**: [N] — **Falliti**: [N] — **Saltati**: [N]
- **Log/estratto rilevante**:

```
[incollare qui l'output reale del test runner, anche solo la parte rilevante]
```

## Esito test e2e

| # | Scenario (rif. piano di test) | Esito (OK / KO / non eseguito) | Note |
| - | ------------------------------- | --------------------------------- | ---- |
| 1 | [...]                            | [...]                              | [...] |

## Anomalie riscontrate

> Se qualcosa è fallito o è risultato inatteso, descriverlo qui e collegarlo a un eventuale nuovo
> `BUG_REPORT_TEMPLATE.md` se si tratta di un difetto separato dal task in corso.

- [...]

## Conclusione

- **Esito complessivo**: `[OK | KO | PARZIALE]`
- **Il task può passare a `done`?**: [sì/no + motivazione]
