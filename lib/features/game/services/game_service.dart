import 'package:lurkers/features/game/models/game_mission.dart';
import 'package:lurkers/features/game/models/game_player.dart';
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
      return false;
    }
  }

  /// Check if user is the host of a party
  Future<bool> isUserHostOfParty(String partyCode, dynamic user) async {
    try {
      final response = await _supabase
          .from('parties')
          .select('host_id')
          .eq('code', partyCode)
          .maybeSingle();
      if (response == null) {
        return false;
      }
      return response['host_id'] == user.id;
    } catch (e) {

      return false;
    }
  }

  /// Get user's data from party_players table
  Future<Map<String, dynamic>?> getUserPartyData(String partyCode, dynamic user) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return null;
      }

      final response = await _supabase
          .from('party_players')
          .select('insert_location, insert_item')
          .eq('party_id', partyId)
          .eq('player_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
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
          'isHost': false,
        };
      }
      // Check if user is the host of this party
      final isHost = await isUserHostOfParty(partyCode, user);

      // Check if user is already in the party
      final isAlreadyInParty = await isUserInParty(partyCode, user);
      
      if (isAlreadyInParty) {
        // User is already in party, get their original data
        final userData = await getUserPartyData(partyCode, user);
        return {
          'success': true,
          'error': null,
          'requiresData': false,
          'isHost': isHost,
          'location': userData?['insert_location'] ?? '',
          'item': userData?['insert_item'] ?? '',
          'message': isHost ? 'Welcome back, Game Master!' : 'Welcome back to the party!',
        };
      } else {
        // User is not in party yet
        if (location == null || item == null) {
          // Need to collect location and item data
          return {
            'success': false,
            'error': null,
            'requiresData': true,
            'isHost': isHost,
            'message': 'Please provide your location and item to join the party',
          };
        } else {
          // Have all data, can join the party
          final joinSuccess = await joinPartyByPartyCode(partyCode, location, item, user);
          return {
            'success': joinSuccess,
            'error': joinSuccess ? null : 'Failed to join party',
            'requiresData': false,
            'isHost': isHost,
            'location': joinSuccess ? location : '',
            'item': joinSuccess ? item : '',
            'message': joinSuccess 
                ? (isHost ? 'Successfully rejoined as Game Master!' : 'Successfully joined the party!')
                : null,
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'An error occurred: $e',
        'requiresData': false,
        'isHost': false,
      };
    }
  }

  /// Get all party information by party code
  Future<List<PartyPlayer>> getPartyPlayers(String partyCode) async {
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
  /// Start the game by party code
  Future<bool> startGame(String partyCode) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        print('Party not found for code: $partyCode');
        return false;
      }
      // Update all players' status to 'active'
      await _supabase
          .from('party_players')
          .update({'status': 'active'})
          .eq('party_id', partyId);
      
      //TODO: Set the party status to 'active'
     /*  await _supabase
          .from('parties')
          .update({'status': 'active'})
          .eq('id', partyId); */
        
      // Set the starting mission for the party}
      final players = await getPartyPlayers(partyCode);
      if (players.isEmpty) {
        print('No players found in the party.');
        return false;
      }

      final partyItem = [];
      final partyLocation = [];

      for (final player in players) {
        partyItem.add(player.insertItem);
        partyLocation.add(player.insertLocation);
        }

      // Randomize players, items, and locations
      players.shuffle();
      partyItem.shuffle();
      partyLocation.shuffle();

      // Assign to each player a target player
      for (int i = 0; i < players.length; i++) {
        final targetPlayer = players[(i + 1) % players.length]; // Next player
        final missionItem = partyItem[i];
        final missionLocation = partyLocation[i];
        await setMission(
          partyId,
          players[i].playerId,
          targetPlayer.playerId,
          missionItem,
          missionLocation,
        );
      }
      return true;
    } catch (e) {
      print('Error starting game: $e');
      return false;
    }
  }

  Future<bool> setMission(
    int partyId,
    String userId,
    String targetId,
    String missionItem,
    String missionLocation,
  ) async {
    try {
      print('Setting mission for user $userId in party $partyId');
      print('Target: $targetId, Item: $missionItem, Location: $missionLocation');
      await _supabase
          .from('missions')
          .insert({
            'party_id': partyId,
            'user_id': userId,
            'target_id': targetId,
            'item': missionItem,
            'location': missionLocation,
            'completed': false,
          });
      return true;
    } catch (e) {
      print('Error setting mission: $e');
      return false;
    }
  }

  Future<List<GameMission>> getCurrentPlayerMissionInfo(String partyCode, String userId) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        print('Party not found for code: $partyCode');
        return [];
      }
      final response = await _supabase
          .from('missions')
          .select()
          .eq('party_id', partyId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        print('No mission found for user $userId in party $partyCode');
        return [];
      }

      return [GameMission.fromJson(response)];
    } catch (e) {
      // print response
      print('Error fetching mission info: $e');
      return [];
    }
}
}