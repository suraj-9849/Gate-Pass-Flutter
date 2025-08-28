import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ApiService {
  // Try multiple possible backend URLs
  static const List<String> possibleBaseUrls = [
    'http://10.0.2.2:3001/api',    // Android emulator
    'http://localhost:3001/api',   // iOS simulator
    'http://127.0.0.1:3001/api',   // Alternative localhost
  ];
  
  static String? _workingBaseUrl;
  static const Duration timeout = Duration(seconds: 15);
  
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

  // Find working backend URL
  Future<String?> _findWorkingBaseUrl() async {
    if (_workingBaseUrl != null) return _workingBaseUrl;
    
    for (String baseUrl in possibleBaseUrls) {
      try {
        _logger.i('Testing backend URL: $baseUrl');
        final healthUrl = baseUrl.replaceAll('/api', '/health');
        
        final response = await http.get(
          Uri.parse(healthUrl),
          headers: {'Accept': 'application/json'},
        ).timeout(Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          _workingBaseUrl = baseUrl;
          _logger.i('✅ Backend found at: $baseUrl');
          return _workingBaseUrl;
        }
      } catch (e) {
        _logger.w('❌ Backend not accessible at: $baseUrl - $e');
        continue;
      }
    }
    
    _logger.e('🚫 No backend servers accessible!');
    return null;
  }

  // GET Method
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final baseUrl = await _findWorkingBaseUrl();
      if (baseUrl == null) {
        throw ApiException('Cannot connect to backend server.');
      }
      
      final url = '$baseUrl$endpoint';
      _logger.i('GET request to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      _logger.e('GET request timeout');
      throw ApiException('Request timed out. Please try again.');
    } catch (e) {
      _logger.e('GET request error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(_getErrorMessage(e));
    }
  }

  // POST Method
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final baseUrl = await _findWorkingBaseUrl();
      if (baseUrl == null) {
        throw ApiException('Cannot connect to backend server. Please ensure the server is running on port 3001.');
      }
      
      final url = '$baseUrl$endpoint';
      _logger.i('POST request to: $url');
      _logger.d('Request data: $data');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      _logger.e('POST request timeout');
      throw ApiException('Request timed out. Please check your connection and try again.');
    } catch (e) {
      _logger.e('POST request error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(_getErrorMessage(e));
    }
  }

  // PUT Method
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final baseUrl = await _findWorkingBaseUrl();
      if (baseUrl == null) {
        throw ApiException('Cannot connect to backend server.');
      }
      
      final url = '$baseUrl$endpoint';
      _logger.i('PUT request to: $url');
      _logger.d('Request data: $data');
      
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      _logger.e('PUT request timeout');
      throw ApiException('Request timed out. Please try again.');
    } catch (e) {
      _logger.e('PUT request error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(_getErrorMessage(e));
    }
  }

  // PATCH Method
  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final baseUrl = await _findWorkingBaseUrl();
      if (baseUrl == null) {
        throw ApiException('Cannot connect to backend server.');
      }
      
      final url = '$baseUrl$endpoint';
      _logger.i('PATCH request to: $url');
      _logger.d('Request data: $data');
      
      final response = await http.patch(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      _logger.e('PATCH request timeout');
      throw ApiException('Request timed out. Please try again.');
    } catch (e) {
      _logger.e('PATCH request error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(_getErrorMessage(e));
    }
  }

  // DELETE Method
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final baseUrl = await _findWorkingBaseUrl();
      if (baseUrl == null) {
        throw ApiException('Cannot connect to backend server.');
      }
      
      final url = '$baseUrl$endpoint';
      _logger.i('DELETE request to: $url');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      ).timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      _logger.e('DELETE request timeout');
      throw ApiException('Request timed out. Please try again.');
    } catch (e) {
      _logger.e('DELETE request error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(_getErrorMessage(e));
    }
  }

  // Response Handler
  Map<String, dynamic> _handleResponse(http.Response response) {
    _logger.i('Response status: ${response.statusCode}');
    _logger.d('Response body: ${response.body}');

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      } else {
        throw ApiException('Server error (${response.statusCode})');
      }
    }

    try {
      final dynamic rawData = jsonDecode(response.body);
      
      // Handle array responses (for lists)
      if (rawData is List) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'data': rawData};
        } else {
          throw ApiException('Server error (${response.statusCode})');
        }
      }
      
      if (rawData is! Map<String, dynamic>) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'data': rawData};
        } else {
          throw ApiException('Server error: $rawData');
        }
      }
      
      final Map<String, dynamic> data = rawData;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        final errorMessage = data['message'] ?? 
                           data['error'] ?? 
                           'Server error (${response.statusCode})';
        throw ApiException(errorMessage);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      
      if (response.statusCode >= 400) {
        throw ApiException('Server error (${response.statusCode}): ${response.body}');
      }
      
      throw ApiException('Failed to parse server response');
    }
  }

  // Error Message Helper
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('Connection refused')) {
      return 'Backend server is not running. Please start the server and try again.';
    } else if (errorString.contains('Network is unreachable')) {
      return 'Network unreachable. Please check your connection.';
    } else if (errorString.contains('No address associated with hostname')) {
      return 'Cannot find backend server. Please check server configuration.';
    } else if (errorString.contains('SocketException')) {
      return 'Connection failed. Please ensure the backend server is running.';
    } else {
      return 'Network error. Please try again.';
    }
  }

  // Test connection method
  Future<bool> testConnection() async {
    try {
      final baseUrl = await _findWorkingBaseUrl();
      return baseUrl != null;
    } catch (e) {
      return false;
    }
  }

  // Get current base URL
  String? get currentBaseUrl => _workingBaseUrl;

  // Reset base URL (useful for testing different endpoints)
  void resetBaseUrl() {
    _workingBaseUrl = null;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}