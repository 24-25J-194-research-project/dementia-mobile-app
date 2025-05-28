import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AICompanionService {
  final String openAIKey;

  // cache ai message for reducing api calls
  final Map<String, String> _messageCache = {};

  //loaded from existing user data
  Map<String, dynamic> _patientContext = {};

  AICompanionService({required this.openAIKey});

  Future<void> initializeForPatient(String patientId) async {
    _patientContext = {
      'patientId': patientId,
      'culturalBackground': 'Sri Lankan elderly',
      'musicPreference': 'Sinhala traditional and popular music',
      'therapyGoals': 'joy, connection, and cultural memory activation'
    };
  }

  Future<String> generateEncouragement({
    required int consecutiveClaps,
    required double rhythmAccuracy,
    required int sessionMinutes,
    required String currentSongTitle,
    required String currentArtist,
    required String difficultyLevel,
    required bool isPerformanceImproving,
  }) async {
    //create cache key
    final cacheKey =
        '${consecutiveClaps}_${(rhythmAccuracy * 100).round()}_${currentSongTitle}';
    if (_messageCache.containsKey(cacheKey)) {
      return _messageCache[cacheKey]!;
    }

    //bbuild context related prompt
    final prompt = _buildEncouragementPrompt(
      consecutiveClaps: consecutiveClaps,
      rhythmAccuracy: rhythmAccuracy,
      sessionMinutes: sessionMinutes,
      currentSongTitle: currentSongTitle,
      currentArtist: currentArtist,
      difficultyLevel: difficultyLevel,
      isPerformanceImproving: isPerformanceImproving,
    );

    try {
      final response = await _callOpenAI(prompt, maxTokens: 80);
      _messageCache[cacheKey] = response;
      return response;
    } catch (e) {
      // if openAPI call fails, fallback to a default message
      return _getFallbackMessage(consecutiveClaps, rhythmAccuracy);
    }
  }

  // build the prompt for OpenAI
  String _buildEncouragementPrompt({
    required int consecutiveClaps,
    required double rhythmAccuracy,
    required int sessionMinutes,
    required String currentSongTitle,
    required String currentArtist,
    required String difficultyLevel,
    required bool isPerformanceImproving,
  }) {
    return '''
You are a warm, compassionate AI companion helping elderly Sri Lankan patients during music therapy sessions.  
Your role is to offer gentle, uplifting encouragement that helps the patient feel connected, joyful, and engaged.

SESSION DETAILS:
- Patient is enjoying: "$currentSongTitle" by $currentArtist
- They’ve been clapping in time for several moments: $consecutiveClaps claps
- They're showing great rhythm and focus
- They've been with the music for: $sessionMinutes minutes
- Song difficulty: $difficultyLevel
- Overall, they are ${isPerformanceImproving ? 'getting more engaged' : 'staying steadily involved'}

CULTURAL CONTEXT:
- This is Sinhala music with emotional and cultural meaning
- The patient is an elderly Sri Lankan, so speak with warmth, respect, and kindness
- Focus on emotional connection, not technical progress

YOUR RESPONSE (limit to 15–20 words):
- Praise the patient’s effort warmly
- Mention something beautiful about the music or artist if it fits
- Encourage continued joy or connection without pressure
- Do not use technical terms like “accuracy,” “metrics,” “performance,” or “consecutive”

GOOD EXAMPLES:
- "Such lovely clapping – you’re really feeling the music of $currentArtist!"
- "This melody brings back beautiful memories, and you’re right there with it."
- "You’re doing wonderfully. What a beautiful moment with $currentSongTitle!"
- "So heartwarming to see you enjoying this rhythm – keep going if you feel like it!"

Always prioritize emotional warmth and cultural sensitivity.
''';
  }

  // core openAPI api integration
  Future<String> _callOpenAI(String prompt, {int maxTokens = 40}) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openAIKey',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a compassionate AI music therapy assistant specializing in culturally-sensitive care for Sri Lankan elderly dementia patients.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': maxTokens,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('OpenAI API call failed: ${response.statusCode}');
    }
  }

  // fallback message if OpenAI call fails
  String _getFallbackMessage(int consecutiveClaps, double rhythmAccuracy) {
    if (consecutiveClaps >= 5) {
      return "Excellent rhythm! Your ${consecutiveClaps} consecutive claps show wonderful focus.";
    } else if (rhythmAccuracy > 0.8) {
      return "Beautiful clapping in sync with the music. keep up great engagement!";
    } else {
      return "Thank you for participating. Every clap shows your connection to the music.";
    }
  }
}
