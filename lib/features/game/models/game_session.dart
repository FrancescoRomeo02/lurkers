import 'game_player.dart';

/// Modello per rappresentare una sessione di gioco
class GameSession {
  final String id;
  final String gameCode;
  final String hostId;
  final String? targetLocation;
  final String? requiredEvidence;
  final String status; // 'waiting', 'active', 'completed'
  final DateTime createdAt;
  final List<GamePlayer> players;

  GameSession({
    required this.id,
    required this.gameCode,
    required this.hostId,
    this.targetLocation,
    this.requiredEvidence,
    required this.status,
    required this.createdAt,
    required this.players,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'],
      gameCode: json['game_code'],
      hostId: json['host_id'],
      targetLocation: json['target_location'],
      requiredEvidence: json['required_evidence'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      players: [], // Verrà popolato separatamente
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game_code': gameCode,
      'host_id': hostId,
      'target_location': targetLocation,
      'required_evidence': requiredEvidence,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Verifica se l'utente corrente è l'host
  bool isUserHost(String userId) => hostId == userId;

  /// Ottieni il numero di giocatori
  int get playerCount => players.length;

  /// Verifica se il gioco può iniziare (almeno 2 giocatori)
  bool get canStart => players.length >= 2 && status == 'waiting';

  /// Verifica se il gioco è attivo
  bool get isActive => status == 'active';

  /// Verifica se il gioco è completato
  bool get isCompleted => status == 'completed';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
