import 'package:flutter/material.dart';

import '../../data/repositories/therapy_feedback_repository_impl.dart';
import '../../domain/entities/therapy_feedback.dart';
import '../../domain/entities/therapy_outline.dart';
import '../../domain/use_cases/therapy_feedback_use_case.dart';

const Map<String, String> emotionLabels = {
  "anger": "Anger",
  "disgust": "Disgust",
  "fear": "Fear",
  "joy": "Joy",
  "neutral": "Neutral",
  "sadness": "Sadness",
  "surprise": "Surprise",
};

const Map<String, IconData> emotionIcons = {
  "anger": Icons.sentiment_very_dissatisfied,
  "disgust": Icons.sentiment_dissatisfied,
  "fear": Icons.sentiment_very_dissatisfied_outlined,
  "joy": Icons.sentiment_very_satisfied,
  "neutral": Icons.sentiment_neutral,
  "sadness": Icons.sentiment_very_dissatisfied,
  "surprise": Icons.sentiment_satisfied_sharp,
};

class TherapyFeedbackScreen extends StatefulWidget {
  final TherapyOutline therapyOutline;

  const TherapyFeedbackScreen({super.key, required this.therapyOutline});

  @override
  TherapyFeedbackScreenState createState() => TherapyFeedbackScreenState();
}

class TherapyFeedbackScreenState extends State<TherapyFeedbackScreen> {
  double rating = 3.0;
  List<String> selectedEmotions = [];
  TextEditingController commentController = TextEditingController();

  // Function to toggle emotion selection
  void toggleEmotion(String emotion) {
    setState(() {
      if (selectedEmotions.contains(emotion)) {
        selectedEmotions.remove(emotion);
      } else {
        selectedEmotions.add(emotion);
      }
    });
  }

  void _submitFeedback(List<String> selectedEmotions, double rating, String? comments) async {
    try {
      final feedback = TherapyFeedback(
        patientId: widget.therapyOutline.patientId,
        memoryId: widget.therapyOutline.memoryId,
        therapyOutlineId: widget.therapyOutline.id,
        selectedEmotions: selectedEmotions,
        rating: rating,
        comments: comments,
      );

      // Use the use case to save feedback
      final useCase = TherapyFeedbackUseCase(TherapyFeedbackRepositoryImpl());
      await useCase.saveFeedback(feedback);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback saved!')));
    } catch (e) {
      // Handle error saving feedback
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Therapy Session'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How do you feel about the therapy session?',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),

              // Emotion selection with large face icons and checkboxes
              Wrap(
                spacing: 16,
                children: emotionLabels.keys.map((emotion) {
                  return GestureDetector(
                    onTap: () => toggleEmotion(emotion),
                    child: Column(
                      children: [
                        Icon(
                          emotionIcons[emotion],
                          size: 60,
                          color: selectedEmotions.contains(emotion)
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emotionLabels[emotion]!,
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedEmotions.contains(emotion)
                                ? Colors.blue
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Slider to rate the therapy
              const Text(
                'How would you rate the therapy session (1-5)?',
                style: TextStyle(fontSize: 16),
              ),
              Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (value) {
                  setState(() {
                    rating = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Rating: ${rating.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Optional comment field
              const Text(
                'Additional Comments (optional):',
                style: TextStyle(fontSize: 16),
              ),
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write your comments here...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Save button (no behavior for now, just pop back)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _submitFeedback(selectedEmotions, rating, commentController.text);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
