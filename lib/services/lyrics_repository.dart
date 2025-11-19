import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/audio_metadata.dart';
import '../models/lyric_page.dart';
import 'lyrics_remote_api.dart';

class LyricsRepository {
  LyricsRepository({
    this.assetPath = 'assets/data/lyrics.json',
    LyricsRemoteApi? remoteApi,
  }) : _remoteApi = remoteApi ?? LyricsRemoteApi();

  final String assetPath;
  final LyricsRemoteApi _remoteApi;

  Future<List<LyricPage>> loadPages() async {
    try {
      final remotePages = await _remoteApi.fetchPages();
      if (remotePages.isNotEmpty) {
        return remotePages;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to load remote lyrics: $error\n$stackTrace');
      }
    }
    return _loadFromBundle();
  }

  Future<List<LyricPage>> loadSeedPages() => _loadFromBundle();

  Future<void> savePages(List<LyricPage> pages) {
    return _remoteApi.replacePages(pages);
  }

  Future<AudioMetadata> uploadAudio(
    File file, {
    required String pageId,
    required String sectionId,
  }) {
    return _remoteApi.uploadAudio(
      file,
      pageId: pageId,
      sectionId: sectionId,
    );
  }

  Map<String, List<LyricPage>> groupPagesByMonth(Iterable<LyricPage> pages) {
    final grouped = <String, List<LyricPage>>{};
    for (final page in pages) {
      grouped.putIfAbsent(page.month, () => <LyricPage>[]).add(page);
    }
    return grouped;
  }

  Future<List<LyricPage>> _loadFromBundle() async {
    final raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> pagesJson = data['pages'] as List<dynamic>;
    return pagesJson
        .map((dynamic e) => LyricPage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
