// lib/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.1.9:3001/api'; // Change this to your backend URL

  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Generic GET request
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw ApiException(_handleError(e));
    }
  }

  // Generic POST request
  Future<dynamic> post(String path, dynamic data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException(_handleError(e));
    }
  }

  // Generic PUT request
  Future<dynamic> put(String path, dynamic data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException(_handleError(e));
    }
  }

  Future<dynamic> patch(String path, dynamic data) async {
    try {
      debugPrint('PATCH Request - URL: $baseUrl$path');
      debugPrint('PATCH Request - Data: $data');
      debugPrint('PATCH Request - Headers: ${_dio.options.headers}');

      final response = await _dio.patch(path, data: data);

      debugPrint('PATCH Response - Status: ${response.statusCode}');
      debugPrint('PATCH Response - Data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      debugPrint('PATCH Error - Type: ${e.type}');
      debugPrint('PATCH Error - Message: ${e.message}');
      debugPrint('PATCH Error - Response: ${e.response?.data}');
      throw ApiException(_handleError(e));
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw ApiException(_handleError(e));
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await post('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    return await post('/auth/register', data);
  }

  // Admin endpoints
  Future<dynamic> getPendingTeachers() async {
    return await get('/admin/teachers/pending');
  }

  Future<dynamic> getAllUsers() async {
    return await get('/admin/teachers');
  }

  Future<dynamic> approveTeacher(String teacherId) async {
    return await post('/admin/teachers/$teacherId/approve', {});
  }

  Future<dynamic> rejectTeacher(String teacherId) async {
    return await post('/admin/teachers/$teacherId/reject', {});
  }

  Future<dynamic> changeUserRole(String userId, String role) async {
    try {
      debugPrint('Changing user role - User ID: $userId, New Role: $role');

      final response = await patch('/admin/users/$userId/role', {
        'role': role,
      });

      debugPrint('Change role response: $response');
      return response;
    } catch (e) {
      debugPrint('Error in changeUserRole: $e');
      rethrow;
    }
  }

  // Approved students endpoints
  Future<dynamic> getApprovedStudents() async {
    return await get('/admin/students/approved');
  }

  Future<dynamic> getStudentsApprovalStats() async {
    return await get('/admin/students/approval-stats');
  }

  // Gate pass endpoints
  Future<dynamic> getStudentPasses() async {
    return await get('/gate-pass/student/passes');
  }

  Future<dynamic> createGatePass(Map<String, dynamic> data) async {
    return await post('/gate-pass/request', data);
  }

  Future<dynamic> getTeacherPendingApprovals() async {
    return await get('/gate-pass/teacher/pending');
  }

  Future<dynamic> getTeacherApprovedRequests() async {
    return await get('/gate-pass/teacher/approved');
  }

  Future<dynamic> approveGatePass(String gatePassId, {String? remarks}) async {
    return await post('/gate-pass/approve/$gatePassId', {
      'remarks': remarks,
    });
  }

  Future<dynamic> rejectGatePass(String gatePassId, {String? remarks}) async {
    return await post('/gate-pass/reject/$gatePassId', {
      'remarks': remarks,
    });
  }

  // Student endpoints
  Future<dynamic> getTeachers() async {
    return await get('/students/teachers');
  }

  // Security endpoints
  Future<dynamic> scanGatePass(String qrCode) async {
    return await post('/security/scan', {'qrCode': qrCode});
  }

  Future<dynamic> getScannedPasses() async {
    return await get('/security/scanned');
  }

  // Error handling
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'];
        if (statusCode == 401) {
          return 'Authentication failed. Please login again.';
        } else if (statusCode == 403) {
          return 'Access denied. You don\'t have permission to perform this action.';
        } else if (statusCode == 404) {
          return 'Resource not found.';
        } else if (statusCode == 400 && message != null) {
          return message.toString();
        } else if (message != null) {
          return message.toString();
        }
        return 'Server error (${statusCode ?? 'Unknown'})';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') == true) {
          return 'No internet connection';
        }
        return 'An unexpected error occurred';
      default:
        return 'Network error occurred';
    }
  }
}

// Custom exception class
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
