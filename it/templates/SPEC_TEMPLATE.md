# Specifica — Capability: [nome-capability]

> Descrive il *cosa* in forma verificabile. Una specifica per ogni capability nuova/modificata
> elencata nella `CHANGE_PROPOSAL_TEMPLATE.md` collegata. I test (unit/e2e) devono allinearsi a
> questi requisiti/scenari.

## Metadati

- **Proposta collegata**: [riferimento a `CHANGE_PROPOSAL_TEMPLATE.md`]
- **Stato**: `[DRAFT | APPROVATA | IMPLEMENTATA]`
- **Versione**: [incrementare se la spec cambia dopo l'implementazione]

## Descrizione della capability

[Cosa fa questa capability, in termini di comportamento osservabile — non di implementazione.]

## Requisiti

> Ogni requisito deve essere verificabile: evitare frasi generiche ("deve essere robusto"), usare
> condizioni osservabili.

### Requisito 1: [titolo breve]

[Descrizione del requisito.]

**Scenari** (dato/quando/allora):

- **Dato** [precondizione], **quando** [azione/evento], **allora** [risultato atteso osservabile].
- **Dato** [precondizione alternativa/edge case], **quando** [...], **allora** [...].

### Requisito 2: [titolo breve]

[...]

## Vincoli e casi limite

- [vincolo 1: es. valori nulli, condizioni di concorrenza, limiti di configurazione]
- [caso limite 1]

## Fuori specifica (esplicitamente non coperto)

- [comportamento non garantito da questa specifica, per evitare fraintendimenti]

## Tracciabilità verso i test

| Requisito | Unit test | Test e2e |
| --- | --- | --- |
| Requisito 1 | [riferimento] | [riferimento] |
| Requisito 2 | [riferimento] | [riferimento] |
