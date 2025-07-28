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

  /// Join a Party by party code

  // Get the party id from the party code
  Future<int> getPartyIdByCode(String partyCode) async {
    try {
      final response = await _supabase
          .from('parties')
          .select('id')
          .eq('code', partyCode)
          .maybeSingle();

      if (response == null) {
        print('No party found with code: $partyCode');
        return 0;
      }

      return response['id'];
    } catch (e) {
      print('Error fetching party ID: $e');
      return 0;
    }
  }

  Future<bool> joinPartyByPartyCode(
    String partyCode,
    String location,
    String item,
    dynamic user,
    ) async {
    try {
      int partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return false;
      }
      await _supabase
      .from('party_players')
      .insert({
        'party_id':partyId,
        'player_id':user.id,
        'insert_location': location,
        'insert_item': item,
        'status': 'waiting',
      });
      return true;
    } catch (e) {
      return false;
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
