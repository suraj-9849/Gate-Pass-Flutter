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
      }
    } catch (e) {
      await _clearAuthData();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<AuthResult> login(String email, String password) async {
    _setLoading(true);
    
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response['token'] != null && response['user'] != null) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        
        await _saveAuthData();
        _apiService.setToken(_token!);
        
        notifyListeners();
        return AuthResult.success('Login successful');
      } else {
        return AuthResult.error('Invalid response from server');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('User not found')) {
        errorMessage = 'No account found with this email address.';
      } else if (errorMessage.contains('Invalid password')) {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (errorMessage.contains('Network error')) {
        errorMessage = 'Unable to connect to server. Please check your internet connection.';
      }
      
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
    _setLoading(true);
    
    try {
      final response = await _apiService.post('/auth/register', {
        'name': name,
        'email': email,
        'rollNo': rollNo,
        'password': password,
      });

      if (response['token'] != null && response['user'] != null) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        
        await _saveAuthData();
        _apiService.setToken(_token!);
        
        notifyListeners();
        return AuthResult.success('Registration successful');
      } else {
        return AuthResult.error('Invalid response from server');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('User already exists')) {
        errorMessage = 'An account with this email already exists.';
      } else if (errorMessage.contains('Network error')) {
        errorMessage = 'Unable to connect to server. Please check your internet connection.';
      }
      
      return AuthResult.error(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await _clearAuthData();
    } catch (e) {
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
    } catch (e) {
      // Handle save error silently
    }
  }

  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    } catch (e) {
      // Handle clear error silently
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
      // Handle refresh error silently
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final String message;

  AuthResult._(this.isSuccess, this.message);

  factory AuthResult.success(String message) => AuthResult._(true, message);
  factory AuthResult.error(String message) => AuthResult._(false, message);
}