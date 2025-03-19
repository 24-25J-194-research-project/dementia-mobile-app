import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../features/auth/presentation/providers/auth_service.dart';
import 'firebase_base_url_service.dart';

class MemoryVaultApiClient {
  final AuthService _authService = AuthService();
  final FirebaseBaseUrlService _firebaseBaseUrlService = FirebaseBaseUrlService();
  String? _baseUrl;

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getFreshIdToken();
    if (token != null) {
      return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
    } else {
      throw Exception('User is not authenticated');
    }
  }

  Future<String> getBaseUrl() async {
    if (_baseUrl != null) {
      return _baseUrl!;
    } else {
      try {
        _baseUrl = await _firebaseBaseUrlService.fetchBaseUrl();
        return _baseUrl!;
      } catch (e) {
        throw Exception('Failed to fetch base URL: $e');
      }
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getAuthHeaders();
    final baseUrl = await getBaseUrl();

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      body: body != null ? json.encode(body) : null,
      headers: headers,
    );
    return _processResponse(response);
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }
}
