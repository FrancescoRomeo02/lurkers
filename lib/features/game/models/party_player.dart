class PartyPlayer {
  final int id;
  final int partyId;
  final String playerId;
  final bool isAlive; // Default to true, assuming player is alive when created
  final String targetId;
  final String insertLocation;
  final String insertItem;
  final DateTime createdAt;
  final Map<String, dynamic>? userInfo;


  const PartyPlayer({
    required this.id,
    required this.createdAt,
    required this.partyId,
    required this.isAlive,
    required this.playerId,
    this.userInfo, // Opzionale, può essere null se non sono disponibili informazioni del profilo
    required this.insertLocation,
    required this.insertItem,
    required this.targetId,
  });

  /// Factory constructor per creare un PartyPlayer da JSON (Supabase response)
  factory PartyPlayer.fromJson(Map<String, dynamic> json) {
    return PartyPlayer(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      partyId: json['party_id'] as int,
      isAlive: json['is_alive'] as bool,
      playerId: json['player_id'] as String,
      userInfo: json['user_info'] as Map<String, dynamic>?, // Aggiunto per le informazioni del profilo
      insertLocation: json['mission_location'] as String,
      insertItem: json['mission_item'] as String,
      targetId: json['target_id'] as String, // Aggiunto per il target del giocatore
    );
  }

  /// Converte il PartyPlayer in JSON per inviarlo a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'party_id': partyId,
      'is_alive': isAlive,
      'player_id': playerId,
      'user_info': userInfo, // Includi le informazioni del profilo se disponibili
      'insert_location': insertLocation,
      'insert_item': insertItem,
      'target_id': targetId, // Includi il target del giocatore
    };
  }

  @override
  String toString() {
    return 'PartyPlayer(id: $id, partyId: $partyId, is alive: $isAlive, playerId: $playerId, userInfo: $userInfo location: $insertLocation, item: $insertItem, targetId: $targetId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartyPlayer &&
        other.id == id &&
        other.partyId == partyId &&
        other.playerId == playerId;
  }

  @override
  int get hashCode {
    return Object.hash(id, partyId, playerId);
  }
}