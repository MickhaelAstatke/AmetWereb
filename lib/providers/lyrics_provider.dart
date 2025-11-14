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
  String? _selectedMonth;
  LyricSection? _currentSection;
  Duration _currentPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _needsMonthMetadataMigration = false;
  bool get needsMonthMetadataMigration => _needsMonthMetadataMigration;

  List<LyricPage> get pages => _pages;
  LyricPage? get selectedPage => _selectedPage;
  String? get selectedMonth => _selectedMonth;
  LyricSection? get currentSection => _currentSection;
  AudioPlayer get audioPlayer => _audioPlayer;
  Duration get currentPosition => _currentPosition;
  PlayerState get playerState => _audioPlayer.state;

  List<String> get sortedMonths {
    final monthSet = <String>{};
    for (final page in _pages) {
      if (page.hasKnownMonth) {
        monthSet.add(page.month);
      }
    }
    final ordered = <String>[];
    for (final month in LyricPage.ethiopianMonths) {
      if (monthSet.remove(month)) {
        ordered.add(month);
      }
    }
    final remaining = monthSet.toList()..sort();
    ordered.addAll(remaining);
    if (_pages.any((page) => !page.hasKnownMonth)) {
      ordered.add(LyricPage.unknownMonth);
    }
    return ordered;
  }

  Map<String, List<LyricPage>> get pagesByMonth {
    final grouped = <String, List<LyricPage>>{};
    for (final month in sortedMonths) {
      grouped[month] = pagesForMonth(month);
    }
    return grouped;
  }

  List<LyricPage> pagesForMonth(String month) {
    final filtered = month == LyricPage.unknownMonth
        ? _pages.where((page) => !page.hasKnownMonth).toList()
        : _pages.where((page) => page.month == month).toList();
    filtered.sort(_comparePagesByCalendarPosition);
    return filtered;
  }

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
          await _performMonthMigrationIfNeeded();
        } else {
          _pages = await _repository.loadPages();
          _refreshMonthMetadataFlag();
          await _persist();
        }
      } catch (error, stackTrace) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Failed to read persisted lyrics: $error\n$stackTrace');
        }
        _pages = await _repository.loadPages();
        _refreshMonthMetadataFlag();
      }
      if (_pages.isNotEmpty) {
        selectPage(_pages.first);
      } else {
        _selectedMonth = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPage(LyricPage page) {
    _selectedPage = page;
    final resolvedMonth =
        page.hasKnownMonth ? page.month : LyricPage.unknownMonth;
    if (_selectedMonth != resolvedMonth) {
      _selectedMonth = resolvedMonth;
    }
    if (_currentSection != null &&
        page.sections.every((section) => section.id != _currentSection!.id)) {
      _currentSection = null;
    }
    notifyListeners();
  }

  void selectMonth(String month) {
    if (_selectedMonth == month && _selectedPage != null) {
      return;
    }
    _selectedMonth = month;
    final monthPages = pagesForMonth(month);
    if (monthPages.isEmpty) {
      _selectedPage = null;
      if (_currentSection != null) {
        _currentSection = null;
        unawaited(_audioPlayer.stop());
      }
      notifyListeners();
      return;
    }
    selectPage(monthPages.first);
  }

  Future<void> addPage(LyricPage page) async {
    _pages = [..._pages, page];
    _refreshMonthMetadataFlag();
    await _persist();
    selectPage(page);
  }

  Future<void> updatePage(LyricPage page) async {
    _pages = _pages.map((p) => p.id == page.id ? page : p).toList();
    final isSelected = _selectedPage?.id == page.id;
    if (isSelected) {
      _selectedPage = page;
      _selectedMonth =
          page.hasKnownMonth ? page.month : LyricPage.unknownMonth;
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
    _refreshMonthMetadataFlag();
    await _persist();
    if (isSelected) {
      selectPage(page);
    } else {
      notifyListeners();
    }
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
    var shouldStopAudio = false;
    final removedSelected = _selectedPage?.id == pageId;
    if (_currentSection != null &&
        removedPage.sections.any((s) => s.id == _currentSection!.id)) {
      _currentSection = null;
      shouldStopAudio = true;
    }
    if (removedSelected) {
      _selectedPage = null;
    }
    _refreshMonthMetadataFlag();
    await _persist();
    if (shouldStopAudio) {
      await _audioPlayer.stop();
    }
    if (_pages.isEmpty) {
      _selectedPage = null;
      _selectedMonth = null;
      notifyListeners();
      return;
    }
    if (removedSelected) {
      final preferredMonth = _selectedMonth ??
          (removedPage.hasKnownMonth
              ? removedPage.month
              : LyricPage.unknownMonth);
      final monthPages = pagesForMonth(preferredMonth);
      if (monthPages.isNotEmpty) {
        selectMonth(preferredMonth);
        return;
      }
      final fallbackMonths = sortedMonths;
      if (fallbackMonths.isNotEmpty) {
        selectMonth(fallbackMonths.first);
        return;
      }
      _selectedPage = null;
      _selectedMonth = null;
    }
    notifyListeners();
  }

  @visibleForTesting
  void replacePagesForTest(List<LyricPage> pages) {
    _pages = List<LyricPage>.from(pages);
    _refreshMonthMetadataFlag();
    if (_pages.isEmpty) {
      _selectedPage = null;
      _selectedMonth = null;
      _currentSection = null;
      notifyListeners();
      return;
    }
    _currentSection = null;
    selectPage(_pages.first);
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
    final updatedPage = page.copyWith(sections: updatedSections);
    await updatePage(updatedPage);
    _currentSection = section;
    notifyListeners();
  }

  Future<void> removeSection(String pageId, String sectionId) async {
    final page = _pages.firstWhere((p) => p.id == pageId);
    final updatedSections =
        page.sections.where((section) => section.id != sectionId).toList();
    final updatedPage = page.copyWith(sections: updatedSections);
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

  int _comparePagesByCalendarPosition(LyricPage a, LyricPage b) {
    if (!a.hasKnownMonth || !b.hasKnownMonth) {
      return a.title.compareTo(b.title);
    }
    final dayA = a.day;
    final dayB = b.day;
    if (dayA != null && dayB != null && dayA != dayB) {
      return dayA.compareTo(dayB);
    }
    if (dayA == null && dayB != null) {
      return 1;
    }
    if (dayA != null && dayB == null) {
      return -1;
    }
    return a.title.compareTo(b.title);
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

  Future<void> _performMonthMigrationIfNeeded() async {
    final requiresMigration =
        _pages.any((page) => !page.hasKnownMonth);
    if (!requiresMigration) {
      _refreshMonthMetadataFlag();
      return;
    }
    final seedPages = await _repository.loadPages();
    final seedById = <String, LyricPage>{
      for (final page in seedPages) page.id: page,
    };
    final migrated = <LyricPage>[];
    var updated = false;
    for (final page in _pages) {
      if (page.hasKnownMonth) {
        migrated.add(page);
        continue;
      }
      final seed = seedById[page.id];
      if (seed != null && seed.hasKnownMonth) {
        migrated.add(page.copyWith(
          month: seed.month,
          day: seed.day,
          icon: seed.icon,
        ));
        updated = true;
      } else {
        migrated.add(page);
      }
    }
    _pages = migrated;
    _refreshMonthMetadataFlag();
    if (updated) {
      await _persist();
    }
  }

  void _refreshMonthMetadataFlag() {
    _needsMonthMetadataMigration =
        _pages.any((page) => !page.hasKnownMonth);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
