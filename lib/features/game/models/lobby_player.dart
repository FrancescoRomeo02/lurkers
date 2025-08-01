class LobbyPlayer {
  final int id;
  final DateTime createdAt;
  final int partyId;
  final String playerId;
  final String insertLocation;
  final String insertItem;
  final Map<String, dynamic>? userInfo;


  const LobbyPlayer({
    required this.id,
    required this.createdAt,
    required this.partyId,
    required this.playerId,
    this.userInfo, // Opzionale, può essere null se non sono disponibili informazioni del profilo
    required this.insertLocation,
    required this.insertItem,
  });

  /// Factory constructor per creare un LobbyPlayer da JSON (Supabase response)
  factory LobbyPlayer.fromJson(Map<String, dynamic> json) {
    return LobbyPlayer(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      partyId: json['party_id'] as int,
      playerId: json['player_id'] as String,
      userInfo: json['user_info'] as Map<String, dynamic>?, // Aggiunto per le informazioni del profilo
      insertLocation: json['submitted_location'] as String,
      insertItem: json['submitted_item'] as String,
    );
  }

  /// Converte il LobbyPlayer in JSON per inviarlo a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'party_id': partyId,
      'player_id': playerId,
      'user_info': userInfo, // Includi le informazioni del profilo se disponibili
      'insert_location': insertLocation,
      'insert_item': insertItem,
    };
  }

  @override
  String toString() {
    return 'LobbyPlayer(id: $id, partyId: $partyId, playerId: $playerId, userInfo: $userInfo location: $insertLocation, item: $insertItem)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LobbyPlayer &&
        other.id == id &&
        other.partyId == partyId &&
        other.playerId == playerId;
  }

  @override
  int get hashCode {
    return Object.hash(id, partyId, playerId);
  }
}