import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isInitialized => _isInitialized;

  final ApiService _apiService = ApiService();

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenData = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');

      if (tokenData != null && userData != null) {
        _token = tokenData;
        _user = User.fromJson(jsonDecode(userData));
        _apiService.setToken(_token!);
        debugPrint('Auth initialized - User: ${_user?.email}, Role: ${_user?.role}');
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      await _clearAuthData();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<AuthResult> login(String email, String password) async {
    debugPrint('Starting login for: $email');
    _setLoading(true);
    
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      debugPrint('Login response received: ${response.toString()}');

      if (response['token'] != null && response['user'] != null) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        
        await _saveAuthData();
        _apiService.setToken(_token!);
        
        debugPrint('Login successful - User: ${_user?.name}, Role: ${_user?.role}');
        notifyListeners();
        return AuthResult.success('Login successful');
      } else {
        debugPrint('Invalid response structure: $response');
        return AuthResult.error('Invalid response from server');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      String errorMessage = _parseErrorMessage(e.toString());
      return AuthResult.error(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String rollNo,
    required String password,
  }) async {
    debugPrint('Starting registration for: $email');
    _setLoading(true);
    
    try {
      final response = await _apiService.post('/auth/register', {
        'name': name,
        'email': email,
        'rollNo': rollNo,
        'password': password,
      });

      debugPrint('Registration response received: ${response.toString()}');

      if (response['token'] != null && response['user'] != null) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        
        await _saveAuthData();
        _apiService.setToken(_token!);
        
        debugPrint('Registration successful - User: ${_user?.name}, Role: ${_user?.role}');
        notifyListeners();
        return AuthResult.success('Registration successful');
      } else {
        debugPrint('Invalid response structure: $response');
        return AuthResult.error('Invalid response from server');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      String errorMessage = _parseErrorMessage(e.toString());
      return AuthResult.error(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    debugPrint('Logging out user: ${_user?.email}');
    try {
      await _clearAuthData();
    } catch (e) {
      debugPrint('Error during logout: $e');
      _token = null;
      _user = null;
      _apiService.clearToken();
    }

    notifyListeners();
  }

  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));
      debugPrint('Auth data saved successfully');
    } catch (e) {
      debugPrint('Error saving auth data: $e');
    }
  }

  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      debugPrint('Auth data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }

    _token = null;
    _user = null;
    _apiService.clearToken();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void ensureTokenSet() {
    if (_token != null) {
      _apiService.setToken(_token!);
    }
  }

  Future<void> refreshUser() async {
    if (_token == null) return;
    
    try {
      ensureTokenSet();
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  String _parseErrorMessage(String errorString) {
    debugPrint('Parsing error: $errorString');
    
    // Remove "ApiException: " prefix if present
    String cleanError = errorString.replaceAll('ApiException: ', '');
    
    // Check for specific error patterns
    if (cleanError.contains('User not found') || cleanError.contains('No account found')) {
      return 'No account found with this email address.';
    } else if (cleanError.contains('Invalid password') || cleanError.contains('Incorrect password')) {
      return 'Incorrect password. Please try again.';
    } else if (cleanError.contains('User already exists') || cleanError.contains('already exists')) {
      return 'An account with this email already exists.';
    } else if (cleanError.contains('Email must end with')) {
      return cleanError; // Return the exact email domain error
    } else if (cleanError.contains('Connection timeout') || cleanError.contains('timeout')) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (cleanError.contains('No internet') || cleanError.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (cleanError.contains('Server error') || cleanError.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (cleanError.contains('Network error')) {
      return 'Network error. Please check your connection.';
    } else if (cleanError.toLowerCase().contains('email') && cleanError.toLowerCase().contains('valid')) {
      return cleanError; // Return email validation errors as-is
    } else if (cleanError.trim().isEmpty) {
      return 'An unexpected error occurred. Please try again.';
    }
    
    return cleanError.length > 100 ? 'An error occurred. Please try again.' : cleanError;
  }
}

class AuthResult {
  final bool isSuccess;
  final String message;

  AuthResult._(this.isSuccess, this.message);

  factory AuthResult.success(String message) => AuthResult._(true, message);
  factory AuthResult.error(String message) => AuthResult._(false, message);
}