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
            title: const Text('Manage Lyric Library'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<LyricPage>(
                        initialValue: selectedPage,
                        decoration: const InputDecoration(
                          labelText: 'Select a page',
                          border: OutlineInputBorder(),
                        ),
                        items: provider.pages
                            .map(
                              (page) => DropdownMenuItem(
                                value: page,
                                child: Text(page.title),
                              ),
                            )
                            .toList(),
                        onChanged: (LyricPage? value) {
                          if (value != null) {
                            _loadPage(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('New Page'),
                      onPressed: () => _loadPage(null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _pageIdController,
                          decoration: const InputDecoration(
                            labelText: 'Page ID',
                            helperText: 'Used internally for storage',
                          ),
                          readOnly: _isExistingPage,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an identifier';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pageTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Page title',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              'Sections',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              icon: const Icon(Icons.library_add),
                              label: const Text('Add section'),
                              onPressed: () async {
                                final section = await showDialog<LyricSection>(
                                  context: context,
                                  builder: (context) => SectionEditorDialog(
                                    pageId: _pageIdController.text,
                                  ),
                                );
                                if (section != null) {
                                  setState(() {
                                    _sections = _upsertSectionLocally(section);
                                  });
                                  if (!mounted) return;
                                  await _commitPage(context);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_sections.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                            child: const Center(
                              child: Text('No sections yet. Tap “Add section”.'),
                            ),
                          )
                        else
                          ..._sections.map(
                            (section) => Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                title: Text(section.title),
                                subtitle: Text(section.note),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Edit section',
                                      onPressed: () async {
                                        final updated =
                                            await showDialog<LyricSection>(
                                          context: context,
                                          builder: (context) => SectionEditorDialog(
                                            pageId: _pageIdController.text,
                                            section: section,
                                          ),
                                        );
                                        if (updated != null) {
                                          setState(() {
                                            _sections =
                                                _upsertSectionLocally(updated);
                                          });
                                          if (!mounted) return;
                                          await _commitPage(context);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      tooltip: 'Remove section',
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Remove section'),
                                            content: Text(
                                              'Are you sure you want to remove "${section.title}"?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: const Text('Remove'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          setState(() {
                                            _sections = _sections
                                                .where((s) => s.id != section.id)
                                                .toList();
                                          });
                                          if (!mounted) return;
                                          await _commitPage(context);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  final provider =
                                      context.read<LyricsProvider>();
                                  await provider.playSection(section);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _commitPage(context),
                      child: const Text('Save changes'),
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Library updated')),
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
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.section == null ? 'New section' : 'Edit section',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Section ID',
                  ),
                  readOnly: widget.section != null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an identifier';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Section title',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Notes for performers',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Provide a short note';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _audioUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Audio asset or URL',
                    helperText: 'Supports bundled assets or remote links',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Provide an audio reference';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration in seconds',
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lyricsController,
                  decoration: const InputDecoration(
                    labelText: 'Lyric lines',
                    helperText: 'Enter one line per row',
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
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
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
