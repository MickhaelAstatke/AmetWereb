import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lyric_line.dart';

class LyricAnnotationsLine extends StatelessWidget {
  const LyricAnnotationsLine({
    required this.line,
    required this.baseStyle,
    this.noteStyle,
    this.glyphSpacing = 12,
    this.runSpacing = 8,
    super.key,
  });

  final LyricLine line;
  final TextStyle baseStyle;
  final TextStyle? noteStyle;
  final double glyphSpacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final glyphs = line.glyphs;
    if (glyphs.isEmpty) {
      return const SizedBox.shrink();
    }
    final resolvedNoteStyle = noteStyle ??
        baseStyle.copyWith(
          fontSize: math.max((baseStyle.fontSize ?? 16) * 0.6, 10),
          fontWeight: FontWeight.w500,
        );
    final notePlaceholderHeight = resolvedNoteStyle.fontSize ?? 12;
    final whitespaceWidth = math.max((baseStyle.fontSize ?? 16) * 0.7, 12);
    return Wrap(
      spacing: glyphSpacing,
      runSpacing: runSpacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: glyphs.map((annotation) {
        if (annotation.isWhitespace) {
          return SizedBox(width: whitespaceWidth);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (annotation.hasNote)
              Text(
                annotation.note!,
                style: resolvedNoteStyle,
                textAlign: TextAlign.center,
              )
            else
              SizedBox(height: notePlaceholderHeight),
            Text(
              annotation.glyph,
              style: baseStyle,
            ),
          ],
        );
      }).toList(),
    );
  }
}
