import 'dart:async';
import 'dart:math';

import 'package:dementia_app/melody_mind/components/count_down_dialog.dart';
import 'package:dementia_app/melody_mind/components/noise_calibration_dialog.dart';
import 'package:dementia_app/melody_mind/services/ai_companion_service.dart';
import 'package:dementia_app/melody_mind/services/clap_detector_service.dart';
import 'package:dementia_app/melody_mind/services/music_service.dart';
import 'package:dementia_app/utils/appColors.dart';
import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final ClapDetectorService _clapDetector = ClapDetectorService();

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
  bool _showTapGuide = true; //show visual "TAP NOW" guide
  bool _enableHapticFeedback = true; //provide haptic feedback on taps
  double _syncThreshold = 350.0; //milliseconds of tolerance for sync

  bool _trackLoaded = false;
  bool _clapDetectorInitialized = false;
  bool _countdownShown = false;

  // calibration flag
  bool _noiseCalibrated = false;

  // AI companion
  AICompanionService? _aiCompanion;
  String _currentAIMessage = "";
  bool _showAIMessage = false;
  Timer? _aiMessageTimer;
  DateTime? _lastAIMessageTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudioSession();

    // Reset all state variables to default values
    _isLoading = true;
    _isPlaying = false;
    _duration = Duration.zero;
    _position = Duration.zero;
    _showBeatAnimation = false;
    _bpm = 90; // Default BPM
    _trackInfo = null;
    _userTapped = false;
    _tapInSync = false;
    _consecutiveSyncTaps = 0;
    _maxConsecutiveSyncTaps = 0;
    _totalTaps = 0;
    _lastBeatTime = null;
    _lastTapTime = null;
    _rhythmSpeedFactor = 1.0;
    _beatSkipFactor = 0;
    _beatCounter = 0;
    _trackLoaded = false;
    _clapDetectorInitialized = false;
    _countdownShown = false;
    _noiseCalibrated = false;

    _setupAudioPlayer();

    _initializeAICompanion();

    _clapDetector.init().then((_) {
      _clapDetector.onClapDetected = _handleClap;

      // Set up callbacks for calibration
      _clapDetector.onCalibrationUpdate = (level) {
        print("Calibration level update: $level");
      };

      _clapDetector.onCalibrationComplete = (threshold) {
        setState(() {
          _clapDetectorInitialized = true;
          _noiseCalibrated = true;
        });

        _checkReadyAndShowCountdown();
      };

      setState(() {
        _clapDetectorInitialized = true;
      });
    });

    _loadTrackOnly();
  }

  Future<void> _initializeAICompanion() async {
    try {
      final openAIKey = dotenv.env['OPENAI_API_KEY'];
      if (openAIKey == null || openAIKey.isEmpty) {
        throw Exception('OpenAI API key is not set in .env file');
      }

      _aiCompanion = AICompanionService(openAIKey: openAIKey);

      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser != null) {
        // Initialize AI Companion with user context
        await _aiCompanion!.initializeForPatient(currentUser.id);
        print("AI Companion initialized for user: ${currentUser.id}");
      } else {
        print("No user logged in, AI Companion will not have patient context");
      }
    } catch (e) {
      print('Error initializing AI Companion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing AI Companion: $e')),
        );
      }
    }
  }

  Future<void> _loadTrackOnly() async {
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

      // song bpm
      final songBpm = _trackInfo!['bpm'] ?? 90;

      // for songs with bpm > 100, default to "relaxed" rhythmn pace
      final defaultBeatSkipFactor = songBpm > 100 ? 1 : 0;

      // Extract BPM from metadata
      setState(() {
        _bpm = songBpm;
        _beatSkipFactor = defaultBeatSkipFactor;
        _isLoading = false;
        _trackLoaded = true; // Add this state variable
      });

      print("BPM extracted: $_bpm");

      // Check if both track and clap detector are ready
      _checkReadyAndShowCountdown();
    } catch (e) {
      print('Error in _loadTrackOnly: $e');
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

  //check everything is ready
  void _checkReadyAndShowCountdown() {
    print(
        "Checking readiness: track loaded: $_trackLoaded, detector initialized: $_clapDetectorInitialized, countdown shown: $_countdownShown");

    if (_trackLoaded && _clapDetectorInitialized && !_countdownShown) {
      if (!_noiseCalibrated) {
        print("Starting noise calibration flow");
        // Show noise calibration dialog first
        _showNoiseCalibrationDialog();
      } else {
        print("Skipping calibration, showing countdown directly");
        _showCountdownDialog();
      }
    }
  }

  void _showCountdownDialog() {
    setState(() {
      _countdownShown = true;
    });

    print("Displaying countdown dialog");

    // Show countdown dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CountdownDialog(
          onCountdownComplete: () {
            print("Countdown complete, starting playback");
            // Start everything when countdown completes
            _startPlaybackAndClapDetection();
          },
        );
      },
    );
  }

  void _showNoiseCalibrationDialog() {
    _clapDetector.onCalibrationUpdate = (level) {
      print("Calibration level update: $level");
    };

    _clapDetector.onCalibrationComplete = (threshold) {
      print("ClapDetector provided threshold: $threshold");
      setState(() {
        _noiseCalibrated = true;
      });
    };

    // Show dialog with improved callback handling
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return NoiseCalibrationDialog(
          onCalibrationComplete: (threshold) {
            print(
                "NoiseCalibrationDialog completed with threshold: $threshold");

            // Dialog is now closed, safe to show next dialog after a short delay
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) {
                print("Showing countdown dialog after calibration");
                _showCountdownDialog();
              }
            });
          },
        );
      },
    );

    // Start calibration process AFTER dialog is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("Starting calibration process");
      _clapDetector.startCalibration();
    });
  }

  Future<void> _startPlaybackAndClapDetection() async {
    try {
      // Start music playback
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

        // Start clap detection after music starts
        _clapDetector.startListening();
        print("Clap detection started!");
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to play song')),
        );
      }
    } catch (e) {
      print('Error starting playback and clap detection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleClap() {
    print("Clap detected!");

    if (!_isPlaying) return;

    final now = DateTime.now();

    setState(() {
      _userTapped = true;
      _totalTaps++;
      _lastTapTime = now;
    });

    // reset tap animation after a short delay
    Future.delayed(Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _userTapped = false;
        });
      }
    });

    if (_lastBeatTime != null) {
      final timeSinceLastBeat = now.difference(_lastBeatTime!).inMilliseconds;
      final effectiveBpm = _getEffectiveBpm(_bpm);
      final beatInterval = (60000 / effectiveBpm).round();

      final skipValue = _beatSkipFactor == 0
          ? 1
          : _beatSkipFactor == 1
              ? 2
              : 4;
      final adjustedInterval = beatInterval * skipValue;

      final timeSinceBeatMod = timeSinceLastBeat % adjustedInterval;
      final distanceFromBeat =
          min(timeSinceBeatMod, adjustedInterval - timeSinceBeatMod);

      final adjustedThreshold = _syncThreshold * (skipValue * 0.25 + 0.75);

      final isInSync = distanceFromBeat < adjustedThreshold;

      //calculate the clap quality
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

      _handleAIAnalysis();

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

  void _handleAIAnalysis() {
    if (_shouldTriggerAIEncouragement()) {
      _generateAIEncouragement();
    }
  }

  bool _shouldTriggerAIEncouragement() {
    return (_consecutiveSyncTaps > 0 &&
            _consecutiveSyncTaps % 5 == 0) || // every 5 consecutive taps
        (_totalTaps >= 10 && _totalTaps % 15 == 0) ||
        ((_consecutiveSyncTaps / _totalTaps) * 100 > 0.85) || //high accuracy
        (_position.inMinutes > 0 &&
            _position.inMinutes % 1 == 0 &&
            _position.inSeconds % 60 < 2); //every 1 mins
  }

  Future<void> _generateAIEncouragement() async {
    if (_aiCompanion == null) {
      print("AI Companion not initialized, skipping encouragement generation");
      return;
    }

    if(_lastAIMessageTime != null &&
        DateTime.now().difference(_lastAIMessageTime!).inSeconds < 10) {
      print("AI encouragement already sent recently, skipping this time");
      return; 
    }
    

    try {
      final currentAccuracy =
          _totalTaps > 0 ? _consecutiveSyncTaps / _totalTaps : 0.0;

      // compare if the patient performance improving
      final isImproving = _isPerformanceImproving();

      final encouragement = await _aiCompanion!.generateEncouragement(
        consecutiveClaps: _consecutiveSyncTaps,
        rhythmAccuracy: currentAccuracy,
        sessionMinutes: _position.inMinutes,
        currentSongTitle: widget.song['title'] ?? "Current Song",
        currentArtist: widget.song['artist'] ?? "Artist",
        difficultyLevel: _beatSkipFactor == 0
            ? 'Regular'
            : (_beatSkipFactor == 1 ? 'Relaxed' : 'Gentle'),
        isPerformanceImproving: isImproving,
      );

      _displayAIMessage(encouragement);
      _lastAIMessageTime = DateTime.now(); //update last message time
    } catch (e) {
      print('AI encrouragement generation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI encouragement failed: $e')),
        );
      }
    }
  }

  bool _isPerformanceImproving() {
    return _consecutiveSyncTaps > _maxConsecutiveSyncTaps * 0.7;
  }

  void _displayAIMessage(String message) {
    setState(() {
      _currentAIMessage = message;
      _showAIMessage = true;
    });

    _aiMessageTimer?.cancel();

    _aiMessageTimer = Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showAIMessage = false;
          _currentAIMessage = "";
        });
      }
    });
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
        _clapDetector.stopListening();
        print('App backgrounded: pausing playback and clap detection');
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
          _clapDetector.startListening();
        } else if (!isNowPlaying && _rhythmTimer != null) {
          print('Player stopped playing - cancelling rhythm timer');
          _rhythmTimer?.cancel();
          _rhythmTimer = null;
          // Ensure animation is stopped
          setState(() {
            _showBeatAnimation = false;
          });
          _clapDetector.stopListening();
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
        _clapDetector.startListening();
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

  //calculate a user-friendly BPM for interaction
  int _getEffectiveBpm(int songBpm) {
    //for very fast songs (faster than 160 BPM), use quarter-time
    if (songBpm > 160) {
      return (songBpm / 4).round();
    }

    //for fast songs (120-160 BPM), use half-time
    else if (songBpm > 120) {
      return (songBpm / 2).round();
    }

    //for very slow songs (slower than 50 BPM), use double-time
    else if (songBpm < 50) {
      return (songBpm * 2).round();
    }

    //for normal tempo songs (50-120 BPM), keep original BPM
    else {
      return songBpm;
    }
  }

  void _startRhythmNotifications() {
    //cancel existing timer if any
    if (_rhythmTimer != null) {
      print('Cancelling existing rhythm timer before starting a new one');
      _rhythmTimer?.cancel();
      _rhythmTimer = null;
    }

    //only start if we're playing
    if (!_isPlaying) {
      print('Not starting rhythm timer because not playing');
      return;
    }

    //get the song's BPM and calculate user friendlyyyy BPM
    final songBpm = _bpm;
    final effectiveBpm = _getEffectiveBpm(songBpm);

    //calculate milliseconds per beat based on the adjusted BPM
    final beatInterval = (60000 / effectiveBpm).round();

    //reset beat counter
    _beatCounter = 0;

    final animVisibleDuration =
        400; // ms - how long the animation stays visible

    //calculate the skip value based on rhythm setting AND the effective BPM
    int skipValue;
    if (_beatSkipFactor == 0) {
      // Regular
      skipValue = 1;
    } else if (_beatSkipFactor == 1) {
      // Relaxed
      // For slower tempos, we want to use a larger skip value
      skipValue = effectiveBpm < 70 ? 1 : 2;
    } else {
      // Gentle
      // For slower tempo  use a smaller skip value to avoid too slow interaction
      skipValue = effectiveBpm < 60 ? 2 : 4;
    }

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

      //only show visual cue on selected beats based on skip factor
      final shouldShowCue = _beatCounter % skipValue == 0;

      //double check we're still playing and mounted
      if (mounted && _isPlaying) {
        setState(() {
          //only show the animation on selected beats
          _showBeatAnimation = shouldShowCue;

          //always update the last beat time for accurate timing calculations
          _lastBeatTime = DateTime.now();
        });

        //reset animation after the visible duration, but only if we showed it
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
        //if we're not playing anymore but timer is still active, cancel it
        print('Playback stopped but timer still running - cancelling timer');
        timer.cancel();
        _rhythmTimer = null;
        //ensure animation is stopped
        setState(() {
          _showBeatAnimation = false;
        });
      }
    });
  }

  //handle user taps to the rhythm
  void _handleUserTap() {
    if (!_isPlaying) return;

    final now = DateTime.now();
    setState(() {
      _userTapped = true;
      _totalTaps++;
      _lastTapTime = now;
    });

    //reset the tap animation after a short delay
    Future.delayed(Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _userTapped = false;
        });
      }
    });

    //check if the tap is in sync with the beat
    if (_lastBeatTime != null) {
      final timeSinceLastBeat = now.difference(_lastBeatTime!).inMilliseconds;
      final effectiveBpm = _getEffectiveBpm(_bpm);
      final beatInterval = (60000 / effectiveBpm).round();

      //calculate beat phase for sync detection - this takes into account the skipValue
      final skipValue = _beatSkipFactor == 0
          ? 1
          : _beatSkipFactor == 1
              ? 2
              : 4;
      final adjustedInterval = beatInterval * skipValue;

      //calculate how close the tap is to the nearest expected interaction point
      final timeSinceBeatMod = timeSinceLastBeat % adjustedInterval;
      final distanceFromBeat =
          min(timeSinceBeatMod, adjustedInterval - timeSinceBeatMod);

      //adjust tolerance based on interaction frequency - more time between cues = more tolerance
      final adjustedThreshold = _syncThreshold * (skipValue * 0.25 + 0.75);

      //if the tap is within the threshold of the beat, consider it in sync
      final isInSync = distanceFromBeat < adjustedThreshold;

      //calculate a "quality" score from 0-1 for this tap
      final tapQuality =
          1.0 - (distanceFromBeat / adjustedThreshold).clamp(0.0, 1.0);

      setState(() {
        _tapInSync = isInSync;
        if (isInSync) {
          _consecutiveSyncTaps++;
          _maxConsecutiveSyncTaps =
              max(_maxConsecutiveSyncTaps, _consecutiveSyncTaps);
        } else {
          //only reset completely on very bad timing
          if (tapQuality < 0.3) {
            _consecutiveSyncTaps = 0;
          } else if (_consecutiveSyncTaps > 0) {
            //just reduce for close misses
            _consecutiveSyncTaps--;
          }
        }
      });

      //provide appropriate haptic feedback based on timing accuracy
      if (_enableHapticFeedback) {
        if (tapQuality > 0.8) {
          HapticFeedback.heavyImpact(); //strong feedback for excellent timing
        } else if (tapQuality > 0.4) {
          HapticFeedback.mediumImpact(); //medium for decent timing
        } else {
          HapticFeedback.lightImpact(); //light for poor timing
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
        'user_id': supabase.auth.currentUser?.id ?? 'anonymous',
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

    _clapDetector.stopListening();

    //get rhythm level description
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
              color: AppColors.deepBlue,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.info,
                color: success ? Colors.green : AppColors.primaryBlue,
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
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.5),
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
                        color: AppColors.deepBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You clapped $_totalTaps times and maintained rhythm for up to $_consecutiveSyncTaps consecutive beats.",
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
                  color: AppColors.primaryBlue,
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

    // stop listening to the claps
    _clapDetector.stopListening();

    if (_isPlaying) {
      _pausePlayback();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Player Settings",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            // Added SingleChildScrollView here
            child: Column(
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
                  // activeColor: AppColors.primaryBlue,
                  activeTrackColor: AppColors.primaryBlue,
                  title:
                      Text("Show 'Clap NOW' Guide", style: GoogleFonts.inter()),
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
                  activeTrackColor: AppColors.primaryBlue,
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
                        child: Text("Timing Tolerance:",
                            style: GoogleFonts.inter()),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Slider(
                    activeColor: AppColors.primaryBlue,
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
                            ? AppColors.primaryBlue
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _beatSkipFactor == 0
                          ? AppColors.primaryBlue.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.speed,
                          color: _beatSkipFactor == 0
                              ? AppColors.primaryBlue
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
                            color: AppColors.primaryBlue,
                          ),
                      ],
                    ),
                  ),
                ),

                // Medium Pace (Every 2nd Beat)
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
                            ? AppColors.primaryBlue
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _beatSkipFactor == 1
                          ? AppColors.primaryBlue.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: _beatSkipFactor == 1
                              ? AppColors.primaryBlue
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
                            color: AppColors.primaryBlue,
                          ),
                      ],
                    ),
                  ),
                ),

                // Slow Pace (Every 4th Beat)
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
                            ? AppColors.primaryBlue
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _beatSkipFactor == 2
                          ? AppColors.primaryBlue.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.accessibility_new,
                          color: _beatSkipFactor == 2
                              ? AppColors.primaryBlue
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
                            color: AppColors.primaryBlue,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                "Close",
                style: TextStyle(
                  color: AppColors.primaryBlue,
                ),
              ),
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
      feedbackText = "Start clapping to the beat!";
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
      _clapDetector.stopListening();

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
      _clapDetector.startListening();
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

    // Reset counters and state variables
    _consecutiveSyncTaps = 0;
    _maxConsecutiveSyncTaps = 0;
    _totalTaps = 0;
    _beatCounter = 0;

    // Stop playback before disposing
    _musicService.stop();

    // clap detector dispose
    _clapDetector.dispose();

    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  Widget _buildAIMessageOverlay() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50.withOpacity(0.95),
            Colors.orange.shade50.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology,
              color: Colors.amber.shade700,
              size: 16,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "AI Therapy Companion",
                  style: GoogleFonts.inter(
                    color: Colors.amber.shade800,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _currentAIMessage,
                  style: GoogleFonts.inter(
                    color: Colors.amber.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showAIMessage = false;
                _currentAIMessage = "";
              });
              _aiMessageTimer?.cancel();
            },
            child: Container(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                color: Colors.amber.shade600,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBpm = _getEffectiveBpm(_bpm);

    return WillPopScope(
      onWillPop: () async {
        // Make sure we properly stop the music and clean up before popping
        print('Back button pressed, cleaning up before navigation');
        _rhythmTimer?.cancel();
        _aiMessageTimer?.cancel(); // cleanup AI timer
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
                AppColors.deepBlue,
                AppColors.black,
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
                    color: AppColors.primaryBlue,
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      // Header with back button and settings button
                      Padding(
                        padding: const EdgeInsets.all(8.0),
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
                                _aiMessageTimer?.cancel(); // cleanup AI timer
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

                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: _showAIMessage ? null : 0,
                        child: _showAIMessage
                            ? Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: _buildAIMessageOverlay(),
                              )
                            : SizedBox.shrink(),
                      ),

                      // Album art and beat animation in a GestureDetector
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
                                    color: AppColors.primaryBlue.withOpacity(
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
                                    color: AppColors.primaryBlue.withOpacity(
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
                                    color: AppColors.primaryBlue.withOpacity(
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
                                        "Clap Now",
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
                                    thumbColor: AppColors.primaryBlue,
                                    activeTrackColor: AppColors.primaryBlue,
                                    inactiveTrackColor:
                                        Colors.white.withOpacity(0.3),
                                    trackHeight: 4.0,
                                    disabledThumbColor: AppColors
                                        .primaryBlue, // Important for disabled slider
                                    disabledActiveTrackColor: AppColors
                                        .primaryBlue, // Important for disabled slider
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
                                          color: AppColors.primaryBlue,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryBlue
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
                                    // Text(
                                    //   "Tap along with the rhythm!",
                                    //   style: GoogleFonts.inter(
                                    //     color: Colors.white.withOpacity(0.6),
                                    //     fontSize: 14,
                                    //   ),
                                    //   textAlign: TextAlign.center,
                                    // ),
                                    // SizedBox(height: 2),
                                    // RichText(
                                    //   textAlign: TextAlign.center,
                                    //   text: TextSpan(
                                    //     style: GoogleFonts.inter(
                                    //       fontSize: 12,
                                    //       color: Colors.white.withOpacity(0.7),
                                    //     ),
                                    //     children: [
                                    //       TextSpan(
                                    //         text: "Original BPM: $_bpm",
                                    //       ),
                                    //       TextSpan(
                                    //         text: " • Adjusted: $effectiveBpm",
                                    //         style: GoogleFonts.inter(
                                    //           fontWeight: FontWeight.bold,
                                    //         ),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
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
