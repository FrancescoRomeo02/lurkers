class PartyPlayer {
  final int id;
  final DateTime createdAt;
  final int partyId;
  final PlayerStatus status;
  final String playerId;
  final Map<String, dynamic>? userInfo; // Aggiunto per le informazioni del profilo
  final String insertLocation;
  final String insertItem;

  const PartyPlayer({
    required this.id,
    required this.createdAt,
    required this.partyId,
    required this.status,
    required this.playerId,
    this.userInfo, // Opzionale, può essere null se non sono disponibili informazioni del profilo
    required this.insertLocation,
    required this.insertItem,
  });

  /// Factory constructor per creare un PartyPlayer da JSON (Supabase response)
  factory PartyPlayer.fromJson(Map<String, dynamic> json) {
    return PartyPlayer(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      partyId: json['party_id'] as int,
      status: PlayerStatus.fromString(json['status'] as String),
      playerId: json['player_id'] as String,
      userInfo: json['user_info'] as Map<String, dynamic>?, // Aggiunto per le informazioni del profilo
      insertLocation: json['insert_location'] as String,
      insertItem: json['insert_item'] as String,
    );
  }

  /// Converte il PartyPlayer in JSON per inviarlo a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'party_id': partyId,
      'status': status.value,
      'player_id': playerId,
      'user_info': userInfo, // Includi le informazioni del profilo se disponibili
      'insert_location': insertLocation,
      'insert_item': insertItem,
    };
  }

  /// Crea una copia del PartyPlayer con alcuni campi modificati
  PartyPlayer copyWith({
    int? id,
    DateTime? createdAt,
    int? partyId,
    PlayerStatus? status,
    String? playerId,
    Map<String, dynamic>? userInfo, // Aggiunto per le informazioni del profilo
    String? insertLocation,
    String? insertItem,
  }) {
    return PartyPlayer(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      partyId: partyId ?? this.partyId,
      status: status ?? this.status,
      playerId: playerId ?? this.playerId,
      userInfo: userInfo ?? this.userInfo, // Aggiunto per le informazioni del profilo
      insertLocation: insertLocation ?? this.insertLocation,
      insertItem: insertItem ?? this.insertItem,
    );
  }

  @override
  String toString() {
    return 'PartyPlayer(id: $id, partyId: $partyId, status: $status, playerId: $playerId, userInfo: $userInfo location: $insertLocation, item: $insertItem)';
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

/// Enum per rappresentare i possibili stati del giocatore
enum PlayerStatus {
  waiting('waiting'),
  playing('playing'),
  eliminated('eliminated'),
  winner('winner');

  const PlayerStatus(this.value);

  final String value;

  /// Factory per creare PlayerStatus da stringa
  factory PlayerStatus.fromString(String status) {
    return PlayerStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => PlayerStatus.waiting,
    );
  }

  /// Getter per ottenere una descrizione user-friendly dello stato
  String get displayName {
    switch (this) {
      case PlayerStatus.waiting:
        return 'Waiting for game to start';
      case PlayerStatus.playing:
        return 'Playing';
      case PlayerStatus.eliminated:
        return 'Eliminated';
      case PlayerStatus.winner:
        return 'Winner';
    }
  }

  /// Controlla se il giocatore è ancora vivo/attivo nel gioco
  bool get isAlive {
    return this == PlayerStatus.waiting || 
           this == PlayerStatus.playing;
  }

  /// Controlla se il giocatore è eliminato
  bool get isEliminated {
    return this == PlayerStatus.eliminated;
  }

  /// Controlla se il gioco è finito per questo giocatore
  bool get isGameOver {
    return this == PlayerStatus.winner || isEliminated;
  }
}
