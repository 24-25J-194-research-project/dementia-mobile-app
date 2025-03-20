import 'package:dementia_app/features/reminiscence_therapy/presentation/screens/therapy_feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../memories/domain/entities/memory_model.dart';
import '../../domain/entities/therapy_outline.dart';

class PlayTherapyScreen extends StatefulWidget {
  final TherapyOutline therapyOutline;
  final Memory memory;

  const PlayTherapyScreen({super.key, required this.therapyOutline, required this.memory});

  @override
  PlayTherapyScreenState createState() => PlayTherapyScreenState();
}

class PlayTherapyScreenState extends State<PlayTherapyScreen> {
  late TherapyOutline therapyOutline;
  late AudioPlayer audioPlayer;
  late int currentStep;
  bool isAudioPlaying = false;
  bool isSlideshowPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    therapyOutline = widget.therapyOutline;
    currentStep = 0;
    audioPlayer = AudioPlayer();

    audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        currentPosition = position;
      });
    });

    audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        totalDuration = duration;
      });
    });
  }

  void _playAudio(String audioUrl) async {
    if (audioUrl.isNotEmpty) {
      await audioPlayer.play(UrlSource(audioUrl));
      setState(() {
        isAudioPlaying = true;
      });
    }
  }

  void _pauseAudio() async {
    await audioPlayer.pause();
    setState(() {
      isAudioPlaying = false;
    });
  }

  void _seekAudio(Duration position) {
    audioPlayer.seek(position);
  }

  void _nextStep() {
    if (currentStep < therapyOutline.steps!.length - 1) {
      setState(() {
        currentStep++;
      });
      _resetPlayerForNextStep();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _resetPlayerForNextStep();
    }
  }

  void _resetPlayerForNextStep() {
    final step = therapyOutline.steps![currentStep];
    _playAudio(step.audioUrl ?? '');
    setState(() {
      currentPosition = Duration.zero;
      isAudioPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (therapyOutline.steps!.isEmpty) {
      return const Center(child: Text("No steps available"));
    }

    final currentStepData = therapyOutline.steps![currentStep];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Therapy'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentStep == 0) ...[
                Text(
                  widget.memory.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.memory.description ?? 'No description',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
              ],

              if (currentStepData.type == StepType.normal) ...[
                Text(
                  currentStepData.description,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
              ],

              if (currentStepData.mediaUrls.isNotEmpty) ...[
                CarouselSlider(
                  options: CarouselOptions(
                    autoPlay: currentStepData.mediaUrls.length > 1,
                    autoPlayInterval: const Duration(seconds: 5),
                    autoPlayAnimationDuration: const Duration(seconds: 2),
                    enlargeCenterPage: true,
                    aspectRatio: 1.0,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: currentStepData.mediaUrls.length > 1,
                  ),
                  items: currentStepData.mediaUrls.map((mediaUrl) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Image.network(mediaUrl, fit: BoxFit.cover);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],


              // Show Slider if totalDuration is available
              if (totalDuration != Duration.zero) ...[
                Slider(
                  value: currentPosition.inSeconds.toDouble(),
                  min: 0,
                  max: totalDuration.inSeconds.toDouble(),
                  onChanged: (value) {
                    _seekAudio(Duration(seconds: value.toInt()));
                  },
                ),
              ],
              const SizedBox(height: 20),

              // Display current time and total duration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(currentPosition),
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    _formatDuration(totalDuration),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentStepData.type != StepType.introduction) ...[
                    ElevatedButton(
                      onPressed: _previousStep,
                      child: const Text('Previous'),
                    ),
                  ] else ...[
                    const SizedBox(width: 100),
                  ],

                  // Large Play Button in the middle
                  Center(
                    child: GestureDetector(
                      onTap: isAudioPlaying ? _pauseAudio : () => _playAudio(currentStepData.audioUrl!),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          isAudioPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),

                  // Next Button
                  ElevatedButton(
                    onPressed: currentStepData.type == StepType.conclusion
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TherapyFeedbackScreen(
                            therapyOutline: therapyOutline,
                        )),
                      );
                    }
                        : _nextStep,
                    child: Text(currentStepData.type == StepType.conclusion
                        ? 'Finish'
                        : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
