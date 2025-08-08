import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/session.dart';

class SessionService {
  final String baseUrl = 'https://spandan.koptotech.solutions/api'; // Live production URL

  Future<Session> getSessionById(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return Session.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load session: $e');
    }
  }

  Future<void> updateSessionNotes({
    required String sessionId,
    required String notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/sessions/$sessionId/notes'),
        headers: await _getHeaders(),
        body: json.encode({'notes': notes}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update session notes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update session notes: $e');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    // TODO: Add your authentication token here if needed
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
