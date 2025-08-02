import 'package:flutter/material.dart';
import 'package:lurkers/features/game/services/game_service.dart';
import 'package:lurkers/features/home/pages/home_page.dart';

class VictoryPage extends StatefulWidget {
  final String partyCode;
  final String winnerId;
  final String winnerName;

  const VictoryPage({
    super.key,
    required this.partyCode,
    required this.winnerId,
    required this.winnerName,
  });

  @override
  State<VictoryPage> createState() => _VictoryPageState();
}

class _VictoryPageState extends State<VictoryPage>
    with TickerProviderStateMixin {
  final GameService _gameService = GameService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic> gameStats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadGameStats();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  Future<void> _loadGameStats() async {
    try {
      final stats = await _gameService.getGameStatistics(widget.partyCode);
      setState(() {
        gameStats = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildVictoryContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Victory Animation
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 120,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '🎉 VITTORIA! 🎉',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black26,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Winner Info Card
          FadeTransition(
            opacity: _fadeAnimation,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Il vincitore è:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade300,
                            Colors.amber.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        widget.winnerName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Game Statistics
          if (gameStats.isNotEmpty) ...[
            FadeTransition(
              opacity: _fadeAnimation,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Statistiche del Gioco',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildStatsGrid(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Player Rankings
          if (gameStats['playerStats'] != null) ...[
            FadeTransition(
              opacity: _fadeAnimation,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.leaderboard,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Classifica Giocatori',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPlayerRankings(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],

          // Return Home Button
          FadeTransition(
            opacity: _fadeAnimation,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _returnHome,
                icon: const Icon(Icons.home),
                label: const Text('Torna alla Home'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Giocatori Totali',
                '${gameStats['totalPlayers'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Eliminazioni Totali',
                '${gameStats['totalEliminations'] ?? 0}',
                Icons.close,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Durata Gioco',
                gameStats['gameDuration'] ?? 'N/A',
                Icons.timer,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Kill del Vincitore',
                '${gameStats['winnerKills'] ?? 0}',
                Icons.emoji_events,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRankings() {
    final players = gameStats['playerStats'] as List<Map<String, dynamic>>? ?? [];
    final winnerId = gameStats['winnerId'] as String?;
    
    return Column(
      children: players.asMap().entries.map((entry) {
        final index = entry.key;
        final player = entry.value;
        final isWinner = player['playerId'] == winnerId;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isWinner
                ? Colors.amber.withOpacity(0.1) 
                : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isWinner
                  ? Colors.amber 
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isWinner ? Colors.amber : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player['displayName'] ?? 'Sconosciuto',
                      style: TextStyle(
                        fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      player['isAlive'] ? 'Sopravvissuto' : 'Eliminato',
                      style: TextStyle(
                        color: player['isAlive'] ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '${player['kills'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (isWinner)
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _returnHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }
}
