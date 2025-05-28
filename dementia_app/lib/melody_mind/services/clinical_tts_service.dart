import 'dart:developer';
import 'package:flutter_tts/flutter_tts.dart';

class ClinicalTTSService {
  static final ClinicalTTSService _instance = ClinicalTTSService._internal();
  factory ClinicalTTSService() => _instance;
  ClinicalTTSService._internal();

  late FlutterTts _flutterTts;
  bool _isInitialized = false;
  bool _isPlaying = false;

  //playback controls
  Function()? onSpeakStart;
  Function()? onSpeakComplete;
  Function(String)? onSpeakProgress;
  Function(String)? onError;

  //default settings
  double _speechRate = 0.5; //speech rate
  double _volume = 0.8;
  double _pitch = 1.0;
  String _language = 'en-US';
  String _voiceType = 'default';

  Future<bool> initialize() async {
    try {
      _flutterTts = FlutterTts();

      await _setupTTSHandlers();
      await _configureMedicalSettings();

      _isInitialized = true;
      log('Clinical TTS Service initialized successfully');
      return true;
    } catch (e) {
      log('Error initializing TTS service: $e');
      onError?.call('Failed to initialize text-to-speech: $e');
      return false;
    }
  }

  Future<void> _setupTTSHandlers() async {
    //handle speech start
    _flutterTts.setStartHandler(() {
      _isPlaying = true;
      onSpeakStart?.call();
      log('TTS: Speech started');
    });

    //handle speech completion
    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      onSpeakComplete?.call();
      log('TTS: Speech completed');
    });

    //handle progress updates
    _flutterTts
        .setProgressHandler((String text, int start, int end, String word) {
      onSpeakProgress?.call(word);
    });

    //handle errors
    _flutterTts.setErrorHandler((message) {
      _isPlaying = false;
      onError?.call(message);
      log('TTS Error: $message');
    });
  }

  Future<void> _configureMedicalSettings() async {
    await _flutterTts.setLanguage(_language);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);
    await _setOptimalVoice();
  }

  Future<void> _setOptimalVoice() async {
    try {
      List<dynamic> voices = await _flutterTts.getVoices;

      dynamic bestVoice;
      for (var voice in voices) {
        String voiceName = voice['name'].toString().toLowerCase();
        String locale = voice['locale'].toString();

        if (locale.startsWith('en-')) {
          if (voiceName.contains('neural') ||
              voiceName.contains('enhanced') ||
              voiceName.contains('premium')) {
            bestVoice = voice;
            break;
          }

          bestVoice ??= voice;
        }
      }

      if (bestVoice != null) {
        await _flutterTts.setVoice(
            {'name': bestVoice['name'], 'locale': bestVoice['locale']});
        _voiceType = bestVoice['name'];
        log('TTS: Set voice to ${bestVoice['name']}');
      }
    } catch (e) {
      log('TTS: Could not set specific voice, using default: $e');
    }
  }

  Future<bool> speakClinicalSummary(String summaryText) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      await stop();

      String processedText = _preprocessMedicalText(summaryText);

      await _flutterTts.speak(processedText);
      return true;
    } catch (e) {
      log('Error speaking clinical summary: $e');
      onError?.call('Failed to start speech synthesis: $e');
      return false;
    }
  }

  Future<bool> speakSection(String sectionTitle, String sectionContent) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      await stop();

      await Future.delayed(Duration(milliseconds: 100));

      String formattedText =
          _formatSectionForSpeech(sectionTitle, sectionContent);
      String processedText = _preprocessMedicalText(formattedText);

      await _flutterTts.speak(processedText);
      return true;
    } catch (e) {
      log('Error speaking section: $e');
      onError?.call('Failed to speak section: $e');
      return false;
    }
  }

  ///pre process the medical text with improved percentage handling
  String _preprocessMedicalText(String text) {
    String processed = text;

    processed = processed.replaceAllMapped(RegExp(r'([A-Z][A-Z\s]+):'),
        (match) => '${match.group(1)}. ... ' // Add pause after section headers
        );

    processed =
        processed.replaceAllMapped(RegExp(r'(\d+(?:\.\d+)?)%'), (match) {
      String number = match.group(1)!;
      return '$number percent';
    });

    processed =
        processed.replaceAllMapped(RegExp(r'(\d+)\.(\d+) percent'), (match) {
      String whole = match.group(1)!;
      String decimal = match.group(2)!;
      return '$whole point $decimal percent';
    });

    processed = processed.replaceAllMapped(RegExp(r'(\d+(?:\.\d+)? percent)\.'),
        (match) => '${match.group(1)}. ... ');

    processed = processed.replaceAllMapped(
        RegExp(r'(\d+)\.'), (match) => '${match.group(1)}. ... ');

    // replace common medical abbreviations with full terms
    final medicalAbbreviations = {
      'BPM': 'beats per minute',
      'mins': 'minutes',
      'vs.': 'versus',
      'e.g.': 'for example',
      'i.e.': 'that is',
      'etc.': 'and so on',
      'ADLs': 'activities of daily living',
      'IADLs': 'instrumental activities of daily living',
      'MT': 'music therapy',
      'EEG': 'electroencephalogram',
      'CNS': 'central nervous system',
      'RAS': 'rhythmic auditory stimulation',
    };

    medicalAbbreviations.forEach((abbrev, replacement) {
      processed =
          processed.replaceAll(RegExp(r'\b' + abbrev + r'\b'), replacement);
    });

    processed = processed.replaceAll('. ', '. ... ');
    processed = processed.replaceAll(', ', ', ');

    return processed;
  }

  String _formatSectionForSpeech(String title, String content) {
    return '$title. ... $content';
  }

  Future<void> stop() async {
    try {
      if (_isPlaying) {
        await _flutterTts.stop();
      }
      _isPlaying = false;
      onSpeakComplete?.call();
      log('TTS: Stopped and state reset');
    } catch (e) {
      log('TTS: Error during stop: $e');
      _isPlaying = false;
      onSpeakComplete?.call();
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
  }

  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  String get currentVoice => _voiceType;
  String get currentLanguage => _language;

  void dispose() {
    try {
      stop();
      _isInitialized = false;
      log('TTS: Service disposed');
    } catch (e) {
      log('TTS: Error during dispose: $e');
      _isInitialized = false;
    }
  }
}
