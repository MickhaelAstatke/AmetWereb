import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/lyric_page.dart';

class LyricsRepository {
  LyricsRepository({this.assetPath = 'assets/data/lyrics.json'});

  final String assetPath;

  Future<List<LyricPage>> loadPages() async {
    final raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> pagesJson = data['pages'] as List<dynamic>;
    return pagesJson
        .map((dynamic e) => LyricPage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
