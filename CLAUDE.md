<!-- CEREBRO:START -->
## CEREBRO RAG — contesto progetto

La documentazione di questo progetto è indicizzata semanticamente in Qdrant
collection `CRB_limet` su http://localhost:6333
(embedding generati via Ollama con modello `nomic-embed-text`).

Quando servono informazioni su architettura, feature, convenzioni o piani del
progetto, recupera contesto con:

```bash
python "C:\Progetti\CEREBRO\scripts\query_qdrant.py" --project limet search "<query>" --limit 5
```

Regole:
- non assumere convenzioni del progetto se non verificate nei documenti recuperati;
- se modifichi codice, verifica coerenza con le convenzioni documentate;
- se Qdrant o Ollama non sono raggiungibili, segnalalo e procedi senza contesto RAG.
<!-- CEREBRO:END -->

<!-- GRAPHIFY:START -->
## GRAPHIFY — knowledge graph del codice

Per contesto a livello codice usa Graphify:

- `graphify query "<domanda>"` — domanda sul grafo (relazioni, dipendenze, simboli);
- `graphify path <A> <B>` — percorso/relazione tra due simboli;
- `graphify explain <simbolo>` — spiegazione di un simbolo/funzione;
- `graphify update .` — rigenera/aggiorna il grafo dopo modifiche al codice.

Regole:
- interroga il grafo prima di modificare funzioni con molte dipendenze;
- se il grafo non è aggiornato, lancia `graphify update .` prima di usarlo.
<!-- GRAPHIFY:END -->

## BUILD & TEST — policy

- **MAI eseguire build o test in autonomia** — l'output riempie il contesto di rumore. MAI lanciare `./mvnw package` o `./mvnw test`.
- Quando serve, **fornisci all'utente** il comando Maven Wrapper (Git Bash), chiedigli di eseguirlo e di comunicare l'esito, poi **resta in standby** finché l'esito non arriva. Usa sempre `./mvnw`, mai `.\mvnw.cmd`.

## TASK LIST — policy

- Quando generi un `PLAN.md` da `PLAN_TEMPLATE.md`, genera **sempre** anche `TASK_LIST.md` (derivato da §6) **senza chiedere** conferma.
- **Mai** chiedere "Vuoi TASK_LIST.md separato?" o simili: la generazione è automatica.

## TEST — policy

- Quando generi un `PLAN.md`, crea **sempre** anche `TEST_PLAN.md` (da `TEST_PLAN_TEMPLATE.md`), `E2E_VERIFICATION.md` (da `E2E_VERIFICATION_TEMPLATE.md`) e, a test eseguiti, `TEST_EXECUTION.md` (da `TEST_EXECUTION_TEMPLATE.md`), **senza chiedere**.
- Ogni test riporta **comando esatto di riesecuzione** (es. `./mvnw test -Dtest=...`) e **descrizione**, così l'utente può rieseguirlo.
- Al termine, archivia `TEST_PLAN.md`, `E2E_VERIFICATION.md` e `TEST_EXECUTION.md` in `limet/archive/<data-slug>/` insieme al resto.
- Prima di dare all'utente un comando di test: **indica cosa fa il test e in quale classe si trova**, poi fornisci **entrambi i comandi** — tutta la classe (`-Dtest=ClasseTest`) e il singolo metodo (`-Dtest=ClasseTest#metodo`).

## COMUNICAZIONE TASK — policy

- Quando implementi un `taskX`: (1) **comunica all'utente** che lo stai implementando; (2) **spiega in cosa consiste**; (3) al termine, **elenca quali modifiche e dove** sono state fatte (file e, se utile, righe).
