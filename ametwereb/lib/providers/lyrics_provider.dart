import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/lyric_page.dart';
import '../models/lyric_section.dart';
import '../services/lyrics_repository.dart';

class LyricsProvider extends ChangeNotifier {
  LyricsProvider({
    required LyricsRepository repository,
    AudioPlayer? audioPlayer,
  })  : _repository = repository,
        _audioPlayer = audioPlayer ?? AudioPlayer() {
    _bindAudioPlayer();
  }

  final LyricsRepository _repository;
  final AudioPlayer _audioPlayer;

  List<LyricPage> _pages = const [];
  LyricPage? _selectedPage;
  LyricSection? _currentSection;
  Duration _currentPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<LyricPage> get pages => _pages;
  LyricPage? get selectedPage => _selectedPage;
  LyricSection? get currentSection => _currentSection;
  AudioPlayer get audioPlayer => _audioPlayer;
  Duration get currentPosition => _currentPosition;
  PlayerState get playerState => _audioPlayer.state;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      try {
        final file = await _storageFile();
        if (await file.exists()) {
          final raw = await file.readAsString();
          final Map<String, dynamic> jsonMap =
              json.decode(raw) as Map<String, dynamic>;
          _pages = (jsonMap['pages'] as List<dynamic>)
              .map((dynamic e) =>
                  LyricPage.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          _pages = await _repository.loadPages();
          await _persist();
        }
      } catch (error, stackTrace) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Failed to read persisted lyrics: $error\n$stackTrace');
        }
        _pages = await _repository.loadPages();
      }
      if (_pages.isNotEmpty) {
        selectPage(_pages.first);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPage(LyricPage page) {
    _selectedPage = page;
    if (_currentSection != null &&
        page.sections.every((section) => section.id != _currentSection!.id)) {
      _currentSection = null;
    }
    notifyListeners();
  }

  Future<void> addPage(LyricPage page) async {
    _pages = [..._pages, page];
    _selectedPage = page;
    await _persist();
    notifyListeners();
  }

  Future<void> updatePage(LyricPage page) async {
    _pages = _pages.map((p) => p.id == page.id ? page : p).toList();
    if (_selectedPage?.id == page.id) {
      _selectedPage = page;
    }
    if (_currentSection != null) {
      LyricSection? updatedSection;
      for (final candidate in page.sections) {
        if (candidate.id == _currentSection!.id) {
          updatedSection = candidate;
          break;
        }
      }
      if (updatedSection != null) {
        _currentSection = updatedSection;
      } else {
        _currentSection = null;
        await _audioPlayer.stop();
      }
    }
    await _persist();
    notifyListeners();
  }

  Future<void> deletePage(String pageId) async {
    LyricPage? removedPage;
    for (final page in _pages) {
      if (page.id == pageId) {
        removedPage = page;
        break;
      }
    }
    if (removedPage == null) {
      return;
    }
    _pages = _pages.where((p) => p.id != pageId).toList();
    if (_selectedPage?.id == pageId) {
      _selectedPage = _pages.isEmpty ? null : _pages.first;
    }
    if (_currentSection != null &&
        removedPage.sections.any((s) => s.id == _currentSection!.id)) {
      _currentSection = null;
      await _audioPlayer.stop();
    }
    await _persist();
    notifyListeners();
  }

  Future<void> upsertSection(String pageId, LyricSection section) async {
    final page = _pages.firstWhere((p) => p.id == pageId);
    final updatedSections = <LyricSection>[];
    var replaced = false;
    for (final existing in page.sections) {
      if (existing.id == section.id) {
        updatedSections.add(section);
        replaced = true;
      } else {
        updatedSections.add(existing);
      }
    }
    if (!replaced) {
      updatedSections.add(section);
    }
    final updatedPage = LyricPage(
      id: page.id,
      title: page.title,
      sections: updatedSections,
    );
    await updatePage(updatedPage);
    _currentSection = section;
    notifyListeners();
  }

  Future<void> removeSection(String pageId, String sectionId) async {
    final page = _pages.firstWhere((p) => p.id == pageId);
    final updatedSections =
        page.sections.where((section) => section.id != sectionId).toList();
    final updatedPage = LyricPage(
      id: page.id,
      title: page.title,
      sections: updatedSections,
    );
    await updatePage(updatedPage);
    if (_currentSection?.id == sectionId) {
      _currentSection = null;
      await _audioPlayer.stop();
    }
    notifyListeners();
  }

  Future<void> playSection(LyricSection section) async {
    _currentSection = section;
    await _audioPlayer.stop();
    final source = section.audio.url.startsWith('http')
        ? UrlSource(section.audio.url)
        : AssetSource(section.audio.url);
    await _audioPlayer.play(source);
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_currentSection != null) {
      if (_audioPlayer.state == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        await playSection(_currentSection!);
      }
    }
  }

  Future<void> seek(Duration position) async {
    final maxDuration = _currentSection == null
        ? null
        : Duration(seconds: _currentSection!.audio.duration);
    var target = position;
    if (target < Duration.zero) {
      target = Duration.zero;
    }
    if (maxDuration != null && target > maxDuration) {
      target = maxDuration;
    }
    await _audioPlayer.seek(target);
    _currentPosition = target;
    notifyListeners();
  }

  void _bindAudioPlayer() {
    _positionSub = _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _currentPosition = Duration.zero;
      }
      notifyListeners();
    });
  }

  Future<File> _storageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/lyrics.json');
  }

  Future<void> _persist() async {
    try {
      final file = await _storageFile();
      final data = {
        'pages': _pages.map((page) => page.toJson()).toList(),
      };
      await file.writeAsString(json.encode(data));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to persist lyrics: $error\n$stackTrace');
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
