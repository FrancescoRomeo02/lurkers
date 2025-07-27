import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurkers/core/utils/toast_helper.dart';
import 'package:lurkers/features/auth/services/auth_service.dart';


class PartyLobbyPage extends StatefulWidget {
  final String partyCode;
  final String location;
  final String evidence;
  final bool isHost;


  const PartyLobbyPage({
    super.key,
    required this.partyCode,
    required this.location,
    required this.evidence,
    this.isHost = false,
  });

  @override
  State<PartyLobbyPage> createState() => _PartyLobbyPageState();
}

class _PartyLobbyPageState extends State<PartyLobbyPage> {
  final AuthService _authService = AuthService();
  String? nickname;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
  }

  void _loadUserNickname() {
    setState(() {
      nickname = _authService.getCurrentUserNick();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (nickname == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading user profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Game: ${widget.partyCode}'),
        centerTitle: true,
        actions: [
          if (widget.isHost)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Game settings
              },
            ),
        ],
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.key, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Game Code',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    widget.partyCode,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: widget.partyCode));
                                SnackBarHelper.showSuccess(context, 'Game code copied to clipboard!');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () {
                                // Share game code
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
            
                    const SizedBox(height: 16),
            
                    // Game Info
                    Text(
                      'Assassination Scenario',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Target Location',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(widget.location),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.inventory, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Required Object',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(widget.evidence),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Players List
                    Text(
                      'Players in the Hunt',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: widget.isHost 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Theme.of(context).colorScheme.secondary,
                                  child: Text(
                                    nickname!.isNotEmpty ? nickname![0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(nickname!),
                                subtitle: Text(widget.isHost ? 'Game Master' : 'Assassin'),
                                trailing: widget.isHost ? const Icon(Icons.star, color: Colors.amber) : null,
                              ),
                              const Divider(),
                              const Text(
                                'Waiting for more assassins to join...',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
            
                    // Action Buttons
                    if (widget.isHost) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Hunt'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            // Start hunt logic
                          },
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.hourglass_empty),
                          label: const Text('Waiting for Game Master to Start'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
          
            
