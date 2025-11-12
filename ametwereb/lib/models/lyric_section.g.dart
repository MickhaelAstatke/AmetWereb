part of 'lyric_section.dart';

LyricSection _$LyricSectionFromJson(Map<String, dynamic> json) => LyricSection(
      id: json['id'] as String,
      title: json['title'] as String,
      note: json['note'] as String,
      audio:
          AudioMetadata.fromJson(json['audio'] as Map<String, dynamic>),
      lyrics: (json['lyrics'] as List<dynamic>)
          .map((e) => LyricLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LyricSectionToJson(LyricSection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'note': instance.note,
      'audio': instance.audio.toJson(),
      'lyrics': instance.lyrics.map((e) => e.toJson()).toList(),
    };
