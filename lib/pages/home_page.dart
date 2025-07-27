// home_page.dart

import 'package:flutter/cupertino.dart';
import 'package:lurkers/pages/create_party_page.dart';


// Schermata di Esempio 2
class JoinPartyScreen extends StatelessWidget {
  const JoinPartyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Join Party')),
      child: Text("join party"),    
      );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    // 1. Usiamo CupertinoPageScaffold invece di Scaffold
    return CupertinoPageScaffold(
      // 2. Usiamo CupertinoNavigationBar invece di AppBar
      navigationBar: CupertinoNavigationBar(
        middle: Text(title), // 'middle' è l'equivalente di 'title'
      ),
      // Il corpo della pagina
      child: SafeArea( // SafeArea è importante su iOS per evitare notch e aree di sistema
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Occupa tutta la larghezza
              children: <Widget>[
                // 3. Azione Principale: CupertinoButton.filled
                CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (context) => const CreatePartyScreen()),
                    );
                  },
                  child: const Text('Create party!', style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 16),

                // 4. Azione Secondaria: CupertinoButton standard
                CupertinoButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (context) => const JoinPartyScreen()),
                    );
                  },
                  child: const Text('Join party!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}