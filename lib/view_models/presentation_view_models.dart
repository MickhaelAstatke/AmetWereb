import 'package:characters/characters.dart';

import '../models/glyph_annotation.dart';
import '../models/lyric_line.dart';
import '../models/lyric_page.dart';
import '../models/lyric_section.dart';

class PresentationGlyphViewModel {
  const PresentationGlyphViewModel({
    required this.letter,
    this.note,
  });

  final String letter;
  final String? note;

  bool get hasNote => note != null && note!.trim().isNotEmpty;
}

class PresentationLineViewModel {
  const PresentationLineViewModel({
    required this.order,
    required this.glyphs,
  });

  final int order;
  final List<PresentationGlyphViewModel> glyphs;

  String get text => glyphs.map((glyph) => glyph.letter).join();
  bool get hasAnyNotes => glyphs.any((glyph) => glyph.hasNote);
}

class PresentationSlideViewModel {
  const PresentationSlideViewModel({required this.lines});

  final List<PresentationLineViewModel> lines;
}

class PresentationSectionMetadata {
  const PresentationSectionMetadata({
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.artGlyph,
  });

  final String title;
  final String subtitle;
  final String durationLabel;
  final String artGlyph;
}

class PresentationSectionViewModel {
  const PresentationSectionViewModel({
    required this.metadata,
    required this.slides,
    required this.backgroundSeed,
  });

  final PresentationSectionMetadata metadata;
  final List<PresentationSlideViewModel> slides;
  final String backgroundSeed;

  bool get hasMultipleSlides => slides.length > 1;
}

class PresentationPageViewModel {
  const PresentationPageViewModel({
    required this.pageTitle,
    required this.monthLabel,
    required this.sections,
    this.dayLabel,
    this.iconLabel,
  });

  final String pageTitle;
  final String monthLabel;
  final String? dayLabel;
  final String? iconLabel;
  final List<PresentationSectionViewModel> sections;

  bool get hasIconLabel => iconLabel != null && iconLabel!.trim().isNotEmpty;
}

class PresentationViewModelFactory {
  const PresentationViewModelFactory._();

  static PresentationPageViewModel fromPage(LyricPage page) {
    return PresentationPageViewModel(
      pageTitle: page.title,
      monthLabel: page.month,
      dayLabel: page.day?.toString(),
      iconLabel: page.icon,
      sections: page.sections.map(_sectionViewModel).toList(),
    );
  }

  static PresentationSectionViewModel _sectionViewModel(
    LyricSection section,
  ) {
    final metadata = PresentationSectionMetadata(
      title: section.title,
      subtitle: section.note,
      durationLabel: _formatDuration(section.audio.duration),
      artGlyph: section.title.characters.isNotEmpty
          ? section.title.characters.first
          : section.id.characters.isNotEmpty
              ? section.id.characters.first
              : '♪',
    );
    final slides = _slidesFromLines(section.lyrics);
    return PresentationSectionViewModel(
      metadata: metadata,
      slides: slides,
      backgroundSeed: section.id,
    );
  }

  static List<PresentationSlideViewModel> _slidesFromLines(
    List<LyricLine> lines,
  ) {
    const maxLinesPerSlide = 3;
    final slides = <PresentationSlideViewModel>[];
    for (var i = 0; i < lines.length; i += maxLinesPerSlide) {
      final chunk = lines
          .skip(i)
          .take(maxLinesPerSlide)
          .map(_lineViewModel)
          .toList(growable: false);
      slides.add(PresentationSlideViewModel(lines: chunk));
    }
    return slides.isEmpty
        ? [PresentationSlideViewModel(lines: const [])]
        : slides;
  }

  static PresentationLineViewModel _lineViewModel(LyricLine line) {
    return PresentationLineViewModel(
      order: line.order,
      glyphs: line.glyphs.map(_glyphViewModel).toList(growable: false),
    );
  }

  static PresentationGlyphViewModel _glyphViewModel(GlyphAnnotation glyph) {
    return PresentationGlyphViewModel(
      letter: glyph.glyph,
      note: glyph.note,
    );
  }

  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
