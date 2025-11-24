import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app/models/audio_metadata.dart';
import 'package:app/models/lyric_line.dart';
import 'package:app/models/lyric_page.dart';
import 'package:app/models/lyric_section.dart';
import 'package:app/providers/lyrics_provider.dart';
import 'package:app/screens/home_page.dart';
import 'package:app/services/lyrics_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LyricSection buildSection(String id, String title) {
    return LyricSection(
      id: id,
      title: title,
      note: 'Notes for $title',
      audio: const AudioMetadata(
        url: 'https://example.com/audio.mp3',
        duration: 120,
      ),
      lyrics: const [
        LyricLine(order: 1, text: 'Line 1'),
        LyricLine(order: 2, text: 'Line 2'),
      ],
    );
  }

  LyricPage buildPage({
    required String id,
    required String title,
    required String month,
  }) {
    return LyricPage(
      id: id,
      title: title,
      month: month,
      sections: [
        buildSection('${id}_section', '$title Section'),
      ],
    );
  }

  group('HomePage month selection', () {
    testWidgets('updates provider state and page content when choosing a month',
        (tester) async {
      final provider = LyricsProvider(
        repository: LyricsRepository(),
        audioPlayer: AudioPlayer(),
      );
      addTearDown(() async {
        await provider.audioPlayer.dispose();
        provider.dispose();
      });

      provider.replacePagesForTest([
        buildPage(
          id: 'meskerem-holiday',
          title: 'Meskerem Holiday',
          month: 'Meskerem',
        ),
        buildPage(
          id: 'tikimt-holiday',
          title: 'Tikimt Holiday',
          month: 'Tikimt',
        ),
      ]);

      await tester.pumpWidget(
        ChangeNotifierProvider<LyricsProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.selectedMonth, 'Meskerem');
      expect(find.text('Meskerem Holiday Section'), findsOneWidget);

      await tester.tap(find.text('Tikimt').first);
      await tester.pumpAndSettle();

      expect(provider.selectedMonth, 'Tikimt');
      expect(provider.selectedPage?.title, 'Tikimt Holiday');
      expect(find.text('Tikimt Holiday Section'), findsOneWidget);
    });

    testWidgets('swiping between pages updates the active selection',
        (tester) async {
      final provider = LyricsProvider(
        repository: LyricsRepository(),
        audioPlayer: AudioPlayer(),
      );
      addTearDown(() async {
        await provider.audioPlayer.dispose();
        provider.dispose();
      });

      provider.replacePagesForTest([
        buildPage(
          id: 'meskerem-first',
          title: 'Meskerem First',
          month: 'Meskerem',
        ),
        buildPage(
          id: 'meskerem-second',
          title: 'Meskerem Second',
          month: 'Meskerem',
        ),
      ]);

      await tester.pumpWidget(
        ChangeNotifierProvider<LyricsProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.selectedPage?.id, 'meskerem-first');
      expect(find.text('Meskerem First Section'), findsOneWidget);
      expect(
        tester.widget<AnimatedContainer>(
          find.byKey(const ValueKey('month_indicator_0')),
        ).width,
        24,
      );

      await tester.fling(
        find.byType(PageView),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(provider.selectedPage?.id, 'meskerem-second');
      expect(find.text('Meskerem Second Section'), findsOneWidget);
      expect(
        tester.widget<AnimatedContainer>(
          find.byKey(const ValueKey('month_indicator_1')),
        ).width,
        24,
      );
    });

    testWidgets('page chips allow selecting another page directly',
        (tester) async {
      final provider = LyricsProvider(
        repository: LyricsRepository(),
        audioPlayer: AudioPlayer(),
      );
      addTearDown(() async {
        await provider.audioPlayer.dispose();
        provider.dispose();
      });

      provider.replacePagesForTest([
        buildPage(
          id: 'meskerem-first',
          title: 'Meskerem First',
          month: 'Meskerem',
        ),
        buildPage(
          id: 'meskerem-second',
          title: 'Meskerem Second',
          month: 'Meskerem',
        ),
      ]);

      await tester.pumpWidget(
        ChangeNotifierProvider<LyricsProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('page_chip_meskerem-second')));
      await tester.pumpAndSettle();

      expect(provider.selectedPage?.id, 'meskerem-second');
      expect(find.text('Meskerem Second Section'), findsOneWidget);
    });
  });
}
