# Idea — Modalità "trading" per LIMET

> Stato: **bozza idea**, non implementata. Da valutare prima di procedere.
> Documento di tracciamento, escluso dal flusso LIMET.

## Contesto / motivazione

- Sviluppo in solitaria di una piattaforma di trading (ML + GenAI: analisi dati/grafici, segnali,
  automazione buy/sell).
- LIMET usato come metodo + memoria per un progetto lungo e solista.
- Necessità: vincoli di dominio specifici del trading che il LIMET generico non copre.

## Idea

Una **modalità/profilo "trading"** da attivare a comando, che aggiunge al flusso LIMET regole e
checklist specifiche solo quando si sviluppa per il trading. Non un motore: solo regole, checklist
e template (profilo di dominio, opt-in).

## Forma proposta

1. **Regole vincolanti trading** (iniettate nel blocco agente):
   - money path isolato + kill-switch obbligatorio;
   - backtest senza look-ahead, out-of-sample, niente survivorship bias;
   - paper trading prima di ogni ordine reale;
   - validazione ML a carico dell'utente (l'agente non garantisce l'alpha).
2. **Checklist/template**:
   - `TRADING_CHECKLIST.md` (a inizio feature);
   - `BACKTEST_PLAN_TEMPLATE.md` (validazione).
3. **Attivazione**: flag `limet init -Domain trading` (o file marker), che inietta le regole e
   copia i template solo per quel progetto.

## Domande aperte

- [ ] Meccanismo di attivazione: flag `-Domain` vs file marker vs preset.
- [ ] Quali regole sono *vincolanti* (binding) vs *suggerite*.
- [ ] Serve un template per la revisione del rischio (risk review) prima di toccare il money path?
- [ ] Interazione con il vincolo "mai build/test" (il backtest è un'esecuzione? chi la esegue?).

## Decisioni prese

- (nessuna ancora)
