import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game_player.dart';
import '../models/game_session.dart';

class GameService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Crea una nuova sessione di gioco
  Future<GameSession?> createGameSession({
    required String gameCode,
    required String targetLocation,
    required String requiredEvidence,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase.from('game_sessions').insert({
        'game_code': gameCode,
        'host_id': user.id,
        'target_location': targetLocation,
        'required_evidence': requiredEvidence,
        'status': 'waiting',
      }).select().single();

      // Aggiungi l'host come primo giocatore
      await joinGame(gameCode: gameCode, location: targetLocation, evidence: requiredEvidence);

      return GameSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create game session: $e');
    }
  }

  /// Partecipa a una sessione di gioco esistente
  Future<GameSession?> joinGame({
    required String gameCode,
    required String location,
    required String evidence,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verifica se la sessione esiste
      final gameResponse = await _supabase
          .from('game_sessions')
          .select()
          .eq('game_code', gameCode)
          .eq('status', 'waiting')
          .single();

      final gameSession = GameSession.fromJson(gameResponse);

      // Controlla se l'utente è già nella partita
      final existingPlayer = await _supabase
          .from('game_players')
          .select()
          .eq('game_session_id', gameSession.id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingPlayer != null) {
        throw Exception('You are already in this game');
      }

      // Aggiungi il giocatore alla partita
      final nickname = user.userMetadata?['display_name'] ?? 'Unknown Player';
      
      await _supabase.from('game_players').insert({
        'game_session_id': gameSession.id,
        'user_id': user.id,
        'nickname': nickname,
        'location': location,
        'evidence': evidence,
        'is_host': gameSession.hostId == user.id,
      });

      return await getGameSession(gameCode);
    } catch (e) {
      throw Exception('Failed to join game: $e');
    }
  }

  /// Recupera una sessione di gioco con tutti i giocatori
  Future<GameSession?> getGameSession(String gameCode) async {
    try {
      final gameResponse = await _supabase
          .from('game_sessions')
          .select()
          .eq('game_code', gameCode)
          .single();

      final gameSession = GameSession.fromJson(gameResponse);

      // Recupera tutti i giocatori
      final playersResponse = await _supabase
          .from('game_players')
          .select()
          .eq('game_session_id', gameSession.id)
          .order('joined_at');

      final players = playersResponse
          .map((player) => GamePlayer.fromJson(player))
          .toList();

      return GameSession(
        id: gameSession.id,
        gameCode: gameSession.gameCode,
        hostId: gameSession.hostId,
        targetLocation: gameSession.targetLocation,
        requiredEvidence: gameSession.requiredEvidence,
        status: gameSession.status,
        createdAt: gameSession.createdAt,
        players: players,
      );
    } catch (e) {
      throw Exception('Failed to get game session: $e');
    }
  }

  /// Recupera tutti i giocatori di una sessione
  Future<List<GamePlayer>> getGamePlayers(String gameCode) async {
    try {
      final gameResponse = await _supabase
          .from('game_sessions')
          .select('id')
          .eq('game_code', gameCode)
          .single();

      final playersResponse = await _supabase
          .from('game_players')
          .select()
          .eq('game_session_id', gameResponse['id'])
          .order('joined_at');

      return playersResponse
          .map((player) => GamePlayer.fromJson(player))
          .toList();
    } catch (e) {
      throw Exception('Failed to get game players: $e');
    }
  }

  /// Avvia il gioco (solo per l'host)
  Future<void> startGame(String gameCode) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final gameResponse = await _supabase
          .from('game_sessions')
          .select()
          .eq('game_code', gameCode)
          .single();

      if (gameResponse['host_id'] != user.id) {
        throw Exception('Only the host can start the game');
      }

      await _supabase
          .from('game_sessions')
          .update({'status': 'active'})
          .eq('game_code', gameCode);
    } catch (e) {
      throw Exception('Failed to start game: $e');
    }
  }

  /// Ascolta i cambiamenti in tempo reale di una sessione
  Stream<GameSession?> watchGameSession(String gameCode) {
    return _supabase
        .from('game_sessions')
        .stream(primaryKey: ['id'])
        .eq('game_code', gameCode)
        .map((data) {
          if (data.isEmpty) return null;
          return GameSession.fromJson(data.first);
        });
  }

  /// Ascolta i cambiamenti in tempo reale dei giocatori
  Stream<List<GamePlayer>> watchGamePlayers(String gameSessionId) {
    return _supabase
        .from('game_players')
        .stream(primaryKey: ['id'])
        .eq('game_session_id', gameSessionId)
        .map((data) {
          return data.map((player) => GamePlayer.fromJson(player)).toList();
        });
  }

  /// Abbandona il gioco
  Future<void> leaveGame(String gameCode) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final gameResponse = await _supabase
          .from('game_sessions')
          .select('id')
          .eq('game_code', gameCode)
          .single();

      await _supabase
          .from('game_players')
          .delete()
          .eq('game_session_id', gameResponse['id'])
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to leave game: $e');
    }
  }
}
