import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Components/user_avatar.dart';
import 'matching_artist_activity_page.dart';

class MatchingArtistSongSearchPage extends StatefulWidget {
  final Map<String, dynamic>? artist; // Make artist optional

  const MatchingArtistSongSearchPage({
    super.key,
    this.artist, // Optional artist parameter
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
  bool _showingFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    
    // Determine if we're showing favorites based on whether artist is null
    _showingFavorites = widget.artist == null;
    _loadSongs();
  }

  Future<void> _loadFavorites() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint('User not logged in');
        return;
      }
      
      final response = await supabase
          .from('favorites')
          .select('song_id')
          .eq('user_id', userId);
      
      setState(() {
        _favorites = Set.from(response.map((item) => item['song_id'] as String));
      });
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final supabase = Supabase.instance.client;
      
      // If showing favorites, load all favorite songs
      if (_showingFavorites) {
        await _loadAllFavoriteSongs();
        return;
      }
      
      // Otherwise, load songs for the specific artist
      if (widget.artist != null) {
        final artistPath = widget.artist!['path'];
        final storageResponse = await supabase
            .storage
            .from('matching_artist_common_music')
            .list(path: artistPath);

        setState(() {
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
              'artist': widget.artist!['name'],
            };
          }).toList();

          _filteredSongs = List.from(_songs);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No artist selected';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading songs: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadAllFavoriteSongs() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint('User not logged in');
        return;
      }
      
      // Get all favorite song details
      final response = await supabase
          .from('favorites')
          .select('song_id, artist_id')
          .eq('user_id', userId);
      
      // Convert response to song format
      List<Map<String, dynamic>> favoriteSongs = [];
      
      for (var favorite in response) {
        final songId = favorite['song_id'] as String;
        final artistId = favorite['artist_id'] as String;
        
        // Get artist folder name from artistId
        final artistName = artistId.replaceAll('_', ' ');
        final title = songId.replaceAll('.mp3', '').replaceAll('_', ' ');
        
        favoriteSongs.add({
          'id': songId,
          'title': title,
          'url': 'common_music_clips/$artistId/$songId',
          'artist': artistName,
        });
      }
      
      setState(() {
        _songs = favoriteSongs;
        _filteredSongs = List.from(_songs);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading favorite songs: $e';
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

  Future<void> _toggleFavorite(String songId, String artistId) async {
    final isFavorite = !_favorites.contains(songId);
    
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint('User not logged in');
        return;
      }
      
      if (isFavorite) {
        // Add to favorites
        await supabase.from('favorites').insert({
          'user_id': userId,
          'song_id': songId,
          'artist_id': artistId,
          'created_at': DateTime.now().toIso8601String(),
        });
        setState(() {
          _favorites.add(songId);
        });
      } else {
        // Remove from favorites
        await supabase
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('song_id', songId);
        setState(() {
          _favorites.remove(songId);
          
          // If we're in favorites view, remove this song from the list
          if (_showingFavorites) {
            _filteredSongs.removeWhere((song) => song['id'] == songId);
            _songs.removeWhere((song) => song['id'] == songId);
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorites: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showingFavorites 
            ? 'Favorite Songs' 
            : widget.artist != null 
                ? '${widget.artist!['name']} Songs' 
                : 'Songs'),
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.music_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showingFavorites
                                  ? 'No favorite songs found'
                                  : 'No songs found',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadFavorites();
                          await _loadSongs();
                        },
                        child: ListView.builder(
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) {
                            final song = _filteredSongs[index];
                            final isFavorite = _favorites.contains(song['id']);
                            final artistId = widget.artist != null 
                                ? widget.artist!['id'] 
                                : song['url'].toString().split('/')[1]; // Extract from path

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
                                    'Artist: ${song['artist']}',
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
                                    onPressed: () => _toggleFavorite(song['id'], artistId),
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