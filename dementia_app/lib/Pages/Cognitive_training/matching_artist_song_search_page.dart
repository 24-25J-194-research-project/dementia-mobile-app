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
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadSongs();
  }

  Future<void> _loadFavorites() async {
    try {
      // Get current user ID
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint('User not logged in');
        return;
      }
      
      // Get favorites from Supabase database
      final response = await supabase
          .from('favorites')
          .select('song_id')
          .eq('user_id', userId);
      
      setState(() {
        _favorites = Set.from(response.map((item) => item['song_id'] as String));
      });
    } catch (e) {
      // Handle error silently
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorite(String songId, bool isFavorite) async {
    try {
      // Get current user ID
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint('User not logged in');
        return;
      }
      
      if (isFavorite) {
        // Add to favorites in database
        await supabase.from('favorites').insert({
          'user_id': userId,
          'song_id': songId,
          'artist_id': widget.artist['id'],
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Remove from favorites in database
        await supabase
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('song_id', songId);
      }
    } catch (e) {
      // Handle error silently
      debugPrint('Error saving favorite: $e');
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
      var filteredList = _songs;
      
      // First filter by favorites if needed
      if (_showOnlyFavorites) {
        filteredList = filteredList
            .where((song) => _favorites.contains(song['id']))
            .toList();
      }
      
      // Then filter by search query
      if (query.isNotEmpty) {
        filteredList = filteredList
            .where((song) => song['title']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
      
      _filteredSongs = filteredList;
    });
  }

  void _toggleFavorite(String songId) {
    final isFavorite = !_favorites.contains(songId);
    
    setState(() {
      if (isFavorite) {
        _favorites.add(songId);
      } else {
        _favorites.remove(songId);
      }
      
      // Re-apply filters in case we're in favorites-only mode
      _filterSongs(_searchController.text);
    });
    
    _saveFavorite(songId, isFavorite);
  }
  
  void _toggleFavoritesFilter() {
    setState(() {
      _showOnlyFavorites = !_showOnlyFavorites;
      // Re-apply filters
      _filterSongs(_searchController.text);
    });
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
                    icon: Icon(
                      _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                      color: _showOnlyFavorites ? Colors.red : Colors.grey,
                      size: 30,
                    ),
                    onPressed: _toggleFavoritesFilter,
                    tooltip: _showOnlyFavorites ? 'Show all songs' : 'Show favorites only',
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
