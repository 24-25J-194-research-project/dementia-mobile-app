import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final supabase = Supabase.instance.client;

  String get userId {
    final currentUser = supabase.auth.currentUser;
    return currentUser?.id ?? 'anonymous';
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        return {
          'full_name': 'Anonymous User',
          'email': 'guest@example.com',
          'avatar_url': null,
          'created_at': DateTime.now().toIso8601String(),
        };
      }

      return {
        'full_name': currentUser.userMetadata?['full_name'] ??
            currentUser.email?.split('@').first ??
            'User',
        'email': currentUser.email,
        'avatar_url': currentUser.userMetadata?['avatar_url'],
        'created_at': currentUser.createdAt != null
            ? DateTime.parse(currentUser.createdAt.toString()).toIso8601String()
            : DateTime.now().toIso8601String(),
      };
    } catch (e) {
      log('Error fetching user profile: $e');
      return {
        'full_name': 'Error loading profile',
        'email': '',
        'avatar_url': null,
        'created_at': DateTime.now().toIso8601String(),
      };
    }
  }

  //fetch all users session data
  Future<List<Map<String, dynamic>>> getUserSessionData() async {
    try {
      final response = await supabase
          .from('music_sessions')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      log('Error fetching user session data: $e');
      return [];
    }
  }

  //get specific dataaa by ID
  Future<Map<String, dynamic>?> getSessionById(String sessionId) async {
    try {
      final response = await supabase
          .from('music_sessions')
          .select()
          .eq('id', sessionId)
          .single();

      return response;
    } catch (e) {
      log('Error fetching session by ID: $e');
      return null;
    }
  }

  //fet aggregated user stats
  Future<Map<String, dynamic>> getUserAggregatedStats() async {
    try {
      final data = await getUserSessionData();

      if (data.isEmpty) {
        return {
          'total_sessions': 0,
          'total_duration': 0,
          'avg_rhythm_accuracy': 0.0,
          'highest_accuracy': 0.0,
          'most_played_song': 'No songs played yet',
          'preferred_pace': 'None',
        };
      }

      //calculate aggregated stats
      int totalSessions = data.length;
      int totalDuration = 0;
      double totalAccuracy = 0;
      double highestAccuracy = 0;
      Map<String, int> songCounts = {};
      Map<String, int> paceCounts = {};

      for (final session in data) {
        totalDuration += session['total_duration'] as int? ?? 0;

        //caccuracy calculations
        double accuracy =
            double.tryParse(session['rhythm_accuracy'] ?? "0.0") ?? 0.0;
        totalAccuracy += accuracy;
        if (accuracy > highestAccuracy) {
          highestAccuracy = accuracy;
        }

        //song count for most played song
        String songName = "${session['song_name']} - ${session['artist']}";
        songCounts[songName] = (songCounts[songName] ?? 0) + 1;

        //pace preference
        String pace = session['rhythm_pace'] ?? 'Regular';
        paceCounts[pace] = (paceCounts[pace] ?? 0) + 1;
      }

      //find most played song
      String mostPlayedSong = 'None';
      int maxPlays = 0;
      songCounts.forEach((song, count) {
        if (count > maxPlays) {
          maxPlays = count;
          mostPlayedSong = song;
        }
      });

      //find preferred pace
      String preferredPace = 'None';
      int maxPaceCount = 0;
      paceCounts.forEach((pace, count) {
        if (count > maxPaceCount) {
          maxPaceCount = count;
          preferredPace = pace;
        }
      });

      return {
        'total_sessions': totalSessions,
        'total_duration': totalDuration,
        'avg_rhythm_accuracy': totalAccuracy / totalSessions,
        'highest_accuracy': highestAccuracy,
        'most_played_song': mostPlayedSong,
        'preferred_pace': preferredPace,
      };
    } catch (e) {
      log('Error calculating aggregated stats: $e');
      return {
        'total_sessions': 0,
        'total_duration': 0,
        'avg_rhythm_accuracy': 0.0,
        'highest_accuracy': 0.0,
        'most_played_song': 'Error calculating stats',
        'preferred_pace': 'Error',
      };
    }
  }

  //get weekly progress data for charts
  Future<List<Map<String, dynamic>>> getWeeklyProgressData() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final response = await supabase
          .from('music_sessions')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', sevenDaysAgo.toIso8601String())
          .order('timestamp', ascending: true);

      final List<Map<String, dynamic>> data = [];

      //group by -> day
      final Map<String, List<Map<String, dynamic>>> groupedByDay = {};

      for (final session in List<Map<String, dynamic>>.from(response)) {
        final timestamp = DateTime.parse(session['timestamp']);
        final day = '${timestamp.day}/${timestamp.month}';

        if (!groupedByDay.containsKey(day)) {
          groupedByDay[day] = [];
        }

        groupedByDay[day]!.add(session);
      }

      //calculate average accuracy for each day
      groupedByDay.forEach((day, sessions) {
        double totalAccuracy = 0;
        for (final session in sessions) {
          totalAccuracy +=
              double.tryParse(session['rhythm_accuracy'] ?? "0.0") ?? 0.0;
        }

        data.add({
          'day': day,
          'accuracy': (totalAccuracy / sessions.length).toStringAsFixed(1),
          'sessions': sessions.length,
        });
      });

      return data;
    } catch (e) {
      log('Error fetching weekly progress data: $e');
      return [];
    }
  }
}
