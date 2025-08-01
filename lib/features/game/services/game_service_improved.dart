import 'package:lurkers/features/game/models/lobby_player.dart';
import 'package:lurkers/features/game/models/party_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Log error messages for debugging - improved logging
  void _logError(String operation, dynamic error) {
    print('GameService[$operation] Error: $error');
  }

  /// Create party by party code - improved with validation
  Future<bool> createParty(String partyCode, dynamic user) async {
    try {
      if (partyCode.trim().isEmpty) {
        _logError('createParty', 'Party code cannot be empty');
        return false;
      }

      await _supabase
          .from('parties')
          .insert({
            'code': partyCode.trim(),
            'host_id': user.id,
            'status': 'inactive',
          });
      return true;
    } catch (e) {
      _logError('createParty', e);
      return false;
    }
  }

  /// Get the party id from the party code - improved with validation
  Future<int> getPartyIdByCode(String partyCode) async {
    try {
      if (partyCode.trim().isEmpty) {
        _logError('getPartyIdByCode', 'Party code cannot be empty');
        return 0;
      }

      final response = await _supabase
          .from('parties')
          .select('id')
          .eq('code', partyCode.trim())
          .maybeSingle();

      if (response == null) {
        return 0;
      }

      return response['id'] as int;
    } catch (e) {
      _logError('getPartyIdByCode', e);
      return 0;
    }
  }

  /// Join a lobby by party code - improved with validation
  Future<bool> joinPartyLobbyByPartyCode(
    String partyCode,
    String location,
    String item,
    dynamic user,
  ) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        _logError('joinPartyLobbyByPartyCode', 'Party not found');
        return false;
      }

      await _supabase.from('lobby_submissions').insert({
        'party_id': partyId,
        'player_id': user.id,
        'submitted_item': item.trim(),
        'submitted_location': location.trim(),
      });
      
      return true;
    } catch (e) {
      _logError('joinPartyLobbyByPartyCode', e);
      return false;
    }
  }

  /// Check if user is already in lobby - improved with validation
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
      _logError('isUserInLobby', e);
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
      _logError('isUserHostOfParty', e);
      return false;
    }
  }

  /// Check party status and return status information - NEW IMPROVED FUNCTION
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
      _logError('getPartyStatus', e);
      return {
        'exists': false,
        'status': null,
        'isActive': false,
      };
    }
  }

  /// Get user's data from party_players table - improved error handling
  Future<Map<String, dynamic>?> getUserLobbyData(String partyCode, dynamic user) async {
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

      return response;
    } catch (e) {
      _logError('getUserLobbyData', e);
      return null;
    }
  }

  /// Process joining a party with comprehensive checks - MAJOR IMPROVEMENT
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

      // Check if user is already in the lobby
      final isAlreadyInParty = await isUserInLobby(partyCode, user);

      final partyStatus = partyStatusInfo['status'];
      final isActive = partyStatusInfo['isActive'];
      
      // If user is already in the party and the party is not finished rejoin them
      if (isAlreadyInParty && partyStatus != 'finished') {
        // User is already in party, get their original data
        final userData = await getUserLobbyData(partyCode, user);
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
      _logError('processJoinParty', e);
      return {
        'success': false,
        'error': 'An error occurred: $e',
        'requiresData': false,
        'isHost': false,
        'isActive': false,
      };
    }
  }

  /// Get all lobby players - OPTIMIZED to reduce N+1 queries
  Future<List<LobbyPlayer>> getLobbyPlayers(String partyCode) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return [];
      }

      // Optimized query using JOIN to avoid N+1 queries
      final response = await _supabase
          .from('lobby_submissions')
          .select('''
            *,
            profiles!inner(id, display_name, email, avatar_url)
          ''')
          .eq('party_id', partyId);

      return (response as List<dynamic>)
          .map((item) {
            // Transform the joined data to match LobbyPlayer.fromJson expectations
            item['user_info'] = item['profiles'];
            return LobbyPlayer.fromJson(item);
          })
          .toList();

    } catch (e) {
      _logError('getLobbyPlayers', e);
      throw Exception('Failed to get lobby players: $e');
    }
  }

  /// Get all party players - OPTIMIZED to reduce N+1 queries
  Future<List<PartyPlayer>> getPartyPlayers(String partyCode) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return [];
      }
      
      // Optimized query using JOIN to avoid N+1 queries
      final response = await _supabase
          .from('party_players')
          .select('''
            *,
            profiles!inner(id, display_name, email, avatar_url)
          ''')
          .eq('party_id', partyId);

      return (response as List<dynamic>)
          .map((item) {
            // Transform the joined data to match PartyPlayer.fromJson expectations
            item['user_info'] = item['profiles'];
            return PartyPlayer.fromJson(item);
          })
          .toList();
    } catch (e) {
      _logError('getPartyPlayers', e);
      throw Exception('Failed to get party players: $e');
    }
  }

  /// Get user info by UUID - OPTIMIZED with better error handling
  Future<Map<String, dynamic>?> getUserInfoByUuid(String uuid) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', uuid)
          .maybeSingle();

      return response;
    } catch (e) {
      _logError('getUserInfoByUuid', e);
      throw Exception('Failed to get user info: $e');
    }
  }

  /// Start the game by party code - IMPROVED with transaction-like behavior
  Future<bool> startGame(String partyCode) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        _logError('startGame', 'Party not found for code: $partyCode');
        return false;
      }
      
      // Get all players in the lobby first
      final players = await getLobbyPlayers(partyCode);
      if (players.isEmpty) {
        _logError('startGame', 'No players found in the party');
        return false;
      }

      if (players.length < 2) {
        _logError('startGame', 'Need at least 2 players to start the game');
        return false;
      }

      // Collect items and locations from players
      final partyItems = players.map((player) => player.insertItem).toList();
      final partyLocations = players.map((player) => player.insertLocation).toList();

      // Randomize players, items, and locations
      players.shuffle();
      partyItems.shuffle();
      partyLocations.shuffle();

      // Prepare batch insert for party_players
      final List<Map<String, dynamic>> partyPlayersData = [];
      for (int i = 0; i < players.length; i++) {
        final targetIndex = (i + 1) % players.length; // Circular target selection
        partyPlayersData.add({
          'party_id': partyId,
          'player_id': players[i].playerId,
          'is_alive': true,
          'target_id': players[targetIndex].playerId,
          'mission_item': partyItems[i],
          'mission_location': partyLocations[i],
        });
      }

      // Insert all party players in batch
      await _supabase.from('party_players').insert(partyPlayersData);
      
      // Set the party status to 'active' after successful player insertion
      await _supabase
          .from('parties')
          .update({'status': 'active'})
          .eq('id', partyId);

      return true;
    } catch (e) {
      _logError('startGame', e);
      return false;
    }
  }
}
