import 'package:characters/characters.dart';
import 'package:json_annotation/json_annotation.dart';

import 'glyph_annotation.dart';

part 'lyric_line.g.dart';

@JsonSerializable()
class LyricLine {
  const LyricLine({
    required this.order,
    required this.text,
    this.annotations = const [],
  });

  factory LyricLine.fromJson(Map<String, dynamic> json) =>
      _$LyricLineFromJson(json);

  final int order;
  final String text;

  @JsonKey(defaultValue: [])
  final List<GlyphAnnotation> annotations;

  bool get hasAnnotations => annotations.isNotEmpty;

  List<GlyphAnnotation> get glyphs {
    if (annotations.isNotEmpty) {
      return annotations;
    }
    return text.characters
        .map((character) => GlyphAnnotation(base: character))
        .toList(growable: false);
  }

  static const Object _undefined = Object();

  LyricLine copyWith({
    int? order,
    String? text,
    Object? annotations = _undefined,
  }) {
    return LyricLine(
      order: order ?? this.order,
      text: text ?? this.text,
      annotations: annotations == _undefined
          ? this.annotations
          : List<GlyphAnnotation>.from(annotations as List<GlyphAnnotation>),
    );
  }

  Map<String, dynamic> toJson() => _$LyricLineToJson(this);
}
