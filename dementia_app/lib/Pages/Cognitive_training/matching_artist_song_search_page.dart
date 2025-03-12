import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Components/user_avatar.dart';
import 'matching_artist_activity_page.dart';

class MatchingArtistSongSearchPage extends StatefulWidget {
  final Map<String, dynamic> artist;

  const MatchingArtistSongSearchPage({
    super.key,
    required this.artist,
  });

  @override
  State<MatchingArtistSongSearchPage> createState() =>
      _MatchingArtistSongSearchPageState();
}

class _MatchingArtistSongSearchPageState
    extends State<MatchingArtistSongSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _filteredSongs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadSongs();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorites') ?? [];
      setState(() {
        _favorites = Set.from(favorites);
      });
    } catch (e) {
      // Handle error silently
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', _favorites.toList());
    } catch (e) {
      // Handle error silently
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final supabase = Supabase.instance.client;
      // Get the artist folder path from the artist data
      final artistPath = widget.artist['path'];

      // List all files in the artist folder
      final storageResponse = await supabase
          .storage
          .from('matching_artist_common_music')
          .list(path: artistPath);

      setState(() {
        // Filter only MP3 files and map them to a usable format
        _songs = storageResponse
            .where((file) => file.name.endsWith('.mp3'))
            .map((file) {
          String fileName = file.name;
          String title = fileName.replaceAll('.mp3', '').replaceAll('_', ' ');

          return {
            'id': fileName,
            'title': title,
            'url': '$artistPath/$fileName',
            'fullPath': file.name,
            'artist': widget.artist['name'],
          };
        }).toList();

        _filteredSongs = List.from(_songs);
        _isLoading = false;
      });
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
            .where((song) => song['title']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleFavorite(String songId) {
    setState(() {
      if (_favorites.contains(songId)) {
        _favorites.remove(songId);
      } else {
        _favorites.add(songId);
      }
    });
    _saveFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.artist['name']} Songs'),
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
            colors: [Colors.purple[100]!, Colors.purple[50]!],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSongs,
                        child: ListView.builder(
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) {
                            final song = _filteredSongs[index];
                            final isFavorite = _favorites.contains(song['id']);

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
                                    child: Icon(Icons.music_note,
                                        color: Colors.white),
                                  ),
                                  title: Text(
                                    song['title'],
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Artist: ${widget.artist['name']}',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color:
                                          isFavorite ? Colors.red : Colors.grey,
                                    ),
                                    onPressed: () =>
                                        _toggleFavorite(song['id']),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MatchingArtistActivityPage(
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
