import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final String? audioUrl;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool showPrevious;
  final bool showNext;
  final String nextButtonText;

  const AudioPlayerWidget({
    super.key,
    required this.audioPlayer,
    required this.audioUrl,
    required this.onNext,
    required this.onPrevious,
    required this.showPrevious,
    required this.showNext,
    required this.nextButtonText,
  });

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: StreamBuilder<Duration>(
                stream: audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: audioPlayer.durationStream,
                    builder: (context, durationSnapshot) {
                      final duration = durationSnapshot.data ?? Duration.zero;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                              activeTrackColor: Theme.of(context).primaryColor,
                              inactiveTrackColor: Colors.grey[300],
                              thumbColor: Theme.of(context).primaryColor,
                              overlayColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2),
                            ),
                            child: Slider(
                              value: position.inMilliseconds.toDouble(),
                              min: 0,
                              max: duration.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                audioPlayer.seek(
                                    Duration(milliseconds: value.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Controls Row
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Previous Button
                  Expanded(
                    child: Center(
                      child: showPrevious
                          ? TextButton.icon(
                              onPressed: onPrevious,
                              icon: const Icon(Icons.skip_previous, size: 32),
                              label: const Text(
                                'Previous',
                                style: TextStyle(fontSize: 18),
                              ),
                            )
                          : null,
                    ),
                  ),

                  // Play/Pause Button Container
                  Container(
                    width: 100,
                    height: double.infinity,
                    alignment: Alignment.center,
                    child: StreamBuilder<PlayerState>(
                      stream: audioPlayer.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final processingState = playerState?.processingState;
                        final playing = playerState?.playing;

                        if (processingState == ProcessingState.loading ||
                            processingState == ProcessingState.buffering) {
                          return Container(
                            width: 80,
                            height: 80,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                strokeWidth: 5,
                              ),
                            ),
                          );
                        }

                        return IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 90,
                          icon: Icon(
                            playing == true
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            if (playing == true) {
                              audioPlayer.pause();
                            } else {
                              audioPlayer.play();
                            }
                          },
                        );
                      },
                    ),
                  ),

                  // Next/Finish Button
                  Expanded(
                    child: Center(
                      child: showNext
                          ? TextButton.icon(
                              onPressed: onNext,
                              icon: Text(
                                nextButtonText,
                                style: const TextStyle(fontSize: 18),
                              ),
                              label: const Icon(Icons.skip_next, size: 32),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
