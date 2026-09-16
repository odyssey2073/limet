# Panoramica dell'architettura — [Nome progetto]

> Complemento scritto (da umano/agente) al `architecture/GRAPH_REPORT.md` generato automaticamente
> (da Graphify via `graphify .`). Il report contiene il grafo visuale/machine-readable di simboli,
> moduli e chiamate; questo documento aggiunge il *perché*: decisioni, confini e invarianti che
> un'analisi statica non può dedurre. Entrambi sono indicizzati nella collection CEREBRO del
> progetto. Mantieni i due coerenti — se il codice cambia, esegui di nuovo `limet-index update`.

## Quadro d'insieme

[Un paragrafo + una mappa puntata dei moduli/componenti principali e delle loro responsabilità.
Linka a `architecture/GRAPH_REPORT.md` per il grafo completo.]

## Componenti chiave e responsabilità

| Componente | Responsabilità | File / entry point principali |
| ---------- | -------------- | ----------------------------- |
| [...]      | [...]          | [...]                         |

## Flussi e percorsi dati principali

[Flussi end-to-end: cosa accade nelle azioni importanti, in ordine. Rimanda al grafo per i dettagli
su chiamate/tipi.]

## Decisioni architetturali (stile ADR)

| Decisione | Alternative considerate | Motivazione | Conseguenze |
| --------- | ----------------------- | ----------- | ----------- |
| [...]     | [...]                   | [...]       | [...]       |

## Confini e invarianti

[Cosa non va mai violato: regole di layering, direzione delle dipendenze, vincoli di scrittura
singola, confini di transazione.]

## Dipendenze e integrazioni esterne

| Dipendenza | Scopo | Interfaccia |
| ---------- | ----- | ----------- |
| [...]      | [...] | [...]       |

## Debito noto / rischi

[Aree che si discostano dalla struttura ideale, con il perché e cosa fare al riguardo.]

## Cronologia modifiche

- **[YYYY-MM-DD]**: [modifica architetturale e perché]
