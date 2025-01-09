import 'package:dementia_app/Pages/Cognitive_training/cognitive_training_page.dart';
import 'package:flutter/material.dart';
import '../Components/dashboard_button.dart';
import '../Components/user_avatar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DashboardButton(
                      icon: Icons.safety_check,
                      label: 'Memory Vault',
                      onPressed: () {},
                    ),
                    const SizedBox(width: 20),
                    DashboardButton(
                      icon: Icons.psychology,
                      label: 'Cognitive Training',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CognitiveTrainingPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DashboardButton(
                      icon: Icons.memory,
                      label: 'Memory Lane',
                      onPressed: () {},
                    ),
                    const SizedBox(width: 20),
                    DashboardButton(
                      icon: Icons.music_note,
                      label: 'Melody Mind',
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}