import 'package:flutter/material.dart';
import 'package:lurkers/auth/auth_service.dart';
import 'package:lurkers/pages/sign_up_pages.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {

  final authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      await authService.signInWithEmailPassword(email, password);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Hero section with game description
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.groups,
                        size: 48,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome back to Lurkers',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // Email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                            Icons.alternate_email_rounded,
                            color: theme.primaryColor,
                            
                          ),
  
                        ),
                      ),
                    
                    const SizedBox(height: 16),

              // Email
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                            Icons.password,
                            color: theme.primaryColor,
                            
                          ),
  
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                   
              
              FilledButton.icon(
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Sign In'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  login();
                },
              ),

              const SizedBox(height: 24,),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const SignUpPage())
                    );
                },
                child: Center(
                  child: Text(
                    "Don't have an account? Sign Up"
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
  