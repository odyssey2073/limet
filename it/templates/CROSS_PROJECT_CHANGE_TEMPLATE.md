# Modifica cross-progetto — [Nome modifica]

> Documento "ombrello" per una modifica (feature o bug fix) che **attraversa più progetti/moduli**
> dello stesso workspace. Non sostituisce i documenti di ciascun progetto (piano, proposta,
> elenco task, ecc.), li **coordina**: ogni progetto coinvolto mantiene comunque i propri
> documenti nella propria cartella `limet/changes/NNNN-slug/`. Vive in
> `limet-workspace/changes/NNNN-slug/CROSS_PROJECT_CHANGE.md`.

## Riferimenti

- **Mappa dei progetti**: [link a `MODULE_MAP.md`]
- **Motivazione della modifica**: [perché serve, in breve — dettaglio nel/nei documento/i di
  proposta di ciascun progetto]

## Progetti/moduli coinvolti e ordine di implementazione

> Fondamentale se esiste un contratto (API/schema/evento) tra i progetti: il produttore del
> contratto va di norma implementato e verificato **prima** dei consumatori.

| Ordine | Progetto/modulo | Ruolo in questa modifica | Documento locale collegato | Stato |
| ------ | ----------------- | ----------------------------- | ------------------------------- | ----- |
| 1      | [nome progetto]   | [produttore del contratto / consumatore / entrambi] | [link a `<progetto>/limet/changes/NNNN-slug/PLAN.md` o `TASK_LIST.md`] | `pending` |
| 2      | [nome progetto]   | [...]                          | [...]                            | `pending` |

## Contratto/interfaccia condivisa (se applicabile)

[Descrizione della nuova interfaccia/campo/evento condiviso tra i progetti — es. nuovo campo in
una risposta API, nuovo evento asincrono, nuova voce di configurazione condivisa. Deve essere
coerente in tutti i progetti coinvolti.]

## Rischi di questa modifica cross-progetto

- **Rischio di disallineamento tra progetti**: [es. un progetto rilasciato prima di un altro può
  causare incompatibilità temporanea — descrivere mitigazione, es. compatibilità
  retro/in-avanti del contratto durante la transizione]
- **Rischio di ordine di deploy errato**: [...]
- **Altro**: [...]

## Criterio di chiusura complessivo

> La modifica cross-progetto si considera conclusa solo quando **tutti** i progetti coinvolti
> hanno i rispettivi task a `done` (con data/ora) e la verifica di integrazione end-to-end tra i
> progetti è stata eseguita con esito positivo — non basta che un singolo progetto sia concluso.

- [ ] Tutti i progetti in tabella hanno stato `done`
- [ ] Verifica e2e di integrazione tra progetti eseguita (vedi sezione seguente)
- [ ] `MODULE_MAP.md` aggiornata se il contratto/le relazioni tra progetti sono cambiate

## Verifica e2e di integrazione tra progetti

[Checklist manuale che copre l'intero flusso attraverso i progetti coinvolti, non solo il
singolo progetto — es. "creare un dato nel progetto A, verificare che il progetto B lo riceva
correttamente e lo elabori come atteso". Può richiamare gli `E2E_VERIFICATION_TEMPLATE.md`
compilati nei singoli progetti come sotto-passi.]

## Esito finale (da compilare a chiusura)

- **Data/ora di chiusura complessiva**: [YYYY-MM-DD HH:MM]
- **Sintesi**: [...]
- **Voce di archivio collegata**: [link a `limet-workspace/archive/NNNN-slug/ARCHIVE_ENTRY.md`,
  eventualmente riassuntiva delle singole `ARCHIVE_ENTRY.md` di progetto]
