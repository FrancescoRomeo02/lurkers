import 'package:flutter/material.dart';

class OtherPlayerCard extends StatelessWidget {
  final dynamic player;
  final bool isHost;
  
  const OtherPlayerCard({
    super.key,
    required this.player,
    required this.isHost,
  });


  @override
  Widget build(BuildContext context) {
    final nickname = player.userInfo?['display_name'] ?? 'Unknown Player';
    // Nella lobby tutti sono in attesa

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isHost
              ? [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
                ]
              : [
                  Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isHost
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: isHost ? 1.5 : 1,
        ),
        boxShadow: [
          if (isHost)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            // Enhanced avatar for lobby (no status overlay needed)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isHost
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.secondary)
                        .withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: isHost
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                child: Text(
                  nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 14),
            
            // Player info for lobby
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nickname.toString(),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Enhanced host indicator
                      if (isHost)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'HOST',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Role for lobby
                  Row(
                    children: [
                      Text(
                        isHost ? 'Game Master' : 'Player',
                        style: TextStyle(
                          color: isHost
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Waiting status chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.orange,
                            width: 0.5,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              color: Colors.orange,
                              size: 10,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'WAITING',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Simple ready status icon for lobby
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.schedule,
                color: Colors.orange,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
