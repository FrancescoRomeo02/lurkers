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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Your State',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'In game',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
                              // Current player (detailed view)
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

                              // Example of other players (simplified view)
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
                                          final targetId = mission.targetId;
                                          
                                          // Filtra sia l'utente corrente che il suo target dalla lista degli altri giocatori
                                          final otherPlayers = _players.where((player) => 
                                              player.playerId != currentUserId && player.playerId != targetId
                                          ).toList();
                                          
                                          if (otherPlayers.isEmpty) {
                                            return const Center(child: Text('No other players in the game'));
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
                                                    onReportKill: () {
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
                                                    },
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
          
            
