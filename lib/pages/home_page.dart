// home_page.dart

import 'package:flutter/material.dart';
import 'package:lurkers/pages/create_party_page.dart';
import 'package:lurkers/pages/join_party_page.dart';

// La schermata JoinParty andrà creata in seguito
// class JoinPartyScreen extends StatelessWidget { ... } 

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  final String title = "Lurkers";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determina la larghezza massima basata sulle dimensioni dello schermo
          double maxWidth;
          if (constraints.maxWidth < 600) {
            maxWidth = double.infinity; // Mobile: larghezza piena
          } else if (constraints.maxWidth < 1200) {
            maxWidth = 700; // Tablet
          } else {
            maxWidth = 800; // Desktop
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                        'Welcome to Lurkers',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A social deduction game where everyone has a secret mission. Eliminate your target without being seen!',
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
              
              FilledButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create New Game'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CreatePartyScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),
              
              OutlinedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Join Existing Game'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const JoinPartyScreen()),
                  );
                },
              ),
            ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}