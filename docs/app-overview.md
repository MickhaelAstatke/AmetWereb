# Flutter Lyric Companion App

This project hosts the Flutter application that powers the lyric browsing,
playback, and editing experience. All Dart code lives under `lib/`, with
feature-specific areas broken down into models, providers, screens, and
widgets. Audio and lyric seed data are located in `assets/`.

## Key paths
- `lib/main.dart` &mdash; application entry point and route wiring.
- `lib/screens/home_page.dart` &mdash; lyric browser with dropdown and section cards.
- `lib/widgets/now_playing_bar.dart` &mdash; compact playback controls.
- `lib/screens/player_page.dart` &mdash; full-screen player UI.
- `lib/screens/editor_page.dart` &mdash; content management flow for pages/sections.
- `assets/data/lyrics.json` &mdash; bundled seed data for lyrics and audio metadata.

## Running locally
```bash
flutter pub get
flutter run -t lib/main.dart
```

If you cloned the repository without the generated Android/iOS tooling files,
you can recreate them safely with:
```bash
flutter create .
```
This will not overwrite the Dart sources or assets in `lib/` and `assets/`.
