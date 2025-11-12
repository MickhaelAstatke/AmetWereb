part of 'audio_metadata.dart';

AudioMetadata _$AudioMetadataFromJson(Map<String, dynamic> json) => AudioMetadata(
      url: json['url'] as String,
      duration: json['duration'] as int,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
    );

Map<String, dynamic> _$AudioMetadataToJson(AudioMetadata instance) =>
    <String, dynamic>{
      'url': instance.url,
      'duration': instance.duration,
      'artist': instance.artist,
      'album': instance.album,
    };
