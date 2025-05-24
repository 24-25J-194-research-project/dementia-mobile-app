import 'package:dementia_app/features/reminiscence_therapy/presentation/screens/therapy_feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../memories/domain/entities/memory_model.dart';
import '../../domain/entities/therapy_outline.dart';
import '../widgets/audio_player_widget.dart';

class PlayTherapyScreen extends StatefulWidget {
  final TherapyOutline therapyOutline;
  final Memory memory;

  const PlayTherapyScreen(
      {super.key, required this.therapyOutline, required this.memory});

  @override
  PlayTherapyScreenState createState() => PlayTherapyScreenState();
}

class PlayTherapyScreenState extends State<PlayTherapyScreen> {
  late TherapyOutline therapyOutline;
  late AudioPlayer _audioPlayer;
  late int currentStep;

  @override
  void initState() {
    super.initState();
    therapyOutline = widget.therapyOutline;
    currentStep = 0;
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _loadCurrentAudio();
  }

  Future<void> _loadCurrentAudio() async {
    final step = therapyOutline.steps![currentStep];
    if (step.audioUrl?.isNotEmpty == true) {
      try {
        await _audioPlayer.setUrl(step.audioUrl!);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('Error loading audio: $e');
      }
    }
  }

  void _nextStep() {
    if (currentStep < therapyOutline.steps!.length - 1) {
      _audioPlayer.stop();
      setState(() {
        currentStep++;
      });
      _loadCurrentAudio();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      _audioPlayer.stop();
      setState(() {
        currentStep--;
      });
      _loadCurrentAudio();
    }
  }

  void _navigateToFeedback() {
    _audioPlayer.stop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TherapyFeedbackScreen(
          therapyOutline: therapyOutline,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 160),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentStep == 0) ...[
                    Text(
                      widget.memory.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
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
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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
                        enableInfiniteScroll:
                            currentStepData.mediaUrls.length > 1,
                      ),
                      items: currentStepData.mediaUrls.map((mediaUrl) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Image.network(mediaUrl, fit: BoxFit.cover);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Fixed bottom audio player
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: AudioPlayerWidget(
                audioPlayer: _audioPlayer,
                audioUrl: currentStepData.audioUrl,
                onNext: currentStepData.type == StepType.conclusion
                    ? _navigateToFeedback
                    : _nextStep,
                onPrevious: _previousStep,
                showNext: currentStep < therapyOutline.steps!.length - 1 ||
                    currentStepData.type == StepType.conclusion,
                showPrevious: currentStep > 0,
                nextButtonText: currentStepData.type == StepType.conclusion
                    ? 'Finish'
                    : 'Next',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
