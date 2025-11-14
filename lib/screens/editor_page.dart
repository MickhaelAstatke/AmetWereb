import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/audio_metadata.dart';
import '../models/lyric_line.dart';
import '../models/lyric_page.dart';
import '../models/lyric_section.dart';
import '../providers/lyrics_provider.dart';

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
                                        children: const [
                                          Icon(
                                            Icons.library_add,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Add',
                                            style: TextStyle(
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
  late final TextEditingController _idController;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _audioUrlController;
  late final TextEditingController _durationController;
  late final TextEditingController _lyricsController;
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
    _lyricsController = TextEditingController(
      text: widget.section == null
          ? ''
          : widget.section!.lyrics
              .map((line) => line.text)
              .join('\n'),
    );
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
    _lyricsController.dispose();
    _previewPlayer.dispose();
    super.dispose();
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
                  TextFormField(
                    controller: _lyricsController,
                    decoration: const InputDecoration(
                      labelText: 'Lyric lines',
                      helperText: 'Enter one line per row',
                      prefixIcon: Icon(Icons.lyrics),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                    validator: (value) {
                      if (value == null ||
                          value.split('\n').where((line) => line.trim().isNotEmpty).isEmpty) {
                        return 'Enter at least one lyric line';
                      }
                      return null;
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
    final lines = _lyricsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final lyricLines = <LyricLine>[];
    for (var i = 0; i < lines.length; i++) {
      lyricLines.add(LyricLine(order: i + 1, text: lines[i]));
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
