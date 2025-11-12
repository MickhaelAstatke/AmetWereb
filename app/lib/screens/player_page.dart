import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lyrics_provider.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  static const routeName = '/player';

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, _) {
        final section = provider.currentSection;
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Now Playing'),
          ),
          body: section == null
              ? const Center(
                  child: Text('Choose a lyric section to begin playback.'),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primaryContainer,
                                theme.colorScheme.secondaryContainer,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.music_note,
                              size: 120,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        section.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.note,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _PlaybackControls(sectionDuration: section.audio.duration),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView(
                          children: section.lyrics
                              .map(
                                (line) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '${line.order}. ${line.text}',
                                    style: theme.textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.sectionDuration});

  final int sectionDuration;

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, _) {
        final duration = Duration(seconds: sectionDuration);
        final position = provider.currentPosition;
        final maxMillis = duration.inMilliseconds;
        final clampedPosition = position.inMilliseconds.clamp(0, maxMillis);
        final sliderEnabled = maxMillis > 0;
        String format(Duration d) =>
            '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
        return Column(
          children: [
            Slider(
              value: sliderEnabled && maxMillis > 0
                  ? clampedPosition / maxMillis
                  : 0,
              onChanged: sliderEnabled
                  ? (value) {
                      provider.seek(
                        Duration(
                          milliseconds:
                              (duration.inMilliseconds * value).toInt(),
                        ),
                      );
                    }
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(format(Duration(milliseconds: clampedPosition))),
                Text(format(duration)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  iconSize: 36,
                  onPressed: () => provider.seek(
                    position - const Duration(seconds: 10),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(
                    provider.playerState == PlayerState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    provider.playerState == PlayerState.playing
                        ? 'Pause'
                        : 'Play',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                  onPressed: provider.togglePlayPause,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  iconSize: 36,
                  onPressed: () => provider.seek(
                    position + const Duration(seconds: 10),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
