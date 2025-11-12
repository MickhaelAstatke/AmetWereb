# Lyric Companion

A cross-platform Flutter experience for browsing, playing, and editing worship lyric content with synchronized audio.

## Project structure

```
app/
├── README.md                 # Directory-level overview and run instructions
├── android/                  # Android launch assets and Gradle config
├── ios/                      # iOS launch assets and storyboard tweaks
├── assets/
│   └── data/lyrics.json      # Seed lyric, section, and audio metadata
├── lib/
│   ├── main.dart             # App entry point and routing
│   ├── models/               # Immutable data models
│   ├── providers/            # Application state & audio coordination
│   ├── screens/              # Home, player, and editor flows
│   └── widgets/              # Reusable UI components
└── pubspec.yaml
```

## Getting started

> **Note:** Flutter SDK is not installed in this execution environment, so run the following steps locally with Flutter ≥3.16.

1. [Install Flutter](https://docs.flutter.dev/get-started/install) and ensure the `flutter` command is on your `PATH`.
2. From the repository root, fetch dependencies:
   ```bash
   cd app
   flutter pub get
   ```
3. (Optional) regenerate native platforms to ensure tooling files match your local toolchain:
   ```bash
   flutter create .
   ```
   The command keeps existing Dart sources, assets, and configuration files while rebuilding any missing Xcode or Gradle wiring.
4. Run the application:
   ```bash
   flutter run
   ```

## Features

- **Home browsing:** filter lyric pages from the seed JSON, preview sections, and trigger playback with highlighted cards.
- **Now playing bar & full-screen player:** powered by [`audioplayers`](https://pub.dev/packages/audioplayers) for play/pause, seeking, and progress display.
- **Content editing:** touch-friendly form flow to add, update, or remove pages, sections, and lyric lines with validation.
- **Offline persistence:** changes are serialized to a sandboxed JSON file using `path_provider` so they survive app restarts.
- **Platform polish:** Material 3 theming, adaptive launcher icons, gradient splash screens, and safe-area aware layouts on both Android and iOS.

## Assets & data

Seed content lives in `assets/data/lyrics.json` and is registered via `pubspec.yaml`. The editor writes modifications to the app documents directory (`lyrics.json`), falling back to bundled data on first launch.

## Testing

With Flutter installed, run the standard test suite:

```bash
flutter test
```

Add additional widget or integration tests inside `app/test/` as new features land.
