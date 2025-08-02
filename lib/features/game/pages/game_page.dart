import 'package:flutter/material.dart';
import 'package:lurkers/features/auth/services/auth_service.dart';
import 'package:lurkers/features/game/models/party_player.dart';
import 'package:lurkers/features/game/services/game_service.dart';
import 'package:lurkers/features/game/widgets/target_mission_card.dart';
import 'package:lurkers/features/game/widgets/game_player_card.dart';
import 'package:lurkers/features/game/widgets/pending_elimination_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class GamePage extends StatefulWidget {
  final String partyCode;


  const GamePage({
    super.key,
    required this.partyCode,
  });
  

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final AuthService _authService = AuthService();
  final GameService _gameService = GameService();
    
  late RealtimeChannel _playersSubscription;
  late RealtimeChannel _eliminationSubscription;
  List<PartyPlayer> _players = [];
  bool _playersLoading = true;
  
  // Elimination system
  Map<String, dynamic>? _pendingElimination;

  String? nickname;
  bool isLoading = true;
  bool isHost = false;

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
    _subscribeToChanges();
    _fetchPlayers();
    _checkPendingElimination();
  }

  void _loadUserNickname() {
    setState(() {
      nickname = _authService.getCurrentUserNick();
      isLoading = false;
    });
  }

  void _subscribeToChanges() async {
    // Get party ID first for filtered subscriptions
    final partyId = await _gameService.getPartyIdByCode(widget.partyCode);
    if (partyId == 0) {
      print('Warning: Could not get party ID for subscriptions');
      return;
    }

    // Subscribe to party_players changes for this specific party
    _playersSubscription = Supabase.instance.client
      .channel('players-${widget.partyCode}')
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'party_players',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'party_id',
            value: partyId,
          ),
          callback: (payload) {
            print('Players data changed: ${payload.eventType}');
            _fetchPlayers();
          },
        )
      .subscribe();

    // Subscribe to elimination_events changes for this specific party
    _eliminationSubscription = Supabase.instance.client
      .channel('eliminations-${widget.partyCode}')
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'elimination_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'party_id',
            value: partyId,
          ),
          callback: (payload) {
            print('Elimination event changed: ${payload.eventType}');
            // Always check for pending eliminations when elimination events change
            _checkPendingElimination();
          },
        )
      .subscribe();
  }

    void _fetchPlayers() async {
      setState(() => _playersLoading = true);
      final players = await _gameService.getPartyPlayers(widget.partyCode);
      setState(() {
        _players = players;
        _playersLoading = false;
      });
  }

  void _checkPendingElimination() async {
    if (_authService.currentUser == null) return;
    
    try {
      final pendingElimination = await _gameService.getPendingEliminationForVictim(
        widget.partyCode,
        _authService.currentUser!.id,
      );
      setState(() {
        _pendingElimination = pendingElimination;
      });
    } catch (e) {
      print('Error checking pending elimination: $e');
    }
  }

  void _confirmElimination() async {
    if (_pendingElimination == null) return;
    
    try {
      final success = await _gameService.confirmElimination(
        widget.partyCode,
        _authService.currentUser!.id,
        _pendingElimination!['id'],
      );
      
      if (success) {
        setState(() {
          _pendingElimination = null;
        });
        // Refresh players data
        _fetchPlayers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Elimination confirmed. You have been eliminated from the game.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to confirm elimination. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _denyElimination() async {
    if (_pendingElimination == null) return;
    
    // For now, just remove the pending elimination locally
    // In a real implementation, you might want to send a denial to the database
    setState(() {
      _pendingElimination = null;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elimination denied. The report has been dismissed.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_playersSubscription);
    Supabase.instance.client.removeChannel(_eliminationSubscription);
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
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
        title: Text('Live Game'),
        centerTitle: true,
        actions: [
          if (isHost)
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
                            Expanded(
                              child: Center(
                                child: FutureBuilder<PartyPlayer>(
                                  future: _gameService.getPartyPlayer(widget.partyCode, _authService.currentUser),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Your State',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          CircularProgressIndicator(),
                                        ],
                                      );
                                    }
                                    
                                    if (snapshot.hasError || !snapshot.hasData) {
                                      return const Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Your State',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Error',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    final player = snapshot.data!;
                                    final isAlive = player.isAlive;
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Your State',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isAlive ? Icons.favorite : Icons.heart_broken,
                                              color: isAlive ? Colors.green : Colors.red,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isAlive ? 'HUNTING' : 'ELIMINATED',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.bold,
                                                color: isAlive ? Colors.green : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Pending Elimination Alert
                    if (_pendingElimination != null)
                      Column(
                        children: [
                          PendingEliminationCard(
                            eliminationData: _pendingElimination!,
                            onConfirm: _confirmElimination,
                            onDeny: _denyElimination,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

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
                              // Current player mission (only if alive)
                              FutureBuilder<PartyPlayer>(
                                future: _gameService.getPartyPlayer(widget.partyCode, _authService.currentUser),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                    return const Center(child: Text('Error loading mission info'));
                                  }
                                  
                                  final mission = snapshot.data!;
                                  
                                  // If player is dead, show elimination message instead of mission
                                  if (!mission.isAlive) {
                                    return Container(
                                      padding: const EdgeInsets.all(20.0),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.dangerous,
                                            size: 48,
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'YOU HAVE BEEN ELIMINATED',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.error,
                                              letterSpacing: 1.2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Your hunt is over. Continue watching the game unfold.',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  // Player is alive, show mission
                                  final targetName = _players.firstWhere(
                                    (player) => player.playerId == mission.targetId,
                                    ).userInfo?['display_name'] ?? 'Unknown';

                                  return TargetMissionCard(
                                    targetName: targetName,
                                    evidence: mission.insertItem,
                                    location: mission.insertLocation,
                                    onEliminateTarget: () {
                                      _gameService.reportKill(
                                        widget.partyCode,
                                        _authService.currentUser!.id,
                                        mission.targetId,
                                      ).then((success) {
                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Kill reported! Waiting for target confirmation...'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Failed to report kill. Please try again.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                    
                              const Divider(),

                              // Other players list
                              Expanded(
                                child: _playersLoading 
                                    ? const Center(child: CircularProgressIndicator())
                                    : FutureBuilder<PartyPlayer>(
                                        future: _gameService.getPartyPlayer(widget.partyCode, _authService.currentUser),
                                        builder: (context, missionSnapshot) {
                                          if (missionSnapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(child: CircularProgressIndicator());
                                          }
                                          if (missionSnapshot.hasError || !missionSnapshot.hasData) {
                                            return const Center(child: Text('Error loading mission info'));
                                          }
                                          
                                          final mission = missionSnapshot.data!;
                                          final currentUserId = _authService.currentUser?.id;
                                          
                                          // Filter logic based on player status
                                          final otherPlayers = _players.where((player) {
                                            // Always exclude current user
                                            if (player.playerId == currentUserId) return false;
                                            
                                            // If current player is alive, also exclude their target
                                            if (mission.isAlive && player.playerId == mission.targetId) {
                                              return false;
                                            }
                                            
                                            // Include all other players
                                            return true;
                                          }).toList();
                                          
                                          if (otherPlayers.isEmpty) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.people_outline,
                                                    size: 48,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    mission.isAlive 
                                                        ? 'No other players visible'
                                                        : 'All players in the hunt',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          
                                          return ListView.builder(
                                            itemCount: otherPlayers.length,
                                            itemBuilder: (context, index) {
                                              final player = otherPlayers[index];
                                              return FutureBuilder<bool>(
                                                future: _gameService.isUserHostOfParty(widget.partyCode, player),
                                                builder: (context, hostSnapshot) {
                                                  final isPlayerHost = hostSnapshot.data ?? false;
                                                  return GamePlayerCard(
                                                    player: player,
                                                    isHost: isPlayerHost,
                                                    onReportKill: mission.isAlive ? () {
                                                      _gameService.reportKill(
                                                        widget.partyCode,
                                                        _authService.currentUser!.id,
                                                        player.playerId,
                                                      ).then((success) {
                                                        if (success) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Kill reported for ${player.userInfo?['display_name'] ?? 'player'}! Waiting for confirmation...'),
                                                              backgroundColor: Colors.orange,
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Failed to report kill. Please try again.'),
                                                              backgroundColor: Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      });
                                                    } : null, // Disable for dead players
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
          
            
