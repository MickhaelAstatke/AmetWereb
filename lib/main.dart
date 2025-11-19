import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/lyrics_provider.dart';
import 'screens/editor_page.dart';
import 'screens/home_page.dart';
import 'screens/player_page.dart';
import 'screens/presentation_page.dart';
import 'services/lyrics_repository.dart';
import 'theme/app_theme.dart';

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
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routes: {
          PresentationPage.routeName: (_) => const PresentationPage(),
          HomePage.routeName: (_) => const HomePage(),
          PlayerPage.routeName: (_) => const PlayerPage(),
          EditorPage.routeName: (_) => const EditorPage(),
        },
        initialRoute: PresentationPage.routeName,
      ),
    );
  }
}
