import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RandomCircles extends StatefulWidget {
  final Function(String?, String?) onMoodSelected;
  const RandomCircles({super.key, required this.onMoodSelected});

  @override
  State<RandomCircles> createState() => _RandomCirclesState();
}

class _RandomCirclesState extends State<RandomCircles> {
  final Random random = Random();
  final ValueNotifier<String?> _selectedMood = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _selectedMoodImage =
      ValueNotifier<String?>(null);

  final List<Map<String, String>> moodData = [
    {'mood': 'Happy', 'image': 'assets/images/happy.png'},
    {'mood': 'Fear', 'image': 'assets/images/heartbroken.png'},
    {'mood': 'Relaxed', 'image': 'assets/images/relaxed.png'},
    {'mood': 'Sad', 'image': 'assets/images/anxious.png'},
    {'mood': 'Angry', 'image': 'assets/images/angry.png'},
    {'mood': 'Surprise', 'image': 'assets/images/energetic.png'},
    // {'mood': 'Grateful', 'image': 'assets/images/grateful.png'},
    // {'mood': 'Romance', 'image': 'assets/images/romance.png'},
  ];

  // Generate fixed colors for each mood to maintain consistency
  final List<Color> predefinedColors = [
    const Color(0xFF8A64B1), // Purple
    const Color(0xFF4FAA83), // Green
    const Color(0xFF5D9CEC), // Blue
    const Color(0xFFE9B35F), // Yellow
    const Color(0xFFE57373), // Red
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate rows needed based on number of moods
    final int itemsPerRow = 3;
    final int numRows = (moodData.length / itemsPerRow).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal size based on available height and width
        final double availableWidth = constraints.maxWidth;
        final double availableHeight =
            constraints.maxHeight - 25; // Account for header

        // Calculate max height per row
        final double maxHeightPerRow = availableHeight / numRows;

        // Calculate item width accounting for spacing
        final double spacing = 8.0;
        final double itemWidth =
            (availableWidth - (spacing * (itemsPerRow - 1))) / itemsPerRow;

        // Determine circle size based on whichever constraint is tighter
        final double maxCircleSizeFromWidth = itemWidth * 0.7;
        final double maxCircleSizeFromHeight =
            maxHeightPerRow * 0.65; // Leave room for label
        final double circleSize =
            maxCircleSizeFromWidth < maxCircleSizeFromHeight
                ? maxCircleSizeFromWidth
                : maxCircleSizeFromHeight;

        // Font size proportional to circle size, but with a minimum
        final double fontSize = (circleSize * 0.14).clamp(10.0, 14.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 5.0, left: 4.0),
              child: Text(
                'Mood',
                style: GoogleFonts.inter(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFFFFF).withOpacity(0.8),
                ),
              ),
            ),

            // Grid layout - using Expanded to take available space
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: itemsPerRow,
                  childAspectRatio: 1.0, // Square cells
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: moodData.length,
                itemBuilder: (context, index) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: _selectedMood,
                    builder: (context, selectedMood, child) {
                      final bool isSelected =
                          selectedMood == moodData[index]['mood'];
                      final Color borderColor = isSelected
                          ? const Color(0xFF0000FF)
                          : Colors.transparent;
                      final Color textBgColor = isSelected
                          ? const Color(0xFF0000FF)
                          : const Color(0xFF000000).withOpacity(0.5);

                      return GestureDetector(
                        onTap: () {
                          _selectedMood.value =
                              isSelected ? null : moodData[index]['mood'];
                          _selectedMoodImage.value =
                              isSelected ? null : moodData[index]['image'];
                          widget.onMoodSelected(
                              _selectedMood.value, _selectedMoodImage.value);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Circle with image
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: borderColor,
                                  width: 2.0,
                                ),
                              ),
                              child: Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  color: predefinedColors[
                                      index % predefinedColors.length],
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Image.asset(
                                    moodData[index]['image']!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),

                            // Mood name text - sized appropriately
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 1.0,
                                ),
                                decoration: BoxDecoration(
                                  color: textBgColor,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  moodData[index]['mood']!,
                                  style: GoogleFonts.inter(
                                    fontSize: fontSize,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
