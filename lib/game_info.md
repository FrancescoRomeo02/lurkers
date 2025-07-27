# Lurkers Game Info
**Versione: 1.0 – Francesco Romeo**

---

## 🎯 Obiettivo del Gioco

Ogni giocatore riceve **una missione segreta** composta da:
- Un *bersaglio* (un altro giocatore)
- Un *luogo*
- Un *oggetto*

L’obiettivo è far sì che il bersaglio abbia **in mano l’oggetto designato**, **nel luogo designato**, **senza farsi vedere da altri**.

---

## 🕹️ Dinamiche di Gioco

- Se il giocatore riesce a compiere l’omicidio senza essere visto:
  - Il bersaglio viene eliminato.
  - L’assassino eredita la **missione del bersaglio** (nuovo target, nuovo oggetto, nuovo luogo).
  - L'assegnazione della nuova missione avviene dopo un periodo di tempo X in cui l'assassino può essere segnalato.

- Se un altro giocatore **vede l’omicidio**, può dichiararlo pubblicamente:
  - Se la dichiarazione è corretta:
    - L’assassino viene eliminato.
    - Il testimone eredita **la missione della vittima originale**.
  - Se la dichiarazione è errata:
    - Il testimone viene eliminato.

---

## 🧠 Condizioni di Vittoria

Sono previste due condizioni di vittoria, alternative:

1. **Ultimo superstite**  
   Vince l’ultimo giocatore rimasto in vita.

2. **Uccidere il proprio assassino**  
   Se un giocatore uccide **il giocatore che aveva come target sé stesso**, vince immediatamente.  
   *(Nota: questa regola si applica solo se l’identità dell’assassino è nota o deducibile).*

---

## ⚠️ Vincoli sull’Assegnazione Iniziale

- Ogni giocatore riceve:
  - Un target ≠ sé stesso
  - Un oggetto
  - Un luogo

- È **vietato** che due giocatori si abbiano come target reciprocamente.  
  In altri termini, è vietato che:
  ```
  A.target = B && B.target = A
  ```

- Questo vincolo evita che la partita possa concludersi in un solo round.

---

## 🔄 Meccaniche di Ereditarietà

- In ogni eliminazione, la **missione attiva** (target, oggetto, luogo) di chi muore viene **trasferita**:
  - All’assassino, se l’omicidio è riuscito senza testimoni.
  - Al testimone, se l’omicidio è stato visto e denunciato con successo.

- Ogni giocatore ha **una sola missione attiva alla volta**.

---
## 👻 Ruolo degli Eliminati: Angeli e Demoni (ANCORA DA IMPLEMENTARE)

I giocatori eliminati ricevono un ruolo post-mortem assegnato casualmente:
- Angelo, che può proteggere un luogo.
- Demone, che può oscurare un luogo.
Azioni disponibili:
- Angelo: Benedizione del luogo, Impedisce che la vittima muoia in quel luogo per X secondi, Max Y volte al giorno, cooldown X * k
- Demone: Oscuramento del luogo, Impedisce che l’assassino sia visto in quel luogo per X secondi, Max Y volte al giorno, cooldown X * k
L’attivazione delle azioni è possibile solo quando il giocatore assegnato si trova nel luogo interessato.
Angeli e Demoni non conoscono l’identità del giocatore a cui sono assegnati e possono agire solo sul luogo.
--- 

## 📊 Stati Possibili del Giocatore

| Stato         | Descrizione                                                                 |
|---------------|------------------------------------------------------------------------------|
| `Attivo`      | Il giocatore è vivo e ha una missione assegnata.                            |
| `Assassino`   | Il giocatore ha appena completato un omicidio e ha ereditato una nuova missione. |
| `Sotto osservazione` | Il giocatore è sospettato (qualcuno lo ha dichiarato testimone, ma senza prova). |
| `Eliminato`   | Il giocatore è stato ucciso (da missione o dichiarazione).                  |
| `Vincitore`   | Il giocatore ha soddisfatto una delle condizioni di vittoria.               |
| `Errore dichiarazione` | Il giocatore è stato eliminato per aver accusato qualcuno ingiustamente. |

---

## 🚫 Casi non ammessi

- Nessun giocatore può avere **sé stesso** come bersaglio.
- Nessuna catena diretta di target reciproci.
- Nessun omicidio può essere dichiarato “riuscito” se **più di un giocatore** lo ha visto e ha validamente denunciato.

---
