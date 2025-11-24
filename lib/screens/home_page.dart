import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../models/lyric_page.dart';
import '../models/lyric_section.dart';
import '../providers/auth_provider.dart';
import '../providers/lyrics_provider.dart';
import '../widgets/lyric_annotations_line.dart';
import '../widgets/now_playing_bar.dart';
import 'editor_page.dart';
import 'player_page.dart';

const Map<String, String> _amharicMonthLabels = {
  'Meskerem': 'መስከረም',
  'Tikimt': 'ጥቅምት',
  'Hidar': 'ህዳር',
  'Tahisas': 'ታኅሣሥ',
  'Tir': 'ጥር',
  'Yekatit': 'የካቲት',
  'Megabit': 'መጋቢት',
  'Miyazya': 'ሚያዚያ',
  'Ginbot': 'ግንቦት',
  'Sene': 'ሰኔ',
  'Hamle': 'ሐምሌ',
  'Nehase': 'ነሐሴ',
  'Pagume': 'ጳጉሜ',
  LyricPage.unknownMonth: 'ያልታወቀ',
};

class HomePage extends HookWidget {
  const HomePage({super.key});

  static const routeName = '/manage';

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, _) {
        final canEdit = context.watch<AuthProvider>().canEdit;
        final months = provider.sortedMonths;
        final selectedMonth = provider.selectedMonth;
        final hasMonths = months.isNotEmpty;
        final resolvedMonthIndex = !hasMonths
            ? 0
            : (() {
                final initialIndex = months.indexOf(selectedMonth ?? '');
                if (initialIndex >= 0) {
                  return initialIndex;
                }
                return 0;
              })();
        final tabController = useTabController(
          initialIndex: resolvedMonthIndex,
          length: hasMonths ? months.length : 1,
        );
        final currentMonth = hasMonths
            ? months[min(tabController.index, months.length - 1)]
            : null;
        final monthPages = currentMonth == null
            ? const <LyricPage>[]
            : provider.pagesForMonth(currentMonth);
        final selectedPage = provider.selectedPage;
        final activeIndex = selectedPage == null
            ? -1
            : monthPages.indexWhere((page) => page.id == selectedPage.id);
        final pageController = usePageController();

        useEffect(() {
          if (!hasMonths) {
            return null;
          }
          if (selectedMonth == null || !months.contains(selectedMonth)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (months.isNotEmpty) {
                provider.selectMonth(months.first);
              }
            });
          }
          return null;
        }, [hasMonths, months, selectedMonth, provider]);

        useEffect(() {
          if (!hasMonths) {
            return null;
          }
          void handleTabChange() {
            if (tabController.indexIsChanging) {
              return;
            }
            final nextMonth = months[tabController.index];
            if (provider.selectedMonth != nextMonth) {
              provider.selectMonth(nextMonth);
            }
          }

          tabController.addListener(handleTabChange);
          return () => tabController.removeListener(handleTabChange);
        }, [tabController, hasMonths, months, provider]);

        useEffect(() {
          if (!hasMonths) {
            return null;
          }
          final targetIndex = months.indexOf(provider.selectedMonth ?? '');
          if (targetIndex >= 0 && targetIndex < tabController.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (tabController.index != targetIndex) {
                tabController.animateTo(targetIndex);
              }
            });
          }
          return null;
        }, [provider.selectedMonth, months, tabController, hasMonths]);

        useEffect(() {
          if (selectedPage == null || currentMonth == null) {
            return null;
          }
          final targetIndex =
              monthPages.indexWhere((page) => page.id == selectedPage.id);
          if (targetIndex < 0) {
            return null;
          }
          void jump() {
            if (!pageController.hasClients) {
              return;
            }
            final currentPage = pageController.page?.round();
            if (currentPage != targetIndex) {
              pageController.jumpToPage(targetIndex);
            }
          }

          if (pageController.hasClients) {
            jump();
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) => jump());
          }
          return null;
        }, [selectedPage?.id, currentMonth, monthPages.length]);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: DropdownButton<String>(
              value: 'መዋጊራ',
              icon: const Icon(Icons.keyboard_arrow_down),
              underline: Container(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              items: const [
                DropdownMenuItem(
                  value: 'መዋጊራ',
                  child: Text('መዋጊራ'),
                ),
              ],
              onChanged: (value) {},
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_note),
                  tooltip: 'Manage pages',
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      EditorPage.routeName,
                    );
                  },
                ),
            ],
            bottom: hasMonths
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(56),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: tabController,
                        isScrollable: true,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        indicatorWeight: 3,
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        tabs: months
                            .map(
                              (month) => Text(
                                _amharicMonthLabels[month] ?? month,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  )
                : null,
          ),
          drawer: _buildDrawer(context, canEdit),
          body: provider.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : currentMonth == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_off,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Add some holidays to get started',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                ),
                          ),
                        ],
                      ),
                    )
                  : monthPages.isEmpty
                      ? _EmptyMonthState(month: currentMonth)
                      : PageView.builder(
                          controller: pageController,
                          onPageChanged: (index) {
                            if (index < 0 || index >= monthPages.length) {
                              return;
                            }
                            final page = monthPages[index];
                            if (provider.selectedPage?.id != page.id) {
                              provider.selectPage(page);
                            }
                          },
                          itemCount: monthPages.length,
                          itemBuilder: (context, pageIndex) {
                            final page = monthPages[pageIndex];
                            return _PageView(
                              page: page,
                              provider: provider,
                            );
                          },
                        ),
          bottomNavigationBar: const NowPlayingBar(),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, bool canEdit) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.lyrics,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lyric Companion',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_fill),
            title: const Text('Player'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(PlayerPage.routeName);
            },
          ),
          if (canEdit)
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Manage Pages'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(EditorPage.routeName);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({
    required this.page,
    required this.provider,
  });

  final LyricPage page;
  final LyricsProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 88,
        top: 16,
      ),
      children: [
        // Page Title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
            textAlign: TextAlign.start,
          ),
        ),
        // Page indicators
        if (provider.pagesForMonth(page.month).length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                for (var i = 0;
                    i < provider.pagesForMonth(page.month).length;
                    i++)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: provider.selectedPage?.id ==
                        provider.pagesForMonth(page.month)[i].id ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: provider.selectedPage?.id ==
                              provider.pagesForMonth(page.month)[i].id
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        // Sections
        ...page.sections.map((section) => _SectionView(
              section: section,
              isPlaying: provider.currentSection?.id == section.id,
              onTap: () => provider.playSection(section),
            )),
      ],
    );
  }
}

class _SectionView extends HookWidget {
  const _SectionView({
    required this.section,
    required this.isPlaying,
    required this.onTap,
  });

  final LyricSection section;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPlaying
                    ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPlaying
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withOpacity(0.3),
                  width: isPlaying ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPlaying ? Icons.play_circle_filled : Icons.play_circle_outline,
                    color: isPlaying
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPlaying
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (section.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              section.note,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${section.audio.duration ~/ 60}:${(section.audio.duration % 60).toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Section Content
          if (section.lyrics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: section.lyrics.map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LyricAnnotationsLine(
                      line: line,
                      baseStyle: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.8,
                            fontSize: 18,
                          ) ??
                          const TextStyle(),
                      noteStyle: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                      glyphSpacing: 8,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyMonthState extends StatelessWidget {
  const _EmptyMonthState({required this.month});

  final String month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No holidays for $month yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a holiday to this month from the editor to see it here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
