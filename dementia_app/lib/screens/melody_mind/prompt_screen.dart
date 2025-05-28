import 'dart:convert';

import 'package:dementia_app/melody_mind/components/age_selector.dart';
import 'package:dementia_app/melody_mind/components/scrolling_text.dart';
import 'package:dementia_app/screens/melody_mind/music_player_screen.dart';
import 'package:dementia_app/screens/melody_mind/random_circles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class PromptScreen extends StatefulWidget {
  final VoidCallback showHomeScreen;
  const PromptScreen({super.key, required this.showHomeScreen});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  // Genre list
  final List<String> genres = [
    '🎺 Jazz',
    '🎸 Rock',
    '🌴 Reggae',
    '🥁 Baila',
    '🎧 Hip-Pop',
    '🎼 Classical',
    '🌾 Folk',
    '🎤 R&B',
  ];

  // Selected genres list
  final Set<String> _selectedGenres = {};

  // Selected mood
  String? _selectedMood;

  // Selected mood image
  String? _selectedMoodImage;

  // Playlist
  List<Map<String, String>> _playlist = [];

  // Loading state
  bool _isLoading = false;

  int _userAge = 55;

  // Function for selected genre(s)
  void _onGenreTap(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  // Function to submit mood and genres and fetch playlist
  Future<void> _submitSelections() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mood'),
        ),
      );
      return;
    }

    // Clean genres by removing emoji icons
    final cleanedGenres = _selectedGenres.map((genre) {
      // Split by space and remove the first part (emoji)
      final parts = genre.split(' ');
      if (parts.length > 1) {
        // Join everything after the emoji
        return parts.sublist(1).join(' ');
      }
      return genre; // Return original if no space found
    }).toList();

    setState(() {
      _isLoading = true;
    });

    // Construct the prompt text using the selected mood and genres ( more optimize for Sinhala )
    final promptText =
        'Generate a single Sinhala music playlist for a dementia patient aged "${_userAge.toString()}". '
        'The user-selected mood is "$_selectedMood" and the genres provided are ${cleanedGenres.join(", ")}. '
        'Even if the input mood is negative, please recommend only optimistic and uplifting songs that can help improve their mood. '
        'Ensure songs are appropriate for a patient in the mentioned age group. '
        'IMPORTANT: Format your response with EXACTLY one song per line. '
        'Each line MUST follow this exact format: "Artist - Title" with a single hyphen between artist and title. '
        'Do not include numbers, bullet points, or any other characters before each line. '
        'Do not include any additional text, explanations, or headers. '
        'Example of correct format: '
        'Nanda Malini - Sathuta Mage Adare\n'
        'Amaradeva - Sasara Wasanathuru\n'
        'Provide exactly 5 songs in this format.';

    print(promptText);

    // API call to get playlist recommendations ( Comment for now )
    // final response = await http.post(
    //   Uri.parse('https://api.openai.com/v1/chat/completions'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer  ',
    //   },
    //   body: jsonEncode(
    //     {
    //       "model": "gpt-3.5-turbo-0125",
    //       "messages": [
    //         {"role": "system", "content": promptText},
    //       ],
    //       'max_tokens': 250,
    //       'temperature': 0,
    //       "top_p": 1,
    //     },
    //   ),
    // );

    // Print
    // print(response.body);

    // if (response.statusCode == 200) {
    //   final data = json.decode(response.body);
    //   final choices = data['choices'] as List;
    //   final playlistString =
    //       choices.isNotEmpty ? choices[0]['message']['content'] as String : '';

    //   setState(() {
    //     // Split the playlist string by newline and then split each song by " - "
    //     _playlist = playlistString
    //         .split('\n')
    //         .where((line) => line.trim().isNotEmpty) // skip empty lines
    //         .map((song) {
    //       final parts = song.split(' - ');
    //       if (parts.length >= 2) {
    //         return {'artist': parts[0].trim(), 'title': parts[1].trim()};
    //       } else {
    //         // Try alternative delimiters if hyphen isn't found
    //         final altParts = song.split(':');
    //         if (altParts.length >= 2) {
    //           return {
    //             'artist': altParts[0].trim(),
    //             'title': altParts[1].trim()
    //           };
    //         }
    //         // Handle the case where song format is not as expected
    //         return {'artist': 'Unknown Artist', 'title': 'Unknown Title'};
    //       }
    //     }).toList();
    //     _isLoading = false;
    //   });

    this._playlist.add(
        {'artist': 'Clarence Wijewardena', 'title': 'Malata Bambareku Se'});

    setState(() {
      _isLoading = false;
    });

    print(this._playlist);
    // } else {
    //     setState(() {
    //       _isLoading = false;
    //     });
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Failed to fetch playlist')),
    //   );
    // }
  }

  // Function to show the first column
  void _showFirstColumn() {
    setState(() {
      _playlist = [];
      _selectedGenres.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF330000),
              Color(0xFF000000),
            ],
          ),

          // Background image here
          image: DecorationImage(
            image: AssetImage(
              "assets/images/background.png",
            ),
            fit: BoxFit.cover,
          ),
        ),

        // Padding around contents
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0, left: 16.0, right: 16.0),
          child: _isLoading
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    height: 50.0,
                    width: 50.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xFF000000),
                    ),
                  ),
                )
              : _playlist.isEmpty
                  ?
                  // First Columns starts here
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First expanded for random circles for moods
                        Expanded(
                          flex: 2,
                          child: RandomCircles(
                            onMoodSelected: (mood, image) {
                              _selectedMood = mood;
                              _selectedMoodImage = image;
                            },
                          ),
                        ),

                        // Age selector
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: AgeSelector(
                            initialAge: _userAge,
                            onAgeSelected: (age) {
                              setState(() {
                                _userAge = age;
                              });
                            },
                          ),
                        ),
                        // Second expanded for various genres and submit button
                        Expanded(
                          flex: 2,
                          // Padding at the top of various genres and submit button in a column
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20.0),

                            // Column starts here
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Genre text here
                                Text(
                                  'Genre',
                                  style: GoogleFonts.inter(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFFFFFF)
                                        .withOpacity(0.8),
                                  ),
                                ),

                                // Padding around various genres in a wrap
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10.0,
                                    right: 10.0,
                                    top: 5.0,
                                  ),

                                  // Wrap starts here
                                  child: StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setState) {
                                      return Wrap(
                                        children: genres.map((genre) {
                                          final isSelected =
                                              _selectedGenres.contains(genre);
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (_selectedGenres
                                                    .contains(genre)) {
                                                  _selectedGenres.remove(genre);
                                                } else {
                                                  _selectedGenres.add(genre);
                                                }
                                              });
                                            },

                                            // Container with border around each genre
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(3.0),
                                              margin: const EdgeInsets.only(
                                                  right: 4.0, top: 4.0),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                                border: Border.all(
                                                  width: 0.4,
                                                  color: const Color(0xFFFFFFFF)
                                                      .withOpacity(0.8),
                                                ),
                                              ),

                                              // Container for each genre
                                              child: Container(
                                                padding: const EdgeInsets.only(
                                                  left: 16.0,
                                                  right: 16.0,
                                                  top: 8.0,
                                                  bottom: 8.0,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFF0000FF)
                                                      : const Color(0xFFFFFFFF)
                                                          .withOpacity(0.8),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                ),

                                                // Text for each genre
                                                child: Text(
                                                  genre,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14.0,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFFFFFFFF)
                                                        : const Color(
                                                            0xFF000000),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                  // Wrap ends here
                                ),

                                // Padding around the submit button here
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 40.0,
                                    left: 10.0,
                                    right: 10.0,
                                  ),

                                  // Container for submit button in GestureDetector
                                  child: GestureDetector(
                                    onTap: _submitSelections,

                                    // Container for submit button
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15.0),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        color: const Color(0xFFFFCCCC),
                                      ),

                                      // Submit text centered
                                      child: Center(
                                        // Submit text here
                                        child: Text(
                                          'Submit',
                                          style: GoogleFonts.inter(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Column ends here
                          ),
                        ),
                      ],
                    )
                  // First Columns ends here

                  // Second Column starts here
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 40.0),
                                // Selected Mood image
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: _selectedMoodImage != null
                                      ? BoxDecoration(
                                          image: DecorationImage(
                                            image:
                                                AssetImage(_selectedMoodImage!),
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  padding: const EdgeInsets.all(3.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    border: Border.all(
                                      width: 0.4,
                                      color: const Color(0xFFFFFFFF)
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                      left: 16.0,
                                      right: 16.0,
                                      top: 8.0,
                                      bottom: 8.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF)
                                          .withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    // Selected mood text
                                    child: Text(
                                      _selectedMood ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF000000),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Container(
                            margin: const EdgeInsets.only(top: 20.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              border: const Border(
                                top: BorderSide(
                                  width: 0.4,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child:
                                // Playlist text here
                                Text(
                              'Playlist',
                              style: GoogleFonts.inter(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFFFFF).withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(0.0),
                            itemCount: _playlist.length,
                            itemBuilder: (context, index) {
                              final song = _playlist[index];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MusicPlayerScreen(
                                        song: {
                                          'artist': song['artist']!,
                                          'title': song['title']!
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16.0,
                                    right: 16.0,
                                    bottom: 20.0,
                                  ),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCCCC)
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFCCCC)
                                                .withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          child: Container(
                                            height: 65.0,
                                            width: 65.0,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFFFFF),
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              image: const DecorationImage(
                                                image: AssetImage(
                                                  "assets/images/sonnetlogo.png",
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16.0),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ScrollingText(
                                                text: song['artist']!,
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w300,
                                                  color: Color(0xFFFFFFFF),
                                                ),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.6,
                                              ),
                                              const SizedBox(height: 4.0),
                                              ScrollingText(
                                                text: song['title']!,
                                                style: const TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFFFFFFF),
                                                ),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.6,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          // Second column ends here
        ),
      ),
      floatingActionButton: _playlist.isEmpty
          ? Container()
          : Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCCCC).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0),
                ),
                onPressed: _showFirstColumn,
                child: const Icon(
                  Icons.add_outlined,
                ),
              ),
            ),
    );
  }
}
