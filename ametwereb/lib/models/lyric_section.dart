import 'package:json_annotation/json_annotation.dart';

import 'audio_metadata.dart';
import 'lyric_line.dart';

part 'lyric_section.g.dart';

@JsonSerializable(explicitToJson: true)
class LyricSection {
  const LyricSection({
    required this.id,
    required this.title,
    required this.note,
    required this.audio,
    required this.lyrics,
  });

  factory LyricSection.fromJson(Map<String, dynamic> json) =>
      _$LyricSectionFromJson(json);

  final String id;
  final String title;
  final String note;
  final AudioMetadata audio;
  final List<LyricLine> lyrics;

  Map<String, dynamic> toJson() => _$LyricSectionToJson(this);
}
