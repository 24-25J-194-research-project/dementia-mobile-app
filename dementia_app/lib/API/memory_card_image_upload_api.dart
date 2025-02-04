import 'dart:convert';
import 'package:dementia_app/Shared/constants.dart';
import 'package:http/http.dart' as http;

class MemoryCardUploadApiService {
  final String baseUrl = Constants.baseAPIUrl;

  Future<bool> uploadMemoryCardData(List<Map<String, dynamic>> cardData) async {
    try {
      final List<Future<http.Response>> requests = [];
      
      for (final card in cardData) {
        final response = http.post(
          Uri.parse('$baseUrl/api/memory-cards'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(card),
        );
        requests.add(response);
      }
      
      //wait for all requests to complete
      final responses = await Future.wait(requests);
      
      //check if any request failed
      for (final response in responses) {
        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception('Failed to upload card data: ${response.body}');
        }
      }
      
      return true;
    } catch (e) {
      throw Exception('API error: $e');
    }
  }
}