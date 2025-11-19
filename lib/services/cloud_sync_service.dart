import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lyric_page.dart';

class CloudSyncService {
  CloudSyncService({http.Client? client})
      : _client = client ?? http.Client(),
        _baseUrl =
            const String.fromEnvironment('LYRICS_CLOUD_BASE', defaultValue: '');

  final http.Client _client;
  final String _baseUrl;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<List<LyricPage>?> downloadPages() async {
    if (!isConfigured) {
      return null;
    }
    final uri = Uri.parse('$_baseUrl/pages');
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final payload = json.decode(response.body);
    if (payload is Map<String, dynamic> && payload['pages'] is List) {
      return (payload['pages'] as List<dynamic>)
          .map((dynamic e) => LyricPage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (payload is List) {
      return payload
          .map((dynamic e) => LyricPage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  Future<void> uploadPages(List<LyricPage> pages) async {
    if (!isConfigured) {
      return;
    }
    final uri = Uri.parse('$_baseUrl/pages');
    final body = json.encode({
      'pages': pages.map((page) => page.toJson()).toList(),
    });
    await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: body,
    );
  }
}
