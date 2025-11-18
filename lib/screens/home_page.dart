import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../models/lyric_page.dart';
import '../models/lyric_section.dart';
import '../providers/lyrics_provider.dart';
import '../widgets/lyric_annotations_line.dart';
import '../widgets/now_playing_bar.dart';
import 'editor_page.dart';
import 'player_page.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, _) {
        final months = provider.sortedMonths;
        final selectedMonth = provider.selectedMonth;
        final dropdownValue =
            months.contains(selectedMonth) ? selectedMonth : null;
        final monthPages = dropdownValue == null
            ? const <LyricPage>[]
            : provider.pagesForMonth(dropdownValue);
        final selectedPage = provider.selectedPage;
        final activeIndex = selectedPage == null
            ? -1
            : monthPages.indexWhere((page) => page.id == selectedPage.id);
        final pageController = usePageController();

        useEffect(() {
          if (selectedPage == null || dropdownValue == null) {
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
        }, [selectedPage?.id, dropdownValue, monthPages.length]);

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
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                tooltip: 'Manage pages',
                onPressed: () => Navigator.of(context).pushNamed(
                  EditorPage.routeName,
                ),
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
                      padding: const EdgeInsets.all(20),
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
                      child: Row(
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
                                  'Select Page',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                            .withOpacity(0.7),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: dropdownValue,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withOpacity(0.9),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  dropdownColor: Theme.of(context).colorScheme.surface,
                                  items: months
                                      .map(
                                        (month) => DropdownMenuItem(
                                          value: month,
                                          child: Text(
                                            month,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: months.isEmpty
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            provider.selectMonth(value);
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (monthPages.length > 1)
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
                      child: dropdownValue == null
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
                              ? _EmptyMonthState(month: dropdownValue)
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
                        color: theme.colorScheme.outlineVariant.withOpacity(0.2),
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
                                    '${section.audio.duration ~/ 60}:${(section.audio.duration % 60).toString().padLeft(2, '0')} mins',
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
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.white.withOpacity(0.15)
                                                : theme.colorScheme.primaryContainer
                                                    .withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${line.order}',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: isActive
                                                  ? Colors.white
                                                  : theme.colorScheme
                                                      .onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: LyricAnnotationsLine(
                                            line: line,
                                            baseStyle:
                                                theme.textTheme.bodyMedium?.copyWith(
                                                      color: isActive
                                                          ? Colors
                                                              .white
                                                              .withOpacity(0.85)
                                                          : theme.colorScheme
                                                              .onSurface
                                                              .withOpacity(0.8),
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
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isActive
                                        ? Colors.white.withOpacity(0.6)
                                        : theme.colorScheme.onSurfaceVariant,
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
