import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class PaymentService {
  // Live production URL
  static String get baseUrl => 'https://spandan.koptotech.solutions/api';

  PaymentService();

  Future<String?> _getToken() async {
    return await AuthService.getToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please log in again.');
    }
    
    print('Using token for API request: ${token.substring(0, 10)}...');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _makeRequest(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    dynamic body,
    String method = 'GET',
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters,
      );

      print('Making $method request to: $uri');
      
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode >= 400) {
        throw Exception(
          responseData['message'] ??
              'Request failed with status: ${response.statusCode}',
        );
      }

      return responseData;
    } catch (e) {
      print('Error in _makeRequest: $e');
      rethrow;
    }
  }

  // Create a new payment (expense/income)
  // Get paginated list of payments with optional filters
  Future<Map<String, dynamic>> getPayments({
    String type = 'all',
    String category = 'all',
    String search = '',
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (type != 'all') {
        queryParams['type'] = type;
      }
      if (category != 'all') {
        queryParams['category'] = category;
      }
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _makeRequest(
        '/payments',
        queryParameters: queryParams,
      );

      return response;
    } catch (e) {
      print('Error fetching payments: $e');
      rethrow;
    }
  }

  // Get payment summary (total income, expenses, net income)
  Future<Map<String, dynamic>> getPaymentSummary() async {
    try {
      final response = await _makeRequest('/payments/summary');
      return response;
    } catch (e) {
      print('Error fetching payment summary: $e');
      rethrow;
    }
  }

  // Get available payment categories
  Future<Map<String, dynamic>> getPaymentCategories() async {
    try {
      final response = await _makeRequest('/payments/categories');
      return response;
    } catch (e) {
      print('Error fetching payment categories: $e');
      rethrow;
    }
  }

  // Create a new payment (expense/income)
  Future<Map<String, dynamic>> createPayment({
    required String type,
    required double amount,
    required String description,
    required String category,
    required DateTime date,
    String paymentMethod = 'cash',
    String? referenceNumber,
    String status = 'completed',
    String? patientId,
    String? notes,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/payments');
      final headers = await _getHeaders();
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'type': type,
          'amount': amount,
          'description': description,
          'category': category,
          'date': DateFormat('yyyy-MM-dd').format(date), // Format as YYYY-MM-DD
          'payment_method': paymentMethod,
          'reference_number': referenceNumber,
          'status': status,
          'patient_id': patientId,
          'notes': notes,
        }),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else if (response.statusCode == 401) {
        // Handle unauthorized (token expired or invalid)
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
          'unauthorized': true,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create payment',
          'errors': responseData['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Get payment categories
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final url = Uri.parse('$baseUrl/payments/categories');
      final headers = await _getHeaders();
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body)['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load categories',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }
}
