# Verifica e2e manuale — [Nome feature / bug fix]

> Checklist passo-passo per una verifica end-to-end eseguita da una persona (non automatizzata),
> tipicamente dopo il deploy in un ambiente vivo. Scrivere i passi in modo che chiunque, anche
> non l'autore della modifica, possa eseguirli senza ambiguità.

## Riferimenti

- **Piano/task collegato**: [...]
- **Ambiente di verifica**: [locale/test/staging/produzione]

## Precondizioni

- [...]
- [dati/utenti/ruoli necessari]

## Stato pre-verifica (controllo PRIMA dei passi)

> Stato da verificare prima di eseguire i passi — es. righe DB (SQL), un file, un valore di config,
> contenuto di cache, un servizio esterno.

- **Controllo**: [...]
  ```sql
  SELECT count(*) FROM employee;  -- atteso 0
  ```

## Passi di verifica

1. [Passo 1 — azione precisa: dove cliccare/cosa chiamare/cosa inserire]
   - **Esito atteso**: [...]
2. [Passo 2]
   - **Esito atteso**: [...]
3. [...]

## Stato post-verifica (controllo DOPO i passi)

> Stato da verificare dopo aver eseguito i passi — es. righe DB (SQL), un file, un valore di
> config, contenuto di cache, un servizio esterno.

- **Controllo**: [...]
  ```sql
  SELECT count(*) FROM employee;  -- atteso 5
  ```

## Casi limite da verificare

- [...]

## Esito esecuzione (da compilare da chi esegue)

- **Data/ora**: [YYYY-MM-DD HH:MM]
- **Eseguito da**: [...]
- **Esito**: `[OK | KO]`
- **Note/anomalie**: [...]
