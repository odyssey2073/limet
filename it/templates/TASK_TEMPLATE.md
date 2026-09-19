# Scheda task singolo — [Titolo task]

> Usare per un task abbastanza complesso da meritare un'analisi dedicata: quando la soluzione non
> è ovvia, servono più fonti di contesto, o ci sono decisioni da esplicitare prima di scrivere
> codice.

## 0. Sintesi

### Scopo (non tecnico)

[Cosa fa questo task e perché, in linguaggio semplice per chi non legge codice.]

### Modifiche (tecnico)

> File creati/modificati, con path e progetto; indicazione sintetica del codice inserito/
> modificato e del perché. Da compilare (o rifinire) a lavoro concluso.

| Progetto | File (path) | Creato/Modificato | Cosa cambia e perché |
| -------- | ----------- | ----------------- | -------------------- |
| ...      | `src/...`   | creato            | [...]                |

## Metadati

- **Riferimento**: task #[N] di `TASK_LIST_TEMPLATE.md` (o piano/proposta associata)
- **Stato**: `[pending | in_progress | blocked | done]`
- **Data ultimo aggiornamento**: [YYYY-MM-DD]

## 1. Descrizione del task

[Cosa va fatto, in termini concreti e verificabili — non un obiettivo generico.]

## 2. Contesto raccolto

> Elencare le fonti consultate prima di agire, e cosa è stato scoperto. Distinguere sempre un
> fatto verificato da un'assunzione.

- **Fonte 1** ([tipo: codice / documentazione / dato reale]): [cosa dice, con riferimento
  puntuale]
- **Fonte 2**: [...]

## 3. Domanda contestuale (se presente)

> Se manca un'informazione per procedere con sicurezza, esplicitarla qui **invece di assumere**.
> Non procedere oltre finché non c'è risposta, salvo assunzione dichiarata in sezione 4.

- **Domanda**: [...]
- **Perché è rilevante**: [cosa cambierebbe nella soluzione a seconda della risposta]
- **Risposta ricevuta**: [...] — **Data**: [YYYY-MM-DD] — **Da**: [chi ha risposto]

> Se si è dovuto procedere con un'assunzione motivata, dichiararlo esplicitamente qui, con il
> rischio associato.

## 4. Soluzione proposta/applicata

[Descrizione tecnica della modifica: file toccati, logica introdotta/modificata, motivazione.]

- **File 1**: [percorso] — [cosa cambia e perché]

### Alternative scartate

- [alternativa] — scartata perché [motivo]

## 5. Strategia di test (obbligatoria)

> Non omettere. Se davvero non applicabile, spiegare esplicitamente perché.

### 5.1 Unit test

- **Esistono già test che coprono quest'area?** [sì/no — riferimento]
- **Nuovi unit test previsti**: [elenco casi, o "nessuno perché..."]
- **Dove sono descritti in dettaglio**: [riferimento a `TEST_PLAN_TEMPLATE.md`]

### 5.2 Test e2e

- **Necessari?** [sì/no + motivazione]
- **Riferimento**: [link a `E2E_VERIFICATION_TEMPLATE.md` compilato per questo task]

## 6. Rischi/impatti su altre parti del sistema

[Cosa altro potrebbe essere influenzato, e come è stato verificato.]

## 7. Esito (da compilare a lavoro concluso)

- **Data**: [YYYY-MM-DD]
- **Stato finale**: [done/blocked — se blocked, motivo]
- **Esito test**: [riassunto, con riferimento a `TEST_EXECUTION_TEMPLATE.md`]
- **Note per chi leggerà questo documento in futuro**: [...]
