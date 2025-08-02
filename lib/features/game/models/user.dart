/// Modello per rappresentare un giocatore
class User {
  final String playerId;
  final String displayName;

  User({
    required this.playerId,
    required this.displayName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      playerId: json['playerId'],
      displayName: json['display_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'display_name': displayName,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId;

  @override
  int get hashCode => playerId.hashCode;

  @override
  String toString() {
    return displayName;
}

}
