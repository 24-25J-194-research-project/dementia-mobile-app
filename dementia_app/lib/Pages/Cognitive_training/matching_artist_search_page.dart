import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Components/user_avatar.dart';
import 'matching_artist_song_search_page.dart';

class MatchingArtistSearchPage extends StatefulWidget {
  const MatchingArtistSearchPage({super.key});

  @override
  State<MatchingArtistSearchPage> createState() => _MatchingArtistSearchPageState();
}

class _MatchingArtistSearchPageState extends State<MatchingArtistSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _filteredArtists = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    // If showing favorites, navigate to the song search page with favorites
    if (_showFavorites) {
      _navigateToFavorites();
      return;
    }
    
    try {
      final supabase = Supabase.instance.client;
      final storageResponse = await supabase
          .storage
          .from('matching_artist_common_music')
          .list(path: 'common_music_clips');
      
      // Extract folder names from paths
      final Set<String> folderNames = {};
      
      for (var item in storageResponse) {
        if (!item.name.endsWith('.mp3')) {
          // This is likely a folder
          folderNames.add(item.name);
        }
      }
      
      setState(() {
        _artists = folderNames.map((folderName) {
          String artistName = folderName.replaceAll('_', ' ');
          
          return {
            'id': folderName,
            'name': artistName,
            'path': 'common_music_clips/$folderName',
          };
        }).toList();
        
        _applyFilters(_searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading artists: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredArtists = List.from(_artists);
      } else {
        _filteredArtists = _artists
            .where((artist) => artist['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  void _toggleFavoritesView() {
    setState(() {
      _showFavorites = !_showFavorites;
    });
    
    if (_showFavorites) {
      _navigateToFavorites();
    } else {
      _loadArtists();
    }
  }
  
  void _navigateToFavorites() {
    // Navigate to song search page showing all favorites
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MatchingArtistSongSearchPage(
          artist: null, // No specific artist
        ),
      ),
    ).then((_) {
      // When returning, reset to artists view
      setState(() {
        _showFavorites = false;
      });
      _loadArtists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching Artists'),
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search artists...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: _applyFilters,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    label: const Text('Favorites'),
                    onPressed: _toggleFavoritesView,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ],
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
                        onPressed: _loadArtists,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: _filteredArtists.isEmpty
                    ? const Center(
                        child: Text(
                          'No artists found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadArtists,
                        child: ListView.builder(
                          itemCount: _filteredArtists.length,
                          itemBuilder: (context, index) {
                            final artist = _filteredArtists[index];
                            
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
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                                  title: Text(
                                    artist['name'],
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: const Text(
                                    'Artist',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MatchingArtistSongSearchPage(
                                          artist: artist,
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

// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../Components/user_avatar.dart';
// import 'matching_artist_activity_page.dart';
// // import 'add_music_page.dart';

// class MatchingArtistSearchPage extends StatefulWidget {
//   const MatchingArtistSearchPage({super.key});

//   @override
//   State<MatchingArtistSearchPage> createState() => _MatchingArtistSearchPageState();
// }

// class _MatchingArtistSearchPageState extends State<MatchingArtistSearchPage> {
//   final TextEditingController _searchController = TextEditingController();
//   List<Map<String, dynamic>> _songs = [];
//   List<Map<String, dynamic>> _filteredSongs = [];
//   bool _isLoading = true;
//   String _errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     _loadSongs();
//   }

//   Future<void> _loadSongs() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });
    
//     try {
//       // Use Supabase SDK to list files in the bucket
//       final supabase = Supabase.instance.client;
//       final storageResponse = await supabase
//           .storage
//           .from('matching_artist_common_music')
//           .list(path: 'common_music_clips');
      
//       setState(() {
//         _songs = storageResponse.map((file) {
//           String fileName = file.name;
//           String title = fileName.replaceAll('.mp3', '').replaceAll('_', ' ');
          
//           return {
//             'id': file.id ?? fileName,
//             'title': title,
//             'url': 'common_music_clips/$fileName',
//             'fullPath': file.name,
//           };
//         }).toList();
        
//         _filteredSongs = List.from(_songs);
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error loading songs: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   void _filterSongs(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredSongs = List.from(_songs);
//       } else {
//         _filteredSongs = _songs
//             .where((song) =>
//                 song['title'].toString().toLowerCase().contains(query.toLowerCase()))
//             .toList();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Matching Artist'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         actions: const [
//           Padding(
//             padding: EdgeInsets.only(right: 8.0),
//             child: UserAvatar(),
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blue[100]!, Colors.blue[50]!],
//           ),
//         ),
//                     child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       decoration: InputDecoration(
//                         hintText: 'Search songs...',
//                         prefixIcon: const Icon(Icons.search),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                         ),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       onChanged: _filterSongs,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   IconButton(
//                     icon: const Icon(Icons.add_circle, size: 40),
//                     onPressed: () {
//                       // Navigator.push(
//                       //   context,
//                       //   MaterialPageRoute(
//                       //     builder: (context) => const AddMusicPage(),
//                       //   ),
//                       // );
//                     },
//                   ),
//                 ],
//               ),
//             ),
            
//             // Loading indicator or error message
//             if (_isLoading)
//               const Expanded(
//                 child: Center(
//                   child: CircularProgressIndicator(),
//                 ),
//               )
//             else if (_errorMessage.isNotEmpty)
//               Expanded(
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.error_outline, size: 48, color: Colors.red),
//                       const SizedBox(height: 16),
//                       Text(
//                         _errorMessage,
//                         style: const TextStyle(fontSize: 16),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 16),
//                       ElevatedButton(
//                         onPressed: _loadSongs,
//                         child: const Text('Retry'),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               Expanded(
//                 child: _filteredSongs.isEmpty
//                     ? const Center(
//                         child: Text(
//                           'No songs found',
//                           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                       )
//                     : RefreshIndicator(
//                         onRefresh: _loadSongs,
//                         child: ListView.builder(
//                           itemCount: _filteredSongs.length,
//                           itemBuilder: (context, index) {
//                             final song = _filteredSongs[index];
//                             return Padding(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 16.0, vertical: 8.0),
//                               child: Card(
//                                 elevation: 4,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(15),
//                                 ),
//                                 child: ListTile(
//                                   contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 20.0, vertical: 10.0),
//                                   leading: const CircleAvatar(
//                                     backgroundColor: Colors.blue,
//                                     child: Icon(Icons.music_note, color: Colors.white),
//                                   ),
//                                   title: Text(
//                                     song['title'],
//                                     style: const TextStyle(
//                                         fontSize: 18, fontWeight: FontWeight.bold),
//                                   ),
//                                   subtitle: const Text(
//                                     'MP3 File',
//                                     style: TextStyle(
//                                         fontSize: 14, color: Colors.grey),
//                                   ),
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => MatchingArtistActivityPage(
//                                           song: song,
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
// }