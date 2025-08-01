import 'package:flutter/widgets.dart';
import 'package:lurkers/features/game/models/lobby_player.dart';
import 'package:lurkers/features/game/models/user.dart';
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
            'status': 'inactive', // Default status is 'inactive'
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

  // Join a lobby by party code
  Future<bool> joinPartyLobbyByPartyCode(
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
      .from('lobby_submissions')
      .insert({
        'party_id':partyId,
        'player_id':user.id,
        'submitted_item': item,
        'submitted_location': location,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is already in lobby
  Future<bool> isUserInLobby(String partyCode, dynamic user) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return false;
      }

      final response = await _supabase
          .from('lobby_submissions')
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

  /// Check party status and return status information
  Future<Map<String, dynamic>> getPartyStatus(String partyCode) async {
    try {
      final response = await _supabase
          .from('parties')
          .select('status')
          .eq('code', partyCode)
          .maybeSingle();
      
      if (response == null) {
        return {
          'exists': false,
          'status': null,
          'isActive': false,
        };
      }
      
      final status = response['status'];
      return {
        'exists': true,
        'status': status,
        'isActive': status == 'active',
      };
    } catch (e) {
      return {
        'exists': false,
        'status': null,
        'isActive': false,
      };
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
          .from('lobby_submissions')
          .select('submitted_location, submitted_item')
          .eq('party_id', partyId)
          .eq('player_id', user.id)
          .maybeSingle();
      print('User party data: $response');
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Process joining a party with comprehensive checks
  Future<Map<String, dynamic>> processJoinParty(String partyCode, dynamic user, {String? location, String? item}) async {
    try {
      // First check if party exists and get its status
      final partyStatusInfo = await getPartyStatus(partyCode);
      if (!partyStatusInfo['exists']) {
        return {
          'success': false,
          'error': 'Party not found',
          'requiresData': false,
          'isHost': false,
          'isActive': false,
        };
      }

      // Check if user is the host of this party
      final isHost = await isUserHostOfParty(partyCode, user);
      print('Is user host: $isHost');

      // Check if user is already in the lobby
      final isAlreadyInParty = await isUserInLobby(partyCode, user);
      print('Is user already in party: $isAlreadyInParty');

      final partyStatus = partyStatusInfo['status'];
      final isActive = partyStatusInfo['isActive'];
      
      // If user is already in the party and the party is not finished rejoin them
      if (isAlreadyInParty && partyStatus != 'finished') {
        // User is already in party, get their original data
        final userData = await getUserPartyData(partyCode, user);
        return {
          'success': true,
          'error': null,
          'requiresData': false,
          'isHost': isHost,
          'isActive': isActive,
          'status': partyStatus,
          'location': userData?['submitted_location'] ?? '',
          'item': userData?['submitted_item'] ?? '',
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
            'isActive': isActive,
            'status': partyStatus,
            'message': 'Please provide your location and item to join the party',
          };
        } else {
          // Have all data, can join the party
          final joinSuccess = await joinPartyLobbyByPartyCode(partyCode, location, item, user);
          return {
            'success': joinSuccess,
            'error': joinSuccess ? null : 'Failed to join party',
            'requiresData': false,
            'isHost': isHost,
            'isActive': isActive,
            'status': partyStatus,
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
        'isActive': false,
      };
    }
  }

  /// Get all party information by party code
  Future<List<LobbyPlayer>> getLobbyPlayers(String partyCode) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return [];
      }

      final response = await _supabase
          .from('lobby_submissions')
          .select()
          .eq('party_id', partyId);
    
      for (final item in response) {
        item['user_info'] = await getUserInfoByUuid(item['player_id']);
      }

      return (response as List<dynamic>)
          .map((item) => LobbyPlayer.fromJson(item))
          .toList();

    } catch (e) {
      throw Exception('Failed to get game players: $e');
    }
  }

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
      for (final item in response) {
        item['user_info'] = await getUserInfoByUuid(item['player_id']);
      }
      return (response as List<dynamic>)
          .map((item) => PartyPlayer.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to get party players: $e');
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
      
      // Set the party status to 'active'
      await _supabase
          .from('parties')
          .update({'status': 'active'})
          .eq('id', partyId);

      // Get all players in the lobby
      final players = await getLobbyPlayers(partyCode);
      if (players.isEmpty) {
        print('No players found in the party.');
        return false;
      }

      // Select items and locations from players
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

      // add all the players into the party_players table with their items, locations and targets
      for (final player in players) {
        final targetIndex = (players.indexOf(player) + 1) % players.length; // Circular target selection
        await _supabase.from('party_players').insert({
          'party_id': partyId,
          'player_id': player.playerId,
          'is_alive': true,
          'target_id': players[targetIndex].playerId, // Set the target player
          'mission_item': partyItem[players.indexOf(player)],
          'mission_location': partyLocation[players.indexOf(player)],
        });
      }
      return true;
    } catch (e) {
      print('Error starting game: $e');
      return false;
    }
  }

}