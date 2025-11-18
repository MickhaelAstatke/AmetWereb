import 'package:json_annotation/json_annotation.dart';

part 'glyph_annotation.g.dart';

@JsonSerializable()
class GlyphAnnotation {
  const GlyphAnnotation({
    required this.glyph,
    this.note,
  });

  factory GlyphAnnotation.fromJson(Map<String, dynamic> json) =>
      _$GlyphAnnotationFromJson(json);

  final String glyph;
  final String? note;

  bool get hasNote => note != null && note!.trim().isNotEmpty;
  bool get isWhitespace => glyph.trim().isEmpty;

  Map<String, dynamic> toJson() => _$GlyphAnnotationToJson(this);
}
