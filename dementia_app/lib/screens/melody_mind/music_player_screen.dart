import 'dart:async';
import 'dart:math';

import 'package:dementia_app/melody_mind/services/music_service.dart';
import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MusicPlayerScreen extends StatefulWidget {
  final Map<String, String> song;

  const MusicPlayerScreen({super.key, required this.song});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with WidgetsBindingObserver {
  final MusicService _musicService = MusicService();

  bool _isLoading = true;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // For rhythm-based notifications
  Timer? _rhythmTimer;
  bool _showBeatAnimation = false;
  int _bpm = 90; // Default BPM
  Map<String, dynamic>? _trackInfo;

  // For user interaction with rhythm
  bool _userTapped = false;
  bool _tapInSync = false;
  int _consecutiveSyncTaps = 0;
  int _maxConsecutiveSyncTaps = 0;
  int _totalTaps = 0;
  DateTime? _lastBeatTime;
  DateTime? _lastTapTime;
  double _rhythmSpeedFactor = 1.0;
  int _beatSkipFactor =
      0; // 0 = every beat, 1 = every 2nd beat, 2 = every 4th beat
  int _beatCounter =
      0; // Tracks the beat number for determining when to show visual cue

  // Settings for rhythm interaction
  bool _showTapGuide = true; // Show visual "TAP NOW" guide
  bool _enableHapticFeedback = true; // Provide haptic feedback on taps
  double _syncThreshold = 250.0; // Milliseconds of tolerance for sync

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudioSession();
    _setupAudioPlayer();
    _loadAndPlayTrack();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state changed to: $state');

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App is not in foreground, pause playback
      if (_isPlaying) {
        _musicService.pause();
        print('App backgrounded: pausing playback');
      }
    }
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  void _setupAudioPlayer() {
    // Listen to position updates
    _musicService.player.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _musicService.player.durationStream.listen((duration) {
      if (duration != null && mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _musicService.player.playerStateStream.listen((state) {
      if (mounted) {
        final wasPlaying = _isPlaying;
        final isNowPlaying = state.playing;

        print(
            'Player state changed: was playing: $wasPlaying, is now: $isNowPlaying');

        setState(() {
          _isPlaying = isNowPlaying;
        });

        // Handle rhythm animation based on play state changes
        if (isNowPlaying && _rhythmTimer == null) {
          print('Player started playing - starting rhythm timer');
          _startRhythmNotifications();
        } else if (!isNowPlaying && _rhythmTimer != null) {
          print('Player stopped playing - cancelling rhythm timer');
          _rhythmTimer?.cancel();
          _rhythmTimer = null;
          // Ensure animation is stopped
          setState(() {
            _showBeatAnimation = false;
          });
        }

        if (state.processingState == ProcessingState.completed) {
          print('Playback completed');

          // Ensure timer is cancelled when playback completes
          if (_rhythmTimer != null) {
            _rhythmTimer?.cancel();
            _rhythmTimer = null;
          }

          setState(() {
            _position = _duration;
            _isPlaying = false;
            _showBeatAnimation = false;
          });

          // submit analytics when playback completes
          _submitAnalytics();
        }
      }
    });
  }

  Future<void> _loadAndPlayTrack() async {
    setState(() {
      _isLoading = true;
    });
    print("Loading track...");

    try {
      _trackInfo = await _musicService.findTrack(
          widget.song['artist']!, widget.song['title']!);
      print("Track info fetched: $_trackInfo");

      if (_trackInfo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Song not found in library: ${widget.song['title']}')),
          );
          setState(() {
            _isLoading = false;
          });
        }
        print("Song not found. Stopping loader.");
        return;
      }

      // Extract BPM from metadata
      setState(() {
        _bpm = _trackInfo!['bpm'] ?? 90;
        _isLoading = false;
      });

      print("BPM extracted: $_bpm");

      // Play the track
      final success = await _musicService.playTrack(
          trackData: _trackInfo,
          artist: widget.song['artist']!,
          title: widget.song['title']!);

      if (success && mounted) {
        setState(() {
          _isPlaying = true;
        });
        print("Playback started!");
        _startRhythmNotifications();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to play song')),
        );
      }
    } catch (e) {
      print('Error in _loadAndPlayTrack: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Calculate a user-friendly BPM for interaction
  int _getEffectiveBpm(int songBpm) {
    int effectiveBpm = songBpm;

    // If BPM is too fast, divide it to get a comfortable pace (half-time)
    if (songBpm > 120) {
      effectiveBpm = (songBpm / 2).round();
    }

    // If still too fast, divide again (quarter-time)
    if (effectiveBpm > 120) {
      effectiveBpm = (songBpm / 4).round();
    }

    // If BPM is too slow, we could multiply it for better engagement
    if (songBpm < 60) {
      effectiveBpm = (songBpm * 2).round();
    }

    return effectiveBpm;
  }

  void _startRhythmNotifications() {
    // Cancel existing timer if any
    if (_rhythmTimer != null) {
      print('Cancelling existing rhythm timer before starting a new one');
      _rhythmTimer?.cancel();
      _rhythmTimer = null;
    }

    // Only start if we're playing
    if (!_isPlaying) {
      print('Not starting rhythm timer because not playing');
      return;
    }

    // Get the song's BPM and calculate user-friendly BPM
    final songBpm = _bpm;
    final effectiveBpm = _getEffectiveBpm(songBpm);

    // Calculate milliseconds per beat based on the adjusted BPM
    final beatInterval = (60000 / effectiveBpm).round();

    // Reset beat counter
    _beatCounter = 0;

    // Define animation parameters
    final animVisibleDuration =
        400; // ms - how long the animation stays visible

    final skipValue = _beatSkipFactor == 0
        ? 1
        : _beatSkipFactor == 1
            ? 2
            : 4;

    //define animation parameters
    print('Starting rhythm notifications:');
    print('Original BPM: $songBpm, Adapted BPM: $effectiveBpm');
    print('Beat interval: $beatInterval ms, Showing every $skipValue beat');

    // Create rhythm timer
    // Create rhythm timer - this always runs at the song's actual rhythm
    _rhythmTimer =
        Timer.periodic(Duration(milliseconds: beatInterval), (timer) {
      // Increment beat counter
      _beatCounter++;

      // Only show visual cue on selected beats based on skip factor
      final shouldShowCue = _beatCounter % skipValue == 0;

      // Double check we're still playing and mounted
      if (mounted && _isPlaying) {
        setState(() {
          // Only show the animation on selected beats
          _showBeatAnimation = shouldShowCue;

          // Always update the last beat time for accurate timing calculations
          _lastBeatTime = DateTime.now();
        });

        // Reset animation after the visible duration, but only if we showed it
        if (shouldShowCue) {
          Future.delayed(Duration(milliseconds: animVisibleDuration), () {
            if (mounted) {
              setState(() {
                _showBeatAnimation = false;
              });
            }
          });
        }
      } else if (!_isPlaying && mounted) {
        // If we're not playing anymore but timer is still active, cancel it
        print('Playback stopped but timer still running - cancelling timer');
        timer.cancel();
        _rhythmTimer = null;
        // Ensure animation is stopped
        setState(() {
          _showBeatAnimation = false;
        });
      }
    });
  }

  // Handle user taps to the rhythm
  void _handleUserTap() {
    if (!_isPlaying) return;

    final now = DateTime.now();
    setState(() {
      _userTapped = true;
      _totalTaps++;
      _lastTapTime = now;
    });

    // Reset the tap animation after a short delay
    Future.delayed(Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _userTapped = false;
        });
      }
    });

    // Check if the tap is in sync with the beat
    if (_lastBeatTime != null) {
      final timeSinceLastBeat = now.difference(_lastBeatTime!).inMilliseconds;
      final effectiveBpm = _getEffectiveBpm(_bpm);
      final beatInterval = (60000 / effectiveBpm).round();

      // Calculate beat phase for sync detection - this takes into account the skipValue
      final skipValue = _beatSkipFactor == 0
          ? 1
          : _beatSkipFactor == 1
              ? 2
              : 4;
      final adjustedInterval = beatInterval * skipValue;

      // Calculate how close the tap is to the nearest expected interaction point
      final timeSinceBeatMod = timeSinceLastBeat % adjustedInterval;
      final distanceFromBeat =
          min(timeSinceBeatMod, adjustedInterval - timeSinceBeatMod);

      // Adjust tolerance based on interaction frequency - more time between cues = more tolerance
      final adjustedThreshold = _syncThreshold * (skipValue * 0.25 + 0.75);

      // If the tap is within the threshold of the beat, consider it in sync
      final isInSync = distanceFromBeat < adjustedThreshold;

      // Calculate a "quality" score from 0-1 for this tap
      final tapQuality =
          1.0 - (distanceFromBeat / adjustedThreshold).clamp(0.0, 1.0);

      setState(() {
        _tapInSync = isInSync;
        if (isInSync) {
          _consecutiveSyncTaps++;
          _maxConsecutiveSyncTaps =
              max(_maxConsecutiveSyncTaps, _consecutiveSyncTaps);
        } else {
          // Only reset completely on very bad timing
          if (tapQuality < 0.3) {
            _consecutiveSyncTaps = 0;
          } else if (_consecutiveSyncTaps > 0) {
            // Just reduce for close misses
            _consecutiveSyncTaps--;
          }
        }
      });

      // Provide appropriate haptic feedback based on timing accuracy
      if (_enableHapticFeedback) {
        if (tapQuality > 0.8) {
          HapticFeedback.heavyImpact(); // Strong feedback for excellent timing
        } else if (tapQuality > 0.4) {
          HapticFeedback.mediumImpact(); // Medium for decent timing
        } else {
          HapticFeedback.lightImpact(); // Light for poor timing
        }
      }
    }
  }

  // submit analytics data when music ends
  Future<void> _submitAnalytics() async {
    try {
      final supabase = Supabase.instance.client;

      //analytics data
      final analyticsData = {
        // 'user_id': supabase.auth.currentUser?.id,
        'user_id': '39eb7276-d2f7-4ce4-b119-8ea0130d9dad',
        'song_name': widget.song['title'],
        'artist': widget.song['artist'],
        'total_beats': _beatCounter,
        'total_taps': _totalTaps,
        'consecutive_sync_taps_max': _consecutiveSyncTaps,
        'rhythm_accuracy': _totalTaps > 0
            ? (_consecutiveSyncTaps / _totalTaps * 100).toStringAsFixed(1)
            : "0.0",
        'rhythm_pace': _beatSkipFactor == 0
            ? 'Regular'
            : (_beatSkipFactor == 1 ? 'Relaxed' : 'Gentle'),
        'time_tolerance': _syncThreshold.round(),
        'total_duration': _duration.inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('Submitting analytics: $analyticsData');

      final response =
          await supabase.from('music_sessions').insert(analyticsData);

      print('submitted analytics: $response');
      print('Analytics submitted successfully to Supabase');

      // Show success feedback to user
      if (mounted) {
        _showCompletionFeedback(true);
      }
    } catch (e) {
      print('Error submitting analytics to Supabase: $e');

      // Show error feedback but still continue
      if (mounted) {
        _showCompletionFeedback(false);
      }
    }
  }

  void _showCompletionFeedback(bool success) {
    setState(() {
      _isLoading = false;
    });

    // Get rhythm level description
    String rhythmLevel;
    if (_totalTaps < 5) {
      rhythmLevel = "Starting your journey";
    } else if (_consecutiveSyncTaps >= 10) {
      rhythmLevel = "Master rhythmist";
    } else if (_consecutiveSyncTaps >= 5) {
      rhythmLevel = "Good rhythm keeper";
    } else if (_consecutiveSyncTaps >= 3) {
      rhythmLevel = "Developing rhythm";
    } else {
      rhythmLevel = "Rhythm explorer";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Session Complete",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF330000),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.info,
                color: success ? Colors.green : const Color(0xFFFFCCCC),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                "Your music therapy session has been completed!",
                style: GoogleFonts.inter(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCCCC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFCCCC).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      rhythmLevel,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF330000),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You tapped $_totalTaps times and maintained rhythm for up to $_consecutiveSyncTaps consecutive beats.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!success)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    "Note: We couldn't save your session data, but your session was still valuable!",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                "Return to Playlist",
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFCCCC),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to playlist screen
              },
            ),
          ],
        );
      },
    );
  }

  // Show the settings dialog
  void _showSettingsDialog() {
    final wasPlaying = _isPlaying;

    if (_isPlaying) {
      _pausePlayback();
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Player Settings",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rhythm settings section
              Text(
                "Rhythm Settings",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              // Visual guide toggle
              SwitchListTile(
                title: Text("Show 'TAP NOW' Guide", style: GoogleFonts.inter()),
                value: _showTapGuide,
                onChanged: (value) {
                  setDialogState(() {
                    _showTapGuide = value;
                  });
                  setState(() {
                    _showTapGuide = value;
                  });
                },
              ),
              // Haptic feedback toggle
              SwitchListTile(
                title: Text("Haptic Feedback", style: GoogleFonts.inter()),
                value: _enableHapticFeedback,
                onChanged: (value) {
                  setDialogState(() {
                    _enableHapticFeedback = value;
                  });
                  setState(() {
                    _enableHapticFeedback = value;
                  });
                },
              ),
              // Tolerance slider
              Padding(
                padding:
                    const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          Text("Timing Tolerance:", style: GoogleFonts.inter()),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Slider(
                  min: 100,
                  max: 400,
                  divisions: 6,
                  value: _syncThreshold,
                  label: "${_syncThreshold.round()} ms",
                  onChanged: (value) {
                    setDialogState(() {
                      _syncThreshold = value;
                    });
                    setState(() {
                      _syncThreshold = value;
                    });
                  },
                ),
              ),
              Text(
                _syncThreshold <= 150
                    ? "Strict"
                    : _syncThreshold <= 250
                        ? "Medium"
                        : "Relaxed",
                style: GoogleFonts.inter(
                  color: _syncThreshold <= 150
                      ? Colors.red
                      : _syncThreshold <= 250
                          ? Colors.amber
                          : Colors.green,
                ),
              ),

              // Rhythm change
              Divider(height: 16),
              Padding(
                padding:
                    const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Rhythm Pace:",
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Set how frequently you need to tap in rhythm with the music",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 12),
              // Option 1: Fast Pace (Every Beat)
              GestureDetector(
                onTap: () {
                  setDialogState(() {
                    _beatSkipFactor = 0;
                  });
                  setState(() {
                    _beatSkipFactor = 0;
                    if (_isPlaying) {
                      _startRhythmNotifications();
                    }
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _beatSkipFactor == 0
                          ? const Color(0xFFFFCCCC)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _beatSkipFactor == 0
                        ? const Color(0xFFFFCCCC).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.speed,
                        color: _beatSkipFactor == 0
                            ? const Color(0xFFFFCCCC)
                            : Colors.grey[600],
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Regular Rhythm",
                              style: GoogleFonts.inter(
                                fontWeight: _beatSkipFactor == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Tap with each beat of the song",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_beatSkipFactor == 0)
                        Icon(
                          Icons.check_circle,
                          color: const Color(0xFFFFCCCC),
                        ),
                    ],
                  ),
                ),
              ),

// Option 2: Medium Pace (Every 2nd Beat)
              GestureDetector(
                onTap: () {
                  setDialogState(() {
                    _beatSkipFactor = 1;
                  });
                  setState(() {
                    _beatSkipFactor = 1;
                    if (_isPlaying) {
                      _startRhythmNotifications();
                    }
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _beatSkipFactor == 1
                          ? const Color(0xFFFFCCCC)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _beatSkipFactor == 1
                        ? const Color(0xFFFFCCCC).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: _beatSkipFactor == 1
                            ? const Color(0xFFFFCCCC)
                            : Colors.grey[600],
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Relaxed Rhythm",
                              style: GoogleFonts.inter(
                                fontWeight: _beatSkipFactor == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "More time between taps, easier to follow",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_beatSkipFactor == 1)
                        Icon(
                          Icons.check_circle,
                          color: const Color(0xFFFFCCCC),
                        ),
                    ],
                  ),
                ),
              ),

// Option 3: Slow Pace (Every 4th Beat)
              GestureDetector(
                onTap: () {
                  setDialogState(() {
                    _beatSkipFactor = 2;
                  });
                  setState(() {
                    _beatSkipFactor = 2;
                    if (_isPlaying) {
                      _startRhythmNotifications();
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _beatSkipFactor == 2
                          ? const Color(0xFFFFCCCC)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _beatSkipFactor == 2
                        ? const Color(0xFFFFCCCC).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.accessibility_new,
                        color: _beatSkipFactor == 2
                            ? const Color(0xFFFFCCCC)
                            : Colors.grey[600],
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Gentle Rhythm",
                              style: GoogleFonts.inter(
                                fontWeight: _beatSkipFactor == 2
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Very spaced out, easiest to follow",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_beatSkipFactor == 2)
                        Icon(
                          Icons.check_circle,
                          color: const Color(0xFFFFCCCC),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Close"),
              onPressed: () => {
                Navigator.of(context).pop(),
                if (wasPlaying && mounted)
                  {
                    Future.delayed(
                      Duration(milliseconds: 300),
                      () {
                        _resumePlayback();
                      },
                    ),
                  },
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pausePlayback() {
    // Cancel rhythm animation
    if (_rhythmTimer != null) {
      _rhythmTimer?.cancel();
      _rhythmTimer = null;
    }

    // Stop beat animation immediately
    setState(() {
      _showBeatAnimation = false;
    });

    // Pause music
    _musicService.pause();

    // Update playing state
    setState(() {
      _isPlaying = false;
    });
  }

  // Helper method to resume playback and animation
  void _resumePlayback() {
    // Only resume if we're not at the end of the track
    if (_position < _duration && mounted) {
      // Start music playback
      _musicService.resume();

      // Update state
      setState(() {
        _isPlaying = true;
      });

      // Restart rhythm notifications after a short delay
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted && _isPlaying) {
          _startRhythmNotifications();
        }
      });
    }
  }

  // Build feedback message based on user's rhythm performance
  Widget _buildRhythmFeedback() {
    String feedbackText;
    Color feedbackColor;

    if (_totalTaps < 3) {
      feedbackText = "Start tapping to the beat!";
      feedbackColor = Colors.white.withOpacity(0.7);
    } else if (_consecutiveSyncTaps >= 5) {
      feedbackText = "Perfect rhythm! 🎵";
      feedbackColor = Colors.green;
    } else if (_consecutiveSyncTaps >= 3) {
      feedbackText = "Good rhythm! 👍";
      feedbackColor = Colors.lightGreen;
    } else if (_tapInSync) {
      feedbackText = "On beat!";
      feedbackColor = Colors.yellow;
    } else {
      feedbackText = "Try to match the beat";
      feedbackColor = Colors.white.withOpacity(0.7);
    }

    return Text(
      feedbackText,
      style: GoogleFonts.inter(
        color: feedbackColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  void _togglePlayPause() async {
    print('Toggle play/pause. Current state: $_isPlaying');

    if (_isPlaying) {
      // Ensure UI updates correctly before stopping the music
      setState(() {
        _showBeatAnimation = false;
      });

      // First, cancel beat animation timer to prevent any more animations
      if (_rhythmTimer != null) {
        print('Cancelling rhythm timer');
        _rhythmTimer?.cancel();
        _rhythmTimer = null;
      }

      // Pause the music and wait for it to complete
      await _musicService.pause();

      // Now update UI state after pausing
      setState(() {
        _isPlaying = false;
      });
    } else {
      // First update UI state
      setState(() {
        _isPlaying = true;
        // Reset tapping stats when restarting
        _consecutiveSyncTaps = 0;
        _totalTaps = 0;
      });

      // Resume playback and start rhythm
      _musicService.resume();
      _startRhythmNotifications();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    print('Disposing MusicPlayerScreen');
    // Clean up resources
    _rhythmTimer?.cancel();
    _rhythmTimer = null;

    // Stop playback before disposing
    _musicService.stop();

    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBpm = _getEffectiveBpm(_bpm);

    return WillPopScope(
      onWillPop: () async {
        // Make sure we properly stop the music and clean up before popping
        print('Back button pressed, cleaning up before navigation');
        _rhythmTimer?.cancel();
        await _musicService.stop();
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF330000),
                Color(0xFF000000),
              ],
            ),
            image: DecorationImage(
              image: AssetImage("assets/images/background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFCCCC),
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      // Header with back button and settings button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                // Ensure clean resources before navigation
                                _rhythmTimer?.cancel();
                                await _musicService.stop();
                                Navigator.pop(context);
                              },
                            ),
                            const Spacer(),
                            // Settings button in top-right corner
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                              ),
                              onPressed: _showSettingsDialog,
                            ),
                          ],
                        ),
                      ),

                      // Album art and beat animation in a GestureDetector for user taps
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: _handleUserTap,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer pulse - slower animation
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  width: _showBeatAnimation ? 320 : 260,
                                  height: _showBeatAnimation ? 320 : 260,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCCCC).withOpacity(
                                        _showBeatAnimation ? 0.15 : 0),
                                    shape: BoxShape.circle,
                                  ),
                                ),

                                // Middle pulse
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  width: _showBeatAnimation ? 300 : 260,
                                  height: _showBeatAnimation ? 300 : 260,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCCCC).withOpacity(
                                        _showBeatAnimation ? 0.25 : 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                ),

                                // Inner pulse (more visible)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  width: _showBeatAnimation ? 280 : 260,
                                  height: _showBeatAnimation ? 280 : 260,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCCCC).withOpacity(
                                        _showBeatAnimation ? 0.4 : 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),

                                // User tap feedback animation
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  width: _userTapped ? 290 : 260,
                                  height: _userTapped ? 290 : 260,
                                  decoration: BoxDecoration(
                                    color: _tapInSync
                                        ? Colors.green
                                            .withOpacity(_userTapped ? 0.3 : 0)
                                        : Colors.amber
                                            .withOpacity(_userTapped ? 0.3 : 0),
                                    shape: BoxShape.circle,
                                  ),
                                ),

                                // Album art
                                Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                    image: const DecorationImage(
                                      image: AssetImage(
                                          "assets/images/sonnetlogo.png"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                // Tap indicator - only visible during beat and if guide is enabled
                                if (_showBeatAnimation && _showTapGuide)
                                  Positioned(
                                    top: 70,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        "TAP NOW",
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Song info with scroll view to fix overflow
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.song['title'] ?? '',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.song['artist'] ?? '',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                // Playback progress
                                const SizedBox(height: 24),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius:
                                            0), // Disable overlay effect
                                    thumbColor: const Color(0xFFFFCCCC),
                                    activeTrackColor: const Color(0xFFFFCCCC),
                                    inactiveTrackColor:
                                        Colors.white.withOpacity(0.3),
                                    trackHeight: 4.0,
                                    disabledThumbColor: const Color(
                                        0xFFFFCCCC), // Important for disabled slider
                                    disabledActiveTrackColor: const Color(
                                        0xFFFFCCCC), // Important for disabled slider
                                    disabledInactiveTrackColor: Colors.white
                                        .withOpacity(
                                            0.3), // Important for disabled slider
                                  ),
                                  child: Slider(
                                    value: _position.inSeconds.toDouble(),
                                    min: 0,
                                    max: _duration.inSeconds.toDouble() > 0
                                        ? _duration.inSeconds.toDouble()
                                        : 1.0, // Prevent division by zero
                                    onChanged:
                                        null, // Setting this to null makes the slider non-interactive
                                  ),
                                ),

                                // Time indicators
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(_position),
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_duration),
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Playback controls
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Play/Pause button
                                    GestureDetector(
                                      onTap: _togglePlayPause,
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFCCCC),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFCCCC)
                                                  .withOpacity(0.3),
                                              blurRadius: 15,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            color: Colors.white,
                                            size: 36,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Rhythm guidance and feedback
                                const SizedBox(height: 16),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Tap along with the rhythm!",
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 2),
                                    RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "Original BPM: $_bpm",
                                          ),
                                          TextSpan(
                                            text: " • Adjusted: $effectiveBpm",
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    _buildRhythmFeedback(),
                                    // Add some extra padding at the bottom to ensure all content is visible
                                    SizedBox(height: 16),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
