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

---

## 🔄 Meccaniche di Ereditarietà

- In ogni eliminazione, la **missione attiva** (target, oggetto, luogo) di chi muore viene **trasferita**:
  - All’assassino, se l’omicidio è riuscito senza testimoni.
  - Al testimone, se l’omicidio è stato visto e denunciato con successo.

---
## BUG riscontrati
- Al primo avvio, premendo su "Enter the Hunt" viene visuallizzato il banner di successo ma non si viene reindirizzati alla schermata di gioco.
**soluzione provvisoria**: ricaricare la pagina dopo aver premuto "Enter the Hunt".
