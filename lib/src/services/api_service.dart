import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class ApiService {
  // For web, use localhost, for Android emulator use 10.0.2.2, for physical device use your computer's IP
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else {
      // For Android emulator
      return 'http://10.0.2.2:8000/api';
      
      // For physical device, uncomment and replace with your computer's IP
      // return 'http://YOUR_COMPUTER_IP:8000/api';
    }
  }

  // Add headers for authenticated requests with CORS support
  static Map<String, String> getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // CORS headers
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token',
    };
    
    // Add authorization header if token is provided
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Handle API responses
  static dynamic _handleResponse(http.Response response) {
    final responseBody = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      // Handle validation errors (422)
      if (response.statusCode == 422 && responseBody is Map) {
        final errors = responseBody['errors'] ?? responseBody;
        final errorMessage = StringBuffer('Validation Error\n');
        
        errors.forEach((key, value) {
          if (value is List) {
            errorMessage.writeln('$key: ${value.join(', ')}');
          } else {
            errorMessage.writeln('$key: $value');
          }
        });
        
        throw Exception(errorMessage.toString());
      }
      
      throw Exception(
        'Failed to load data: ${response.statusCode} - ${responseBody['message'] ?? response.body}',
      );
    }
  }

  // Create a new appointment
  static Future<Map<String, dynamic>> createAppointment({
    required int patientId,
    required String date,
    required String time,
    required String appointmentType,
    required int durationMinutes,
    String? note,
    required String token,
  }) async {
    try {
      // Create the request data
      final Map<String, dynamic> appointmentData = {
        'patient_id': patientId,
        'date': date,
        'time': time,
        'appointment_type': appointmentType,
        'duration_minutes': durationMinutes,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      // Log the full request details
      print('=== Appointment Request ===');
      print('URL: $baseUrl/appointments');
      print('Method: POST');
      print('Headers: ${getHeaders(token: token)}');
      print('Body: ${jsonEncode(appointmentData)}');
      print('==========================');
      
      final response = await http.post(
        Uri.parse('$baseUrl/appointments'),
        headers: {
          ...getHeaders(token: token),
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(appointmentData),
      );

      print('=== Appointment Response ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('==========================');

      return _handleResponse(response);
    } catch (e) {
      print('Error creating appointment: $e');
      rethrow;
    }
  }

  // Create a new patient with appointment (kept for backward compatibility)
  static Future<Map<String, dynamic>> createPatientWithAppointment(
    Map<String, dynamic> patientData, {
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patients'),
        headers: getHeaders(token: token),
        body: jsonEncode(patientData),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get all patients
  static Future<List<Map<String, dynamic>>> getPatients({
    required String token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/patients');
      print('API Request: GET $url');
      final headers = getHeaders(token: token);
      print('Headers: $headers');
      
      // For web, we need to handle CORS preflight
      final response = await http.get(
        url,
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      print('API Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Debug: Print the raw response for inspection
        print('API Response Body (parsed): $responseBody');
        
        // Handle paginated response format
        if (responseBody is Map && responseBody['data'] is List) {
          final patients = List<Map<String, dynamic>>.from(responseBody['data']);
          print('Found ${patients.length} patients in paginated response');
          return patients;
        } 
        // Handle non-paginated list response
        else if (responseBody is List) {
          final patients = List<Map<String, dynamic>>.from(responseBody);
          print('Found ${patients.length} patients in list response');
          return patients;
        } 
        // Handle single patient object
        else if (responseBody is Map && responseBody['data'] is Map) {
          print('Found single patient object');
          return [responseBody['data']];
        } 
        // Handle error in response
        else if (responseBody is Map && responseBody['status'] == 'error') {
          throw Exception(responseBody['message'] ?? 'Failed to load patients');
        } 
        // Unknown format
        else {
          print('Unexpected response format: $responseBody');
          throw Exception('Invalid response format: Expected list or data field');
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Failed to load patients: ${response.statusCode} - ${responseBody['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      rethrow;
    }
  }

  // Complete a session with all details including file uploads
  static Future<Map<String, dynamic>> completeSession({
    required int sessionId,
    required String token,
    String? physicalHealthNotes,
    String? mentalHealthNotes,
    String? medicationNotes,
    String? selectedDosage,
    List<String>? imagePaths,
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/sessions/$sessionId/complete'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add text fields
      if (physicalHealthNotes != null && physicalHealthNotes.isNotEmpty) {
        request.fields['physical_health_notes'] = physicalHealthNotes;
      }
      
      if (mentalHealthNotes != null && mentalHealthNotes.isNotEmpty) {
        request.fields['mental_health_notes'] = mentalHealthNotes;
      }
      
      if (medicationNotes != null && medicationNotes.isNotEmpty) {
        request.fields['medication_notes'] = medicationNotes;
      }
      
      if (selectedDosage != null && selectedDosage.isNotEmpty) {
        request.fields['dosage'] = selectedDosage;
      }

      // Add image files
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (var imagePath in imagePaths) {
          var file = File(imagePath);
          var stream = http.ByteStream(file.openRead());
          var length = await file.length();
          var multipartFile = http.MultipartFile(
            'prescription_images[]',
            stream,
            length,
            filename: path.basename(imagePath),
            contentType: MediaType('image', path.extension(imagePath).substring(1)),
          );
          request.files.add(multipartFile);
        }
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Log the response
      print('=== Complete Session Response ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('================================');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        var errorResponse = jsonDecode(response.body);
        throw Exception(
          errorResponse['message'] ??
          'Failed to complete session: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error completing session: $e');
      rethrow;
    }
  }
}
