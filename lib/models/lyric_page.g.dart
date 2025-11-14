part of 'lyric_page.dart';

LyricPage _$LyricPageFromJson(Map<String, dynamic> json) => LyricPage(
      id: json['id'] as String,
      title: json['title'] as String,
      month: json['month'] as String? ?? LyricPage.unknownMonth,
      sections: (json['sections'] as List<dynamic>)
          .map((e) => LyricSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      day: json['day'] as int?,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$LyricPageToJson(LyricPage instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'title': instance.title,
    'month': instance.month,
    'sections': instance.sections.map((e) => e.toJson()).toList(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('day', instance.day);
  writeNotNull('icon', instance.icon);
  return val;
}
