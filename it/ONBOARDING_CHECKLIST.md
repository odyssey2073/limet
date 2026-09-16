# Checklist di onboarding — inizio sessione/feature (LIMET)

> Da consultare a inizio sessione o prima di iniziare una nuova feature/bug fix con un agente AI.
> Spuntare ogni voce; se una voce non è applicabile, annotarlo esplicitamente invece di saltarla
> in silenzio.

## 1. Prima di iniziare

- [ ] Ho letto/richiamato il contesto di progetto rilevante (documentazione esistente, istruzioni
      per l'agente, se presenti).
- [ ] Ho verificato se esiste già un piano/proposta per questo lavoro (evitare duplicazioni).
- [ ] Ho chiaro se il lavoro è abbastanza piccolo da non richiedere un documento di piano formale
      (vedi `FRAMEWORK_MANUAL.md` §3) oppure se serve `PLAN_TEMPLATE.md`/`CHANGE_PROPOSAL_TEMPLATE.md`.

## 2. Raccolta di contesto

- [ ] Ho usato le fonti di contesto disponibili (documentale/strutturale/dati reali — vedi
      §2 del manuale) secondo il criterio di combinazione (§2.4), non a caso.
- [ ] Ogni ambiguità trovata è stata registrata come domanda contestuale (§1.2), non assunta.

## 3. Pianificazione

- [ ] Il piano/proposta descrive esplicitamente perimetro dentro/fuori scope.
- [ ] Le alternative considerate e scartate sono documentate (se rilevanti).
- [ ] La strategia di verifica (unit test + e2e) è già abbozzata in questa fase, non rimandata a
      dopo l'implementazione.

## 4. Implementazione

- [ ] Le modifiche restano dentro il perimetro dichiarato (o lo scostamento è stato segnalato ed
      eventualmente approvato).
- [ ] Nessun comando con effetti persistenti (commit, push, migrazioni, deploy) è stato eseguito
      senza autorizzazione esplicita.

## 5. Verifica (obbligatoria — vedi §1.5/§5 del manuale)

- [ ] Sono stati scritti/estesi unit test per il comportamento modificato.
- [ ] È stato valutato se serve un test e2e approfondito; se sì, è stato documentato con
      `E2E_VERIFICATION_TEMPLATE.md` (precondizioni, passi numerati, risultato atteso per passo,
      criteri di verifica oggettivi, rollback).
- [ ] Se un test non è stato previsto, la motivazione è esplicita nel documento di task (§5.3).
- [ ] L'esito reale dei test (non solo quello previsto) è stato registrato in
      `TEST_EXECUTION_TEMPLATE.md`.

## 6. Chiusura

- [ ] I documenti di piano/task sono stati aggiornati a ritroso con l'esito implementazione
      (data, scostamenti rispetto al piano).
- [ ] Se rilevante, è stata prodotta una sintesi non tecnica (`NON_TECHNICAL_SUMMARY_TEMPLATE.md`).
- [ ] Il lavoro concluso è stato congelato con `ARCHIVE_ENTRY_TEMPLATE.md`, se il progetto separa
      documentazione attiva da documentazione archiviata.
- [ ] Sono stati eliminati/segnalati i task residui che non servono più.
