import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ApiService {
  // Update this based on your setup:
  // For Android emulator: 'http://10.0.2.2:3001/api'
  // For iOS simulator: 'http://localhost:3001/api' 
  // For physical device: 'http://YOUR_COMPUTER_IP:3001/api'
  static const String baseUrl = 'http://192.168.1.11:3001/api';
  
  final Logger _logger = Logger();
  String? _token;
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  void setToken(String token) {
    _token = token;
    _logger.i('Token set for API requests');
  }

  void clearToken() {
    _token = null;
    _logger.i('Token cleared from API requests');
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      _logger.i('GET request to: $baseUrl$endpoint');
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      _logger.e('GET request error: $e');
      throw ApiException('Network error: Cannot connect to server. Please check your internet connection and ensure the backend server is running.');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      _logger.i('POST request to: $baseUrl$endpoint');
      _logger.d('Request data: $data');
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      _logger.e('POST request error: $e');
      throw ApiException('Network error: Cannot connect to server. Please check your internet connection and ensure the backend server is running.');
    }
  }

  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      _logger.i('PATCH request to: $baseUrl$endpoint');
      _logger.d('Request data: $data');
      
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      _logger.e('PATCH request error: $e');
      throw ApiException('Network error: Cannot connect to server. Please check your internet connection and ensure the backend server is running.');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      _logger.i('DELETE request to: $baseUrl$endpoint');
      
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      _logger.e('DELETE request error: $e');
      throw ApiException('Network error: Cannot connect to server. Please check your internet connection and ensure the backend server is running.');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    _logger.i('Response status: ${response.statusCode}');
    _logger.d('Response body: ${response.body}');

    try {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        final errorMessage = data['message'] ?? 'Unknown error occurred';
        throw ApiException(errorMessage);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      
      // Handle non-JSON responses
      if (response.statusCode >= 400) {
        throw ApiException('Server error (${response.statusCode})');
      }
      
      throw ApiException('Failed to parse response: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);

  @override
  String toString() => message;
}