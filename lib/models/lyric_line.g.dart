part of 'lyric_line.dart';

LyricLine _$LyricLineFromJson(Map<String, dynamic> json) => LyricLine(
      order: json['order'] as int,
      text: json['text'] as String,
    );

Map<String, dynamic> _$LyricLineToJson(LyricLine instance) => <String, dynamic>{
      'order': instance.order,
      'text': instance.text,
    };
