import 'package:flutter/cupertino.dart';
import 'package:english_words/english_words.dart';

// 1. CONVERTITO A STATEFULWIDGET per gestire lo stato interno.
class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  State<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  // 2. CONTROLLER per ogni campo di testo.
  // Ci permettono di leggere e modificare il testo programmaticamente.
  late final TextEditingController _partyCodeController;
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _objectController = TextEditingController();

  // 3. VARIABILI DI STATO per gestire la logica della UI.
  bool _isPartyCodeLocked = false;
  bool _isButtonEnabled = false;

  // 4. GETTER DI CONVENIENZA per controllare se il form è valido.
  // Il bottone si abilita solo se il codice è bloccato e tutti gli altri campi sono pieni.
  bool get _isFormValid =>
      _isPartyCodeLocked &&
      _nicknameController.text.isNotEmpty &&
      _placeController.text.isNotEmpty &&
      _objectController.text.isNotEmpty;

  // 5. INITSTATE: viene eseguito UNA SOLA VOLTA quando il widget viene creato.
  // Perfetto per inizializzare i dati.
  @override
  void initState() {
    super.initState();
    // Genera una coppia di parole casuali e le unisce con un trattino.
    final wordPair = generateWordPairs().first;
    final randomCode = '${wordPair.first}-${wordPair.second}'.toLowerCase();
    
    // Inizializza il controller del codice con la parola generata.
    _partyCodeController = TextEditingController(text: randomCode);

    // Aggiungiamo dei "listener": ogni volta che l'utente scrive in un campo,
    // controlliamo se il form è diventato valido per abilitare il bottone.
    _partyCodeController.addListener(_validateForm);
    _nicknameController.addListener(_validateForm);
    _placeController.addListener(_validateForm);
    _objectController.addListener(_validateForm);
  }
  
  // 6. Metodo per aggiornare lo stato del bottone
  void _validateForm() {
    // Usiamo setState per dire a Flutter di ricostruire la UI
    // perché lo stato (_isButtonEnabled) potrebbe essere cambiato.
    setState(() {
      _isButtonEnabled = _isFormValid;
    });
  }

  // 7. Ricordati di fare il dispose dei controller per liberare memoria!
  @override
  void dispose() {
    _partyCodeController.dispose();
    _nicknameController.dispose();
    _placeController.dispose();
    _objectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Create Party'),
        previousPageTitle: "Home",
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          // Usiamo un ListView per evitare problemi di overflow se la tastiera appare.
          child: ListView(
            children: <Widget>[
              const SizedBox(height: 24),

              // --- CAMPO CODICE PARTITA ---
              const Text("Codice Partita", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Il campo di testo ora occupa lo spazio disponibile
                  Expanded(
                    child: CupertinoTextField(
                      controller: _partyCodeController,
                      placeholder: "es. blue-car",
                      readOnly: _isPartyCodeLocked, // 8. Diventa non modificabile se bloccato
                      decoration: BoxDecoration(
                        color: _isPartyCodeLocked 
                            ? CupertinoColors.systemGrey5 
                            : CupertinoColors.white,
                        border: Border.all(color: CupertinoColors.systemGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bottone per bloccare/sbloccare il codice
                  CupertinoButton(
                    padding: const EdgeInsets.all(10),
                    onPressed: () {
                      setState(() {
                        _isPartyCodeLocked = !_isPartyCodeLocked;
                        _validateForm(); // Ricalcola la validità del form
                      });
                    },
                    child: Icon(
                      _isPartyCodeLocked ? CupertinoIcons.lock_fill : CupertinoIcons.lock_open_fill
                    ),
                  )
                ],
              ),
              
              const SizedBox(height: 20),

              // --- ALTRI CAMPI ---
              const Text("Nickname", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _nicknameController,
                placeholder: "Il tuo nome in gioco",
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),
              
              const Text("Luogo", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _placeController,
                placeholder: "Dove si svolge la partita?",
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 20),

              const Text("Oggetto", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _objectController,
                placeholder: "Un oggetto misterioso...",
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 40),

              // 9. BOTTONE FINALE
              // L'onPressed è null se _isButtonEnabled è false, disabilitandolo automaticamente.
              CupertinoButton.filled(
                onPressed: _isButtonEnabled ? () {
                  // Qui, in futuro, avvierai la partita con i dati raccolti.
                  // Esempio:
                  // final partyCode = _partyCodeController.text;
                  // final nickname = _nicknameController.text;
                  // ...
                  print("Partita pronta per essere avviata!");
                } : null, // Se null, il bottone è disabilitato.
                child: const Text(
                  "Avvia Partita", 
                  style: TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}