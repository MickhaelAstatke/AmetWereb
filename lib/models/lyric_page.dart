import 'package:json_annotation/json_annotation.dart';

import 'lyric_section.dart';

part 'lyric_page.g.dart';

@JsonSerializable(explicitToJson: true)
class LyricPage {
  const LyricPage({
    required this.id,
    required this.title,
    required this.month,
    required this.sections,
    this.day,
    this.icon,
  });

  factory LyricPage.fromJson(Map<String, dynamic> json) =>
      _$LyricPageFromJson(json);

  static const unknownMonth = 'Unknown';

  static const List<String> ethiopianMonths = [
    'Meskerem',
    'Tikimt',
    'Hidar',
    'Tahisas',
    'Tir',
    'Yekatit',
    'Megabit',
    'Miyazya',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagume',
  ];

  final String id;
  final String title;
  @JsonKey(defaultValue: unknownMonth)
  final String month;
  final List<LyricSection> sections;
  @JsonKey(includeIfNull: false)
  final int? day;
  @JsonKey(includeIfNull: false)
  final String? icon;

  bool get hasKnownMonth => month != unknownMonth && month.isNotEmpty;

  static const Object _undefined = Object();

  LyricPage copyWith({
    String? id,
    String? title,
    String? month,
    List<LyricSection>? sections,
    Object? day = _undefined,
    Object? icon = _undefined,
  }) {
    return LyricPage(
      id: id ?? this.id,
      title: title ?? this.title,
      month: month ?? this.month,
      sections: sections ?? this.sections,
      day: day == _undefined ? this.day : day as int?,
      icon: icon == _undefined ? this.icon : icon as String?,
    );
  }

  Map<String, dynamic> toJson() => _$LyricPageToJson(this);
}
