import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dementia_app/melody_mind/services/analytics_service.dart';

class AIClinicalSummaryService {
  static final AIClinicalSummaryService _instance =
      AIClinicalSummaryService._internal();
  factory AIClinicalSummaryService() => _instance;
  AIClinicalSummaryService._internal();

  final AnalyticsService _analyticsService = AnalyticsService();
  final String _openAIEndpoint = 'https://api.openai.com/v1/chat/completions';

  Future<ClinicalSummary> generateClinicalSummary({
    required String patientId,
  }) async {
    try {
      //gather user information
      final userProfile = await _analyticsService.getUserProfile();
      final sessionData = await _analyticsService.getUserSessionData();
      final aggregatedStats = await _analyticsService.getUserAggregatedStats();
      final weeklyProgress = await _analyticsService.getWeeklyProgressData();

      //build prompt by using user's raw data
      final prompt = _buildRawDataPrompt(
        userProfile: userProfile,
        sessionData: sessionData,
        aggregatedStats: aggregatedStats,
        weeklyProgress: weeklyProgress,
      );

      final aiResponse = await _callOpenAI(prompt);

      //convert AI response into structured clinical summary
      return _parseClinicalSummary(aiResponse, aggregatedStats);
    } catch (e) {
      log('Error generating clinical summary: $e');
      throw Exception('Failed to generate clinical summary: $e');
    }
  }

  ///build the raw data prompt for OpenAI
  String _buildRawDataPrompt({
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> sessionData,
    required Map<String, dynamic> aggregatedStats,
    required List<Map<String, dynamic>> weeklyProgress,
  }) {
    final rawDataPackage = {
      'patient_profile': userProfile,
      'session_data': sessionData,
      'aggregated_statistics': aggregatedStats,
      'weekly_progress': weeklyProgress,
    };

    log("Raw Data Package: ${jsonEncode(rawDataPackage)}");
    return '''
You are a clinical music therapist and neurologist specializing in dementia care. 
I'm providing you with raw music therapy session data for a patient. Please analyze this data and provide a professional clinical summary.

IMPORTANT: Use your medical knowledge to interpret what these patterns mean clinically. Look for meaningful changes, assess clinical significance based on established research, and provide evidence-based insights.

RAW PATIENT DATA:
${jsonEncode(rawDataPackage)}

CLINICAL CONTEXT FOR INTERPRETATION:
- Music therapy for dementia patients typically shows benefits in cognitive function, mood, and behavioral symptoms
- Rhythm accuracy reflects temporal processing abilities and procedural memory function
- Session consistency indicates engagement, motivation, and cognitive stamina
- Progressive changes over time may indicate disease progression or therapeutic effectiveness
- Individual variations should be considered within the context of dementia stages and comorbidities

Please analyze the data and return your findings in this JSON format (do not include any explanations or extra text):

{
  "executive": "2-3 sentence summary highlighting key findings.",
  "clinical": "Detailed paragraph analyzing cognitive and behavioral indicators, clinical significance, and actionable recommendations based on the data patterns."
}

Requirements:
- Use evidence-based clinical language appropriate for healthcare professionals
- Identify patterns that are clinically significant vs. normal variation
- Provide specific, actionable recommendations within the narrative
- Include appropriate caveats about limitations of remote data analysis
- Consider the data within the broader context of dementia care
- The clinical paragraph must be one comprehensive paragraph, no subheadings or lists
- The response must be valid JSON
''';
  }

  ///call OpenAI API with the raw data prompt
  Future<String> _callOpenAI(String prompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a clinical music therapist and neurologist with extensive experience in dementia care. Provide professional, evidence-based clinical analysis of music therapy data. Draw upon established research in music therapy for dementia to inform your interpretations.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'max_tokens': 1500,
      'temperature': 0.2,
    });

    final response = await http.post(
      Uri.parse(_openAIEndpoint),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception(
          'OpenAI API error: ${response.statusCode} - ${response.body}');
    }
  }

  ClinicalSummary _parseClinicalSummary(
      String aiResponse, Map<String, dynamic> stats) {
    log("AI Response: $aiResponse");

    final sections = _extractSummarySection(aiResponse);

    return ClinicalSummary(
      executiveSummary:
          sections['executive'] ?? 'Executive summary not generated',
      cognitiveAssessment:
          sections['clinical'] ?? 'Clinical assessment not generated',
      generatedAt: DateTime.now(),
      keyMetrics: ClinicalMetrics(
        averageAccuracy: stats['avg_rhythm_accuracy'] ?? 0.0,
        totalSessions: stats['total_sessions'] ?? 0,
        engagementTrend: 'AI-analyzed',
      ),
    );
  }

  ///extract structured sections from AI response
  Map<String, String> _extractSummarySection(String aiResponse) {
    try {
      final decoded = jsonDecode(aiResponse);
      return {
        'executive': decoded['executive']?.toString().trim() ?? '',
        'clinical': decoded['clinical']?.toString().trim() ?? ''
      };
    } catch (e) {
      // Handle invalid JSON or unexpected format
      return {'executive': '', 'clinical': ''};
    }
  }
}

class ClinicalSummary {
  final String executiveSummary;
  final String cognitiveAssessment;
  final DateTime generatedAt;
  final ClinicalMetrics keyMetrics;

  ClinicalSummary({
    required this.executiveSummary,
    required this.cognitiveAssessment,
    required this.generatedAt,
    required this.keyMetrics,
  });
}

class ClinicalMetrics {
  final double averageAccuracy;
  final int totalSessions;
  final String engagementTrend;

  ClinicalMetrics({
    required this.averageAccuracy,
    required this.totalSessions,
    required this.engagementTrend,
  });
}
