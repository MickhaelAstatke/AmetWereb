import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:characters/characters.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/audio_metadata.dart';
import '../models/glyph_annotation.dart';
import '../models/lyric_line.dart';
import '../models/lyric_page.dart';
import '../models/lyric_section.dart';
import '../providers/auth_provider.dart';
import '../providers/lyrics_provider.dart';
import 'home_page.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  static const routeName = '/editor';

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageIdController = TextEditingController();
  final _pageTitleController = TextEditingController();
  final _dayController = TextEditingController();
  final _iconController = TextEditingController();

  String? _selectedMonth;

  List<LyricSection> _sections = [];
  bool _isExistingPage = false;
  bool _authChecked = false;

  @override
  void dispose() {
    _pageIdController.dispose();
    _pageTitleController.dispose();
    _dayController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null) {
      return;
    }
    final filePath = result.files.single.path;
    if (filePath == null) {
      setState(() {
        _audioValidationError =
            'Unable to access the selected file. Please try another audio.';
      });
      return;
    }
    setState(() {
      _pickedFilePath = filePath;
      _initialStoredAudioPath = null;
      _pickedFileDuration = null;
      _audioUrlController.clear();
      _audioValidationError = null;
    });
    await _loadDurationFromFile(filePath);
  }

  void _clearPickedFile() {
    setState(() {
      _pickedFilePath = null;
      _initialStoredAudioPath = null;
      _pickedFileDuration = null;
      _isLoadingDuration = false;
      _audioValidationError = null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_authChecked) {
      return;
    }
    _authChecked = true;
    final auth = context.read<AuthProvider>();
    if (!auth.canEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacementNamed(HomePage.routeName);
      });
    }
  }

  Future<void> _loadDurationFromFile(String path) async {
    setState(() {
      _isLoadingDuration = true;
    });
    try {
      await _previewPlayer.setSource(DeviceFileSource(path));
      final duration = await _previewPlayer.getDuration();
      if (!mounted) {
        return;
      }
      setState(() {
        _pickedFileDuration = duration;
        if (duration != null) {
          _durationController.text = duration.inSeconds.toString();
        }
        _audioValidationError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _audioValidationError =
            'Failed to analyze the selected audio file. Please ensure it plays correctly.';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingDuration = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} (${duration.inSeconds}s)';
  }

  String? _resolveLocalAudioPath(String value) {
    if (value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'file') {
      return uri.toFilePath();
    }
    try {
      final file = File(value);
      if (file.isAbsolute) {
        return value;
      }
    } catch (_) {
      // ignore invalid paths
    }
    return null;
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    if (normalized.contains('/')) {
      final parts = normalized.split('/');
      if (parts.isNotEmpty) {
        return parts.last;
      }
    }
    final uri = Uri.tryParse(path);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return path;
  }

  String _sanitizeFileName(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  Future<String?> _persistSelectedFile() async {
    final selectedPath = _pickedFilePath;
    if (selectedPath == null) {
      return null;
    }
    try {
      final file = File(selectedPath);
      if (_initialStoredAudioPath != null &&
          _initialStoredAudioPath == selectedPath &&
          await file.exists()) {
        return selectedPath;
      }
      if (!await file.exists()) {
        return null;
      }
      final docsDir = await getApplicationDocumentsDirectory();
      final audioDir =
          Directory('${docsDir.path}${Platform.pathSeparator}audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      final sectionId = _idController.text.trim().isEmpty
          ? 'section'
          : _idController.text.trim();
      final fileName = _sanitizeFileName(
        '${widget.pageId}_$sectionId_${DateTime.now().millisecondsSinceEpoch}_${_fileNameFromPath(selectedPath)}',
      );
      final destinationPath =
          '${audioDir.path}${Platform.pathSeparator}$fileName';
      final copiedFile = await file.copy(destinationPath);
      _initialStoredAudioPath = copiedFile.path;
      _pickedFilePath = copiedFile.path;
      return copiedFile.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.watch<AuthProvider>().canEdit;
    if (!canEdit) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Consumer<LyricsProvider>(
      builder: (context, provider, _) {
        LyricPage? selectedPage;
        if (_isExistingPage) {
          try {
            selectedPage = provider.pages
                .firstWhere((page) => page.id == _pageIdController.text);
          } on StateError {
            selectedPage = null;
          }
        }
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_note,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Manage Library'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Preview presentation',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.present_to_all,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                onPressed: () => Navigator.of(context).pushNamed(
                  PresentationPage.routeName,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page selector header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer.withOpacity(0.5),
                        theme.colorScheme.secondaryContainer.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<LyricPage>(
                          value: selectedPage,
                          decoration: InputDecoration(
                            labelText: 'Select a page',
                            labelStyle: theme.textTheme.labelMedium,
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(
                              Icons.library_music,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          dropdownColor: theme.colorScheme.surface,
                          style: theme.textTheme.titleMedium,
                          items: provider.pages
                              .map(
                                (page) => DropdownMenuItem(
                                  value: page,
                                  child: Text(page.title),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _loadPage(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.tertiary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('New'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onPressed: () => _loadPage(null),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (provider.needsMonthMetadataMigration)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: theme.colorScheme.tertiaryContainer,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Some holidays are missing Ethiopian month data. '
                                'Select each page and assign the correct month '
                                'so the calendar view can group them properly.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        // Page details card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  theme.colorScheme.outlineVariant.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Page Details',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _pageIdController,
                                decoration: InputDecoration(
                                  labelText: 'Page ID',
                                  helperText: 'Used internally for storage',
                                  prefixIcon: const Icon(Icons.tag),
                                  filled: true,
                                  fillColor: _isExistingPage
                                      ? theme.colorScheme.surfaceVariant
                                          .withOpacity(0.3)
                                      : null,
                                ),
                                readOnly: _isExistingPage,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an identifier';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _pageTitleController,
                                decoration: const InputDecoration(
                                  labelText: 'Page title',
                                  prefixIcon: Icon(Icons.title),
                                ),
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedMonth,
                                decoration: const InputDecoration(
                                  labelText: 'Ethiopian month',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                items: LyricPage.ethiopianMonths
                                    .map(
                                      (month) => DropdownMenuItem(
                                        value: month,
                                        child: Text(month),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMonth = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please choose a month';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _dayController,
                                decoration: const InputDecoration(
                                  labelText: 'Day of month',
                                  helperText:
                                      'Optional Ethiopian calendar day (1-30, Pagume up to 6)',
                                  prefixIcon: Icon(Icons.event),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null) {
                                    return null;
                                  }
                                  final trimmed = value.trim();
                                  if (trimmed.isEmpty) {
                                    return null;
                                  }
                                  final parsed = int.tryParse(trimmed);
                                  if (parsed == null) {
                                    return 'Enter a valid number';
                                  }
                                  final maxDay =
                                      _selectedMonth == 'Pagume' ? 6 : 30;
                                  if (parsed < 1 || parsed > maxDay) {
                                    return 'Enter a day between 1 and $maxDay';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _iconController,
                                decoration: const InputDecoration(
                                  labelText: 'Icon identifier',
                                  helperText:
                                      'Optional Material icon name or asset path',
                                  prefixIcon: Icon(Icons.image_outlined),
                                ),
                                textCapitalization: TextCapitalization.none,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Sections header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.1),
                                theme.colorScheme.secondary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.queue_music,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sections',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      final section =
                                          await showDialog<LyricSection>(
                                        context: context,
                                        builder: (context) =>
                                            SectionEditorDialog(
                                          pageId: _pageIdController.text,
                                        ),
                                      );
                                      if (section != null) {
                                        setState(() {
                                          _sections =
                                              _upsertSectionLocally(section);
                                        });
                                        await _commitPage(context);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.library_add,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Add',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_sections.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withOpacity(0.3),
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.music_note,
                                  size: 48,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No sections yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap "Add" to create your first section',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._sections.map(
                            (section) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primaryContainer
                                        .withOpacity(0.3),
                                    theme.colorScheme.secondaryContainer
                                        .withOpacity(0.3),
                                  ],
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    final provider =
                                        context.read<LyricsProvider>();
                                    await provider.playSection(section);
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                theme.colorScheme.primary
                                                    .withOpacity(0.2),
                                                theme.colorScheme.secondary
                                                    .withOpacity(0.2),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.music_note_rounded,
                                            color: theme.colorScheme.primary,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                section.title,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                section.note,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surface
                                                .withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit_outlined,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                                tooltip: 'Edit',
                                                onPressed: () async {
                                                  final updated =
                                                      await showDialog<
                                                          LyricSection>(
                                                    context: context,
                                                    builder: (context) =>
                                                        SectionEditorDialog(
                                                      pageId: _pageIdController
                                                          .text,
                                                      section: section,
                                                    ),
                                                  );
                                                  if (updated != null) {
                                                    setState(() {
                                                      _sections =
                                                          _upsertSectionLocally(
                                                              updated);
                                                    });
                                                    await _commitPage(context);
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color: theme
                                                      .colorScheme.error,
                                                ),
                                                tooltip: 'Remove',
                                                onPressed: () async {
                                                  final confirmed =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title: const Text(
                                                          'Remove section'),
                                                      content: Text(
                                                        'Are you sure you want to remove "${section.title}"?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(false),
                                                          child: const Text(
                                                              'Cancel'),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(true),
                                                          child: const Text(
                                                              'Remove'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirmed == true) {
                                                    setState(() {
                                                      _sections = _sections
                                                          .where((s) =>
                                                              s.id !=
                                                              section.id)
                                                          .toList();
                                                    });
                                                    await _commitPage(context);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SafeArea(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.tertiary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => _commitPage(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _loadPage(LyricPage? page) {
    setState(() {
      if (page == null) {
        _isExistingPage = false;
        _pageIdController
          ..text = ''
          ..selection = const TextSelection.collapsed(offset: 0);
        _pageTitleController.text = '';
        _sections = [];
        _selectedMonth = null;
        _dayController.clear();
        _iconController.clear();
      } else {
        _isExistingPage = true;
        _pageIdController.text = page.id;
        _pageTitleController.text = page.title;
        _sections = List.of(page.sections);
        _selectedMonth = page.hasKnownMonth ? page.month : null;
        _dayController.text = page.day?.toString() ?? '';
        _iconController.text = page.icon ?? '';
      }
    });
  }

  List<LyricSection> _upsertSectionLocally(LyricSection section) {
    final updated = <LyricSection>[];
    var replaced = false;
    for (final existing in _sections) {
      if (existing.id == section.id) {
        updated.add(section);
        replaced = true;
      } else {
        updated.add(existing);
      }
    }
    if (!replaced) {
      updated.add(section);
    }
    return updated;
  }

  Future<void> _commitPage(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final month = _selectedMonth ?? LyricPage.unknownMonth;
    final dayText = _dayController.text.trim();
    final day = dayText.isEmpty ? null : int.parse(dayText);
    final iconText = _iconController.text.trim();
    final page = LyricPage(
      id: _pageIdController.text.trim(),
      title: _pageTitleController.text.trim(),
      month: month,
      day: day,
      icon: iconText.isEmpty ? null : iconText,
      sections: _sections,
    );
    final provider = context.read<LyricsProvider>();
    if (_isExistingPage) {
      await provider.updatePage(page);
    } else {
      await provider.addPage(page);
      setState(() {
        _isExistingPage = true;
      });
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Library updated successfully'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

class SectionEditorDialog extends StatefulWidget {
  const SectionEditorDialog({
    required this.pageId,
    this.section,
    super.key,
  });

  final String pageId;
  final LyricSection? section;

  @override
  State<SectionEditorDialog> createState() => _SectionEditorDialogState();
}

class _SectionEditorDialogState extends State<SectionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lyricsFieldKey = GlobalKey<FormFieldState<void>>();
  late final TextEditingController _idController;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _audioUrlController;
  late final TextEditingController _durationController;
  final List<_LyricLineForm> _lineForms = [];
  late final AudioPlayer _previewPlayer;

  String? _pickedFilePath;
  String? _initialStoredAudioPath;
  Duration? _pickedFileDuration;
  bool _isLoadingDuration = false;
  bool _isSaving = false;
  String? _audioValidationError;

  @override
  void initState() {
    super.initState();
    _previewPlayer = AudioPlayer();
    final initialAudioUrl = widget.section?.audio.url ?? '';
    final localPath = _resolveLocalAudioPath(initialAudioUrl);
    _idController = TextEditingController(text: widget.section?.id ?? '');
    _titleController = TextEditingController(text: widget.section?.title ?? '');
    _noteController = TextEditingController(text: widget.section?.note ?? '');
    _audioUrlController = TextEditingController(
      text: localPath == null ? initialAudioUrl : '',
    );
    _durationController = TextEditingController(
      text: widget.section != null
          ? widget.section!.audio.duration.toString()
          : '60',
    );
    _initializeLyricForms();
    _pickedFilePath = localPath;
    _initialStoredAudioPath = localPath;
    if (localPath != null) {
      _pickedFileDuration = Duration(seconds: widget.section!.audio.duration);
      _loadDurationFromFile(localPath);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _audioUrlController.dispose();
    _durationController.dispose();
    for (final form in _lineForms) {
      form.dispose();
    }
    _previewPlayer.dispose();
    super.dispose();
  }

  void _initializeLyricForms() {
    final lyrics = widget.section?.lyrics ?? const <LyricLine>[];
    if (lyrics.isEmpty) {
      _lineForms.add(_createLineForm());
      return;
    }
    for (final line in lyrics) {
      _lineForms.add(
        _createLineForm(
          text: line.displayText,
          annotations: line.annotations,
        ),
      );
    }
    if (_lineForms.isEmpty) {
      _lineForms.add(_createLineForm());
    }
  }

  _LyricLineForm _createLineForm({
    String text = '',
    List<GlyphAnnotation> annotations = const [],
  }) {
    return _LyricLineForm(
      text: text,
      annotations: annotations,
      onChanged: _handleLyricsChanged,
    );
  }

  void _handleLyricsChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    _lyricsFieldKey.currentState?.validate();
  }

  void _addLine() {
    setState(() {
      _lineForms.add(_createLineForm());
    });
    _lyricsFieldKey.currentState?.validate();
  }

  void _removeLine(int index) {
    if (index < 0 || index >= _lineForms.length) {
      return;
    }
    final removed = _lineForms.removeAt(index);
    removed.dispose();
    if (_lineForms.isEmpty) {
      _lineForms.add(_createLineForm());
    }
    setState(() {});
    _lyricsFieldKey.currentState?.validate();
  }

  Widget _buildLyricLineEditor(
      ThemeData theme, _LyricLineForm form, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Line ${index + 1}',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(width: 8),
              if (form.lineController.text.trim().isEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Empty',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: _lineForms.length == 1
                    ? null
                    : () => _removeLine(index),
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.error,
                tooltip: 'Remove line',
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: form.lineController,
            decoration: const InputDecoration(
              labelText: 'Line text',
              prefixIcon: Icon(Icons.short_text),
            ),
          ),
          if (form.glyphEntries.isNotEmpty) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in form.glyphEntries)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildGlyphEditor(theme, entry),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlyphEditor(ThemeData theme, _GlyphNoteEntry entry) {
    if (entry.isWhitespace) {
      return const SizedBox(width: 16);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          child: TextField(
            controller: entry.noteController,
            decoration: const InputDecoration(
              hintText: 'Note',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: Text(
            entry.glyph,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.section == null
                              ? Icons.add_circle_outline
                              : Icons.edit_outlined,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.section == null
                                ? 'New Section'
                                : 'Edit Section',
                            style:
                                theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'Section ID',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    readOnly: widget.section != null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter an identifier';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Section title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notes for performers',
                      prefixIcon: Icon(Icons.note),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Provide a short note';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Audio source',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.folder_open),
                              label: Text(
                                _pickedFilePath == null
                                    ? 'Browse local audio'
                                    : 'Replace selected audio',
                              ),
                              onPressed: _pickAudioFile,
                            ),
                          ),
                          if (_pickedFilePath != null)
                            IconButton(
                              tooltip: 'Remove selected file',
                              onPressed: _clearPickedFile,
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                      if (_pickedFilePath != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer
                                .withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.audiotrack,
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _fileNameFromPath(_pickedFilePath!),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_isLoadingDuration)
                                Row(
                                  children: const [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Analyzing duration...'),
                                  ],
                                )
                              else if (_pickedFileDuration != null)
                                Text(
                                  'Duration: ${_formatDuration(_pickedFileDuration!)}',
                                  style: theme.textTheme.bodySmall,
                                )
                              else
                                Text(
                                  'Duration: Unknown — please confirm manually.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              Text(
                                'Location: ${_pickedFilePath!}',
                                style: theme.textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'The file will be copied into the app library when saved.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _audioUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Audio asset or URL',
                          helperText: 'Optional when a local file is selected',
                          prefixIcon: Icon(Icons.link),
                        ),
                        onChanged: (_) {
                          if (_audioValidationError != null) {
                            setState(() {
                              _audioValidationError = null;
                            });
                          }
                        },
                        validator: (value) {
                          if (_pickedFilePath == null &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Provide an audio reference or choose a file';
                          }
                          return null;
                        },
                      ),
                      if (_audioValidationError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _audioValidationError!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration in seconds',
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FormField<void>(
                    key: _lyricsFieldKey,
                    validator: (_) {
                      final hasLine = _lineForms.any(
                        (form) => form.lineController.text.trim().isNotEmpty,
                      );
                      if (!hasLine) {
                        return 'Enter at least one lyric line';
                      }
                      return null;
                    },
                    builder: (state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lyrics,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Text(
                                'Lyric lines',
                                style: theme.textTheme.titleMedium,
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _addLine,
                                icon: const Icon(Icons.add),
                                label: const Text('Add line'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              for (var i = 0; i < _lineForms.length; i++)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: _buildLyricLineEditor(
                                    theme,
                                    _lineForms[i],
                                    i,
                                  ),
                                ),
                            ],
                          ),
                          if (state.hasError) ...[
                            const SizedBox(height: 8),
                            Text(
                              state.errorText!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(_isSaving ? 'Saving...' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: _isSaving ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_pickedFilePath == null &&
        _audioUrlController.text.trim().isEmpty) {
      setState(() {
        _audioValidationError =
            'Select a local audio file or provide an asset/URL reference.';
      });
      return;
    }
    setState(() {
      _audioValidationError = null;
      _isSaving = true;
    });

    var audioReference = _audioUrlController.text.trim();
    if (_pickedFilePath != null) {
      final storedPath = await _persistSelectedFile();
      if (storedPath == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _audioValidationError =
              'Unable to store the selected audio. Please try again.';
          _isSaving = false;
        });
        return;
      }
      audioReference = storedPath;
    }

    final duration = int.parse(_durationController.text.trim());
    final lyricLines = <LyricLine>[];
    for (final form in _lineForms) {
      final rawText = form.lineController.text;
      if (rawText.trim().isEmpty) {
        continue;
      }
      final annotations = form.buildAnnotations();
      lyricLines.add(
        LyricLine(
          order: lyricLines.length + 1,
          text: rawText,
          annotations: annotations,
        ),
      );
    }
    if (lyricLines.isEmpty) {
      setState(() {
        _isSaving = false;
      });
      _lyricsFieldKey.currentState?.validate();
      return;
    }
    final section = LyricSection(
      id: _idController.text.trim(),
      title: _titleController.text.trim(),
      note: _noteController.text.trim(),
      audio: AudioMetadata(
        url: audioReference,
        duration: duration,
      ),
      lyrics: lyricLines,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
    Navigator.of(context).pop(section);
  }
}

class _LyricLineForm {
  _LyricLineForm({
    String text = '',
    List<GlyphAnnotation> annotations = const [],
    required VoidCallback onChanged,
  }) : _onChanged = onChanged {
    final normalizedText = annotations.isNotEmpty
        ? annotations.map((annotation) => annotation.glyph).join()
        : text;
    lineController = TextEditingController(text: normalizedText);
    _lineListener = () {
      _syncGlyphEntries(lineController.text);
      _onChanged();
    };
    lineController.addListener(_lineListener);
    if (annotations.isNotEmpty) {
      for (final annotation in annotations) {
        glyphEntries.add(
          _GlyphNoteEntry(
            glyph: annotation.glyph,
            note: annotation.note,
            onChanged: _onChanged,
          ),
        );
      }
    } else {
      _syncGlyphEntries(lineController.text);
    }
  }

  final VoidCallback _onChanged;
  late final TextEditingController lineController;
  late final VoidCallback _lineListener;
  final List<_GlyphNoteEntry> glyphEntries = [];

  void _syncGlyphEntries(String text) {
    final characters = text.characters.toList();
    while (glyphEntries.length > characters.length) {
      glyphEntries.removeLast().dispose();
    }
    for (var i = 0; i < characters.length; i++) {
      final glyph = characters[i];
      if (i < glyphEntries.length) {
        glyphEntries[i].updateGlyph(glyph);
      } else {
        glyphEntries.add(
          _GlyphNoteEntry(
            glyph: glyph,
            onChanged: _onChanged,
          ),
        );
      }
    }
  }

  List<GlyphAnnotation> buildAnnotations() {
    return glyphEntries.map((entry) => entry.toAnnotation()).toList();
  }

  void dispose() {
    lineController.removeListener(_lineListener);
    lineController.dispose();
    for (final entry in glyphEntries) {
      entry.dispose();
    }
  }
}

class _GlyphNoteEntry {
  _GlyphNoteEntry({
    required this.glyph,
    String? note,
    required VoidCallback onChanged,
  })  : _onChanged = onChanged,
        noteController = TextEditingController(text: note ?? '') {
    noteController.addListener(_onChanged);
  }

  String glyph;
  final VoidCallback _onChanged;
  final TextEditingController noteController;

  bool get isWhitespace => glyph.trim().isEmpty;

  void updateGlyph(String value) {
    if (glyph == value) {
      return;
    }
    glyph = value;
    if (noteController.text.isNotEmpty) {
      noteController.text = '';
    }
  }

  GlyphAnnotation toAnnotation() {
    final noteText = noteController.text.trim();
    return GlyphAnnotation(
      glyph: glyph,
      note: noteText.isEmpty ? null : noteText,
    );
  }

  void dispose() {
    noteController.removeListener(_onChanged);
    noteController.dispose();
  }
}
