import 'package:json_annotation/json_annotation.dart';

part 'lyric_line.g.dart';

@JsonSerializable()
class LyricLine {
  const LyricLine({
    required this.order,
    required this.text,
  });

  factory LyricLine.fromJson(Map<String, dynamic> json) =>
      _$LyricLineFromJson(json);

  final int order;
  final String text;

  Map<String, dynamic> toJson() => _$LyricLineToJson(this);
}
