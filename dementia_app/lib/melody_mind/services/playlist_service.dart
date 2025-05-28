import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistService {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  final supabase = Supabase.instance.client;

  String get userId {
    final currentUser = supabase.auth.currentUser;
    return currentUser?.id ?? 'anonymous';
  }

  //Load playlists
  Future<List<Map<String, dynamic>>> loadPlaylist() async {
    try {
      //get playlist items for the current user
      final playlistItems = await supabase
          .from('user_playlists')
          .select('track_id, added_at')
          .eq('user_id', userId)
          .order('added_at', ascending: true);

      if (playlistItems.isEmpty) {
        return [];
      }

      //extract track IDs
      final trackIds =
          playlistItems.map((item) => item['track_id'].toString()).toList();

      final trackData = await supabase
          .from('music_tracks')
          .select('id, title, artist, bpm, duration, file_path')
          .inFilter('id', trackIds);

      //sort the tracks to match playlist order
      final sortedPlaylist = <Map<String, dynamic>>[];
      for (var id in trackIds) {
        final trackInfo = trackData.firstWhere(
          (track) => track['id'].toString() == id,
          orElse: () => <String, dynamic>{},
        );
        if (trackInfo != null) {
          sortedPlaylist.add(Map<String, dynamic>.from(trackInfo));
        }
      }

      log('Loaded ${sortedPlaylist.length} tracks in playlist');
      return sortedPlaylist;
    } catch (e) {
      log('Error loading playlist: $e');
      rethrow;
    }
  }

  //ad track to playlist
  Future<void> addTrack(Map<String, dynamic> track) async {
    try {
      //add to Supabase playlist table
      await supabase.from('user_playlists').insert({
        'user_id': userId,
        'track_id': track['id'],
        'added_at': DateTime.now().toIso8601String(),
      });

      log('Added track to playlist: ${track['title']}');
    } catch (e) {
      log('Error adding track to playlist: $e');
      rethrow;
    }
  }

  //reemove track from playlist
  Future<void> removeTrack(String trackId) async {
    try {
      // Remove from Supabase playlist table
      await supabase
          .from('user_playlists')
          .delete()
          .eq('user_id', userId)
          .eq('track_id', trackId);

      log('Removed track from playlist: $trackId');
    } catch (e) {
      log('Error removing track from playlist: $e');
      rethrow;
    }
  }

  //clear entire playlist
  Future<void> clearPlaylist() async {
    try {
      await supabase.from('user_playlists').delete().eq('user_id', userId);

      log('Cleared playlist for user: $userId');
    } catch (e) {
      log('Error clearing playlist: $e');
      rethrow;
    }
  }

  //update playlist order
  Future<void> updatePlaylistOrder(
      List<Map<String, dynamic>> orderedPlaylist) async {
    try {
      await supabase.from('user_playlists').delete().eq('user_id', userId);

      //reinsert with new order
      for (int i = 0; i < orderedPlaylist.length; i++) {
        await supabase.from('user_playlists').insert({
          'user_id': userId,
          'track_id': orderedPlaylist[i]['id'],
          'added_at':
              DateTime.now().add(Duration(milliseconds: i)).toIso8601String(),
        });
      }

      log('Updated playlist order for user: $userId');
    } catch (e) {
      log('Error updating playlist order: $e');
      rethrow;
    }
  }

  Future<bool> isTrackInPlaylist(String trackId) async {
    try {
      final result = await supabase
          .from('user_playlists')
          .select('id')
          .eq('user_id', userId)
          .eq('track_id', trackId)
          .limit(1);

      return result.isNotEmpty;
    } catch (e) {
      log('Error checking if track is in playlist: $e');
      return false;
    }
  }

  //get playlist count
  Future<int> getPlaylistCount() async {
    try {
      final result = await supabase
          .from('user_playlists')
          .select('count')
          .eq('user_id', userId);

      return (result as List).length;
    } catch (e) {
      log('Error getting playlist count: $e');
      return 0;
    }
  }
}
