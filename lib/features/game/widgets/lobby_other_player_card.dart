import 'package:flutter/material.dart';
import 'package:lurkers/features/game/models/party_player.dart';

class LobbyOtherPlayerCard extends StatelessWidget {
  final PartyPlayer player;
  final bool isHost;
  
  const LobbyOtherPlayerCard({
    super.key,
    required this.player,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    final nickname = player.playerId.isNotEmpty ? player.playerId : 'Unknown Player';
    final isOnline = player.status == PlayerStatus.active;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
          color: isHost
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Simple avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isHost
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  child: Text(
                    player.playerId.isNotEmpty ? nickname[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nickname,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      // Simple host indicator
                      if (isHost)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'HOST',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Simple role text
                  Text(
                    isHost ? 'Game Master' : 'Assassin',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Status icon
            Icon(
              isOnline ? Icons.circle : Icons.circle_outlined,
              color: isOnline ? Colors.green : Colors.grey,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
