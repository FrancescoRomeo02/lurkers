import 'package:lurkers/features/game/models/party_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
        print('Party not found for code: $partyCode');
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
      print('Error joining party: $e');
      return false;
    }
  }

  /// Check if user is already in a party
  Future<bool> isUserInParty(String partyCode, dynamic user) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return false;
      }

      final response = await _supabase
          .from('party_players')
          .select('id')
          .eq('party_id', partyId)
          .eq('player_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking if user is in party: $e');
      return false;
    }
  }

  /// Join or rejoin a party - handles both first time and returning users
  Future<Map<String, dynamic>> joinOrRejoinParty(
    String partyCode,
    dynamic user, {
    String? location,
    String? item,
  }) async {
    try {
      // First check if party exists
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return {
          'success': false,
          'error': 'Party not found',
          'requiresData': false,
        };
      }

      // Check if user is already in the party
      final isAlreadyInParty = await isUserInParty(partyCode, user);
      
      if (isAlreadyInParty) {
        // User is already in party, can proceed to lobby
        return {
          'success': true,
          'error': null,
          'requiresData': false,
          'message': 'Welcome back to the party!',
        };
      } else {
        // User is not in party yet
        if (location == null || item == null) {
          // Need to collect location and item data
          return {
            'success': false,
            'error': null,
            'requiresData': true,
            'message': 'Please provide your location and item to join the party',
          };
        } else {
          // Have all data, can join the party
          final joinSuccess = await joinPartyByPartyCode(partyCode, location, item, user);
          return {
            'success': joinSuccess,
            'error': joinSuccess ? null : 'Failed to join party',
            'requiresData': false,
            'message': joinSuccess ? 'Successfully joined the party!' : null,
          };
        }
      }
    } catch (e) {
      print('Error in joinOrRejoinParty: $e');
      return {
        'success': false,
        'error': 'An error occurred: $e',
        'requiresData': false,
      };
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

      // Aggiungi le informazioni del profilo per ogni giocatore
      for (final item in response) {
        item['user_info'] = await getUserInfoByUuid(item['player_id']);
        print('User info for ${item['player_id']}: ${item['user_info']}');

      }

      return (response as List<dynamic>)
          .map((item) => PartyPlayer.fromJson(item))
          .toList();

    } catch (e) {
      throw Exception('Failed to get game players: $e');
    }
  }

  // get user info fom his UUid
  Future<Map<String, dynamic>?> getUserInfoByUuid(String uuid) async {
    try {
      // Opzione 2: Usa una tabella profiles invece di auth.users
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', uuid)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get user info: $e');
    }
  }


}