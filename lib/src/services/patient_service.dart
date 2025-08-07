import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/src/models/patient_history_model.dart';
import 'package:flutter_app/src/models/patient_session_model.dart';
import 'package:flutter_app/src/models/session_details_model.dart';
import 'package:flutter_app/src/services/api_service.dart';
import 'package:flutter_app/src/services/auth_service.dart';

class Patient {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;

  Patient({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'].toString(),
      fullName: json['full_name'] ?? 'Unknown',
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class PatientSearchResponse {
  final List<Patient> patients;
  final String message;
  final String status;

  PatientSearchResponse({
    required this.patients,
    required this.message,
    required this.status,
  });

  factory PatientSearchResponse.fromJson(Map<String, dynamic> json) {
    return PatientSearchResponse(
      patients: (json['data'] as List)
          .map((patientJson) => Patient.fromJson(patientJson))
          .toList(),
      message: json['message'] ?? '',
      status: json['status'] ?? 'error',
    );
  }
}

class PatientService {
  static Future<PatientSearchResponse> getAllPatients() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/patients'),
        headers: ApiService.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return PatientSearchResponse.fromJson({
          'data': json.decode(response.body)['data'],
          'message': 'Success',
          'status': 'success'
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch patients');
      }
    } catch (e) {
      throw Exception('Failed to fetch patients: $e');
    }
  }

  static Future<PatientSearchResponse> searchPatients(String query, {int limit = 10}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/patients/search?query=$query&limit=$limit'),
        headers: ApiService.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return PatientSearchResponse.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to search patients');
      }
    } catch (e) {
      throw Exception('Failed to search patients: $e');
    }
  }

  static Future<PatientSessionResponse> getPatientSessions(String patientId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/patients/$patientId/sessions'),
        headers: ApiService.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return PatientSessionResponse.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch patient sessions');
      }
    } catch (e) {
      throw Exception('Failed to fetch patient sessions: $e');
    }
  }

  static Future<PatientHistoryResponse> getPatientHistory(String patientId) async {
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

  static Future<SessionDetailsResponse> getSessionDetails(String sessionId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/sessions/$sessionId'),
        headers: ApiService.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return SessionDetailsResponse.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load session details');
      }
    } catch (e) {
      throw Exception('Failed to load session details: $e');
    }
  }
}
