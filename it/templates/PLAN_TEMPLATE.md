# Piano — [Nome feature / bug fix]

> Compilare prima di iniziare a modificare codice, quando il lavoro non è banale (tocca più
> file/moduli, richiede decisioni non ovvie, o l'esito non è scontato). Per micro-fix triviali
> questo documento può essere omesso — vedi `FRAMEWORK_MANUAL.md` §3. Per modifiche ampie,
> considerare `CHANGE_PROPOSAL_TEMPLATE.md` + `SPEC_TEMPLATE.md` (+ `DESIGN_TEMPLATE.md`) invece
> di questo singolo documento.

## Metadati

- **Data creazione**: [YYYY-MM-DD]
- **Autore/agente**: [nome]
- **Stato**: `[DRAFT | APPROVATO | IN CORSO | COMPLETATO | ABBANDONATO]`
- **Approvato da / data**: [chi — YYYY-MM-DD] (compilare quando lo Stato passa a APPROVATO)
- **Riferimento richiesta originale**: [issue/ticket/messaggio utente, se esiste]

## 1. Obiettivo

[2-4 frasi: cosa si vuole ottenere e perché. Non ancora *come*.]

## 2. Perimetro (scope)

### Dentro perimetro
- [elemento 1]

### Fuori perimetro (esplicitamente escluso)
- [elemento 1 — motivo dell'esclusione]

## 3. Stato attuale (analisi preliminare)

[Cosa esiste già oggi, verificato per fatti (non per assunzione). Citare i componenti coinvolti.]

- [componente 1]: [cosa fa oggi]

## 4. Domande contestuali aperte

| # | Domanda | Risposta | Data | Da chi |
| - | ------- | -------- | ---- | ------ |
| 1 | [...]   | [...]    | [...] | [...]  |

## 5. Approccio proposto

[Disegno della soluzione: componenti toccati, logica introdotta/modificata.]

### Alternative considerate e scartate

- **Alternativa A**: [descrizione] — scartata perché [motivo].

## 6. Todo/elenco attività

> Il dettaglio granulare va in `TASK_LIST_TEMPLATE.md`. **Genera sempre** il
> `TASK_LIST.md` separato da questa sezione — non chiedere mai se crearlo.

1. [attività 1]

## 7. Strategia di verifica (obbligatoria)

- **Unit test previsti**: [sì/no + dove — tipicamente `TEST_PLAN_TEMPLATE.md`] — se "no",
  motivare esplicitamente.
- **Test e2e previsti**: [sì/no + riferimento a `E2E_VERIFICATION_TEMPLATE.md`] — se "no",
  motivare esplicitamente.
- **Genera sempre** `TEST_PLAN.md` (da `TEST_PLAN_TEMPLATE.md`),
  `E2E_VERIFICATION.md` (da `E2E_VERIFICATION_TEMPLATE.md`) e, a esecuzione avvenuta,
  `TEST_EXECUTION.md` (da `TEST_EXECUTION_TEMPLATE.md`), ciascuno con comandi esatti di
  riesecuzione e descrizioni dei test. Archivia tutti e tre in `limet/archive/<data-slug>/`.
  motivare esplicitamente.

## 8. Rischi e impatti

- **Rischio 1**: [descrizione] — mitigazione: [...]
- **Impatto su altri componenti**: [elenco o "nessuno, verificato perché..."]
- **Compatibilità all'indietro**: [comportamento legacy invariato? come verificato?]

## 9. Note operative

- Commit/push: [chi li esegue]
- Ambiente/permessi necessari per build/test: [...]

---

## Storico aggiornamenti del piano

| Data | Modifica | Motivo |
| ---- | -------- | ------ |
| [YYYY-MM-DD] | [...] | [...] |
