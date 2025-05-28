import 'package:dementia_app/utils/appColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dementia_app/melody_mind/components/scrolling_text.dart';
import 'package:dementia_app/screens/melody_mind/music_player_screen.dart';
import 'package:dementia_app/melody_mind/services/playlist_service.dart';

class PlaylistWidget extends StatefulWidget {
  final List<Map<String, dynamic>> playlist;
  final Function(Map<String, dynamic>) onRemoveTrack;
  final VoidCallback onClearPlaylist;
  final Function(Map<String, dynamic>) onPlayTrack;

  const PlaylistWidget({
    Key? key,
    required this.playlist,
    required this.onRemoveTrack,
    required this.onClearPlaylist,
    required this.onPlayTrack,
  }) : super(key: key);

  @override
  State<PlaylistWidget> createState() => _PlaylistWidgetState();
}

class _PlaylistWidgetState extends State<PlaylistWidget> {
  bool _isReordering = false;
  final PlaylistService _playlistService = PlaylistService();

  @override
  Widget build(BuildContext context) {
    if (widget.playlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_music,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Your playlist is empty',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add songs from the library',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Playlist header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCCCC).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.playlist.length} song${widget.playlist.length != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              // Reorder toggle button
              TextButton.icon(
                icon: Icon(
                  _isReordering ? Icons.check : Icons.swap_vert,
                  color: _isReordering ? Colors.green : const Color(0xFFFFCCCC),
                  size: 20,
                ),
                label: Text(
                  _isReordering ? 'Done' : 'Reorder',
                  style: GoogleFonts.inter(
                    color:
                        _isReordering ? Colors.green : const Color(0xFFFFCCCC),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isReordering = !_isReordering;
                  });
                },
              ),
              const SizedBox(width: 8),
              // Clear playlist button
              TextButton.icon(
                icon: const Icon(
                  Icons.clear_all,
                  color: Color(0xFFFFCCCC),
                  size: 20,
                ),
                label: Text(
                  'Clear',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFCCCC),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: widget.onClearPlaylist,
              ),
            ],
          ),
        ),

        // Playlist items
        Expanded(
          child: _isReordering
              ? ReorderableListView.builder(
                  itemCount: widget.playlist.length,
                  onReorder: (oldIndex, newIndex) async {
                    // Adjust indices
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }

                    // Update local state first for immediate feedback
                    setState(() {
                      final item = widget.playlist.removeAt(oldIndex);
                      widget.playlist.insert(newIndex, item);
                    });

                    try {
                      // Update playlist order via service
                      await _playlistService
                          .updatePlaylistOrder(widget.playlist);
                    } catch (e) {
                      // If there's an error, show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Failed to save playlist order: $e')),
                      );
                    }
                  },
                  itemBuilder: (context, index) {
                    final track = widget.playlist[index];
                    return _buildPlaylistItem(track, index, true);
                  },
                )
              : ListView.builder(
                  itemCount: widget.playlist.length,
                  itemBuilder: (context, index) {
                    final track = widget.playlist[index];
                    return _buildPlaylistItem(track, index, false);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlaylistItem(
      Map<String, dynamic> track, int index, bool reorderable) {
    return Dismissible(
      key: ValueKey(track['id'] ?? 'track-$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red.withOpacity(0.7),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) async {
        try {
          await _playlistService.removeTrack(track['id'].toString());
          widget.onRemoveTrack(track);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove from playlist: $e')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/sonnetlogo.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (!reorderable)
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
          title: ScrollingText(
            text: track['title'] ?? 'Unknown Title',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            width: MediaQuery.of(context).size.width * 0.5,
          ),
          subtitle: ScrollingText(
            text: track['artist'] ?? 'Unknown Artist',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            width: MediaQuery.of(context).size.width * 0.5,
          ),
          trailing: reorderable
              ? const Icon(
                  Icons.drag_handle,
                  color: Colors.white,
                )
              : IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.primaryBlue,
                  ),
                  onPressed: () => widget.onRemoveTrack(track),
                ),
          onTap: reorderable ? null : () => widget.onPlayTrack(track),
        ),
      ),
    );
  }
}
