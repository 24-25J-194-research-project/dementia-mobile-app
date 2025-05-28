import 'package:dementia_app/melody_mind/components/user_avatar.dart';
import 'package:dementia_app/utils/appColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_app/screens/melody_mind/music_player_screen.dart';
import 'package:dementia_app/melody_mind/components/scrolling_text.dart';
import 'package:dementia_app/melody_mind/services/playlist_service.dart';

class MusicLibraryScreen extends StatefulWidget {
  final VoidCallback showHomeScreen;
  const MusicLibraryScreen({super.key, required this.showHomeScreen});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  //supabase client
  final supabase = Supabase.instance.client;
  final PlaylistService _playlistService = PlaylistService();

  //search controller
  final TextEditingController _searchController = TextEditingController();

  //track lists
  List<Map<String, dynamic>> _allTracks = [];
  List<Map<String, dynamic>> _filteredTracks = [];

  //playlist
  List<Map<String, dynamic>> _playlist = [];

  bool _isLoading = true;
  bool _isSearchActive = false;
  bool _isShowingPlaylist = false;
  bool _isAddingToPlaylist = false;
  bool _isRemovingFromPlaylist = false;
  Map<String, bool> _loadingTrackIds = {};

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTracksFromSupabase();
    _loadPlaylistFromSupabase();
  }

  Future<void> _loadPlaylistFromSupabase() async {
    try {
      final playlistTracks = await _playlistService.loadPlaylist();

      setState(() {
        _playlist = playlistTracks;
      });

      print('Loaded ${_playlist.length} tracks in playlist');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load playlist: $e';
      });
      print('Error loading playlist: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  //load tracks from Supabase
  Future<void> _loadTracksFromSupabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      //fetch tracks from music_tracks table
      final response = await supabase
          .from('music_tracks')
          .select('id, title, artist, bpm, duration, file_path')
          .order('title', ascending: true);

      setState(() {
        _allTracks = List<Map<String, dynamic>>.from(response);
        _filteredTracks = _allTracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tracks: $e';
        _isLoading = false;
      });
      print('Error loading tracks: $e');
    }
  }

  //search tracks
  void _searchTracks(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTracks = _allTracks;
        _isSearchActive = false;
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();

    setState(() {
      _filteredTracks = _allTracks.where((track) {
        final title = track['title']?.toString().toLowerCase() ?? '';
        final artist = track['artist']?.toString().toLowerCase() ?? '';

        return title.contains(lowerCaseQuery) ||
            artist.contains(lowerCaseQuery);
      }).toList();

      _isSearchActive = true;
    });
  }

  //add track to playlist
  Future<void> _addToPlaylist(Map<String, dynamic> track) async {
    //check if track is already in playlist
    final isAlreadyInPlaylist =
        _playlist.any((item) => item['id'] == track['id']);

    if (isAlreadyInPlaylist) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${track['title']} is already in your playlist')),
      );
      return;
    }

    setState(() {
      _loadingTrackIds[track['id'].toString()] = true;
    });

    try {
      //add to playlist
      await _playlistService.addTrack(track);

      //update local playlist state
      setState(() {
        _playlist.add(track);
        _loadingTrackIds.remove(track['id'].toString());
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${track['title']} to your playlist')),
      );
    } catch (e) {
      setState(() {
        _loadingTrackIds.remove(track['id'].toString());
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to playlist: $e')),
      );
      print('Error adding track to playlist: $e');
    }
  }

  //remove track from playlist
  Future<void> _removeFromPlaylist(Map<String, dynamic> track) async {
    setState(() {
      _loadingTrackIds[track['id'].toString()] = true;
    });

    try {
      await _playlistService.removeTrack(track['id'].toString());

      //update local playlist state
      setState(() {
        _playlist.removeWhere((item) => item['id'] == track['id']);
        _loadingTrackIds.remove(track['id'].toString());
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${track['title']} from your playlist')),
      );
    } catch (e) {
      setState(() {
        _loadingTrackIds.remove(track['id'].toString());
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove from playlist: $e')),
      );
      print('Error removing track from playlist: $e');
    }
  }

  //toggle track library and playlist
  void _togglePlaylistView() {
    setState(() {
      _isShowingPlaylist = !_isShowingPlaylist;

      if (_isShowingPlaylist) {
        _searchController.clear();
        _isSearchActive = false;
      }
    });
  }

  //navigate to music player screen
  void _navigateToMusicPlayer(Map<String, dynamic> track) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerScreen(
          song: {
            'artist': track['artist'],
            'title': track['title'],
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.deepBlue, AppColors.black],
          ),
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //header with title and toggle button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isShowingPlaylist ? 'Your Playlist' : 'Music Library',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isShowingPlaylist
                                ? Icons.library_music
                                : Icons.playlist_play,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlaylistView,
                        ),
                        const UserAvatar(),
                      ],
                    ),
                  ],
                ),

                //search bar (hidden in playlist view)
                if (!_isShowingPlaylist)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _searchTracks,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by title or artist...',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          suffixIcon: _isSearchActive
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchTracks('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                //playlist stats (only in playlist view)
                if (_isShowingPlaylist)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_playlist.length} song${_playlist.length != 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_playlist.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                            label: Text(
                              'Clear All',
                              style: GoogleFonts.inter(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () async {
                              try {
                                await _playlistService.clearPlaylist();
                                setState(() {
                                  _playlist = [];
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Playlist cleared')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Failed to clear playlist: $e')),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),

                //error message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Loading indicator
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),

                //no results message
                if (!_isLoading &&
                    !_isShowingPlaylist &&
                    _filteredTracks.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.music_off,
                            size: 60,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tracks found',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          if (_isSearchActive)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Try different search terms',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                //empty playlist message
                if (!_isLoading && _isShowingPlaylist && _playlist.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.playlist_add,
                            size: 60,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your playlist is empty',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextButton.icon(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primaryBlue,
                              ),
                              label: Text(
                                'Add songs from library',
                                style: GoogleFonts.inter(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onPressed: _togglePlaylistView,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                //track list
                if (!_isLoading &&
                    ((!_isShowingPlaylist && _filteredTracks.isNotEmpty) ||
                        (_isShowingPlaylist && _playlist.isNotEmpty)))
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8.0),
                      itemCount: _isShowingPlaylist
                          ? _playlist.length
                          : _filteredTracks.length,
                      itemBuilder: (context, index) {
                        final track = _isShowingPlaylist
                            ? _playlist[index]
                            : _filteredTracks[index];

                        return GestureDetector(
                          onTap: () => _navigateToMusicPlayer(track),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // Track artwork or placeholder
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        image: const DecorationImage(
                                          image: AssetImage(
                                              "assets/images/sonnetlogo.png"),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    //track info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ScrollingText(
                                            text: track['title'] ??
                                                'Unknown Title',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.5,
                                          ),

                                          const SizedBox(height: 4),

                                          ScrollingText(
                                            text: track['artist'] ??
                                                'Unknown Artist',
                                            style: GoogleFonts.inter(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 14,
                                            ),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.5,
                                          ),

                                          // Display duration if available
                                          if (track['duration'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 4.0),
                                              child: Text(
                                                '${track['duration']}',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    //bPM indicator if available
                                    if (track['bpm'] != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBlue
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${track['bpm']} BPM',
                                            style: GoogleFonts.inter(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),

                                    //action button
                                    _loadingTrackIds[track['id'].toString()] ==
                                            true
                                        ? Container(
                                            width: 24,
                                            height: 24,
                                            padding: EdgeInsets.all(4),
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryBlue,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : IconButton(
                                            icon: Icon(
                                              _isShowingPlaylist
                                                  ? Icons.remove_circle_outline
                                                  : Icons.add_circle_outline,
                                              color: AppColors.primaryBlue,
                                            ),
                                            onPressed: () {
                                              if (_isShowingPlaylist) {
                                                _removeFromPlaylist(track);
                                              } else {
                                                _addToPlaylist(track);
                                              }
                                            },
                                          ),
                                  ],
                                ),
                              ),
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
      ),
      floatingActionButton: (!_isShowingPlaylist && _playlist.isNotEmpty)
          ? FloatingActionButton(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              onPressed: _togglePlaylistView,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.playlist_play),
                  if (_playlist.length > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_playlist.length}',
                          style: GoogleFonts.inter(
                            color: AppColors.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
    );
  }
}
