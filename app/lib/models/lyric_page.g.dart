part of 'lyric_page.dart';

LyricPage _$LyricPageFromJson(Map<String, dynamic> json) => LyricPage(
      id: json['id'] as String,
      title: json['title'] as String,
      sections: (json['sections'] as List<dynamic>)
          .map((e) => LyricSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LyricPageToJson(LyricPage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'sections': instance.sections.map((e) => e.toJson()).toList(),
    };
