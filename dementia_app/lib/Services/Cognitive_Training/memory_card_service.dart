import 'dart:convert';
import 'package:dementia_app/Shared/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  final String baseUrl = Constants.baseAPIUrl;
  final supabase = Supabase.instance.client;
  
  //singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  //headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Fetch memory cards from Supabase database
  Future<List<Map<String, String>>> fetchMemoryCards() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Query the memory_card table for current user's cards
      final response = await supabase
          .from('memory_card')
          .select('card_text, image_url')
          .eq('user_id', user.id)
          .eq('cognitive_training_id', 3);
      
      // Convert response to format needed by MemoryCardGamePage
      final List<Map<String, String>> cards = [];
      
      for (var item in response) {
        cards.add({
          'text': item['card_text'] as String,
          'image_url': item['image_url'] as String,
        });
      }
      
      return cards;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching memory cards: $e');
      }
      throw Exception('Failed to fetch memory cards: $e');
    }
  }

  //save memory card training history
  Future<bool> saveMemoryCardHistory({
    required String level,
    required int attempts,
  }) async {
    try {
      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) return false;
      
      final userId = user.id;
      
      //memory card is cognitive training ID 3
      const cognitiveTrainingId = 3;
      
      //calculate score
      final score = 100 - (attempts * 5);
      
      //create request body
      final body = {
        'user_id': userId,
        'cognitive_training_id': cognitiveTrainingId,
        'level': level.toLowerCase(),
        'score': score,
        'error_count': attempts
      };
      
      //make API call
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/cognitive-training-history'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving memory card history: $e');
      }
      return false;
    }
  }
}