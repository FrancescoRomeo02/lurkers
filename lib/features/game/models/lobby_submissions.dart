class LobbySubmissions {
  final String id;
  final String createdAt;
  final String partyId;
  final String playerId;
  final String submittedItem;
  final String submittedLocation;

  LobbySubmissions({
    required this.id,
    required this.createdAt,
    required this.partyId,
    required this.playerId,
    required this.submittedItem,
    required this.submittedLocation,
  });

  factory LobbySubmissions.fromJson(Map<String, dynamic> json) {
    return LobbySubmissions(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      partyId: json['party_id'] as String,
      playerId: json['player_id'] as String,
      submittedItem: json['submitted_item'] as String,
      submittedLocation: json['submitted_location'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt,
      'party_id': partyId,
      'player_id': playerId,
      'submitted_item': submittedItem,
      'submitted_location': submittedLocation,
    };
  }
}