import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../providers/lyrics_provider.dart';
import '../view_models/presentation_view_models.dart';
import 'home_page.dart';

class PresentationPage extends HookWidget {
  const PresentationPage({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
          );
        }
        final viewModel = provider.presentationViewModel;
        if (viewModel == null || viewModel.sections.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushNamed(HomePage.routeName),
              icon: const Icon(Icons.tune),
              label: const Text('Manage'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.present_to_all, color: Colors.white24, size: 96),
                    const SizedBox(height: 24),
                    Text(
                      'Presentation view is empty',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add a page with at least one section in the manager to project lyrics here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final sectionIndex = useState(0);
        final sectionController = usePageController();

        useEffect(() {
          if (sectionIndex.value >= viewModel.sections.length) {
            sectionIndex.value = 0;
          }
          return null;
        }, [viewModel.sections.length]);

        return Scaffold(
          backgroundColor: Colors.black,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).pushNamed(HomePage.routeName),
            icon: const Icon(Icons.tune),
            label: const Text('Manage'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _PresentationHeader(
                  viewModel: viewModel,
                  activeSectionIndex: sectionIndex.value,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: sectionController,
                    onPageChanged: (index) => sectionIndex.value = index,
                    itemCount: viewModel.sections.length,
                    itemBuilder: (context, index) {
                      final section = viewModel.sections[index];
                      return _PresentationSection(section: section);
                    },
                  ),
                ),
                if (viewModel.sections.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < viewModel.sections.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            height: 6,
                            width: sectionIndex.value == i ? 28 : 10,
                            decoration: BoxDecoration(
                              color: sectionIndex.value == i
                                  ? Colors.white
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PresentationHeader extends StatelessWidget {
  const _PresentationHeader({
    required this.viewModel,
    required this.activeSectionIndex,
  });

  final PresentationPageViewModel viewModel;
  final int activeSectionIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeSection = viewModel.sections[activeSectionIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (viewModel.hasIconLabel)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white10,
                  ),
                  child: Text(
                    viewModel.iconLabel!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (viewModel.hasIconLabel) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.pageTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildDateLabel(),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(0.08),
                ),
                child: Text(
                  activeSection.metadata.durationLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            activeSection.metadata.title,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activeSection.metadata.subtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  String _buildDateLabel() {
    if (viewModel.dayLabel == null || viewModel.dayLabel!.isEmpty) {
      return viewModel.monthLabel;
    }
    return '${viewModel.monthLabel} ${viewModel.dayLabel}';
  }
}

class _PresentationSection extends HookWidget {
  const _PresentationSection({required this.section});

  final PresentationSectionViewModel section;

  @override
  Widget build(BuildContext context) {
    final slideController = usePageController();
    final slideIndex = useState(0);
    final colors = _colorsForSeed(section.backgroundSeed);
    return Stack(
      children: [
        _SectionBackground(
          colors: colors,
          artGlyph: section.metadata.artGlyph,
        ),
        PageView.builder(
          controller: slideController,
          onPageChanged: (index) => slideIndex.value = index,
          itemCount: section.slides.length,
          itemBuilder: (context, index) {
            final slide = section.slides[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: _LyricSlide(lines: slide.lines),
                    ),
                  ),
                  if (section.hasMultipleSlides)
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '${index + 1} / ${section.slides.length}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LyricSlide extends StatelessWidget {
  const _LyricSlide({required this.lines});

  final List<PresentationLineViewModel> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (lines.isEmpty) {
      return Text(
        'No lyrics available for this section',
        style: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white70,
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: _LyricLine(line: line),
          ),
      ],
    );
  }
}

class _LyricLine extends StatelessWidget {
  const _LyricLine({required this.line});

  final PresentationLineViewModel line;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 24,
      children: line.glyphs
          .map(
            (glyph) => _StackedGlyph(glyph: glyph),
          )
          .toList(),
    );
  }
}

class _StackedGlyph extends StatelessWidget {
  const _StackedGlyph({required this.glyph});

  final PresentationGlyphViewModel glyph;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          glyph.letter,
          style: theme.textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 0.9,
          ),
        ),
        if (glyph.hasNote)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              glyph.note!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.1,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionBackground extends StatelessWidget {
  const _SectionBackground({required this.colors, required this.artGlyph});

  final List<Color> colors;
  final String artGlyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Opacity(
            opacity: 0.15,
            child: Text(
              artGlyph,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 220,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

List<Color> _colorsForSeed(String seed) {
  final hash = seed.codeUnits.fold<int>(0, (value, element) => value + element);
  final hue = (hash * 37) % 360;
  final hue2 = (hue + 48) % 360;
  final color1 = HSLColor.fromAHSL(0.85, hue.toDouble(), 0.6, 0.45).toColor();
  final color2 = HSLColor.fromAHSL(0.85, hue2.toDouble(), 0.55, 0.35).toColor();
  return [color1, color2];
}
