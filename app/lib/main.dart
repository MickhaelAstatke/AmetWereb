import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/lyrics_provider.dart';
import 'screens/editor_page.dart';
import 'screens/home_page.dart';
import 'screens/player_page.dart';
import 'services/lyrics_repository.dart';

void main() {
  runApp(const LyricsApp());
}

class LyricsApp extends StatelessWidget {
  const LyricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LyricsProvider(repository: LyricsRepository())..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Lyric Companion',
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        routes: {
          HomePage.routeName: (_) => const HomePage(),
          PlayerPage.routeName: (_) => const PlayerPage(),
          EditorPage.routeName: (_) => const EditorPage(),
        },
        initialRoute: HomePage.routeName,
      ),
    );
  }
}
