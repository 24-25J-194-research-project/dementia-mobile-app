import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Components/user_avatar.dart';
import 'matching_artist_activity_page.dart';
import 'add_music_page.dart';

class MatchingArtistSearchPage extends StatefulWidget {
  const MatchingArtistSearchPage({super.key});

  @override
  State<MatchingArtistSearchPage> createState() => _MatchingArtistSearchPageState();
}

class _MatchingArtistSearchPageState extends State<MatchingArtistSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _filteredSongs = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // This is a simple approach to list files from a public bucket
      // In a production app, you should use the Supabase SDK with proper authentication
      final response = await http.get(Uri.parse(
          'https://scffupiugkbxqtinuwqs.supabase.co/storage/v1/object/list/matching_artist_common_music/common_music_clips'));
      
      if (response.statusCode == 200) {
        final List<dynamic> files = json.decode(response.body);
        
        setState(() {
          _songs = files.map((file) {
            // Extract filename from path
            String fileName = file['name'] as String;
            
            // Clean up filename to use as title (remove .mp3 extension)
            String title = fileName.replaceAll('.mp3', '').replaceAll('_', ' ');
            
            return {
              'id': file['id'] ?? fileName,
              'title': title,
              'url': 'common_music_clips/$fileName',
              'fullPath': file['name'],
            };
          }).toList();
          
          _filteredSongs = List.from(_songs);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load songs: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading songs: $e';
        _isLoading = false;
      });
    }
  }

  void _filterSongs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = List.from(_songs);
      } else {
        _filteredSongs = _songs
            .where((song) =>
                song['title'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  // Create a simple random artist name for demo purposes
  String _getRandomArtistName() {
    final List<String> artists = [
      'Michael Jackson', 'Queen', 'Guns N\' Roses', 
      'Madonna', 'John Lennon', 'Elvis Presley',
      'Beyoncé', 'Taylor Swift', 'Ed Sheeran',
      'Adele', 'Justin Bieber', 'Ariana Grande'
    ];
    return artists[DateTime.now().millisecond % artists.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching Artist'),
        centerTitle: true,
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
                    child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search songs...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: _filterSongs,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 40),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddMusicPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Loading indicator or error message
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSongs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: _filteredSongs.isEmpty
                    ? const Center(
                        child: Text(
                          'No songs found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSongs,
                        child: ListView.builder(
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) {
                            final song = _filteredSongs[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 10.0),
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Icon(Icons.music_note, color: Colors.white),
                                  ),
                                  title: Text(
                                    song['title'],
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'MP3 File',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MatchingArtistActivityPage(
                                          song: song,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
