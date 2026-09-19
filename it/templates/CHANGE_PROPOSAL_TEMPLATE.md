# Proposta di modifica — [Nome capability/change]

> Da usare al posto di (o in aggiunta a) `PLAN_TEMPLATE.md` per modifiche più ampie: nuova
> capability, cambiamento di contratto/interfaccia, impatto su più moduli. Descrive il *perché*.
> Il *cosa* verificabile va in `SPEC_TEMPLATE.md`; il *come* (se non ovvio) in `DESIGN_TEMPLATE.md`.

## Metadati

- **Data creazione**: [YYYY-MM-DD]
- **Stato**: `[DRAFT | APPROVATA | IN CORSO | COMPLETATA | ABBANDONATA]`
- **Approvata da / data**: [chi — YYYY-MM-DD] (compilare quando lo Stato passa a APPROVATA)
- **Specifiche collegate**: [elenco file `SPEC_TEMPLATE.md` istanziati per questa proposta]
- **Disegno collegato**: [file `DESIGN_TEMPLATE.md`, se presente]

## Perché

[Qual è il problema o l'opportunità? Perché ora? Cosa succede se non si fa questa modifica?]

## Cosa cambia (riepilogo)

[Elenco sintetico ad alto livello — il dettaglio verificabile sta nelle spec collegate.]

- [cambiamento 1]
- [cambiamento 2]

## Capability

### Nuove capability
- `[nome-capability]`: [descrizione breve]

### Capability modificate
- `[nome-capability-esistente]`: [quale requisito cambia e perché]

### Capability rimosse/deprecate
- `[nome-capability]`: [motivo della rimozione, piano di migrazione se applicabile]

## Impatto

- **Codice/moduli interessati**: [elenco]
- **API/contratti interessati**: [elenco, con nota su compatibilità all'indietro]
- **Dipendenze esterne**: [librerie, servizi terzi, altri team]
- **Dati esistenti**: [serve una migrazione? è retrocompatibile?]

## Domande contestuali aperte

| # | Domanda | Risposta | Data | Da chi |
| - | ------- | -------- | ---- | ------ |
| 1 | [...]   | [...]    | [...] | [...]  |

## Strategia di verifica (obbligatoria, vedi `FRAMEWORK_MANUAL.md` §5)

- **Unit test**: [riferimento a `TEST_PLAN_TEMPLATE.md`]
- **Test e2e**: [riferimento a `E2E_VERIFICATION_TEMPLATE.md`]

## Esito (da compilare a chiusura, prima dell'archiviazione)

- **Data**: [YYYY-MM-DD]
- **Sintesi**: [...]
- **Scostamenti rispetto alla proposta originale**: [...]
