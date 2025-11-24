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
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lyrics,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Lyric Companion'),
              ],
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(canEdit ? 1 : 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withOpacity(canEdit ? 1 : 0.4),
                  ),
                ),
                tooltip:
                    canEdit ? 'Manage pages' : 'You do not have permission to edit',
                onPressed: canEdit
                    ? () {
                        assert(canEdit,
                            'An edit role is required before opening the editor.');
                        Navigator.of(context).pushNamed(
                          EditorPage.routeName,
                        );
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                  ),
                ),
                tooltip: 'Open player',
                onPressed: () => Navigator.of(context).pushNamed(
                  PlayerPage.routeName,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: provider.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Loading lyrics...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.secondaryContainer,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.library_music,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'የበዓላት ምድቦች',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                                .withOpacity(0.7),
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Select an Ethiopian month to browse pages',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                                .withOpacity(0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.9),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: TabBar(
                              controller: tabController,
                              isScrollable: true,
                              indicator: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              labelColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              unselectedLabelColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              tabs: hasMonths
                                  ? months
                                      .map(
                                        (month) => Tab(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _amharicMonthLabels[month] ??
                                                    month,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                month,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList()
                                  : const [Tab(text: '—')],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (monthPages.length > 1) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < monthPages.length; i++)
                              AnimatedContainer(
                                key: ValueKey('month_indicator_$i'),
                                duration: const Duration(milliseconds: 250),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                height: 8,
                                width: activeIndex == i ? 24 : 8,
                                decoration: BoxDecoration(
                                  color: activeIndex == i
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                          ],
                        ),
                    ),
                    Expanded(
                      child: currentMonth == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant
                                          .withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.music_off,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.3),
                                    ),
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
                                    if (index < 0 ||
                                        index >= monthPages.length) {
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
                                    return ListView.builder(
                                      key: PageStorageKey<String>('page_${page.id}'),
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: 88,
                                        top: 8,
                                      ),
                                      itemCount: page.sections.length,
                                      itemBuilder: (context, index) {
                                        final section = page.sections[index];
                                        return _LyricSectionTile(
                                          section: section,
                                          isActive: provider
                                                  .currentSection?.id ==
                                              section.id,
                                          onTap: () =>
                                              provider.playSection(section),
                                          index: index,
                                        );
                                      },
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

class _LyricSectionTile extends HookWidget {
  const _LyricSectionTile({
    required this.section,
    required this.isActive,
    required this.onTap,
    required this.index,
  });

  final LyricSection section;
  final bool isActive;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 400),
    );

    final scaleAnimation = useMemoized(
      () => Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    final fadeAnimation = useMemoized(
      () => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOut,
        ),
      ),
    );

    useEffect(() {
      Future.delayed(Duration(milliseconds: 50 * index), () {
        animationController.forward();
      });
      return null;
    }, []);

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 6,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: isActive
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isActive
                          ? null
                          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      border: isActive
                          ? null
                          : Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.2),
                              width: 1.5,
                            ),
                      boxShadow: [
                        if (isActive)
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white.withOpacity(0.2)
                                      : theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: isActive
                                      ? Colors.white
                                      : theme.colorScheme.onPrimaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      section.title,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 16,
                                          color: isActive
                                              ? Colors.white.withOpacity(0.8)
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${section.audio.duration ~/ 60}:${(section.audio.duration % 60).toString().padLeft(2, '0')}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: isActive
                                                ? Colors.white.withOpacity(0.8)
                                                : theme.colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white.withOpacity(0.1)
                                  : theme.colorScheme.surface.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.note,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: isActive
                                        ? Colors.white.withOpacity(0.9)
                                        : theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (section.lyrics.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Divider(
                                    color: isActive
                                        ? Colors.white.withOpacity(0.2)
                                        : theme.colorScheme.outlineVariant
                                            .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 12),
                                  ...section.lyrics.take(3).map(
                                        (line) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Line ${line.order.toString().padLeft(2, '0')}',
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: isActive
                                                      ? Colors.white
                                                          .withOpacity(0.8)
                                                      : theme.colorScheme
                                                          .onSurfaceVariant,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: LyricAnnotationsLine(
                                                  line: line,
                                                  baseStyle: theme
                                                          .textTheme.bodyMedium
                                                          ?.copyWith(
                                                        color: isActive
                                                            ? Colors.white
                                                                .withOpacity(
                                                                    0.85)
                                                            : theme.colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                    0.8),
                                                        height: 1.5,
                                                      ) ??
                                                      const TextStyle(),
                                                  noteStyle: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: isActive
                                                        ? Colors.white
                                                            .withOpacity(0.75)
                                                        : theme.colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                                  glyphSpacing: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  if (section.lyrics.length > 3)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '+${section.lyrics.length - 3} more lines',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: isActive
                                              ? Colors.white.withOpacity(0.6)
                                              : theme.colorScheme
                                                  .onSurfaceVariant,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.surfaceVariant.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
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
