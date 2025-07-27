import 'package:flutter/cupertino.dart';
import 'package:lurkers/pages/home_page.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Usiamo CupertinoApp come radice
    return const CupertinoApp(
      title: 'Lurkers Party Game',
      // 2. Il tema viene gestito da CupertinoThemeData
      theme: CupertinoThemeData(
        brightness: Brightness.light, // Puoi definire tema chiaro/scuro
        primaryColor: CupertinoColors.systemRed, // Colore principale (per bottoni, link...)
      ),
      home: MyHomePage(title: 'Lurkers, let\'s play!'),
    );
  }
}