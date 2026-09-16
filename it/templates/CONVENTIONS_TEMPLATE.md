# Convenzioni di codice — [Nome progetto]

> Documento di riferimento delle convenzioni di codice del progetto, generato dalla codebase (con il
> giudizio dell'agente) e indicizzato nella collection CEREBRO del progetto. È la "fonte unica" su
> come va scritto il codice in questo progetto, così ogni agente AI lavora in modo coerente tra le
> sessioni. Aggiornalo quando cambia una convenzione o viene adottato un nuovo pattern.

## Linguaggi, framework e versioni

| Area | Tecnologia | Versione |
| ---- | ---------- | -------- |
| [...] | [...]      | [...]    |

## Convenzioni di naming

| Tipo | Convenzione | Esempio |
| ---- | ----------- | ------- |
| file | [...]       | [...]   |
| variabili | [...]   | [...]   |
| funzioni | [...]  | [...]   |
| classi/tipi | [...] | [...]   |
| costanti | [...]   | [...]   |

## Struttura e organizzazione

[Dove stanno le cose: layout delle cartelle, confini dei moduli, entry point, cosa va dove.
Derivato dal layout reale della codebase, non da un template generico.]

## Gestione degli errori

[Come vengono sollevati/propagati/loggati gli errori in questo progetto; dove si intercettano le
eccezioni; eventuali convenzioni specifiche.]

## Convenzioni di test

[Framework di test, nome/posizione dei file, cosa è testato unit vs e2e, come si preparano
fixture/mock. Deve restare coerente con il requisito vincolante di verifica in
`FRAMEWORK_MANUAL.md` §1.5/§5.]

## Logging e osservabilità

[Livelli di log, formato dei messaggi, identificatori di correlazione, se presenti.]

## Configurazione e segreti

[Dove vive la configurazione, come si forniscono i segreti (mai hardcoded), convenzioni
d'ambiente.]

## Convenzioni git / branch / commit

[Nome dei branch, formato dei messaggi di commit, flusso PR/review, se presenti.]

## Anti-pattern da evitare

[Cose specifiche del progetto che sembrano allettanti ma sono note per essere sbagliate in questa
codebase.]

## Cronologia modifiche

- **[YYYY-MM-DD]**: [convenzione aggiunta/cambiata e perché]
