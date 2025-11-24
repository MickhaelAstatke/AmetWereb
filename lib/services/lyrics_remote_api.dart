import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/audio_metadata.dart';
import '../models/lyric_page.dart';

class LyricsRemoteException implements Exception {
  LyricsRemoteException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return 'LyricsRemoteException: $message';
    }
    return 'LyricsRemoteException($statusCode): $message';
  }
}

class LyricsRemoteApi {
  LyricsRemoteApi({
    http.Client? httpClient,
    String? baseUrl,
    this.apiKey,
    this.pagesPath = '/pages',
    this.uploadPath = '/audio',
  })  : httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ??
            const String.fromEnvironment(
              'LYRICS_API_URL',
              defaultValue: 'http://localhost:8787',
            );

  final http.Client httpClient;
  final String baseUrl;
  final String? apiKey;
  final String pagesPath;
  final String uploadPath;

  Uri _buildUri(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Map<String, String> _headers({bool jsonContent = false}) {
    return <String, String>{
      if (jsonContent) HttpHeaders.contentTypeHeader: 'application/json',
      if (apiKey != null && apiKey!.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $apiKey',
    };
  }

  Future<List<LyricPage>> fetchPages() async {
    final response = await httpClient.get(
      _buildUri(pagesPath),
      headers: _headers(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final payload = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> pagesJson =
          payload['pages'] as List<dynamic>? ?? const [];
      return pagesJson
          .map((dynamic e) =>
              LyricPage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw LyricsRemoteException(
      'Failed to fetch lyrics (status ${response.statusCode}).',
      response.statusCode,
    );
  }

  Future<void> replacePages(List<LyricPage> pages) async {
    final response = await httpClient.put(
      _buildUri(pagesPath),
      headers: _headers(jsonContent: true),
      body: json.encode({
        'pages': pages.map((page) => page.toJson()).toList(),
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw LyricsRemoteException(
      'Failed to save lyrics (status ${response.statusCode}).',
      response.statusCode,
    );
  }

  Future<AudioMetadata> uploadAudio(
    File file, {
    required String pageId,
    required String sectionId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _buildUri(uploadPath),
    );
    request.headers.addAll(_headers());
    request.fields['pageId'] = pageId;
    request.fields['sectionId'] = sectionId;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final payload = json.decode(response.body) as Map<String, dynamic>;
      return AudioMetadata(
        url: payload['url'] as String,
        duration: (payload['duration'] as num).round(),
        artist: payload['artist'] as String?,
        album: payload['album'] as String?,
      );
    }
    throw LyricsRemoteException(
      'Failed to upload audio (status ${response.statusCode}).',
      response.statusCode,
    );
  }

  void dispose() {
    httpClient.close();
  }
}
