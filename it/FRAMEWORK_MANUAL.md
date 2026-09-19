# LIMET — Manuale del framework

> **LIMET** (*Lightweight Iterative Method for Engineering with Traceability*) è un metodo di
> lavoro "spec-driven" per usare in modo avanzato agenti AI da riga di comando (Copilot CLI,
> Claude Code o strumenti equivalenti) su attività di bug fixing e sviluppo di nuove feature.
> È **agnostico rispetto agli strumenti**: non assume nessun prodotto specifico per il recupero
> di documentazione, l'analisi statica del codice o l'accesso ai dati — vedi §2 per le categorie
> generiche e l'Appendice A per un setup concreto opzionale.

---

## 1. Principi generali

### 1.1 Spec-driven, non vibe-driven

Prima di modificare codice non banale, si scrive un documento che descrive **cosa** si vuole
ottenere, **perché**, e **come** (a livello di disegno) — non si procede per tentativi affidandosi
solo al contesto implicito della conversazione. Il documento è la fonte di verità condivisa tra
utente e agente.

### 1.2 Tracciabilità delle decisioni

Ogni scelta ambigua incontrata durante il lavoro va esplicitata come **domanda contestuale**, con
la risposta ottenuta e la data — mai assunta silenziosamente. Se occorre procedere comunque
(nessuna risposta disponibile in tempo utile), l'assunzione va dichiarata esplicitamente insieme
al rischio che comporta.

### 1.3 Separazione tra scrivere ed eseguire

L'agente propone/scrive modifiche e comandi; l'esecuzione di build/test/deploy può restare a cura
dell'utente o della pipeline, con i log incollati per il debug successivo. **L'agente non deve MAI
eseguire build o test in autonomia** — dà all'utente il comando, chiede di eseguirlo e di comunicare
l'esito, e resta in standby finché l'esito non arriva. Non eseguire mai comandi con effetti
persistenti (commit, push, migrazioni, deploy) senza autorizzazione esplicita.

### 1.4 Aggiornamento a ritroso della documentazione

Dopo l'implementazione, i documenti di task/piano vengono aggiornati con una sezione "Esito
implementazione" datata, che descrive cosa è stato realmente fatto (compresi eventuali
scostamenti dal piano) — non si riscrive la storia, la si completa.

### 1.5 Nessun task si considera concluso senza una strategia di verifica (vincolante)

> Questo è un principio **non negoziabile** del framework: ogni task, se non già coperto da test
> esistenti, **deve** prevedere unit test dedicati **e** un piano di test e2e approfondito con
> istruzioni passo-passo per l'esecuzione (anche manuale). Un task può essere marcato come
> `done` solo se questa sezione è compilata — anche un "non applicabile" deve essere motivato
> esplicitamente, non semplicemente omesso. Dettagli completi in §5.

---

## 2. Categorie di "context provider" (generiche)

Un agente lavora meglio quando può attingere a fonti di contesto oltre alla sola conversazione.
Si distinguono tre categorie generiche, ciascuna implementabile con strumenti diversi:

### 2.1 Contesto documentale (RAG semantico)

Un sistema che indicizza la documentazione di progetto (specifiche, note architetturali, decisioni
passate) in una forma interrogabile semanticamente, per recuperare i frammenti più rilevanti a una
domanda in linguaggio naturale. Utile per: "perché è stato fatto così", "cosa dice la specifica
su X", "qual è la convenzione di progetto per Y".

### 2.2 Contesto strutturale del codice (knowledge graph statico)

Uno strumento che analizza staticamente il codice sorgente e costruisce un grafo delle relazioni
tra simboli/moduli/chiamate, interrogabile in linguaggio naturale o per percorso tra due nodi.
Utile per: "dove è implementato X", "cosa dipende da Y", "che impatto ha modificare Z" — a costo
computazionale minimo (nessuna chiamata a modello esterno necessaria per l'analisi in sé).

### 2.3 Accesso ai dati reali (read-only)

Un canale di accesso in sola lettura ai dati reali del sistema (database applicativo, log, API di
osservabilità), da usare per verificare ipotesi sullo stato effettivo del sistema invece di
assumerlo dalla sola lettura del codice. Va sempre mantenuto rigorosamente **read-only** in
contesti di lavoro non distruttivi.

### 2.4 Criterio di combinazione

1. Domanda su "dove/come è implementato nel codice" → contesto strutturale (2.2) prima, costo
   quasi nullo.
2. Domanda su "perché/qual è la specifica" → contesto documentale (2.1).
3. Per analisi cross-modulo o comprensione di un flusso end-to-end: usare prima 2.2, poi 2.1,
   incrociare i risultati prima di scrivere un piano.
4. Per verificare un'ipotesi sullo stato reale del sistema → 2.3, sempre in sola lettura.
5. Non ripetere una ricerca se il contesto rilevante è già stato recuperato in un turno precedente
   della stessa sessione (evita spreco di tempo/token).
6. Se nessuno strumento avanzato è disponibile, vedi §7 (adattabilità/degradazione controllata).

---

## 3. Ciclo di vita di una modifica (feature o bug fix)

LIMET adotta un ciclo di vita a fasi fluide (non rigide: si può tornare a una fase precedente se
emergono nuove informazioni), ispirato ai flussi di *change proposal* spec-driven diffusi in
strumenti come OpenSpec, ma reso agnostico dagli strumenti e con l'aggiunta esplicita di una fase
di verifica.

| Fase | Scopo | Template di riferimento |
| --- | --- | --- |
| 0. Esplorazione (opzionale) | Raccogliere contesto, chiarire il problema prima di formalizzare | — (uso libero dei context provider di §2) |
| 1. Proposta | Descrivere perché, cosa cambia, come (a grandi linee) | `PLAN_TEMPLATE.md` + (per modifiche più strutturate) `CHANGE_PROPOSAL_TEMPLATE.md`, `SPEC_TEMPLATE.md`, `DESIGN_TEMPLATE.md` |
| 2. Revisione | Validare la proposta con l'utente prima di scrivere codice | domande contestuali risolte (§1.2), piano approvato |
| 3. Scomposizione in task | Tradurre la proposta in attività granulari tracciabili | `TASK_LIST_TEMPLATE.md`, `TASK_TEMPLATE.md` per i task complessi |
| 4. Applicazione | Implementare seguendo i task, aggiornandone lo stato | — (nessun template dedicato, si aggiorna la task list) |
| 5. Verifica (obbligatoria) | Unit test + test e2e secondo quanto pianificato in fase 1/3 | `TEST_PLAN_TEMPLATE.md`, `TEST_EXECUTION_TEMPLATE.md`, `E2E_VERIFICATION_TEMPLATE.md` |
| 6. Comunicazione | Sintetizzare l'esito per un pubblico non tecnico, se pertinente | `NON_TECHNICAL_SUMMARY_TEMPLATE.md` |
| 7. Archiviazione | Congelare lo storico della modifica, aggiornare la documentazione permanente | `ARCHIVE_ENTRY_TEMPLATE.md`, aggiornamento a ritroso (§1.4) |

### 3.1 Quando usare la variante "change proposal" completa (fase 1 estesa)

Per modifiche piccole/isolate, `PLAN_TEMPLATE.md` da solo è sufficiente. Per modifiche più ampie
(nuova capability, cambiamento di contratto/interfaccia tra componenti, impatto su più moduli),
conviene separare la fase 1 in tre documenti distinti, ciascuno con una responsabilità precisa:

- **`CHANGE_PROPOSAL_TEMPLATE.md`** — il *perché*: motivazione, capability nuove/modificate/
  rimosse, impatto atteso. Analogo concettuale di un documento "proposal" nei flussi spec-driven.
- **`SPEC_TEMPLATE.md`** — il *cosa*: i requisiti in forma verificabile (scenari dato/quando/
  allora), uno per ogni capability toccata. È la "specifica" a cui i test si allineeranno.
- **`DESIGN_TEMPLATE.md`** (opzionale) — il *come*: decisioni tecniche di disegno, alternative
  scartate, quando il "come" non è ovvio dalla sola specifica.

Questa separazione rende esplicito che una specifica può restare stabile anche se il disegno
tecnico cambia, e viceversa — utile per modifiche rilevanti o quando più persone (o sessioni
agente diverse) collaborano sulla stessa proposta nel tempo.

### 3.2 Fase di archiviazione

A modifica conclusa e verificata, il lavoro va "congelato": la cronologia delle decisioni non va
persa, ma nemmeno lasciata mescolata con il lavoro attivo. Usare `ARCHIVE_ENTRY_TEMPLATE.md` per
registrare, in un'unica voce datata, il riferimento alla proposta/piano originale, l'esito finale
e i documenti permanenti che sono stati aggiornati di conseguenza (es. glossario, specifiche
correnti). Questo evita che la documentazione "vivente" del progetto si accumuli all'infinito con
lavoro ormai concluso, pur mantenendone la tracciabilità.

---

## 4. Convenzioni di naming e stato

- **Stato dei documenti**: `DRAFT` → `APPROVATO` → `IN CORSO` → `COMPLETATO` (o `ABBANDONATO`).
- **Stato dei task**: `pending` → `in_progress` → `done` (o `blocked`, con motivo esplicito).
- **Date**: sempre in formato `YYYY-MM-DD`, associate a ogni decisione/aggiornamento significativo.
- **Data e ora per il passaggio a `done`**: quando un task passa a `done`, registrare **data e
  ora** in formato `YYYY-MM-DD HH:MM` (non solo la data), sia nella tabella dei task
  (`TASK_LIST_TEMPLATE.md`) sia nella sezione "Esito" di `TASK_TEMPLATE.md`. Serve a garantire un
  ordinamento cronologico preciso quando più task/sotto-task vengono completati nello stesso
  giorno (es. per capire in che ordine sono stati verificati, o quale modifica ha reso obsoleta
  un'altra). Per gli altri stati/documenti la sola data resta sufficiente, salvo che si stia
  già lavorando con più aggiornamenti nello stesso giorno, nel qual caso vale la stessa regola.
- **Aggiornamenti a ritroso**: aggiungere una sezione datata ("Esito implementazione (YYYY-MM-DD)"),
  non modificare silenziosamente il testo originale del piano.
- **Nomi file**: usare i nomi dei template così come forniti (in inglese) come base; per istanze
  concrete, aggiungere un identificativo descrittivo (es. `PLAN_TEMPLATE.md` → `PLAN_<slug>.md`).

---

## 5. Requisito vincolante: unit test + test e2e per ogni task

> Vedi anche §1.5. Questa sezione descrive **come** soddisfare il requisito, non se applicarlo:
> si applica sempre, salvo eccezione motivata esplicitamente (§5.3).

### 5.1 Unit test

Per ogni task che introduce o modifica comportamento (non solo commenti/documentazione):
- verificare se esistono già test che coprono l'area toccata; se sì, estenderli invece di
  duplicare;
- se non esistono, scriverne di nuovi mirati al comportamento modificato (non solo "far passare
  la build" — devono fallire se il bug/difetto torna);
- documentare i casi previsti in `TEST_PLAN_TEMPLATE.md` prima o durante l'implementazione, e
  l'esito reale in `TEST_EXECUTION_TEMPLATE.md` dopo l'esecuzione (che può essere effettuata
  dall'utente, non necessariamente dall'agente — vedi §1.3);
- per i test che toccano risorse con stato (DB, file, cache, servizi esterni), registrare lo stato
  da verificare **prima** (pre) e **dopo** (post) il test — es. query SQL sul DB — non solo la
  risposta di ritorno/HTTP.

### 5.2 Test e2e approfonditi

Da prevedere quando gli unit test da soli non danno fiducia sufficiente (integrazioni esterne,
effetti collaterali su sistemi reali, comportamento dipendente da configurazione/ambiente,
interfacce utente, timing/concorrenza). Il documento di verifica e2e (`E2E_VERIFICATION_TEMPLATE.md`)
deve sempre includere:
- **Precondizioni** (ambiente, dati di test necessari, stato di partenza);
- **Passi numerati** eseguibili da un umano senza conoscenza pregressa del task;
- **Risultato atteso per ogni passo** (non solo alla fine — permette di individuare a che punto
  qualcosa si discosta);
- **Come verificare l'esito** in modo oggettivo (query di controllo, log attesi, risposta attesa)
  — evitare "verificare che funzioni" senza criteri misurabili;
- **Controllo pre/post dello stato**: lo stato da verificare prima dei passi e dopo i passi (righe
  DB via SQL, file, config, cache, servizi esterni) — non solo la risposta finale;
- **Rollback/pulizia** se il test lascia stato residuo nel sistema.

Non è necessario che sia automatizzato: può essere una checklist manuale, purché sufficientemente
dettagliata da essere ripetibile da chiunque, non solo da chi l'ha scritta.

### 5.3 Quando è accettabile omettere

Solo per modifiche puramente non comportamentali (es. commenti, riformattazione senza effetto
funzionale, rinomina di variabili interne senza cambi di contratto) — e comunque va dichiarato
esplicitamente nel documento di task, non lasciato sottinteso.

---

## 6. Anti-pattern da evitare

- **Assumere invece di chiedere**: procedere su un'ambiguità senza registrarla come domanda
  contestuale (§1.2).
- **Eseguire operazioni con effetti persistenti senza permesso**: commit, push, migrazioni,
  comandi distruttivi non esplicitamente richiesti.
- **Documentazione che diverge dal codice reale**: piani/task non aggiornati dopo che
  l'implementazione reale si è discostata da quanto previsto.
- **Task marcato `done` senza verifica**: scrivere codice non equivale a un task concluso; serve
  la strategia di verifica di §5 completata (o esplicitamente motivata come non applicabile).
- **Accumulo di documentazione "viva" mai archiviata**: piani conclusi da mesi che restano
  mescolati al lavoro attivo, invece di essere congelati con `ARCHIVE_ENTRY_TEMPLATE.md`.
- **Uso esclusivamente per intuizione (vibe-driven) su modifiche non banali**: saltare la fase di
  proposta/specifica per cambiamenti che meriterebbero un piano scritto.

---

## 7. Adattabilità: lavorare senza strumenti avanzati (degradazione controllata)

Il framework resta valido anche senza contesto documentale semantico o knowledge graph del
codice:
- il contesto documentale (2.1) si sostituisce con ricerca testuale/full-text manuale nella
  documentazione esistente;
- il contesto strutturale (2.2) si sostituisce con ricerca testuale nel codice (grep/ricerca per
  simbolo) ed esplorazione manuale dei riferimenti;
- l'accesso ai dati reali (2.3) resta valido solo se un canale read-only esiste comunque (anche
  una semplice query manuale va bene, purché in sola lettura).

Ciò che **non** cambia mai, indipendentemente dagli strumenti disponibili, è il principio di
tracciabilità (§1.2) e il requisito di verifica (§1.5/§5): sono principi metodologici, non legati
a nessuno strumento specifico.

---

## 8. Indice dei template disponibili

| Template | Quando usarlo |
| --- | --- |
| `templates/PLAN_TEMPLATE.md` | Prima di iniziare una feature/bug fix non banale (uso singolo, modifiche piccole/medie) |
| `templates/CHANGE_PROPOSAL_TEMPLATE.md` | Per modifiche più ampie: il *perché* e l'impatto atteso |
| `templates/SPEC_TEMPLATE.md` | Il *cosa*: requisiti verificabili per una capability toccata |
| `templates/DESIGN_TEMPLATE.md` | Il *come* (opzionale): decisioni tecniche non ovvie dalla sola specifica |
| `templates/TASK_LIST_TEMPLATE.md` | Per scomporre il piano/proposta in task tracciabili |
| `templates/TASK_TEMPLATE.md` | Per un task complesso che richiede analisi/domande esplicite |
| `templates/BUG_REPORT_TEMPLATE.md` | Quando si isola un difetto da correggere |
| `templates/TEST_PLAN_TEMPLATE.md` | Per pianificare gli unit test (e i criteri e2e) di un task |
| `templates/TEST_EXECUTION_TEMPLATE.md` | Per registrare l'esito reale di un'esecuzione di test |
| `templates/E2E_VERIFICATION_TEMPLATE.md` | Per una checklist di verifica manuale end-to-end |
| `templates/NON_TECHNICAL_SUMMARY_TEMPLATE.md` | Per comunicare l'esito a un pubblico non tecnico |
| `templates/GLOSSARY_TEMPLATE.md` | Per fissare terminologia/concetti di dominio condivisi |
| `templates/ARCHIVE_ENTRY_TEMPLATE.md` | Per congelare lo storico di una modifica conclusa |

**Template di livello workspace** (per scenari multi-progetto/multi-modulo, vedi Appendice C —
installati in `limet-workspace/templates/`, non in `limet/templates/` del singolo progetto):

| Template | Quando usarlo |
| --- | --- |
| `templates/MODULE_MAP_TEMPLATE.md` | Per mappare i progetti/moduli di un workspace, i loro ruoli e le dipendenze/contratti tra loro |
| `templates/CROSS_PROJECT_CHANGE_TEMPLATE.md` | Per coordinare una modifica (feature o bug fix) che attraversa più progetti/moduli |

**Template di documentazione della codebase** (generati in `docs/_templates/` da `limet-index`, vedi
§A.4 — documentano la codebase stessa, non una singola modifica):

| Template | Quando usarlo |
| --- | --- |
| `templates/ARCHITECTURE_TEMPLATE.md` | Per scrivere la panoramica architetturale che completa il report Graphify |
| `templates/CONVENTIONS_TEMPLATE.md` | Per distillare le convenzioni di codice del progetto dalla codebase |

Vedi anche `ONBOARDING_CHECKLIST.md` per una checklist rapida operativa da seguire a inizio
sessione, e `scripts/limet.ps1` / `scripts/limet.sh` per l'installazione automatica (§9).

Per il setup concreto di strumenti di supporto (RAG documentale, knowledge graph codice) vedi
**Appendice A**; per esempi operativi completi passo-passo (setup progetto, nuovo progetto, bug
fix, nuova feature) vedi **Appendice B**; per scenari multi-progetto/multi-modulo (workspace) vedi
**Appendice C**. Per l'ordine di lettura consigliato dell'intera cartella LIMET vedi
`MASTER_INDEX.md`.

---

## 9. Attivazione pratica: come far seguire LIMET a Copilot CLI / Claude Code

Avere questi documenti scritti non basta: l'agente deve essere **istruito a consultarli e
applicarli** a ogni sessione, non solo quando gli viene chiesto esplicitamente. LIMET usa **un
solo meccanismo di attivazione, trasversale a tutti gli strumenti**, non una soluzione diversa
per ciascuno — proprio perché convenzioni di skill/plugin differiscono da tool a tool e
manutenere N varianti custom sarebbe fragile e disallineabile nel tempo.

### 9.1 Il meccanismo: `AGENTS.md` come fonte unica + import in `CLAUDE.md`

- **`AGENTS.md`** nella root del progetto è la fonte unica di verità. È lo standard aperto
  "agents.md" letto nativamente da Copilot CLI e dalla maggior parte degli agenti CLI moderni che
  lo supportano.
- **Claude Code** legge di default `CLAUDE.md`, non `AGENTS.md`. Il modo ufficialmente
  documentato per fargli leggere anche `AGENTS.md` è una singola riga di import `@AGENTS.md` in
  cima a `CLAUDE.md` — è una funzionalità nativa di Claude Code (import di file), non un
  workaround specifico di LIMET.
- Risultato: **un solo contenuto scritto una sola volta** (il blocco LIMET in `AGENTS.md`), letto
  da entrambi gli strumenti. Nessun contenuto duplicato, nessuna logica per-tool da mantenere.

### 9.2 Installazione tramite script

Gli script `scripts/limet.ps1` (PowerShell) e `scripts/limet.sh` (Bash, eseguibile anche da WSL/
Linux/macOS) automatizzano l'attivazione, sul modello `init`/`update` di strumenti analoghi:

```powershell
# PowerShell
.\scripts\limet.ps1 init -ProjectPath C:\percorso\progetto -Lang it
.\scripts\limet.ps1 update -ProjectPath C:\percorso\progetto -Lang it
```

```bash
# Bash
./scripts/limet.sh init --project-path /percorso/progetto --lang it
./scripts/limet.sh update --project-path /percorso/progetto --lang it
```

Cosa fa `init`:

1. Copia il manuale, la checklist di onboarding e i template (edizione IT o EN) in
   `<progetto>/limet/`, insieme alle cartelle `limet/changes/` (lavoro in corso) e
   `limet/archive/` (lavoro concluso).
2. Scrive/aggiorna un blocco marcato (`<!-- LIMET:START -->` / `<!-- LIMET:END -->`) in
   `AGENTS.md` nella root del progetto, con i principi vincolanti e i riferimenti ai template.
3. Crea `CLAUDE.md` con la riga `@AGENTS.md` (se il file non esiste), oppure la prepone se manca
   (senza toccare il resto del contenuto esistente).

`update` ripete gli stessi passi in modo **idempotente**: rigenera il contenuto di `limet/`
dall'edizione sorgente e sostituisce il blocco marcato in `AGENTS.md` in-place, senza duplicarlo;
se `CLAUDE.md` contiene già l'import non lo tocca.

### 9.3 Verifica dopo l'installazione

- A inizio sessione, chiedere esplicitamente conferma che l'agente conosce la posizione del
  manuale e dei template (non assumere che l'abbia letto solo perché il blocco è presente).
- Rieseguire `init`/`update` su una cartella di prova per controllare che non vengano duplicati
  blocchi (`grep -c 'LIMET:START' AGENTS.md` deve restituire `1`).

### 9.4 Cosa NON basta

- Limitarsi a salvare i documenti in `limet/` senza referenziarli in `AGENTS.md`/`CLAUDE.md`: un
  agente non "scopre" da solo un framework non menzionato nelle sue istruzioni di sessione.
- Menzionare il framework una tantum in un messaggio di chat: senza un blocco persistente nei
  file di istruzioni, l'indicazione si perde alla sessione successiva.
- Presumere che l'agente applichi §1.5/§5 (test obbligatori) "perché è scritto nel manuale": è
  richiamato esplicitamente nel blocco generato dallo script, perché è la regola più facile da
  dimenticare sotto pressione di consegna.
- Creare soluzioni diverse per ogni tool (skill separate, cartelle di istruzioni parallele): va
  contro il principio "una sola fonte" di questa sezione.

---

## Appendice A — Setup di riferimento con strumenti concreti (opzionale)

> Il corpo del manuale (§1-8) è volutamente agnostico da prodotti specifici, perché le categorie
> di §2 possono essere implementate con strumenti diversi. Questa appendice documenta un **setup
> concreto di riferimento**, realmente utilizzabile, per chi vuole partire subito senza dover
> scegliere/valutare alternative. Sostituisce le categorie di §2 così:
> - §2.1 (contesto documentale/RAG) → **CEREBRO** + **Qdrant** + **Ollama**
> - §2.2 (contesto strutturale del codice) → **Graphify**
> - §2.3 (accesso dati reali) → resta a scelta del progetto (es. connettore MCP read-only al DB
>   applicativo), non trattato qui perché troppo specifico dell'infrastruttura di ogni progetto.

### A.1 CEREBRO (RAG documentale locale, multi-progetto)

Repository: <https://github.com/odyssey2073/cerebro>

**Cos'è**: un sistema RAG locale e multi-progetto. Indicizza la documentazione di un progetto
(`.md`, `.txt`, `.pdf`, `.docx`, `.xlsx`, `.pptx`, `.html`) in un vector database, e genera
automaticamente i blocchi di istruzioni (`CLAUDE.md` / `copilot-instructions.md`) che insegnano
all'agente come interrogarlo. Ogni progetto ha una collection isolata (`CRB_<slug>`) — nessuna
contaminazione tra progetti diversi. Funziona **100% in locale**: nessuna chiamata cloud, nessuna
API key, i documenti non lasciano la macchina.

**Prerequisiti**: Python 3.10+, Docker Desktop (per Qdrant), Ollama (per gli embedding).

**Setup una tantum**:

```powershell
# 1. Qdrant (vector database) — richiede Docker Desktop avviato
docker pull qdrant/qdrant
docker run -d --name qdrant -p 6333:6333 -p 6334:6334 -v qdrant_storage:/qdrant/storage qdrant/qdrant
curl http://localhost:6333/collections   # verifica: risposta JSON con elenco collection (vuoto)

# 2. Ollama + modello di embedding
#    installare Ollama da https://ollama.com, poi:
ollama pull nomic-embed-text
curl http://localhost:11434   # verifica: "Ollama is running"

# 3. Clone del repo CEREBRO + virtualenv
git clone https://github.com/odyssey2073/cerebro.git
cd cerebro
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
# .env di default già corretto per un'installazione locale standard
# (QDRANT_URL=http://localhost:6333, OLLAMA_URL=http://localhost:11434, EMBEDDING_MODEL=nomic-embed-text)
```

**Setup di un nuovo progetto** (esempio con progetto `miaapp` in `C:\Progetti\miaapp`):

```powershell
# 1. Registrare il progetto (dove sono i docs, dov'è la root)
python scripts\register_project.py add miaapp --docs "C:\Progetti\miaapp\docs" --root "C:\Progetti\miaapp"

# 2. Indicizzare i documenti (crea la collection CRB_miaapp)
python scripts\ingest_docs.py --project miaapp

# 3. Generare le istruzioni per l'agente (CLAUDE.md e/o copilot-instructions.md)
python scripts\register_project.py instructions miaapp --tool both

# 4. Verifica
python scripts\query_qdrant.py --project miaapp count
python scripts\query_qdrant.py --project miaapp search "architettura" --limit 3
```

**Manutenzione**:
- Documenti aggiornati → ri-eseguire `ingest_docs.py` (incrementale per file, no duplicati).
- Nuova cartella docs → `register_project.py add` con l'elenco aggiornato, poi ingest.
- Documento eliminato → `remove_doc.py --project miaapp --source "<path relativo>"`.
- Dismissione progetto → `register_project.py remove miaapp` (la collection Qdrant resta, va
  eliminata a parte se necessario: `curl -X DELETE http://localhost:6333/collections/CRB_miaapp`).

**Query manuale**: `python scripts\query_qdrant.py --project miaapp search "<domanda>" --limit 5`

**Launcher web (consigliato)**: CEREBRO fornisce una SPA web locale
(`python scripts\cerebro-launcher.py`) che gestisce nuovo progetto, re-index, status, rimozione e
query dal browser — una sola interfaccia per Claude Code e GitHub Copilot. Vedi `INSTALL.md` nel
repo CEREBRO per come avviarla e usarla.

**Server MCP (RAG trasparente)**: `scripts\limet_mcp.py` in CEREBRO espone un unico tool
`limet_search` (embedding della query via Ollama → search su Qdrant) così Claude Code e Copilot CLI
interrogano i documenti senza digitare il comando manuale. Si registra una volta per tool:

- Claude Code: `.mcp.json` nel progetto, o `claude mcp add limet -- python <path-a-limet_mcp.py>`.
- Copilot CLI: `copilot mcp add limet -- python <path-a-limet_mcp.py>`, o `.github/mcp.json` nel
  progetto.

Claude Code può inoltre auto-iniettare il RAG a ogni prompt con un hook `UserPromptSubmit`
(`scripts\limet_rag.py`, configurato in `.claude/settings.json`). Copilot CLI non ha un hook
equivalente: si affida al tool `limet_search` + l'istruzione in `AGENTS.md`.

**Troubleshooting rapido**:

| Sintomo | Causa probabile | Fix |
| --- | --- | --- |
| `Connection refused :6333` | Qdrant non avviato | `docker start qdrant` |
| `Connection refused :11434` | Ollama non avviato | `ollama serve` |
| `Collection doesn't exist` | mai indicizzato | eseguire il passo 2 del setup progetto |
| Risultati non aggiornati | docs cambiati, non re-indicizzati | ri-eseguire `ingest_docs.py` |

### A.2 Graphify (knowledge graph statico del codice)

**Cos'è**: uno strumento che analizza staticamente (AST) il codice sorgente di un progetto e
costruisce un knowledge graph delle relazioni tra simboli/moduli/chiamate, interrogabile in
linguaggio naturale. Complementare a CEREBRO: CEREBRO copre la documentazione, Graphify copre la
struttura reale del codice (utile per verificare che la documentazione non sia disallineata).

**Installazione (CLI)**:

```powershell
# opzione consigliata (via uv, https://github.com/astral-sh/uv)
uv tool install graphifyy

# alternative
pipx install graphifyy
pip install graphifyy
```

**Registrazione della skill per l'assistente AI in uso** (una tantum, a livello utente o di
progetto):

```powershell
graphify install                # rilevamento automatico dell'assistente in uso
graphify install --project      # oppure, solo per il progetto corrente
```

**Generazione del grafo** (da eseguire nella root del progetto/codebase da analizzare):

```powershell
graphify .
```

Genera nella cartella `graphify-out/`:
- `graph.json` — rappresentazione machine-readable del grafo;
- `graph.html` — visualizzazione interattiva navigabile nel browser;
- `GRAPH_REPORT.md` — report architetturale in linguaggio naturale, utile per una review ad alto
  livello senza dover esplorare il grafo interattivo.

**Interrogazione del grafo**:

```powershell
graphify query "cosa collega ClasseA a ClasseB?"
graphify explain "NomeClasse"
graphify path "ClasseA" "ClasseB"
```

**Aggiornamento dopo modifiche al codice** (solo analisi AST, nessuna chiamata a modelli esterni,
costo trascurabile):

```powershell
graphify update .
```

**Nota su scope**: se il progetto ha anche una cartella di documentazione indicizzata da CEREBRO
(es. `docs/`), è buona norma escluderla dall'analisi di Graphify tramite un file `.graphifyignore`
nella root del progetto, per mantenere la separazione delle responsabilità (Graphify = solo
codice, CEREBRO = solo documentazione) ed evitare duplicazione di informazioni tra le due fonti.

### A.3 Combinazione pratica CEREBRO + Graphify (riepilogo operativo)

Coerente con il criterio generale di §2.4:

1. Domanda su "dov'è implementato/come funziona X nel codice" → `graphify query`/`graphify
   explain`/`graphify path` prima (costo quasi nullo, nessuna chiamata a modello esterno).
2. Domanda su "perché è stato fatto così"/"cosa dice la specifica" → query CEREBRO
   (`query_qdrant.py search`) sulla documentazione indicizzata.
3. Per analisi cross-modulo o comprensione di un flusso end-to-end: eseguire prima 1, poi 2,
   incrociare i risultati prima di scrivere un piano o proporre una soluzione.
4. Non ripetere una ricerca CEREBRO se il contesto rilevante è già stato recuperato in un turno
   precedente della stessa sessione (evita spreco di token/tempo).

### A.4 Mantenere gli indici aggiornati (lato scrittura): `limet-index`

A.1-A.3 coprono il setup e il *recupero* (interrogare indice/grafo). Non dicono **quando
ricostruirli**. È il ruolo dello script trasversale `scripts/limet-index.ps1` (e `limet-index.sh`),
installato nella cartella `limet/scripts/` di ogni progetto da `limet init`.

`limet-index` collega i tre strumenti sul lato **scrittura**:

| Comando | Effetto |
| --- | --- |
| `limet/scripts/limet-index.ps1 init -ProjectPath .` | crea `docs/` + template codebase-doc, esegue `graphify .` (report architetturale → `docs/architecture/GRAPH_REPORT.md`), registra il progetto in CEREBRO (`CRB_<slug>`), indicizza i documenti e scrive il blocco `<!-- LIMET-CONTEXT:START/END -->` in `AGENTS.md` |
| `limet/scripts/limet-index.ps1 update -ProjectPath .` | riesegue `graphify update .` e re-indicizza (upsert deterministico, nessun duplicato) |
| `limet/scripts/limet-index.ps1 status -ProjectPath .` | stampa i progetti registrati e il conteggio chunk di questo progetto |
| `limet/scripts/limet-index.ps1 remove -ProjectPath .` | rimuove dal registro CEREBRO (la collection Qdrant resta; il comando DELETE è stampato per una rimozione deliberata con doppia conferma) |

**Cosa viene indicizzato** (collection `CRB_<slug>` del progetto):
- `docs/` — documentazione generata della codebase: `architecture/GRAPH_REPORT.md` (auto, Graphify)
  più i documenti scritti dall'agente `architecture/ARCHITECTURE.md`, `conventions.md`,
  `module-map.md`, `glossary.md` (dai template in `docs/_templates/`).
- `limet/changes/` e `limet/archive/` — i documenti LIMET prodotti nel ciclo di vita (§3).

L'indicizzazione è **ricorsiva**: ogni sottocartella delle cartelle registrate viene ingerita,
quindi `docs/features/` o `docs/bugfixes/` sono indicizzate esattamente come la radice `docs/`.
Solo due percorsi vengono saltati: `docs/_templates/` (scaffolding dei template) e `.obsidian/`
(stato dell'editor).

**Aggiunta documenti via launcher**: la UI web `scripts/limet-launcher.py` offre l'azione
"Documentazione → Aggiungi documenti" che copia i file selezionati in `docs/` (opzionalmente nella
sottocartella scelta in "Sotto-cartella": `features`, `bugfixes`, o nessuna) e poi esegue
`limet-index update` — così i file vengono scritti su disco **e** indicizzati su Qdrant
(`graphify update` rieseguito).

**Workspace / multi-progetto**: eseguendo `limet-index init -Workspace` sulla cartella padre si crea
una collection `CRB_<ws>` per `limet-workspace/changes/`, `limet-workspace/archive/` e
`MODULE_MAP.md`. Ogni progetto sotto il workspace la rileva automaticamente e registra `CRB_<ws>`
come extra collection, così `query_qdrant.py --project <slug>` interroga entrambe. Vedi Appendice C.

**Cross-tool**: `limet-index` è una semplice CLI senza file per-tool; i comandi di query e
manutenzione sono scritti una volta nel blocco `AGENTS.md`, letti da Copilot nativamente e da
Claude Code via l'import `@AGENTS.md` (§9).

**Hook del ciclo di vita**: dopo aver archiviato una modifica (fase 7 / `ARCHIVE_ENTRY_TEMPLATE.md`),
esegui `limet-index update` così i documenti archiviati diventano contesto ricercabile. È il
corrispettivo in scrittura del routing in lettura di §2.4 / A.3, e degrada con grazia (§7): senza
CEREBRO/Graphify i documenti restano su disco e ricercabili con full-text.

---

## Appendice B — Guida operativa: esempi concreti passo-passo

> Le sezioni seguenti usano un progetto di esempio **fittizio** ("TaskFlow", una generica web app
> di gestione attività — nessun riferimento a progetti reali) per mostrare, comando per comando e
> documento per documento, come si applica LIMET in quattro scenari operativi tipici. Percorsi ed
> esempi sono adattabili a qualunque progetto reale.

### Convenzione di cartella per il lavoro in corso

Ogni modifica (bug fix o feature) vive in una sottocartella dedicata di `limet/changes/`, con
nome `NNNN-slug-breve` (numero progressivo a 4 cifre + slug descrittivo), per mantenere ordine
cronologico e univocità:

```
<progetto>/limet/changes/0001-nome-modifica/
  PLAN.md               (o CHANGE_PROPOSAL.md + SPEC.md + DESIGN.md)
  TASK_LIST.md
  TEST_PLAN.md
  TEST_EXECUTION.md
  ...
```

A modifica conclusa, l'intera sottocartella viene riassunta con `ARCHIVE_ENTRY_TEMPLATE.md` e
spostata (o linkata) in `limet/archive/0001-nome-modifica/`.

### B.1 Setup di LIMET su un progetto esistente

**Scenario**: esiste già il repository `C:\Progetti\TaskFlow` e si vuole attivare LIMET.

1. Dalla cartella sorgente di LIMET, eseguire lo script di installazione indicando il progetto
   target e la lingua desiderata:

   ```powershell
   cd C:\Progetti\VSC\LIMET
   .\scripts\limet.ps1 init -ProjectPath C:\Progetti\TaskFlow -Lang it
   ```

2. Lo script:
   - copia manuale, checklist e template in `C:\Progetti\TaskFlow\limet\` (con `changes\` e
     `archive\` vuote, pronte all'uso);
   - scrive il blocco marcato in `C:\Progetti\TaskFlow\AGENTS.md` (lo crea se non esiste);
   - crea `C:\Progetti\TaskFlow\CLAUDE.md` con la riga `@AGENTS.md` (o la prepone se il file
     esiste già senza quella riga).

3. **Verifica manuale**: aprire `C:\Progetti\TaskFlow\AGENTS.md` e controllare la presenza del
   blocco tra `<!-- LIMET:START -->` e `<!-- LIMET:END -->`; aprire `CLAUDE.md` e controllare la
   riga `@AGENTS.md` in cima.

4. **Primo avvio di sessione**: aprire e seguire
   `C:\Progetti\TaskFlow\limet\ONBOARDING_CHECKLIST.md`.

5. **Aggiornamenti futuri** (nuova versione di LIMET, template aggiunti/modificati): rieseguire
   lo stesso comando sostituendo `init` con `update` — è idempotente, non duplica nulla.

   ```powershell
   .\scripts\limet.ps1 update -ProjectPath C:\Progetti\TaskFlow -Lang it
   ```

### B.2 Creazione di un nuovo progetto con LIMET (partendo da zero)

**Scenario**: si vuole avviare da zero il progetto "TaskFlow", con LIMET operativo fin dal primo
commit.

1. Creare la cartella di progetto e inizializzare il repository:

   ```powershell
   New-Item -ItemType Directory -Path C:\Progetti\TaskFlow
   cd C:\Progetti\TaskFlow
   git init
   ```

2. Installare LIMET (crea anche la cartella se non esistesse ancora):

   ```powershell
   C:\Progetti\VSC\LIMET\scripts\limet.ps1 init -ProjectPath C:\Progetti\TaskFlow -Lang it
   ```

3. Prima di scrivere la prima riga di codice, creare il primo piano copiando il template:

   ```powershell
   New-Item -ItemType Directory -Path C:\Progetti\TaskFlow\limet\changes\0001-setup-iniziale
   Copy-Item C:\Progetti\TaskFlow\limet\templates\PLAN_TEMPLATE.md `
     C:\Progetti\TaskFlow\limet\changes\0001-setup-iniziale\PLAN.md
   ```

   Compilare `PLAN.md`: scope della prima iterazione (es. "scheletro applicativo minimo, senza
   funzionalità di dominio"), decisioni tecniche di base, eventuali domande contestuali aperte.

4. Derivare l'elenco task dal piano copiando `TASK_LIST_TEMPLATE.md` nella stessa sottocartella e
   compilandolo con i task granulari (es. "inizializzare struttura repo", "configurare pipeline
   di build", "primo endpoint di health-check").

5. Per ciascun task non banale, compilare `TEST_PLAN_TEMPLATE.md` **prima** di implementare, poi
   implementare, poi registrare l'esito in `TEST_EXECUTION_TEMPLATE.md` (si veda B.3 per il
   dettaglio del ciclo completo, identico anche per il primo setup).

6. A fine iterazione, archiviare con `ARCHIVE_ENTRY_TEMPLATE.md` come descritto in B.3/B.4.

### B.3 Bug fix su un progetto con LIMET (esempio concreto)

**Scenario**: è stato segnalato che nell'app TaskFlow il pulsante "Esporta CSV" produce un file
che non include la colonna "stato" dell'attività.

1. **Consultare la checklist di onboarding** (`limet/ONBOARDING_CHECKLIST.md`) a inizio sessione.

2. **Creare la cartella della modifica e il bug report**:

   ```powershell
   New-Item -ItemType Directory -Path C:\Progetti\TaskFlow\limet\changes\0002-fix-export-csv-stato
   Copy-Item C:\Progetti\TaskFlow\limet\templates\BUG_REPORT_TEMPLATE.md `
     C:\Progetti\TaskFlow\limet\changes\0002-fix-export-csv-stato\BUG_REPORT.md
   ```

   Compilare `BUG_REPORT.md`: comportamento osservato (manca la colonna), comportamento atteso
   (colonna presente con il valore corrente), passi di riproduzione, e — dopo l'investigazione nel
   codice — la causa radice (es. "la funzione che genera le intestazioni CSV non è stata
   aggiornata quando è stato introdotto il campo 'stato'").

3. **Elenco task**: per un fix puntuale come questo, un `TASK_LIST.md` minimale (1-2 righe) è
   sufficiente — copiare `TASK_LIST_TEMPLATE.md` nella stessa sottocartella, con una riga che
   punta al `BUG_REPORT.md`.

4. **Piano di test — prima di scrivere il fix**: copiare `TEST_PLAN_TEMPLATE.md` e definire lo
   unit test di regressione (deve fallire con il bug presente): es. "generare un export CSV per
   un'attività con stato 'completata' e verificare che l'intestazione e il valore della colonna
   'stato' siano presenti nell'output".

5. **Implementare il fix minimale** nel codice, seguendo esattamente la causa radice individuata
   al passo 2 (non un fix cosmetico sul sintomo).

6. **Eseguire i test e registrare l'esito reale** in `TEST_EXECUTION.md` (copiato da
   `TEST_EXECUTION_TEMPLATE.md`): comando eseguito, log/estratto, esito PASS/FAIL.

7. **Segnare il task come `done`** in `TASK_LIST.md`, con data e ora (`YYYY-MM-DD HH:MM`), solo
   dopo che il test è verde.

8. **Verifica e2e manuale**: copiare `E2E_VERIFICATION_TEMPLATE.md`, compilare i passi (es.
   "esportare CSV da un'attività reale in ambiente di test, aprire il file, controllare la
   colonna"), eseguirli e registrare l'esito.

9. **Chiudere e archiviare**: copiare `ARCHIVE_ENTRY_TEMPLATE.md`, riassumere la modifica,
   spostare/linkare la sottocartella in `limet/archive/0002-fix-export-csv-stato/`.

### B.4 Aggiunta di una nuova feature su un progetto con LIMET (esempio concreto)

**Scenario**: si vuole aggiungere a TaskFlow la possibilità di esportare le attività anche in
formato PDF (oltre al CSV già esistente).

1. **Consultare la checklist di onboarding**, come sempre a inizio lavoro.

2. **Creare la cartella della modifica e la proposta**:

   ```powershell
   New-Item -ItemType Directory -Path C:\Progetti\TaskFlow\limet\changes\0003-export-pdf
   Copy-Item C:\Progetti\TaskFlow\limet\templates\CHANGE_PROPOSAL_TEMPLATE.md `
     C:\Progetti\TaskFlow\limet\changes\0003-export-pdf\CHANGE_PROPOSAL.md
   ```

   Compilare il *perché* (es. "richiesta ricorrente degli utenti per condividere report non
   modificabili") e l'impatto atteso.

3. **Specifica** (`SPEC.md`, da `SPEC_TEMPLATE.md`): il *cosa* in termini verificabili — es.
   "dato un elenco di attività filtrate, l'utente può generare un PDF con le stesse colonne
   dell'export CSV, impaginato su A4, con intestazione contenente data e filtro applicato".

4. **Disegno tecnico** (opzionale, `DESIGN.md` da `DESIGN_TEMPLATE.md`): decisioni non ovvie dalla
   sola specifica — es. scelta della libreria di generazione PDF, gestione dell'impaginazione per
   elenchi lunghi (paginazione), gestione errori di generazione.

5. **Elenco task** (`TASK_LIST.md` da `TASK_LIST_TEMPLATE.md`): scomporre in task granulari, es.
   "endpoint backend di generazione PDF", "pulsante 'Esporta PDF' in UI", "gestione permessi di
   export", "test di generazione con elenco vuoto (edge case)".

6. **Per ciascun task**: `TEST_PLAN.md` prima di implementare (unit test sul contenuto/struttura
   del PDF generato, test e2e sul pulsante in UI), implementazione, poi `TEST_EXECUTION.md` con
   l'esito reale, poi `done` con data/ora in `TASK_LIST.md`.

7. **Sintesi non tecnica** (`NON_TECHNICAL_SUMMARY.md` da `NON_TECHNICAL_SUMMARY_TEMPLATE.md`):
   una volta conclusa la feature, riassumere per un pubblico non tecnico cosa cambia per l'utente
   (nuovo pulsante "Esporta PDF"), senza dettagli implementativi.

8. **Verifica e2e finale** (`E2E_VERIFICATION.md`): checklist manuale end-to-end su ambiente di
   test/staging prima del rilascio.

9. **Chiudere e archiviare**: `ARCHIVE_ENTRY.md`, spostare/linkare la sottocartella in
   `limet/archive/0003-export-pdf/`.

## Appendice C — Scenari multi-progetto: workspace con più progetti/moduli correlati

Questa appendice copre il caso in cui il lavoro non riguarda un singolo progetto isolato, ma:

- **due o più repository separati e correlati**, lavorati in parallelo (es. un backend e un
  frontend in repo distinti, oppure un servizio principale e un servizio satellite che lo
  consuma);
- oppure **un unico repository (monorepo) composto da più moduli**, ciascuno dei quali viene
  trattato come un "progetto" a sé stante ai fini di LIMET (proprio `limet/`, proprio ciclo di
  vita delle modifiche).

In entrambi i casi si introduce un **livello di coordinamento a livello di workspace**, distinto e
sovraordinato rispetto ai singoli `limet/` di progetto, che serve a mappare le relazioni tra i
progetti/moduli e a coordinare le modifiche che li attraversano.

Esempio ricorrente usato in questa appendice: il progetto fittizio "TaskFlow" (introdotto in
Appendice B) viene esteso con un secondo progetto correlato, **"TaskFlow-Notifications"** (un
servizio satellite che invia notifiche quando una card cambia stato), che espone un contratto
(API/evento) consumato da TaskFlow.

### C.0 — Il livello "workspace" in breve

- Si installa con lo stesso script di installazione (`limet.ps1` / `limet.sh`), aggiungendo il
  flag `-Workspace` (PowerShell) o `--workspace` (Bash), puntato sulla cartella **padre** che
  contiene i vari progetti (o sulla radice del monorepo).
- Crea una cartella `limet-workspace/` (parallela, non dentro, ai singoli `limet/` di progetto)
  con:
  - `MODULE_MAP.md` — l'inventario dei progetti/moduli, i loro ruoli, le dipendenze/contratti tra
    loro, l'ordine di build/deploy (da `MODULE_MAP_TEMPLATE.md`, compilato manualmente una volta e
    poi mantenuto aggiornato — **non viene mai sovrascritto automaticamente** dagli aggiornamenti
    dello script, per non perdere il lavoro fatto);
  - `templates/MODULE_MAP_TEMPLATE.md` e `templates/CROSS_PROJECT_CHANGE_TEMPLATE.md` (solo questi
    due, non l'intero set di 13 template per-progetto, perché a livello di workspace si coordina,
    non si implementa);
  - `changes/`, `archive/` per le modifiche cross-progetto (stessa logica di `limet/changes/` ma a
    livello di workspace);
  - un blocco marcato `<!-- LIMET-WORKSPACE:START/END -->` nell'`AGENTS.md` della cartella
    workspace (distinto dal blocco `<!-- LIMET:START/END -->` usato nei singoli progetti), più un
    `CLAUDE.md` con `@AGENTS.md`.
- Ogni progetto/modulo mantiene **il proprio `limet/` locale**, installato normalmente (senza
  `-Workspace`) nella propria root. Il blocco standard scritto in ogni `AGENTS.md` di progetto
  include già un promemoria per l'agente: controllare se esiste una cartella `limet-workspace/`
  a livello superiore e, in caso affermativo, consultare `MODULE_MAP.md` prima di modifiche che
  potrebbero avere impatti su altri progetti.
- **Non sostituisce** i documenti per-progetto (`PLAN.md`, `TASK_LIST.md`, ecc.): li **coordina**.
  Il lavoro di dettaglio (piano, task, test) resta sempre nel `limet/` del singolo progetto
  coinvolto.

### C.1 — Setup di un nuovo workspace con più progetti correlati

Caso: si vogliono gestire con LIMET due repository già esistenti e correlati, `taskflow-backend/`
e `taskflow-notifications/`, entrambi dentro una cartella padre comune `taskflow-suite/`.

```
taskflow-suite/
  taskflow-backend/          (repo git 1, già esistente)
  taskflow-notifications/    (repo git 2, già esistente)
```

Passi:

1. Installare il livello workspace sulla cartella padre:
   ```powershell
   .\limet\scripts\limet.ps1 init -ProjectPath C:\...\taskflow-suite -Lang it -Workspace
   ```
   (o, da bash/WSL: `./limet/scripts/limet.sh init --project-path /path/taskflow-suite --lang it --workspace`)

2. Aprire `taskflow-suite/limet-workspace/MODULE_MAP.md` e compilarlo: elencare i due progetti, il
   ruolo di ciascuno ("taskflow-backend: API REST + persistenza", "taskflow-notifications:
   consumer di eventi, invio email/push"), la relazione tra loro ("taskflow-backend pubblica un
   evento `CardStatusChanged`; taskflow-notifications lo consuma") e l'ordine di
   build/deploy consigliato (backend prima, perché espone il contratto consumato dall'altro).

3. Installare LIMET normalmente (senza `-Workspace`) in ciascun progetto:
   ```powershell
   .\limet\scripts\limet.ps1 init -ProjectPath C:\...\taskflow-suite\taskflow-backend -Lang it
   .\limet\scripts\limet.ps1 init -ProjectPath C:\...\taskflow-suite\taskflow-notifications -Lang it
   ```

4. Verificare che ogni progetto abbia il proprio `limet/` e `AGENTS.md` locale, e che la cartella
   padre abbia `limet-workspace/` con `MODULE_MAP.md` compilato. Da questo momento, aprendo un
   agente CLI in uno qualsiasi dei due progetti, questo leggerà il proprio `AGENTS.md` locale (che
   gli ricorda di controllare `limet-workspace/` se rilevante); aprendo l'agente nella cartella
   padre `taskflow-suite/`, leggerà invece il blocco `LIMET-WORKSPACE`.

**Variante monorepo**: se invece di due repository si ha un unico repository con più moduli
(es. `taskflow-mono/backend/` e `taskflow-mono/notifications/` nello stesso repo git), la procedura
è identica: si installa `-Workspace` sulla radice del monorepo (`taskflow-mono/`) e si installa
LIMET normalmente in ciascuna sottocartella-modulo (`taskflow-mono/backend/`,
`taskflow-mono/notifications/`). L'unica differenza pratica è che i comandi git (branch, commit)
riguardano un solo repository condiviso, quindi nel `MODULE_MAP.md` conviene annotare per ciascun
modulo eventuali vincoli aggiuntivi (es. "modificare backend e notifications nello stesso commit
se il contratto cambia, per evitare stati intermedi incoerenti nel monorepo").

### C.2 — Bug fix che attraversa più progetti

Caso: un bug per cui la card in TaskFlow-backend cambia stato correttamente, ma
TaskFlow-Notifications non invia mai la notifica corrispondente. La causa potrebbe essere in
uno dei due progetti (o nel contratto tra loro) — non è ancora chiaro a priori.

1. **Aprire la modifica cross-progetto**: nella cartella workspace, creare
   `limet-workspace/changes/0001-notifica-mancante-cambio-stato/`, copiare
   `CROSS_PROJECT_CHANGE_TEMPLATE.md` come `CROSS_PROJECT_CHANGE.md` e compilare la sezione
   iniziale: sintomo osservato, progetti potenzialmente coinvolti (entrambi, in questo caso),
   stato "in analisi".

2. **Analisi guidata da dove serve**: usare i "context provider" (§2) per capire in quale dei due
   progetti si trova la causa radice — es. verificare nel knowledge graph/RAG di
   taskflow-backend se l'evento `CardStatusChanged` viene effettivamente pubblicato, e in
   taskflow-notifications se il consumer lo riceve/processa. Aggiornare `MODULE_MAP.md` se emerge
   che il contratto documentato non corrisponde più alla realtà (es. nome evento cambiato senza
   aggiornare la mappa).

3. **Una volta isolata la causa** (es. l'evento non viene pubblicato per un branch di codice non
   coperto in taskflow-backend): aprire, **nel progetto interessato**
   (`taskflow-backend/limet/changes/0007-evento-non-pubblicato/`), un normale
   `BUG_REPORT.md` (da `BUG_REPORT_TEMPLATE.md`) con causa radice, impatto, fix proposto — esattamente
   come un bug fix a progetto singolo (vedi B.3). Se la causa root tocca **entrambi** i progetti
   (es. contratto ambiguo su entrambi i lati), aprire un `BUG_REPORT.md` in ciascuno dei due,
   linkati dal documento cross-progetto.

4. **Task e implementazione per progetto**: procedere come in B.3 dentro ciascun progetto coinvolto
   (`TASK_LIST.md`, `TASK.md` se serve, `TEST_PLAN.md`/`TEST_EXECUTION.md`, unit test + verifica
   e2e per ogni task, per il requisito vincolante di §5).

5. **Chiudere il documento cross-progetto**: nel `CROSS_PROJECT_CHANGE.md` di workspace, registrare
   quale progetto conteneva effettivamente la causa radice (per riferimento futuro e per correggere
   eventuali assunzioni sbagliate in `MODULE_MAP.md`), l'ordine in cui sono stati applicati i fix
   (di solito: produttore del contratto/evento prima, consumatore dopo, per evitare che un fix nel
   consumer venga testato contro un producer non ancora corretto), e i risultati della verifica
   e2e complessiva (vedi C.5).

6. **Archiviare**: `ARCHIVE_ENTRY.md` in ciascun progetto coinvolto (come in B.3) **più**
   `ARCHIVE_ENTRY.md` a livello di `limet-workspace/archive/0001-.../`, che riassume l'intera
   vicenda cross-progetto e linka gli archivi di dettaglio dei singoli progetti.

### C.3 — Nuova feature che attraversa più progetti

Caso: aggiungere una nuova tipologia di notifica ("promemoria scadenza card") che richiede sia una
modifica al backend (nuovo campo `scadenza` sulla card, nuovo evento `CardDeadlineApproaching`) sia
una modifica al servizio notifiche (nuovo consumer + nuovo template email).

1. **Documento di coordinamento**: creare
   `limet-workspace/changes/0002-notifica-scadenza-card/CROSS_PROJECT_CHANGE.md` da
   `CROSS_PROJECT_CHANGE_TEMPLATE.md`. Compilare: obiettivo della feature (in termini funzionali,
   non tecnici), elenco dei progetti coinvolti con il ruolo di ciascuno in questa feature
   ("taskflow-backend: produttore del nuovo evento", "taskflow-notifications: consumatore"),
   **ordine di implementazione consigliato** (qui: backend prima, per avere il contratto/evento
   disponibile prima di implementare il consumer) e la descrizione del contratto condiviso (forma
   esatta dell'evento `CardDeadlineApproaching`: campi, formato data, garanzie di consegna).

2. **Per il progetto "produttore" (taskflow-backend)**: procedere come in B.4 dentro
   `taskflow-backend/limet/changes/0011-evento-scadenza/` — `CHANGE_PROPOSAL.md`/`SPEC.md` se la
   feature è abbastanza grande da giustificarli, `DESIGN.md` se serve una decisione di design
   esplicita (es. come viene calcolata la "prossimità" alla scadenza), `TASK_LIST.md` con i task
   granulari, implementazione con test plan/execution e unit test + verifica e2e per ogni task
   (§5).

3. **Per il progetto "consumatore" (taskflow-notifications)**: **solo dopo** che il contratto è
   stato implementato (o quantomeno "congelato" nella sua forma finale) nel produttore, aprire
   analogamente `taskflow-notifications/limet/changes/0004-consumer-scadenza/` con lo stesso ciclo
   di documenti. Riferirsi al `CROSS_PROJECT_CHANGE.md` di workspace per la forma esatta del
   contratto, invece di ridefinirla localmente.

4. **Se il contratto cambia in corsa** (es. durante l'implementazione del consumer ci si accorge
   che serve un campo aggiuntivo nell'evento): aggiornare **prima** il `CROSS_PROJECT_CHANGE.md` di
   workspace con la nuova versione del contratto (tracciabilità della decisione, §1.4), poi il
   `DESIGN.md`/`TASK_LIST.md` del progetto produttore, poi propagare al consumatore. Non modificare
   mai il contratto silenziosamente in un solo progetto.

5. **Sintesi non tecnica unica**: per una feature cross-progetto conviene scrivere **una sola**
   `NON_TECHNICAL_SUMMARY.md` a livello di `limet-workspace/changes/0002-.../` (non una per
   progetto), perché lo stakeholder non tecnico è interessato al risultato funzionale complessivo
   ("gli utenti ricevono un promemoria prima della scadenza"), non a come si distribuisce il lavoro
   tra i due repository.

6. **Verifica e2e cross-progetto** (vedi C.5) e poi archiviazione, analoga a C.2 punto 6.

### C.4 — Note sulla variante "monorepo con più moduli"

Quando i "progetti" sono in realtà moduli dello stesso repository (invece di repository separati),
tutto quanto descritto in C.1-C.3 resta valido, con queste differenze pratiche:

- Il workspace (`limet-workspace/`) si installa alla **radice del monorepo**, non in una cartella
  padre esterna al controllo di versione.
- I singoli `limet/` di modulo vivono sotto le rispettive sottocartelle
  (`<monorepo>/<modulo>/limet/`), esattamente come per repository separati.
- Essendo un unico repository, un cambiamento di contratto tra due moduli **può** essere applicato
  in un singolo commit/PR che tocca entrambi i moduli — in tal caso il `CROSS_PROJECT_CHANGE.md`
  di workspace resta comunque utile per documentare la motivazione e l'ordine logico (anche se
  fisicamente il commit è unico), ma non è obbligatorio aprire due Pull Request separate.
- Prestare attenzione affinché build/CI del monorepo (se builda tutto insieme) non nasconda
  problemi di sequenza: anche se il commit è unico, l'ordine logico "chi produce il contratto,
  chi lo consuma" resta rilevante per la revisione e per il testing (prima verificare il
  produttore in isolamento, poi il consumatore).

### C.5 — Verifica e2e cross-progetto

Quando una modifica attraversa più progetti, la checklist di `E2E_VERIFICATION_TEMPLATE.md` va
compilata **per ciascun progetto coinvolto** (verifica locale: "il backend pubblica l'evento
correttamente") **più** una checklist aggiuntiva, a livello di workspace, che verifica il flusso
end-to-end attraverso il confine tra i progetti (es. "creando una card con scadenza vicina nel
backend, arriva davvero l'email di promemoria dal servizio notifiche, in un ambiente con entrambi
i servizi attivi"). Questa checklist aggiuntiva può essere annotata direttamente nel
`CROSS_PROJECT_CHANGE.md` di workspace, in una sezione dedicata, invece di creare un file separato,
salvo che la complessità del flusso non giustifichi un `E2E_VERIFICATION.md` dedicato anche a
livello di workspace.

## Fonti di ispirazione

Il ciclo di vita a fasi (§3) e la separazione proposta/specifica/disegno (§3.1) generalizzano
concetti presenti nei flussi di lavoro spec-driven di alcuni strumenti open source dedicati alla
gestione di *change proposal* per agenti AI (es. proposta → specifica → disegno → task →
archiviazione), adattati qui per essere indipendenti da qualunque strumento specifico e per
rendere vincolante la copertura di test (§1.5/§5), non presente come requisito esplicito in tutti
quei flussi di riferimento.
