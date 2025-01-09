import 'package:dementia_app/Pages/Cognitive_training/matching_artist_search_page.dart';
import 'package:flutter/material.dart';
import 'package:dementia_app/Pages/Cognitive_training/cash_tally_page.dart';
import 'package:dementia_app/Pages/Cognitive_training/memory_card_image_upload_page.dart';
import '../../../Components/user_avatar.dart';
import '../../../Components/Cognitive_Training/cognitive_training_button.dart';

class CognitiveTrainingPage extends StatelessWidget {
  const CognitiveTrainingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cognitive Training'),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: UserAvatar(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.blue[50]!],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                TrainingButton(
                  icon: Icons.calculate,
                  label: 'Cash Tally',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  onPressed: () {
                    },
                  ),
                const SizedBox(height: 20),
                TrainingButton(
                  icon: Icons.view_carousel,
                  label: 'Memory Card',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  onPressed: () {
   
                  },
                ),
                const SizedBox(height: 20),
                TrainingButton(
                  icon: Icons.people,
                  label: 'Matching Artist',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  onPressed: () {
                    
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}