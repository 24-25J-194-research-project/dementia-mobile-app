import 'package:dementia_app/Pages/Cognitive_training/cognitive_training_page.dart';
// import 'package:dementia_app/melody_mind/components/toggle_page.dart';
import 'package:flutter/material.dart';
import '../Components/dashboard_button.dart';
import '../Components/user_avatar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 4,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text(
                //   'Welcome to Memory Bloom',
                //   style: TextStyle(
                //     fontSize: 24,
                //     fontWeight: FontWeight.w400,
                //     color: Colors.black,
                //   ),
                // ),
                // const Text(
                //   'Select an activity to begin',
                //   style: TextStyle(
                //     fontSize: 20,
                //     color: Colors.black,
                //     fontWeight: FontWeight.w300,
                //   ),
                // ),
                const SizedBox(height: 24),
                
                // App Icon centered
                Center(
                  child: Image.asset(
                    'assets/app_icon.png',
                    height: 120,
                    width: 120,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    // Fix for overflow - add more height to each grid item
                    childAspectRatio: 0.8, // Lower aspect ratio gives more height
                    children: [
                      _buildEnhancedDashboardButton(
                        context: context,
                        icon: Icons.safety_check,
                        label: 'Memory Vault',
                        description: 'Store important memories',
                        color: Colors.green,
                        onPressed: () {},
                      ),
                      _buildEnhancedDashboardButton(
                        context: context,
                        icon: Icons.psychology,
                        label: 'Cognitive Training',
                        description: 'Play brain training exercises',
                        color: Colors.blue,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CognitiveTrainingPage(),
                            ),
                          );
                        },
                      ),
                      _buildEnhancedDashboardButton(
                        context: context,
                        icon: Icons.memory,
                        label: 'Memory Lane',
                        description: 'Journey through events',
                        color: Colors.orange,
                        onPressed: () {},
                      ),
                      _buildEnhancedDashboardButton(
                        context: context,
                        icon: Icons.music_note,
                        label: 'Melody Mind',
                        description: 'Music therapy activities',
                        color: Colors.purple,
                        onPressed: () { },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDashboardButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // Increased padding to give more room for content
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Added to minimize height requirements
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(  // Added Flexible to ensure text doesn't cause overflow
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible, // Added to prevent text overflow
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Flexible(  // Added Flexible to ensure text doesn't cause overflow
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible, // Added to prevent text overflow
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}