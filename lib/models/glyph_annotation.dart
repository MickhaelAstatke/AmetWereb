import 'package:json_annotation/json_annotation.dart';

part 'glyph_annotation.g.dart';

@JsonSerializable()
class GlyphAnnotation {
  const GlyphAnnotation({
    required this.base,
    this.note,
  });

  factory GlyphAnnotation.fromJson(Map<String, dynamic> json) =>
      _$GlyphAnnotationFromJson(json);

  final String base;
  final String? note;

  GlyphAnnotation copyWith({
    String? base,
    Object? note = _undefined,
  }) {
    return GlyphAnnotation(
      base: base ?? this.base,
      note: note == _undefined ? this.note : note as String?,
    );
  }

  Map<String, dynamic> toJson() => _$GlyphAnnotationToJson(this);

  static const _undefined = Object();
}
