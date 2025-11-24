import 'dart:convert';
import 'dart:io';

import 'package:app/models/lyric_page.dart';
import 'package:app/services/lyrics_remote_api.dart';

Future<void> main(List<String> arguments) async {
  final options = _SeedOptions.parse(arguments);
  final file = File(options.seedPath);
  if (!await file.exists()) {
    stderr.writeln('Seed file not found at ${file.path}');
    exitCode = 2;
    return;
  }
  final raw = await file.readAsString();
  final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
  final pagesJson = data['pages'] as List<dynamic>? ?? const [];
  final pages = pagesJson
      .map((dynamic e) => LyricPage.fromJson(e as Map<String, dynamic>))
      .toList();
  if (pages.isEmpty) {
    stdout.writeln('No pages found in ${file.path}; aborting.');
    return;
  }
  final api = LyricsRemoteApi(
    baseUrl: options.baseUrl,
    apiKey: options.apiKey,
  );
  stdout.writeln(
    'Seeding ${pages.length} pages to ${options.baseUrl}${options.pagesPath}...',
  );
  try {
    await api.replacePages(pages);
    stdout.writeln('Seed completed successfully.');
  } on LyricsRemoteException catch (error) {
    stderr.writeln('Failed to seed remote lyrics: ${error.message}');
    exitCode = 1;
  } finally {
    api.dispose();
  }
}

class _SeedOptions {
  _SeedOptions({
    required this.baseUrl,
    required this.seedPath,
    required this.apiKey,
    required this.pagesPath,
  });

  factory _SeedOptions.parse(List<String> args) {
    String? baseUrl;
    String? apiKey;
    String? seedPath;
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--base-url' && i + 1 < args.length) {
        baseUrl = args[++i];
      } else if (arg == '--api-key' && i + 1 < args.length) {
        apiKey = args[++i];
      } else if (arg == '--seed' && i + 1 < args.length) {
        seedPath = args[++i];
      }
    }
    baseUrl ??=
        const String.fromEnvironment('LYRICS_API_URL', defaultValue: 'http://localhost:8787');
    apiKey ??= const String.fromEnvironment('LYRICS_API_KEY', defaultValue: '');
    seedPath ??= 'assets/data/lyrics.json';
    return _SeedOptions(
      baseUrl: baseUrl,
      seedPath: seedPath,
      apiKey: apiKey?.isEmpty == true ? null : apiKey,
      pagesPath: '/pages',
    );
  }

  final String baseUrl;
  final String seedPath;
  final String? apiKey;
  final String pagesPath;
}
