import 'package:flutter/material.dart';
import 'package:lurkers/features/auth/services/auth_service.dart';
import 'package:lurkers/features/game/pages/party_lobby_page.dart';
import 'package:lurkers/core/utils/toast_helper.dart';
import 'package:lurkers/features/game/services/game_service.dart';

class JoinPartyScreen extends StatefulWidget {
  const JoinPartyScreen({super.key});

  @override
  State<JoinPartyScreen> createState() => _JoinPartyScreenState();
}

class _JoinPartyScreenState extends State<JoinPartyScreen> {
  final GameService _gameService = GameService();
  final AuthService _authService = AuthService();

  final TextEditingController _partyCodeController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _objectController = TextEditingController();

  bool _isButtonEnabled = false;
  bool _showLocationFields = false;
  bool _isLoading = false;

  bool get _isPartyCodeValid =>
      _partyCodeController.text.isNotEmpty &&
      _partyCodeController.text.contains('-') &&
      _partyCodeController.text.length >= 5;

  bool get _isFormValid =>
      _isPartyCodeValid &&
      (!_showLocationFields || 
        (_placeController.text.isNotEmpty && _objectController.text.isNotEmpty));

  @override
  void initState() {
    super.initState();

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
        title: const Text('Join Game'),
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
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.group_add),
                                SizedBox(width: 8),
                                Text(
                                  'Join the Hunt',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Enter the game code shared by your host and prepare for the assassination game.',
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
                      decoration: const InputDecoration(
                        labelText: 'Game Code',
                        helperText: 'Enter the code provided by your game host',
                        hintText: 'e.g., word-word',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.key),
                      ),
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Character Background Section - Show only if needed
                    if (_showLocationFields) ...[
                      Text(
                        'Your Starting Resources',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Choose your starting location and object for the assassination game.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: _placeController,
                        decoration: const InputDecoration(
                          labelText: "Your Starting Location",
                          helperText: "Where will you begin the game?",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: _objectController,
                        decoration: const InputDecoration(
                          labelText: "Your Starting Object",
                          helperText: "What object do you possess at the start?",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
              
              // Bottom action button
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _isLoading 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login),
                    label: Text(_showLocationFields ? "Join the Hunt" : "Check Game"),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    onPressed: _isButtonEnabled ? () async {
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        final result = await _gameService.joinOrRejoinParty(
                          _partyCodeController.text,
                          _authService.currentUser,
                          location: _showLocationFields ? _placeController.text : null,
                          item: _showLocationFields ? _objectController.text : null,
                        );

                        if (result['success'] == true) {
                          // Successfully joined or rejoined
                          SnackBarHelper.showSuccess(
                            context, 
                            result['message'] ?? "Successfully joined game '${_partyCodeController.text}'!"
                          );
                          
                          // Wait a moment for the snackbar, then navigate
                          await Future.delayed(const Duration(milliseconds: 1000));
                          
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => PartyLobbyPage(
                                  partyCode: _partyCodeController.text,
                                  location: result['location'] ?? (_showLocationFields ? _placeController.text : ''),
                                  evidence: result['item'] ?? (_showLocationFields ? _objectController.text : ''),
                                  isHost: result['isHost'] ?? false,
                                ),
                              ),
                            );
                          }
                        } else if (result['requiresData'] == true) {
                          // Need to show location and item fields
                          setState(() {
                            _showLocationFields = true;
                          });
                          SnackBarHelper.showInfo(
                            context, 
                            result['message'] ?? "Please provide your location and item to join the party"
                          );
                        } else {
                          // Error occurred
                          SnackBarHelper.showError(
                            context, 
                            result['error'] ?? "Failed to join game '${_partyCodeController.text}'!"
                          );
                        }
                      } catch (e) {
                        SnackBarHelper.showError(context, "An unexpected error occurred: $e");
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
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