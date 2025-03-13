import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';

class MusicService {
  final SupabaseClient _supabase;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Singleton instance
  static final MusicService _instance = MusicService._internal();

  // Factory constructor
  factory MusicService() {
    return _instance;
  }

  // Private constructor
  MusicService._internal() : _supabase = Supabase.instance.client {
    // Initialize audio player if needed
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    // Configure audio player settings if needed
  }

  // Find a track in the library based on artist and title
  Future<Map<String, dynamic>?> findTrack(String artist, String title) async {
    try {
      // Use the RPC function
      final response = await _supabase.rpc('find_track', params: {
        'p_artist': artist,
        'p_title': title,
      }).select();

      if (response != null && response.isNotEmpty) {
        print(
            'Found track via RPC: ${response[0]['artist']} - ${response[0]['title']}');
        print('File path in database: ${response[0]['file_path']}');
        return response[0];
      }

      print('No track found via RPC');
      return null;
    } catch (e) {
      print('Error finding track via RPC: $e');
      return null;
    }
  }

  // Get streaming URL for a track
  Future<String?> getStreamUrl(String fileName) async {
    try {
      // Ensure we're working with just the filename (no paths or URLs)
      String cleanFileName = fileName;

      // If we have a full URL, extract just the filename
      if (fileName.startsWith('http')) {
        final uri = Uri.parse(fileName);
        final pathSegments = uri.pathSegments;
        cleanFileName = pathSegments.isNotEmpty ? pathSegments.last : '';
      }
      // If we have a path with slashes, extract just the filename
      else if (fileName.contains('/')) {
        cleanFileName = fileName.split('/').last;
      }

      print('Getting URL for file: $cleanFileName');

      // Generate a public URL using the bucket name and file name
      final publicUrl =
          _supabase.storage.from('musics').getPublicUrl(cleanFileName);
      print('Generated URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Error getting stream URL: $e');
      return null;
    }
  }

  // Play a track
  Future<bool> playTrack(
      {Map<String, dynamic>? trackData, String? artist, String? title}) async {
    try {
      Map<String, dynamic>? track;

      // Use the track data if provided, otherwise look it up
      if (trackData != null) {
        track = trackData;
      } else if (artist != null && title != null) {
        track = await findTrack(artist, title);
      } else {
        print('Invalid parameters: need either trackData or artist/title');
        return false;
      }

      if (track == null) {
        print('Track not found in database');
        return false;
      }

      final filePathOrUrl = track['file_path'];
      print('File path from database: $filePathOrUrl');

      // Get stream URL
      final url = await getStreamUrl(filePathOrUrl);
      if (url == null) {
        print('Could not get streaming URL');
        return false;
      }

      // Play the track
      print('Playing track with URL: $url');
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();

      return true;
    } catch (e) {
      print('Error playing track: $e');
      return false;
    }
  }

  // Get current audio player
  AudioPlayer get player => _audioPlayer;

  // Pause playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  // Resume playback
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  // Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
