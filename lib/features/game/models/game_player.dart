/// Modello per rappresentare un giocatore
class GamePlayer {
  final String id;
  final String nickname;
  final String? location;
  final String? evidence;
  final bool isHost;
  final DateTime joinedAt;

  GamePlayer({
    required this.id,
    required this.nickname,
    this.location,
    this.evidence,
    required this.isHost,
    required this.joinedAt,
  });

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    return GamePlayer(
      id: json['id'],
      nickname: json['nickname'],
      location: json['location'],
      evidence: json['evidence'],
      isHost: json['is_host'] ?? false,
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'location': location,
      'evidence': evidence,
      'is_host': isHost,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GamePlayer &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
