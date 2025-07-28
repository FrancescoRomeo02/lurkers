import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in
  Future<AuthResponse> signInWithEmailPassword(
    String email, String password ) async {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password
      );
    }

  // Sign up
  Future<AuthResponse> signUpWithEmailPassword(
    String email, String password, String nickname) async {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': nickname},
      );
    }
  
  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }


  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user nickname
 String? getCurrentUserNick() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.userMetadata?['display_name'];
  }


  // Update user profile
  Future<UserResponse> updateProfile({String? nickname}) async {
    final authResponse = await _supabase.auth.updateUser(
      UserAttributes(
        data: nickname != null ? {'display_name': nickname} : null,
      ),
    );

    // Aggiorna anche la tabella profiles per sincronizzare i dati
    if (authResponse.user != null && nickname != null) {
      try {
        await _supabase
            .from('profiles')
            .update({'display_name': nickname})
            .eq('id', authResponse.user!.id);
      } catch (e) {
        // Log l'errore ma non bloccare l'operazione di aggiornamento auth
        // In produzione, potresti voler usare un logger più sofisticato
      }
    }

    return authResponse;
  }
}
