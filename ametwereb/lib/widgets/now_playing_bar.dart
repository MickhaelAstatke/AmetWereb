import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lyrics_provider.dart';
import '../screens/player_page.dart';

class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, _) {
        final section = provider.currentSection;
        if (section == null) {
          return const SizedBox.shrink();
        }
        final duration = Duration(seconds: section.audio.duration);
        final position = provider.currentPosition;
        final maxMillis = duration.inMilliseconds;
        final clampedPosition = position.inMilliseconds.clamp(0, maxMillis);
        final sliderEnabled = maxMillis > 0;
        return Material(
          elevation: 8,
          color: Theme.of(context).colorScheme.surface,
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed(PlayerPage.routeName),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          section.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          section.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                        Slider(
                          value: sliderEnabled && maxMillis > 0
                              ? clampedPosition / maxMillis
                              : 0,
                          onChanged: sliderEnabled
                              ? (value) {
                                  provider.seek(
                                    Duration(
                                      milliseconds:
                                          (duration.inMilliseconds * value)
                                              .toInt(),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      provider.playerState == PlayerState.playing
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      size: 36,
                    ),
                    onPressed: provider.togglePlayPause,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
