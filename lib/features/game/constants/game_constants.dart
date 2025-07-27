/// Costanti per il gioco
class GameConstants {
  // Stati del gioco
  static const String statusWaiting = 'waiting';
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  
  // Limiti
  static const int minPlayersToStart = 2;
  static const int maxPlayersPerGame = 10;
  static const int gameCodeMinLength = 5;
  
  // Timeout
  static const Duration gameJoinTimeout = Duration(minutes: 30);
  static const Duration gameActiveTimeout = Duration(hours: 24);
  
  // Nomi tabelle database
  static const String gameSessionsTable = 'game_sessions';
  static const String gamePlayersTable = 'game_players';
}
