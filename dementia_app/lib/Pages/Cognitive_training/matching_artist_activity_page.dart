import 'package:dementia_app/Shared/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Components/user_avatar.dart';

class MatchingArtistActivityPage extends StatefulWidget {
  final Map<String, dynamic> song;

  const MatchingArtistActivityPage({
    super.key,
    required this.song,
  });

  @override
  State<MatchingArtistActivityPage> createState() =>
      _MatchingArtistActivityPageState();
}

class _MatchingArtistActivityPageState
    extends State<MatchingArtistActivityPage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _selectedArtist = '';
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _shuffledArtists = [];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializePlayer();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final supabase = Supabase.instance.client;
      
      // Get all artist folders from common_music_clips
      final response = await supabase
          .storage
          .from('matching_artist_common_music')
          .list(path: 'common_music_clips');
      
      // Filter to get only directories
      final List<String> artistFolders = [];
      
      for (var item in response) {
        if (!item.name.endsWith('.mp3')) {
          artistFolders.add(item.name);
        }
      }
      
      // Create artist objects with image URLs
      _artists = artistFolders.map((folderName) {
        String artistName = folderName.replaceAll('_', ' ');
        String imageUrl = '${Constants.artistImageUrl}/$folderName.jpg';
        
        return {
          'name': artistName,
          'image': imageUrl,
          'folder': folderName,
        };
      }).toList();
      
      //shuffle and make sure correct artist is included
      _shuffleArtists();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading artists: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shuffleArtists() {
    //create a copy of the artists list and shuffle it
    _shuffledArtists = List.from(_artists);
    _shuffledArtists.shuffle();
    
    //get the current song's artist
    final correctArtistName = widget.song['artist'];
    
    //check if the correct artist is in our list
    final correctArtistIndex = _shuffledArtists.indexWhere(
        (artist) => artist['name'] == correctArtistName);
    
    //if the correct artist is not in the first 5 or not found, replace one with the correct artist
    if (correctArtistIndex >= 5 || correctArtistIndex == -1) {
      //find the correct artist in our full list
      final correctArtistInList = _artists.indexWhere(
          (artist) => artist['name'] == correctArtistName);
      
      if (correctArtistInList != -1) {
        // Replace the first element with the correct artist
        _shuffledArtists[0] = _artists[correctArtistInList];
      } else {
        // If not found in our list, create a custom entry with default image
        final artistFolder = correctArtistName.replaceAll(' ', '_');
        _shuffledArtists[0] = {
          'name': correctArtistName,
          'image': 'https://scffupiugkbxqtinuwqs.supabase.co/storage/v1/object/public/matching_artist_common_music/artist_images/$artistFolder.jpg',
          'folder': artistFolder,
        };
      }
    }
    
    // Only take the first 5 artists
    _shuffledArtists = _shuffledArtists.take(5).toList();
  }

  Future<void> _initializePlayer() async {
    try {
      // Supabase storage URL
      final String songUrl =
          'https://scffupiugkbxqtinuwqs.supabase.co/storage/v1/object/public/matching_artist_common_music/${widget.song['url']}';

      await _audioPlayer.setUrl(songUrl);
      _audioPlayer.playerStateStream.listen((state) {
        if (state.playing != _isPlaying) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      _audioPlayer.durationStream.listen((d) {
        setState(() {
          _duration = d ?? Duration.zero;
        });
      });

      _audioPlayer.positionStream.listen((p) {
        setState(() {
          _position = p;
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing player: $e');
      }
    }
  }

  void _playPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  void _resetActivity() {
    setState(() {
      _isAnswered = false;
      _selectedArtist = '';
      _position = Duration.zero;
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.pause();
      _isPlaying = false;
    });
    _shuffleArtists();
  }
  
  void _showResultDialog(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isCorrect ? 'Correct!' : 'Incorrect!',
            style: TextStyle(
              color: isCorrect ? Colors.green : const Color.fromARGB(255, 255, 106, 95),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: isCorrect
              ? const Text('You selected the right artist. Well done!')
              : Text('The correct artist is ${widget.song['artist']}.'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _resetActivity(); // Reset the activity
              },
              child: const Text('Try Again'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to song search page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? Colors.green : const Color.fromARGB(255, 255, 106, 95),
                foregroundColor: Colors.white,
              ),
              child: Text(isCorrect ? 'OK' : 'Try Another'),
            ),
          ],
        );
      },
    );
  }

  void _checkAnswer(String selectedArtist) {
    setState(() {
      _selectedArtist = selectedArtist;
      _isAnswered = true;
      _isCorrect = selectedArtist == widget.song['artist'];
    });

    // Add haptic feedback
    if (_isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.vibrate();
    }

    // Show result with a small delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _showResultDialog(_isCorrect);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Who\'s the Artist?'),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Music Player Card
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Play Button
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                size: 60,
                                color: Colors.blue,
                              ),
                              onPressed: _playPause,
                            ),
                            const SizedBox(height: 16),
                            
                            // Progress Bar
                            Slider(
                              value: _position.inSeconds.toDouble(),
                              min: 0,
                              max: _duration.inSeconds.toDouble() == 0 ? 1 : _duration.inSeconds.toDouble(),
                              onChanged: (value) {
                                final position = Duration(seconds: value.toInt());
                                _audioPlayer.seek(position);
                              },
                              activeColor: Colors.blue,
                            ),
                            
                            // Duration Display
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(_position)),
                                  Text(_formatDuration(_duration)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Question
                    const Text(
                      'Who is the artist of this song?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Artist Options
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _shuffledArtists.length,
                        itemBuilder: (context, index) {
                          final artist = _shuffledArtists[index];
                          final isSelected = _selectedArtist == artist['name'];
                          final isCorrectArtist = widget.song['artist'] == artist['name'];
                          
                          Color borderColor = Colors.transparent;
                          if (_isAnswered) {
                            if (isSelected && isCorrectArtist) {
                              borderColor = Colors.green;
                            } else if (isSelected && !isCorrectArtist) {
                              borderColor = Colors.red;
                            } else if (isCorrectArtist) {
                              borderColor = Colors.green;
                            }
                          }
                          
                          return GestureDetector(
                            onTap: _isAnswered ? null : () => _checkAnswer(artist['name']),
                            child: Card(
                              elevation: isSelected ? 8 : 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(
                                  color: borderColor,
                                  width: 3,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          artist['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            // Use a placeholder if image fails to load
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      artist['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}