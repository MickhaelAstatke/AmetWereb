import 'package:flutter/material.dart';

import '../models/lyric_line.dart';

class LyricGlyphLine extends StatelessWidget {
  const LyricGlyphLine({
    required this.line,
    this.glyphStyle,
    this.noteStyle,
    this.spacing = 8,
    super.key,
  });

  final LyricLine line;
  final TextStyle? glyphStyle;
  final TextStyle? noteStyle;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letters = line.glyphs;
    if (letters.isEmpty) {
      return const SizedBox.shrink();
    }
    final glyphTextStyle = glyphStyle ??
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final noteTextStyle = noteStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 2,
        );
    return Wrap(
      spacing: spacing,
      runSpacing: 12,
      children: [
        for (final glyph in letters)
          _GlyphStack(
            glyph: glyph.base,
            note: glyph.note,
            glyphStyle: glyphTextStyle,
            noteStyle: noteTextStyle,
          ),
      ],
    );
  }
}

class _GlyphStack extends StatelessWidget {
  const _GlyphStack({
    required this.glyph,
    required this.note,
    required this.glyphStyle,
    required this.noteStyle,
  });

  final String glyph;
  final String? note;
  final TextStyle? glyphStyle;
  final TextStyle? noteStyle;

  @override
  Widget build(BuildContext context) {
    if (glyph.trim().isEmpty) {
      return SizedBox(width: (glyphStyle?.fontSize ?? 16) * 0.75);
    }
    final trimmedNote = note?.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trimmedNote != null && trimmedNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                trimmedNote,
                style: noteStyle,
              ),
            ),
          Text(
            glyph,
            style: glyphStyle,
          ),
        ],
      ),
    );
  }
}
