import 'package:flutter/material.dart';
import 'package:lurkers/features/auth/services/auth_service.dart';
import 'package:lurkers/features/game/models/party_player.dart';
import 'package:lurkers/features/game/services/game_service.dart';
import 'package:lurkers/features/game/widgets/current_player_card.dart';
import 'package:lurkers/features/game/widgets/other_player_card.dart';
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
    
  late RealtimeChannel _subscription;
  List<PartyPlayer> _players = [];
  bool _playersLoading = true;

  String? nickname;
  bool isLoading = true;
  bool isHost = false;

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
    _subscribeToPlayers();
    _fetchPlayers();
  }

  void _loadUserNickname() {
    setState(() {
      nickname = _authService.getCurrentUserNick();
      isLoading = false;
    });
  }

  void _subscribeToPlayers() {
    _subscription = Supabase.instance.client
      .channel('public:party_players')
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'party_players',
          callback: (payload) => _fetchPlayers(),
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

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_subscription);
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

                                  return CurrentPlayerCard(
                                    nickname: targetName,
                                    evidence: mission.insertItem,
                                    location: mission.insertLocation,
                                    isHost: isHost,
                                  );
                                },
                              ),
                    
                              const Divider(),

                              // Example of other players (simplified view)
                              Expanded(
                                child: _playersLoading 
                                    ? const Center(child: CircularProgressIndicator())
                                    : FutureBuilder<List<PartyPlayer>>(
                                    initialData: _players,
                                    future: Future.value(_players),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    if (snapshot.hasError) {
                                      return Center(child: Text('Error: ${snapshot.error}'));
                                    }
                                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      return const Center(child: Text('No other players in the game'));
                                    }

                                    final players = snapshot.data!;
                                    // Filtra l'utente corrente dalla lista degli altri giocatori
                                    final currentUserId = _authService.currentUser?.id;
                                    final otherPlayers = players.where((player) => 
                                        player.playerId != currentUserId
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
                                            return OtherPlayerCard(
                                              player: player,
                                              isHost: isPlayerHost,
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
          
            
