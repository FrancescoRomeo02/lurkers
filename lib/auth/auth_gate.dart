/*
  AUTH GATE listen for auth state changes for page access. 
*/

import 'package:flutter/material.dart';
import 'package:lurkers/pages/home_page.dart';
import 'package:lurkers/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange, 
      builder: (BuildContext context, AsyncSnapshot<AuthState> snapshot) { 
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // User is signed in, show home page or main app
          return const HomePage();
        } else {
          // User is not signed in, show sign-in page
          return const SignInPage();
        }
       },
    );
  }
}
