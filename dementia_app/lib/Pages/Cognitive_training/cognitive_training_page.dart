import 'package:dementia_app/Pages/Cognitive_training/cognitive_training_stats_page.dart';
import 'package:dementia_app/Pages/Cognitive_training/matching_artist_search_page.dart';
import 'package:flutter/material.dart';
import 'package:dementia_app/Pages/Cognitive_training/cash_tally_page.dart';
import 'package:dementia_app/Pages/Cognitive_training/memory_card_image_upload_page.dart';
import '../../Components/user_avatar.dart';

class CognitiveTrainingPage extends StatelessWidget {
  const CognitiveTrainingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cognitive Training',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section with instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose an Activity',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap any activity below to begin training',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Activity buttons in a scrollable container
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Cash Tally Button
                        _buildEnhancedTrainingButton(
                          context: context,
                          icon: Icons.calculate,
                          label: 'Cash Tally',
                          description: 'Practice counting money and making change',
                          iconColor: Colors.green,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CashTallyPage(),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Memory Card Button - Enhanced
                        _buildEnhancedTrainingButton(
                          context: context,
                          icon: Icons.view_carousel,
                          label: 'Memory Card',
                          description: 'Find matching pairs of cards',
                          iconColor: Colors.orange,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MemoryCardImageUploadPage(),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Matching Artist Button
                        _buildEnhancedTrainingButton(
                          context: context,
                          icon: Icons.people,
                          label: 'Matching Artist',
                          description: 'Listen music and find their creators',
                          iconColor: Colors.purple,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MatchingArtistSearchPage(),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Activity Stats Button
                        _buildEnhancedTrainingButton(
                          context: context,
                          icon: Icons.bar_chart,
                          label: 'Activity Stats',
                          description: 'View progress and performance data',
                          iconColor: Colors.blue,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StatsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced button design with description and better visual cues
  Widget _buildEnhancedTrainingButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon with background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: iconColor,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow indicator
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bottom navigation item with optional active state
  Widget _buildBottomNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.blue : Colors.grey[600],
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.grey[600],
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}