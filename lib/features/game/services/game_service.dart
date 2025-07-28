import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game_player.dart';

class GameService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create party by party code
  Future<bool> createParty(String partyCode, dynamic user) async {
    try {
      await _supabase
          .from('parties')
          .insert({
            'code': partyCode,
            'host_id': user.id,
          });
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// Join a Party by party code : DA CONTROLLARE
  Future<void> joinParty(String partyCode, String nickname) async {
    try {
      await _supabase
          .from('game_sessions')
          .insert({
            'party_code': partyCode,
            'nickname': nickname,
          })
          .select()
          .single();
    } catch (e) {
      throw Exception('Failed to join party: $e');
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

}
