import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Update this based on your setup:
  // For Android emulator: 'http://10.0.2.2:3001/api'
  // For iOS simulator: 'http://localhost:3001/api' 
  // For physical device: 'http://YOUR_COMPUTER_IP:3001/api'
  static const String baseUrl = 'http://192.168.1.11:3001/api';
  
  String? _token;
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException('Request timeout. Please check your internet connection and try again.');
      }
      throw ApiException('Network error: Cannot connect to server. Please check your internet connection and ensure the backend server is running.');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException('Request timeout. Please check your internet connection and try again.');
      }
      throw ApiException('Network error: Cannot connect to server. Please check your internet connection and ensure the backend server is running.');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException('Request timeout. Please check your internet connection and try again.');
      }
      throw ApiException('Network error: Cannot connect to server. Please check your internet connection and ensure the backend server is running.');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException('Request timeout. Please check your internet connection and try again.');
      }
      throw ApiException('Network error: Cannot connect to server. Please check your internet connection and ensure the backend server is running.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    try {
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {};
        } else {
          throw ApiException('Server error (${response.statusCode}): Empty response');
        }
      }

      final dynamic data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        String errorMessage = 'Unknown error occurred';
        
        if (data is Map<String, dynamic>) {
          errorMessage = data['message'] ?? data['error'] ?? 'Server error (${response.statusCode})';
        } else if (data is String) {
          errorMessage = data;
        }
        
        if (response.statusCode == 401) {
          errorMessage = 'Authentication failed. Please login again.';
        } else if (response.statusCode == 403) {
          errorMessage = 'Access denied. You don\'t have permission to perform this action.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Resource not found. Please check the request.';
        }
        
        throw ApiException(errorMessage);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      
      if (response.statusCode >= 400) {
        throw ApiException('Server error (${response.statusCode}): ${response.body}');
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