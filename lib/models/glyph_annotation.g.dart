part of 'glyph_annotation.dart';

GlyphAnnotation _$GlyphAnnotationFromJson(Map<String, dynamic> json) =>
    GlyphAnnotation(
      base: json['base'] as String,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$GlyphAnnotationToJson(GlyphAnnotation instance) =>
    <String, dynamic>{
      'base': instance.base,
      'note': instance.note,
    };
