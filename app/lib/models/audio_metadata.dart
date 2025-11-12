import 'package:json_annotation/json_annotation.dart';

part 'audio_metadata.g.dart';

@JsonSerializable()
class AudioMetadata {
  const AudioMetadata({
    required this.url,
    required this.duration,
    this.artist,
    this.album,
  });

  factory AudioMetadata.fromJson(Map<String, dynamic> json) =>
      _$AudioMetadataFromJson(json);

  final String url;
  final int duration;
  final String? artist;
  final String? album;

  Map<String, dynamic> toJson() => _$AudioMetadataToJson(this);
}
