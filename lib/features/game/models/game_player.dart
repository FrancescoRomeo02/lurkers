/// Modello per rappresentare un giocatore
class GamePlayer {
  final String id;
  final String nickname;

  GamePlayer({
    required this.id,
    required this.nickname,
  });

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    return GamePlayer(
      id: json['id'],
      nickname: json['nickname'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
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

  @override
  String toString() {
    return nickname;
}

}
