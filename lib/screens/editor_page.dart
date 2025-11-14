import 'package:flutter/material.dart';
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

  List<LyricSection> _sections = [];
  bool _isExistingPage = false;

  @override
  void dispose() {
    _pageIdController.dispose();
    _pageTitleController.dispose();
    super.dispose();
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
      } else {
        _isExistingPage = true;
        _pageIdController.text = page.id;
        _pageTitleController.text = page.title;
        _sections = List.of(page.sections);
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
    final page = LyricPage(
      id: _pageIdController.text.trim(),
      title: _pageTitleController.text.trim(),
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
    _lyricsController = TextEditingController(
      text: widget.section == null
          ? ''
          : widget.section!.lyrics
              .map((line) => line.text)
              .join('\n'),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _audioUrlController.dispose();
    _durationController.dispose();
    _lyricsController.dispose();
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
        url: _audioUrlController.text.trim(),
        duration: duration,
      ),
      lyrics: lyricLines,
    );
    Navigator.of(context).pop(section);
  }
}
