import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/glyph_annotation.dart';
import '../models/audio_metadata.dart';
import '../models/lyric_line.dart';
import '../models/lyric_page.dart';
import '../models/lyric_section.dart';
import '../providers/lyrics_provider.dart';
import '../services/app_access.dart';
import '../widgets/lyric_glyph_line.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<LyricsProvider>(
      builder: (context, provider, _) {
        if (!AppAccess.canEdit) {
          return const _EditorLockedView();
        }
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

class _EditorLockedView extends StatelessWidget {
  const _EditorLockedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Library'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Editing restricted',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This build is running in viewer mode. Relaunch the app with '
                "APP_ROLE=editor to access the management tools.",
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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
  late final List<_EditableLyricLine> _lineEntries;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.section?.id ?? '');
    _titleController = TextEditingController(text: widget.section?.title ?? '');
    _noteController = TextEditingController(text: widget.section?.note ?? '');
    _audioUrlController =
        TextEditingController(text: widget.section?.audio.url ?? '');
    _durationController = TextEditingController(
      text: widget.section != null
          ? widget.section!.audio.duration.toString()
          : '60',
    );
    final lyricLines = widget.section?.lyrics ?? const [];
    if (lyricLines.isEmpty) {
      _lineEntries = [_EditableLyricLine(order: 1)];
    } else {
      _lineEntries = [
        for (final line in lyricLines)
          _EditableLyricLine.fromLyric(line),
      ];
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _audioUrlController.dispose();
    _durationController.dispose();
    for (final line in _lineEntries) {
      line.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    setState(() {
      _lineEntries.add(
        _EditableLyricLine(order: _lineEntries.length + 1),
      );
    });
  }

  void _removeLine(int index) {
    if (_lineEntries.length == 1) {
      return;
    }
    setState(() {
      final removed = _lineEntries.removeAt(index);
      removed.dispose();
      _reindexLines();
    });
  }

  void _reindexLines() {
    for (var i = 0; i < _lineEntries.length; i++) {
      _lineEntries[i].order = i + 1;
    }
  }

  Future<void> _editGlyphs(_EditableLyricLine line) async {
    if (line.annotations.isEmpty) {
      return;
    }
    final updated = await showModalBottomSheet<List<GlyphAnnotation>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GlyphAnnotationSheet(line: line),
    );
    if (updated != null) {
      setState(() {
        line.replaceAnnotations(updated);
      });
    }
  }

  Widget _buildLyricLineCard(
    BuildContext context,
    _EditableLyricLine line,
    int index,
  ) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: line.controller,
      builder: (context, value, _) {
        final hasContent = value.text.trim().isNotEmpty;
        final noteCount = line.annotations
            .where((glyph) => (glyph.note?.trim().isNotEmpty ?? false))
            .length;
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: line.controller,
                  decoration: InputDecoration(
                    labelText: 'Line ${index + 1}',
                    prefixIcon: const Icon(Icons.lyrics),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter lyrics or remove this line';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: hasContent ? () => _editGlyphs(line) : null,
                      icon: const Icon(Icons.notes),
                      label: const Text('Annotate letters'),
                    ),
                    if (noteCount > 0) ...[
                      const SizedBox(width: 12),
                      Chip(
                        label: Text('$noteCount note${noteCount == 1 ? '' : 's'}'),
                        backgroundColor:
                            theme.colorScheme.secondaryContainer.withOpacity(0.4),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      tooltip: 'Remove line',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _lineEntries.length == 1
                          ? null
                          : () => _removeLine(index),
                    ),
                  ],
                ),
                if (noteCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Preview',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  LyricGlyphLine(
                    line: LyricLine(
                      order: line.order,
                      text: line.controller.text,
                      annotations: List<GlyphAnnotation>.from(line.annotations),
                    ),
                    glyphStyle: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    noteStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
                  TextFormField(
                    controller: _audioUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Audio asset or URL',
                      helperText: 'Supports bundled assets or remote links',
                      prefixIcon: Icon(Icons.audiotrack),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Provide an audio reference';
                      }
                      return null;
                    },
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lyric lines',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final entry = _lineEntries[index];
                      return _buildLyricLineCard(context, entry, index);
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _lineEntries.length,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add line'),
                      onPressed: _addLine,
                    ),
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
                          icon: const Icon(Icons.check),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: _submit,
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final duration = int.parse(_durationController.text.trim());
    final lyricLines = <LyricLine>[];
    for (final entry in _lineEntries) {
      final text = entry.controller.text.trim();
      if (text.isEmpty) {
        continue;
      }
      lyricLines.add(
        LyricLine(
          order: lyricLines.length + 1,
          text: text,
          annotations: [
            for (final glyph in entry.annotations)
              GlyphAnnotation(base: glyph.base, note: glyph.note),
          ],
        ),
      );
    }
    if (lyricLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one lyric line before saving.')),
      );
      return;
    }
    final section = LyricSection(
      id: _idController.text.trim(),
      title: _titleController.text.trim(),
      note: _noteController.text.trim(),
      audio: AudioMetadata(
        url: _audioUrlController.text.trim(),
        duration: duration,
      ),
      lyrics: lyricLines,
    );
    Navigator.of(context).pop(section);
  }
}

class _GlyphAnnotationSheet extends StatefulWidget {
  const _GlyphAnnotationSheet({required this.line});

  final _EditableLyricLine line;

  @override
  State<_GlyphAnnotationSheet> createState() => _GlyphAnnotationSheetState();
}

class _GlyphAnnotationSheetState extends State<_GlyphAnnotationSheet> {
  late final List<GlyphAnnotation> _glyphs;
  late final List<TextEditingController> _noteControllers;

  @override
  void initState() {
    super.initState();
    _glyphs = [
      for (final glyph in widget.line.annotations)
        GlyphAnnotation(base: glyph.base, note: glyph.note),
    ];
    _noteControllers = [
      for (final glyph in _glyphs)
        TextEditingController(text: glyph.note ?? ''),
    ];
  }

  @override
  void dispose() {
    for (final controller in _noteControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final updated = <GlyphAnnotation>[];
    for (var i = 0; i < _glyphs.length; i++) {
      final noteText = _noteControllers[i].text.trim();
      updated.add(
        _glyphs[i].copyWith(note: noteText.isEmpty ? null : noteText),
      );
    }
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Annotate letters',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add optional notes that will appear above individual glyphs.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _glyphs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final glyph = _glyphs[index];
                    final label = glyph.base.trim().isEmpty ? '␣' : glyph.base;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.primaryContainer.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            label,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _noteControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Note for "$label"',
                              hintText: 'Optional guidance',
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save notes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableLyricLine {
  _EditableLyricLine({
    required this.order,
    String text = '',
    List<GlyphAnnotation>? annotations,
  })  : controller = TextEditingController(text: text),
        _annotations = List<GlyphAnnotation>.from(annotations ?? const []) {
    _listener = _onTextChanged;
    controller.addListener(_listener);
    _syncAnnotationsWithText();
  }

  factory _EditableLyricLine.fromLyric(LyricLine line) {
    return _EditableLyricLine(
      order: line.order,
      text: line.text,
      annotations: line.annotations.isNotEmpty ? line.annotations : line.glyphs,
    );
  }

  final TextEditingController controller;
  int order;
  late final VoidCallback _listener;
  List<GlyphAnnotation> _annotations;

  List<GlyphAnnotation> get annotations => _annotations;

  void replaceAnnotations(List<GlyphAnnotation> next) {
    _annotations = List<GlyphAnnotation>.from(next);
  }

  void _onTextChanged() => _syncAnnotationsWithText();

  void _syncAnnotationsWithText() {
    final charactersList = controller.text.characters.toList();
    final existing = _annotations;
    final updated = <GlyphAnnotation>[];
    for (var i = 0; i < charactersList.length; i++) {
      final note = i < existing.length ? existing[i].note : null;
      updated.add(GlyphAnnotation(base: charactersList[i], note: note));
    }
    _annotations = updated;
  }

  void dispose() {
    controller.removeListener(_listener);
    controller.dispose();
  }
}
