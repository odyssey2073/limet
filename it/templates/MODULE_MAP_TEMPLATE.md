# Mappa dei moduli/progetti — [Nome workspace]

> Documento di riferimento per un **workspace** composto da più progetti/repository correlati
> (o da un unico repository suddiviso in più moduli, ciascuno trattato come un "progetto" a sé
> ai fini di LIMET). Va tenuto aggiornato: è la prima cosa da leggere prima di pianificare una
> modifica che tocca più di un progetto/modulo.

## Elenco progetti/moduli

| Progetto/modulo | Percorso locale | Ruolo/responsabilità | Repository proprio? |
| ---------------- | ----------------- | ------------------------ | ----------------------- |
| [nome-progetto-1] | [percorso]         | [cosa fa]                 | [sì/no — se "no", è un modulo dello stesso repo del workspace] |
| [nome-progetto-2] | [percorso]         | [cosa fa]                 | [...]                    |

## Relazioni e dipendenze tra progetti/moduli

> Chi chiama chi, chi produce un contratto (API/schema/evento) e chi lo consuma. Necessario per
> stabilire l'ordine di implementazione quando una modifica attraversa più progetti.

| Produttore | Consumatore | Contratto/interfaccia | Tipo di comunicazione |
| ----------- | ------------- | ------------------------ | ------------------------ |
| [...]       | [...]         | [...]                    | [es. REST/API interna, evento asincrono, libreria condivisa] |

## Ordine di build/deploy consigliato (se rilevante)

[Se esiste un ordine obbligato per compilare/deployare le modifiche — es. "il produttore del
contratto va aggiornato e rilasciato prima dei consumatori" — descriverlo qui.]

## Convenzioni condivise tra i progetti del workspace

[Eventuali convenzioni di naming, versioning dei contratti, terminologia comune — vedere anche
`GLOSSARY_TEMPLATE.md` di ciascun progetto, o un glossario condiviso a livello di workspace se
creato.]

## Note

- Ogni progetto/modulo elencato qui ha (o dovrebbe avere) la propria installazione locale di
  LIMET (`AGENTS.md` + `CLAUDE.md` + cartella `limet/`) — vedi `FRAMEWORK_MANUAL.md` §9 e
  Appendice C.
- Questo documento vive nella cartella di workspace (`limet-workspace/MODULE_MAP.md`), non
  dentro un singolo progetto.

## Storico modifiche a questa mappa

- **[YYYY-MM-DD]**: [cosa è cambiato — nuovo progetto aggiunto, contratto modificato, ecc.]
