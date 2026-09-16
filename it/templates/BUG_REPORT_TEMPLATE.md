# Bug report — [Titolo breve del difetto]

## Metadati

- **Data segnalazione**: [YYYY-MM-DD]
- **Segnalato da**: [...]
- **Stato**: `[APERTO | IN ANALISI | IN FIX | RISOLTO | NON RIPRODUCIBILE | NON UN BUG]`
- **Severità**: `[bloccante | alta | media | bassa]`

## Comportamento osservato

[Cosa succede realmente, con evidenze concrete — log, screenshot, messaggi di errore, passi che
lo hanno prodotto.]

## Comportamento atteso

[Cosa dovrebbe succedere invece, secondo la specifica/il comportamento di dominio corretto.]

## Passi per riprodurre

1. [passo 1]
2. [passo 2]
3. [...]

## Ambiente

- **Versione/branch/commit**: [...]
- **Ambiente**: [locale/test/produzione, se rilevante]
- **Dati di test necessari**: [...]

## Analisi della causa radice

> Compilare dopo l'investigazione — distinguere ciò che è stato verificato per fatti (con
> riferimento puntuale al codice/log) da ciò che resta ipotesi.

- **Causa identificata**: [...]
- **File/componente coinvolto**: [percorso, righe]
- **Perché accade**: [spiegazione tecnica]

## Impatto

- **Chi/cosa è affetto**: [...]
- **Da quando**: [se noto, versione/commit in cui è stato introdotto]
- **Aggirabile (workaround)?**: [sì/no + descrizione]

## Fix proposto

[Descrizione della modifica minimale e chirurgica proposta per risolvere la causa radice, non
solo il sintomo.]

## Strategia di verifica (obbligatoria)

- **Unit test di regressione**: [descrizione — deve fallire con il bug presente e passare dopo
  il fix]
- **Test e2e**: [se necessario — riferimento a `E2E_VERIFICATION_TEMPLATE.md`]

## Task di verifica collegati

- [riferimento a `TASK_TEMPLATE.md` o riga di `TASK_LIST_TEMPLATE.md`]

## Esito (da compilare a chiusura)

- **Data risoluzione**: [YYYY-MM-DD]
- **Commit/PR**: [...]
- **Note**: [...]
