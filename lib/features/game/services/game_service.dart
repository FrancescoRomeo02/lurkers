import 'package:lurkers/features/game/models/party_player.dart';
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
        return 0;
      }

      return response['id'];
    } catch (e) {
      return 0;
    }
  }

  // Join a party by party code
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

  /// Get all party information by party code
  Future<List<PartyPlayer>> getGamePlayers(String partyCode) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return [];
      }

      final response = await _supabase
          .from('party_players')
          .select()
          .eq('party_id', partyId);

      return (response as List<dynamic>)
          .map((item) => PartyPlayer.fromJson(item))
          .toList();

    } catch (e) {
      throw Exception('Failed to get game players: $e');
    }
  }
}