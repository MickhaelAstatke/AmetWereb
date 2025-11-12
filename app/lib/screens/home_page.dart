import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../models/lyric_section.dart';
import '../providers/lyrics_provider.dart';
import '../widgets/now_playing_bar.dart';
import 'editor_page.dart';
import 'player_page.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    return Consumer<LyricsProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Lyric Companion'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note),
                tooltip: 'Manage pages',
                onPressed: () => Navigator.of(context).pushNamed(
                  EditorPage.routeName,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_fill),
                tooltip: 'Open player',
                onPressed: () => Navigator.of(context).pushNamed(
                  PlayerPage.routeName,
                ),
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Page',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField(
                              value: provider.selectedPage,
                              decoration: const InputDecoration(
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
                              onChanged: provider.pages.isEmpty
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        provider.selectPage(value);
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: provider.selectedPage == null
                          ? const Center(
                              child: Text('No pages available'),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: 88,
                              ),
                              itemCount: provider.selectedPage!.sections.length,
                              itemBuilder: (context, index) {
                                final section =
                                    provider.selectedPage!.sections[index];
                                return _LyricSectionTile(
                                  section: section,
                                  isActive: provider.currentSection?.id ==
                                      section.id,
                                  onTap: () => provider.playSection(section),
                                );
                              },
                            ),
                    ),
                  ],
                ),
          bottomNavigationBar: const NowPlayingBar(),
        );
      },
    );
  }
}

class _LyricSectionTile extends StatelessWidget {
  const _LyricSectionTile({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  final LyricSection section;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.secondaryContainer,
                    ],
                  )
                : null,
            color: isActive
                ? null
                : theme.colorScheme.surfaceVariant.withOpacity(0.4),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.music_note,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.note,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${section.audio.duration ~/ 60}:${(section.audio.duration % 60).toString().padLeft(2, '0')} mins',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: section.lyrics
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${line.order}. ${line.text}',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
