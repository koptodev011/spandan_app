import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/src/models/patient_history_model.dart';
import 'package:flutter_app/src/services/api_service.dart';
import 'package:flutter_app/src/services/auth_service.dart';

class PatientService {
  static Future<PatientHistoryResponse> getPatientHistory(int patientId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/sessions/patient/$patientId/history'),
        headers: ApiService.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return PatientHistoryResponse.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load patient history');
      }
    } catch (e) {
      throw Exception('Failed to load patient history: $e');
    }
  }
}
