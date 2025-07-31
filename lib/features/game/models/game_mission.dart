class GameMission {
  final int id;
  final int partyId;
  final String userId;
  final String targetId;
  final String item;
  final String location;
  final bool completed; 

  GameMission({
    required this.id,
    required this.partyId,
    required this.userId,
    required this.targetId,
    required this.item,
    required this.location,
    required this.completed,
  });

  factory GameMission.fromJson(Map<String, dynamic> json) {
    // print all data and all their types
    for (var entry in json.entries) {
      print('Key: ${entry.key}, Value: ${entry.value}, Type: ${entry.value.runtimeType}');
    }
    try {
          return GameMission(
            id: json['id'],
            partyId: json['party_id'],
            userId: json['user_id'],
            targetId: json['target_id'],
            item: json['item'],
            location: json['location'],
            completed: json['completed'] ?? false,  
          );
    } catch (e) {
      print('Error parsing GameMission from JSON: $e');
      throw Exception('Invalid GameMission data');
      
    }

  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'party_id': partyId,
      'user_id': userId,
      'target_id': targetId,
      'item': item,
      'location': location,
      'completed': completed,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameMission &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          partyId == other.partyId &&
          userId == other.userId &&
          targetId == other.targetId &&
          item == other.item &&
          location == other.location &&
          completed == other.completed; 
    
}