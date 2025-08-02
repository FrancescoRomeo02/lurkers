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
        _logError('isUserHostOfParty', 'Host not found for party code: $partyCode');
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

  /// Get user's data from lobby_submissions table
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

  Future<PartyPlayer> getPartyPlayer(String partyCode, dynamic user) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        throw Exception('Party not found for code: $partyCode');
      }
      final response = await _supabase
          .from('party_players')
          .select('''
            *,
            profiles!party_players_player_id_fkey(id, display_name, email, avatar_url)
          ''')
          .eq('party_id', partyId)
          .eq('player_id', user.id)
          .maybeSingle();
      if (response == null) {
        throw Exception('Player not found in party: $partyCode');
      } 
        return PartyPlayer.fromJson({
          ...response,
          'user_info': response['profiles'],
        });
    } catch (e) {
      _logError('getPartyPlayer', e);
      throw Exception('Failed to get party player: $e');
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
      // Specify the exact foreign key relationship to avoid ambiguity
      final response = await _supabase
          .from('party_players')
          .select('''
            *,
            profiles!party_players_player_id_fkey(id, display_name, email, avatar_url)
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

// Check if a player is alive
  Future<bool> isPlayerAlive(String partyCode, String playerId) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        _logError('isPlayerAlive', 'Party not found for code: $partyCode');
        return false;
      }
      final response = await _supabase
          .from('party_players')
          .select('is_alive')
          .eq('party_id', partyId)
          .eq('player_id', playerId)
          .maybeSingle();
      if (response == null) {
        _logError('isPlayerAlive', 'Player not found in party: $partyCode');
        return false;
      }
      return response['is_alive'] as bool;
    } catch (e) {
      _logError('isPlayerAlive', e);
      return false;
    }
  }

// Perform a kill (now just reports the kill, needs confirmation)
  Future<bool> reportKill(String partyCode, String killerId, String targetId) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        _logError('reportKill', 'Party not found for code: $partyCode');
        return false;
      }
      
      // Check if the killer is alive
      final killerAlive = await isPlayerAlive(partyCode, killerId);
      if (!killerAlive) {
        _logError('reportKill', 'Killer is not alive');
        return false;
      }

      // Check if the target is alive
      final targetAlive = await isPlayerAlive(partyCode, targetId);
      if (!targetAlive) {
        _logError('reportKill', 'Target is already dead');
        return false;
      }

      // Check if there's already a pending elimination for this target
      final existingElimination = await _supabase
          .from('elimination_events')
          .select('id')
          .eq('party_id', partyId)
          .eq('victim_id', targetId)
          .eq('event_confirmed', false)
          .maybeSingle();

      if (existingElimination != null) {
        _logError('reportKill', 'There is already a pending elimination for this target');
        return false;
      }

      // Create elimination event with confirmation pending
      await _supabase.from('elimination_events').insert({
        'party_id': partyId,
        'actor_id': killerId,
        'victim_id': targetId,
        'event_type': 'kill',
        'event_confirmed': false,
      });

      return true;
    } catch (e) {
      _logError('reportKill', e);
      return false;
    }
  }

  // Confirm elimination (victim confirms their death)
  Future<bool> confirmElimination(String partyCode, String victimId, int eliminationEventId) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        _logError('confirmElimination', 'Party not found for code: $partyCode');
        return false;
      }

      // Get the elimination event details
      final eliminationEvent = await _supabase
          .from('elimination_events')
          .select('actor_id, victim_id, event_confirmed')
          .eq('id', eliminationEventId)
          .eq('party_id', partyId)
          .eq('victim_id', victimId)
          .maybeSingle();

      if (eliminationEvent == null) {
        _logError('confirmElimination', 'Elimination event not found');
        return false;
      }

      if (eliminationEvent['event_confirmed'] == true) {
        _logError('confirmElimination', 'Elimination already confirmed');
        return false;
      }

      final killerId = eliminationEvent['actor_id'];

      // Get victim's current mission data before killing them
      final victimData = await _supabase
          .from('party_players')
          .select('mission_item, mission_location, target_id')
          .eq('party_id', partyId)
          .eq('player_id', victimId)
          .maybeSingle();

      if (victimData == null) {
        _logError('confirmElimination', 'Victim data not found');
        return false;
      }

      // Start transaction-like operations
      // 1. Mark elimination as confirmed
      await _supabase
          .from('elimination_events')
          .update({'event_confirmed': true})
          .eq('id', eliminationEventId);

      // 2. Kill the victim
      await _supabase
          .from('party_players')
          .update({'is_alive': false})
          .eq('party_id', partyId)
          .eq('player_id', victimId);

      // 3. Transfer victim's mission to killer
      await _supabase
          .from('party_players')
          .update({
            'mission_item': victimData['mission_item'],
            'mission_location': victimData['mission_location'],
            'target_id': victimData['target_id'],
          })
          .eq('party_id', partyId)
          .eq('player_id', killerId);

      return true;
    } catch (e) {
      _logError('confirmElimination', e);
      return false;
    }
  }

  // Get pending elimination for a victim
  Future<Map<String, dynamic>?> getPendingEliminationForVictim(String partyCode, String victimId) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return null;
      }

      final response = await _supabase
          .from('elimination_events')
          .select('''
            id,
            actor_id,
            victim_id,
            event_type,
            event_confirmed,
            created_at,
            profiles!elimination_events_actor_id_fkey(id, display_name)
          ''')
          .eq('party_id', partyId)
          .eq('victim_id', victimId)
          .eq('event_confirmed', false)
          .maybeSingle();

      if (response != null) {
        response['killer_info'] = response['profiles'];
      }

      return response;
    } catch (e) {
      _logError('getPendingEliminationForVictim', e);
      return null;
    }
  }

  // Get all pending eliminations for a party (for debugging/admin)
  Future<List<Map<String, dynamic>>> getPendingEliminations(String partyCode) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return [];
      }

      final response = await _supabase
          .from('elimination_events')
          .select('''
            id,
            actor_id,
            victim_id,
            event_type,
            event_confirmed,
            created_at,
            actor_profile:profiles!elimination_events_actor_id_fkey(id, display_name),
            victim_profile:profiles!elimination_events_victim_id_fkey(id, display_name)
          ''')
          .eq('party_id', partyId)
          .eq('event_confirmed', false);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      _logError('getPendingEliminations', e);
      return [];
    }
  }

// Legacy method - kept for backward compatibility, now calls reportKill
  Future<bool> performKill(String partyCode, String killerId, String targetId) async {
    return await reportKill(partyCode, killerId, targetId);
  }

  /// Check if a player has won the game (has themselves as target)
  Future<bool> checkVictoryCondition(String partyCode, String playerId) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return false;
      }

      // First check if the game is already completed
      final partyStatus = await _supabase
          .from('parties')
          .select('status')
          .eq('id', partyId)
          .maybeSingle();

      if (partyStatus != null && partyStatus['status'] == 'completed') {
        return false; // Game already completed
      }

      final response = await _supabase
          .from('party_players')
          .select('player_id, target_id, is_alive')
          .eq('party_id', partyId)
          .eq('player_id', playerId)
          .eq('is_alive', true)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      // Victory condition: player has themselves as target
      return response['target_id'] == playerId;
    } catch (e) {
      _logError('checkVictoryCondition', e);
      return false;
    }
  }

  /// Force victory for testing purposes - sets player's target to themselves
  Future<bool> forceVictoryForTesting(String partyCode, String playerId) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return false;
      }

      // Set the player's target to themselves to trigger victory
      await _supabase
          .from('party_players')
          .update({'target_id': playerId})
          .eq('party_id', partyId)
          .eq('player_id', playerId);

      return true;
    } catch (e) {
      _logError('forceVictoryForTesting', e);
      return false;
    }
  }

  /// Mark the game as completed and set the winner
  Future<bool> completeGame(String partyCode, String winnerId) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return false;
      }

      // Update party status to completed and set the winner
      await _supabase
          .from('parties')
          .update({
            'status': 'completed',
            'winner_id': winnerId,
            // 'completed_at': DateTime.now().toIso8601String(), // Add this if completed_at field exists
          })
          .eq('id', partyId);

      return true;
    } catch (e) {
      _logError('completeGame', e);
      return false;
    }
  }

  /// Get comprehensive game statistics for the victory page
  Future<Map<String, dynamic>> getGameStatistics(String partyCode) async {
    try {
      final partyId = await getPartyIdByCode(partyCode);
      if (partyId == 0) {
        return {};
      }

      // Get party info with winner_id
      final partyInfo = await _supabase
          .from('parties')
          .select('created_at, status, winner_id')
          .eq('id', partyId)
          .maybeSingle();

      // Get all players with their stats
      final playersResponse = await _supabase
          .from('party_players')
          .select('''
            player_id,
            is_alive,
            created_at,
            profiles!party_players_player_id_fkey(display_name)
          ''')
          .eq('party_id', partyId);

      // Get elimination events to count kills
      final eliminationsResponse = await _supabase
          .from('elimination_events')
          .select('actor_id, victim_id, event_confirmed')
          .eq('party_id', partyId)
          .eq('event_confirmed', true);

      // Process player statistics
      List<Map<String, dynamic>> playerStats = [];
      Map<String, int> killCounts = {};
      
      // Count kills for each player
      for (var elimination in eliminationsResponse) {
        final killerId = elimination['actor_id'];
        killCounts[killerId] = (killCounts[killerId] ?? 0) + 1;
      }

      // Build player stats
      for (var player in playersResponse) {
        final playerId = player['player_id'];
        playerStats.add({
          'playerId': playerId,
          'displayName': player['profiles']['display_name'],
          'isAlive': player['is_alive'],
          'kills': killCounts[playerId] ?? 0,
          'joinedAt': player['created_at'],
        });
      }

      // Sort players by kills (descending) and then by alive status
      playerStats.sort((a, b) {
        if (a['kills'] != b['kills']) {
          return b['kills'].compareTo(a['kills']);
        }
        if (a['isAlive'] != b['isAlive']) {
          return a['isAlive'] ? -1 : 1;
        }
        return 0;
      });

      // Calculate game duration (simplified without completed_at)
      String gameDuration = 'N/A';
      if (partyInfo != null && partyInfo['created_at'] != null) {
        final startTime = DateTime.parse(partyInfo['created_at']);
        final currentTime = DateTime.now();
        final duration = currentTime.difference(startTime);
        
        if (duration.inHours > 0) {
          gameDuration = '${duration.inHours}h ${duration.inMinutes % 60}m';
        } else {
          gameDuration = '${duration.inMinutes}m';
        }
      }

      // Get winner kills using the winner_id from the database
      int winnerKills = 0;
      String? winnerId;
      if (partyInfo != null && partyInfo['winner_id'] != null) {
        winnerId = partyInfo['winner_id'];
        winnerKills = killCounts[winnerId] ?? 0;
      } else {
        // Fallback: find the player with most kills who is still alive
        for (var player in playerStats) {
          if (player['isAlive'] && player['kills'] > winnerKills) {
            winnerKills = player['kills'];
            winnerId = player['playerId'];
          }
        }
      }

      return {
        'totalPlayers': playersResponse.length,
        'totalEliminations': eliminationsResponse.length,
        'gameDuration': gameDuration,
        'winnerKills': winnerKills,
        'playerStats': playerStats,
        'partyInfo': partyInfo,
        'winnerId': winnerId,
      };
    } catch (e) {
      _logError('getGameStatistics', e);
      return {};
    }
  }

}
