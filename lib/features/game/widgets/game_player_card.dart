import 'package:flutter/material.dart';
import 'package:lurkers/features/game/models/party_player.dart';

class GamePlayerCard extends StatelessWidget {
  final PartyPlayer player;
  final bool isHost;
  final VoidCallback? onReportKill;

  const GamePlayerCard({
    super.key,
    required this.player,
    this.isHost = false,
    this.onReportKill,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = player.userInfo?['display_name'] ?? 'Unknown';
    final isAlive = player.isAlive;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isHost
              ? [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                ]
              : isAlive
                  ? [
                      Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ]
                  : [
                      Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.4),
                      Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.2),
                    ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isHost
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
              : isAlive
                  ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.error.withValues(alpha: 0.4),
          width: isHost ? 1.5 : 1,
        ),
        boxShadow: [
          if (isHost)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          if (!isAlive)
            BoxShadow(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            // Enhanced avatar with game status
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isHost
                                ? Theme.of(context).colorScheme.primary
                                : isAlive 
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.error)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: isHost
                        ? Theme.of(context).colorScheme.primary
                        : isAlive
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.outline,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                // Elimination overlay
                if (!isAlive)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ),
                // Alive status indicator
                if (isAlive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Enhanced player info for game
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and host badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: isAlive 
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            decoration: isAlive ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if (isHost)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'HOST',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Role and detailed status
                  Row(
                    children: [
                      Text(
                        isHost ? 'Game Master' : 'Assassin',
                        style: TextStyle(
                          color: isHost
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Detailed status chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAlive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAlive ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAlive ? Icons.favorite : Icons.heart_broken,
                              color: isAlive ? Colors.green : Colors.red,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAlive ? 'HUNTING' : 'ELIMINATED',
                              style: TextStyle(
                                color: isAlive ? Colors.green : Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
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
            
            // Enhanced action button
            if (isAlive && onReportKill != null)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: onReportKill,
                  icon: Icon(
                    Icons.visibility_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                  tooltip: 'Report Kill',
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              )
            else if (!isAlive)
              // Eliminated status icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.dangerous,
                  color: Colors.red,
                  size: 20,
                ),
              )
            else
              // Disabled state for alive players when current user is dead
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: Icon(
                  Icons.visibility_off_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
