import 'package:json_annotation/json_annotation.dart';

import 'lyric_section.dart';

part 'lyric_page.g.dart';

@JsonSerializable(explicitToJson: true)
class LyricPage {
  const LyricPage({
    required this.id,
    required this.title,
    required this.sections,
  });

  factory LyricPage.fromJson(Map<String, dynamic> json) =>
      _$LyricPageFromJson(json);

  final String id;
  final String title;
  final List<LyricSection> sections;

  Map<String, dynamic> toJson() => _$LyricPageToJson(this);
}
