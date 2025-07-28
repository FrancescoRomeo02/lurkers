import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:lurkers/features/auth/services/auth_service.dart';
import 'package:lurkers/features/game/pages/party_lobby_page.dart';
import 'package:lurkers/core/utils/toast_helper.dart';
import 'package:lurkers/features/game/services/game_service.dart';

class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  State<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  final GameService _gameService = GameService();
  final AuthService _authService = AuthService();


  late final TextEditingController _partyCodeController;
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _objectController = TextEditingController();

  bool _isPartyCodeLocked = false;
  bool _isButtonEnabled = false;

  bool get _isFormValid =>
      _isPartyCodeLocked &&
      _placeController.text.isNotEmpty &&
      _objectController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final wordPair = generateWordPairs().first;
    final randomCode = '${wordPair.first}-${wordPair.second}'.toLowerCase();
    _partyCodeController = TextEditingController(text: randomCode);

    _partyCodeController.addListener(_validateForm);
    _placeController.addListener(_validateForm);
    _objectController.addListener(_validateForm);
  }
  
  void _validateForm() {
    setState(() {
      _isButtonEnabled = _isFormValid;
    });
  }

  @override
  void dispose() {
    _partyCodeController.dispose();
    _placeController.dispose();
    _objectController.dispose();
    super.dispose();
  }
  // --- FINE DELLA LOGICA DI STATO (INVARIATA) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Game'),
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determina la larghezza massima basata sulle dimensioni dello schermo
          double maxWidth;
          if (constraints.maxWidth < 600) {
            maxWidth = double.infinity; // Mobile: larghezza piena
          } else if (constraints.maxWidth < 1200) {
            maxWidth = 700; // Tablet
          } else {
            maxWidth = 800; // Desktop
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
              Expanded(
                child: ListView(
                  children: <Widget>[
                    const SizedBox(height: 24),
                    
                    // Informational card
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline),
                                SizedBox(width: 8),
                                Text(
                                  'Game Setup',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create a unique game code and set up the assassination scenario. Other players will use this code to join your game.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Party Code Field
                    TextField(
                      controller: _partyCodeController,
                      enabled: !_isPartyCodeLocked, 
                      decoration: InputDecoration(
                        labelText: 'Game Code',
                        helperText: _isPartyCodeLocked 
                          ? 'Game code is locked and ready to share' 
                          : 'Tap the lock to finalize your game code',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.tag),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPartyCodeLocked ? Icons.lock : Icons.lock_open,
                            color: _isPartyCodeLocked ? Colors.green : Colors.orange,
                          ),
                          tooltip: _isPartyCodeLocked ? 'Unlock to edit' : 'Lock to confirm',
                          onPressed: () {
                            setState(() {
                              _isPartyCodeLocked = !_isPartyCodeLocked;
                              _validateForm();
                            });
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Game Setup Section
                    Text(
                      'Assassination Scenario',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: _placeController,
                      decoration: const InputDecoration(
                        labelText: "Target Location",
                        helperText: "Where will the assassinations take place?",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _objectController,
                      decoration: const InputDecoration(
                        labelText: "Required Object",
                        helperText: "What object must the target possess to be eliminated?",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
              
              // Bottom action button
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text("Launch Game"),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    onPressed: _isButtonEnabled ? () async {
                      // Create the game party
                      bool partyCreated = await _gameService.createParty(_partyCodeController.text, _authService.currentUser);
                      
                      if (!partyCreated) {
                        SnackBarHelper.showError(context, "Failed to create game party. Please try again.");
                        return;
                      }
                      SnackBarHelper.showSuccess(context, "Game '${_partyCodeController.text}' created successfully!");
                      
                      // Wait a moment for the snackbar, then navigate
                      await Future.delayed(const Duration(milliseconds: 1000));
                      
                      if (context.mounted && partyCreated) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => PartyLobbyPage(
                              partyCode: _partyCodeController.text,
                              location: _placeController.text,
                              evidence: _objectController.text,
                              isHost: true, // Chi crea la party è sempre l'host
                            ),
                          ),
                        );
                      }
                    } : null,
                  ),
                ),
              ),
            ],
          ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}