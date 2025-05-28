import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';

class MusicService {
  final SupabaseClient _supabase;
  final AudioPlayer _audioPlayer = AudioPlayer();

  static final MusicService _instance = MusicService._internal();

  factory MusicService() {
    return _instance;
  }

  MusicService._internal() : _supabase = Supabase.instance.client {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    
  }

  
  //cache tracks
  final Map<String, Map<String, dynamic>> _trackCache = {};

  //find a track in the library based on artist and title
  Future<Map<String, dynamic>?> findTrack(String artist, String title) async {
    final cacheKey = '$artist - $title';

    //check if track is already in cache
    if (_trackCache.containsKey(cacheKey)) {
      log('Found track in cache: $cacheKey');
      return _trackCache[cacheKey];
    }
    try {
      //use the RPC function
      final response = await _supabase.rpc('find_track', params: {
        'p_artist': artist,
        'p_title': title,
      }).select();

      if (response != null && response.isNotEmpty) {
        print(
            'Found track via RPC: ${response[0]['artist']} - ${response[0]['title']}');
        print('File path in database: ${response[0]['file_path']}');
        //cache the track for future requests
        _trackCache[cacheKey] = response[0];
        return response[0];
      }

      print('No track found via RPC');
      return null;
    } catch (e) {
      print('Error finding track via RPC: $e');
      return null;
    }
  }

  //fetch all tracks from the database
  Future<List<Map<String, dynamic>>> getAllTracks() async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('music_tracks')
          .select('id, title, artist, bpm, duration, file_path')
          .order('title', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      log('Error fetching all tracks: $e');
      return [];
    }
  }

  //search tracks by query
  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    if (query.isEmpty) {
      return getAllTracks();
    }

    try {
      final supabase = Supabase.instance.client;
      final lowerQuery = query.toLowerCase();

      final response = await supabase
          .from('music_tracks')
          .select('id, title, artist, bpm, duration, file_path')
          .or('title.ilike.%$lowerQuery%,artist.ilike.%$lowerQuery%')
          .order('title', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      log('Error searching tracks: $e');
      return [];
    }
  }

  //get streaming URL for a track
  Future<String?> getStreamUrl(String fileName) async {
    try {
      //ensure we are working with just the filename
      String cleanFileName = fileName;

      //if we have a full URL, extract just the filename
      if (fileName.startsWith('http')) {
        final uri = Uri.parse(fileName);
        final pathSegments = uri.pathSegments;
        cleanFileName = pathSegments.isNotEmpty ? pathSegments.last : '';
      }
      //if we have a path with slashes, extract just the filename
      else if (fileName.contains('/')) {
        cleanFileName = fileName.split('/').last;
      }

      print('Getting URL for file: $cleanFileName');

      //generate a public URL using the bucket name and file name
      final publicUrl =
          _supabase.storage.from('musics').getPublicUrl(cleanFileName);
      print('Generated URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Error getting stream URL: $e');
      return null;
    }
  }

  //play a track
  Future<bool> playTrack(
      {Map<String, dynamic>? trackData, String? artist, String? title}) async {
    try {
      Map<String, dynamic>? track;

      //use the track data if provided, otherwise look it up
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

  //get current audio player
  AudioPlayer get player => _audioPlayer;

  //pause playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  //resume playback
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  //stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  //seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  //dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
