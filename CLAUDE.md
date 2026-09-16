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
