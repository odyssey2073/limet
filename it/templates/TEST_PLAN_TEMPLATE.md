# Piano di test — [Nome feature / bug fix / task]

> Da compilare **prima** di scrivere il codice di produzione (o comunque prima di considerare
> un task pronto per essere marcato `done`). Vedi `FRAMEWORK_MANUAL.md` §1.5 e §5: ogni task
> prevede unit test **e** test e2e approfonditi, salvo motivazione esplicita.

## Riferimenti

- **Piano/proposta collegata**: [link a `PLAN_TEMPLATE.md` o `CHANGE_PROPOSAL_TEMPLATE.md`]
- **Task collegato/i**: [riferimento a `TASK_LIST_TEMPLATE.md` / `TASK_TEMPLATE.md`]

## Ambito della verifica

[Cosa deve essere garantito da questo piano di test — funzionalità, regressioni da evitare,
casi limite noti.]

## Unit test previsti

| # | Cosa verifica | File/classe di test | Caso (happy path / edge case / regressione) |
| - | -------------- | -------------------- | --------------------------------------------- |
| 1 | [...]          | [...]                 | [...]                                          |

### Autorevisione della qualità (obbligatoria — vedi `FRAMEWORK_MANUAL.md` §5.1)

> Da compilare prima di dichiarare completo il lavoro di test. Non è una formalità: un test può
> essere presente e tracciato e nondimeno non fallire quando il difetto torna.

- **Sabotaggio mentale**: quale singola alterazione plausibile del codice di produzione NON
  farebbe fallire nessun test? [risposta, o "nessuna" — se una esiste, manca un test]
- [ ] Ogni assert può fallire **per il motivo dichiarato** (nessun assert che non può fallire da solo)
- [ ] Il valore atteso **non è derivato** dall'oggetto sotto test
- [ ] Nessun campione arbitrario: insieme completo, o criterio di selezione scritto
- [ ] Verificato il contratto del metodo (input assenti/vuoti/non validi), non solo il percorso felice
- [ ] Eventuali ridondanze fra test sono dichiarate e motivate
- [ ] Ciò che lo unit test non può coprire è scritto, con rimando a cosa lo copre
- [ ] Nessuna mutazione di stato condiviso (l'esito non dipende dall'ordine di esecuzione)

## Test e2e previsti

> Vedi anche `E2E_VERIFICATION_TEMPLATE.md` per la checklist passo-passo di esecuzione manuale.

| # | Scenario | Precondizioni | Passi principali | Esito atteso |
| - | -------- | -------------- | ------------------ | -------------- |
| 1 | [...]    | [...]          | [...]               | [...]          |

## Dati di test necessari

[Fixture, dati di dominio, utenti/ruoli, stati particolari da preparare.]

## Casi esclusi dal test (e perché)

> Se qualcosa non viene testato, va motivato esplicitamente qui — non lasciato implicito.

- [...]

## Chi esegue

> Principio "write vs execute" (`FRAMEWORK_MANUAL.md` §1.3): chi scrive il codice non
> necessariamente esegue la build/i test. Annotare qui chi ha in carico l'esecuzione.

- **Scrittura test**: [...]
- **Esecuzione**: [...]

## Comandi di test rieseguibili

> Comando esatto per rieseguire ogni test, con breve descrizione — così chiunque (o una sessione
> futura) può riprodurre la verifica senza ridedurla.

Forme di comando (Surefire/JUnit):

- Intera classe: `./mvnw test -Dtest=MiaClasseTest`
- Singolo metodo: `./mvnw test -Dtest=MiaClasseTest#mioMetodo`

Per ogni test: lo stato da verificare **prima** (pre-test) e **dopo** (post-test) — es. righe DB
via SQL, un file su disco, un valore di config, contenuto di cache, un servizio esterno — più i
due comandi. Ometti pre/post se non applicabile.

### Test 1 — [breve descrizione]

- **Pre-test** (stato atteso prima):
  ```sql
  SELECT count(*) FROM employee;  -- atteso 0
  ```
- **Comando — intera classe**: `./mvnw test -Dtest=MiaClasseTest`
- **Comando — singolo metodo**: `./mvnw test -Dtest=MiaClasseTest#mioMetodo`
- **Post-test** (stato atteso dopo):
  ```sql
  SELECT count(*) FROM employee;  -- atteso 5
  ```

### Test 2 — [...]

- **Pre-test**: [...]
- **Comando — intera classe**: `./mvnw test -Dtest=...`
- **Comando — singolo metodo**: `./mvnw test -Dtest=...#...`
- **Post-test**: [...]
