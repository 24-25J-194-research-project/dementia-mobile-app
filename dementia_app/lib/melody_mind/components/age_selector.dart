import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgeSelector extends StatefulWidget {
  final int initialAge;
  final Function(int) onAgeSelected;
  const AgeSelector(
      {super.key, required this.initialAge, required this.onAgeSelected});

  @override
  State<AgeSelector> createState() => _AgeSelectorState();
}

class _AgeSelectorState extends State<AgeSelector> {
  late int _selectedAge;

  @override
  void initState() {
    super.initState();
    _selectedAge = widget.initialAge;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Age text header
        Text(
          'Age',
          style: GoogleFonts.inter(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFFFFF).withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12.0),

        // Age selection container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              width: 0.4,
              color: const Color(0xFFFFFFFF).withOpacity(0.6),
            ),
          ),
          child: Column(
            children: [
              // Display selected age
              Text(
                '$_selectedAge years',
                style: GoogleFonts.inter(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFFFFF),
                ),
              ),

              const SizedBox(height: 16.0),

              // Slider for age selection
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFFFCCCC),
                  inactiveTrackColor: const Color(0xFFFFFFFF).withOpacity(0.3),
                  thumbColor: const Color(0xFFFFCCCC),
                  overlayColor: const Color(0xFFFFCCCC).withOpacity(0.3),
                  valueIndicatorColor: const Color(0xFFFFCCCC),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 20.0),
                ),
                child: Slider(
                  value: _selectedAge.toDouble(),
                  min: 55.0,
                  max: 95.0,
                  divisions: 40,
                  label: _selectedAge.toString(),
                  onChanged: (double value) {
                    setState(() {
                      _selectedAge = value.round();
                    });
                    widget.onAgeSelected(_selectedAge);
                  },
                ),
              ),

              // Age range indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '55',
                      style: GoogleFonts.inter(
                        fontSize: 12.0,
                        color: const Color(0xFFFFFFFF).withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '95',
                      style: GoogleFonts.inter(
                        fontSize: 12.0,
                        color: const Color(0xFFFFFFFF).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
