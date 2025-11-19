part of 'lyric_line.dart';

LyricLine _$LyricLineFromJson(Map<String, dynamic> json) => LyricLine(
      order: json['order'] as int,
      text: json['text'] as String,
      annotations: (json['annotations'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  GlyphAnnotation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$LyricLineToJson(LyricLine instance) =>
    <String, dynamic>{
      'order': instance.order,
      'text': instance.text,
      'annotations': instance.annotations.map((e) => e.toJson()).toList(),
    };
