// lib/providers/admin_provider.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/approved_student_model.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<User> _pendingTeachers = [];
  List<User> _allUsers = [];
  List<ApprovedStudent> _approvedStudents = [];
  bool _isLoading = false;
  bool _isLoadingApprovedStudents = false;

  // Getters
  List<User> get pendingTeachers => _pendingTeachers;
  List<User> get allUsers => _allUsers;
  List<ApprovedStudent> get approvedStudents => _approvedStudents;
  bool get isLoading => _isLoading;
  bool get isLoadingApprovedStudents => _isLoadingApprovedStudents;

  void _ensureAuthenticated(String? token) {
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token available');
    }
    _apiService.setToken(token);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Load pending teachers
  Future<void> loadPendingTeachers({String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      final response = await _apiService.get('/admin/teachers/pending');
      debugPrint('Pending teachers response: $response');
      
      List<dynamic> teachersData = [];
      if (response is List) {
        teachersData = response;
      } else if (response is Map<String, dynamic>) {
        teachersData = response['data'] ?? response['teachers'] ?? [];
      }

      _pendingTeachers = teachersData
          .map((json) {
            try {
              return User.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              debugPrint('Error parsing pending teacher: $e');
              return null;
            }
          })
          .where((teacher) => teacher != null)
          .cast<User>()
          .toList();

      debugPrint('Loaded ${_pendingTeachers.length} pending teachers');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading pending teachers: $e');
      _pendingTeachers = [];
      notifyListeners();
    }
  }

  // Load all users
  Future<void> loadAllUsers({String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      final response = await _apiService.get('/admin/teachers');
      debugPrint('All users response: $response');
      
      List<dynamic> usersData = [];
      if (response is List) {
        usersData = response;
      } else if (response is Map<String, dynamic>) {
        usersData = response['data'] ?? response['users'] ?? response['teachers'] ?? [];
      }

      _allUsers = usersData
          .map((json) {
            try {
              return User.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              debugPrint('Error parsing user: $e');
              debugPrint('User data: $json');
              return null;
            }
          })
          .where((user) => user != null)
          .cast<User>()
          .toList();

      debugPrint('Loaded ${_allUsers.length} total users');
      
      // Debug: Print user breakdown
      final students = _allUsers.where((u) => u.role == 'STUDENT').length;
      final teachers = _allUsers.where((u) => u.role == 'TEACHER').length;
      final security = _allUsers.where((u) => u.role == 'SECURITY').length;
      final admins = _allUsers.where((u) => u.role == 'SUPER_ADMIN').length;
      
      debugPrint('User breakdown: Students: $students, Teachers: $teachers, Security: $security, Admins: $admins');
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading all users: $e');
      _allUsers = [];
      notifyListeners();
    }
  }

  // Load approved students
  Future<void> loadApprovedStudents({String? token}) async {
    _isLoadingApprovedStudents = true;
    notifyListeners();

    try {
      _ensureAuthenticated(token);
      
      debugPrint('Loading approved students...');
      
      // Try the approval stats endpoint first
      dynamic response;
      try {
        response = await _apiService.get('/admin/students/approval-stats');
        debugPrint('Approved students response from /approval-stats: $response');
      } catch (e) {
        debugPrint('Approval stats endpoint failed: $e');
        // Try alternative endpoint
        try {
          response = await _apiService.get('/admin/students/approved');
          debugPrint('Approved students response from /approved: $response');
        } catch (e2) {
          debugPrint('Both endpoints failed: $e2');
          throw e2;
        }
      }
      
      List<dynamic> studentsData = [];
      if (response is List) {
        studentsData = response;
      } else if (response is Map<String, dynamic>) {
        studentsData = response['data'] ?? [];
        
        // Also log any error message from the server
        if (response['error'] != null) {
          debugPrint('Server reported error: ${response['error']}');
        }
      }

      debugPrint('Processing ${studentsData.length} students data');

      _approvedStudents = studentsData
          .map((json) {
            try {
              return ApprovedStudent.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              debugPrint('Error parsing approved student: $e');
              debugPrint('Student data that failed: $json');
              return null;
            }
          })
          .where((student) => student != null)
          .cast<ApprovedStudent>()
          .toList();

      debugPrint('Successfully loaded ${_approvedStudents.length} approved students');
      
      // Debug: Print first student if available
      if (_approvedStudents.isNotEmpty) {
        final firstStudent = _approvedStudents.first;
        debugPrint('First student example: ${firstStudent.name} - ${firstStudent.stats.approvedRequests} approved requests');
      }

    } catch (e) {
      debugPrint('Error loading approved students: $e');
      debugPrint('Error type: ${e.runtimeType}');
      _approvedStudents = [];
    } finally {
      _isLoadingApprovedStudents = false;
      notifyListeners();
    }
  }

  // Approve teacher
  Future<bool> approveTeacher(String teacherId, {String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      await _apiService.post('/admin/teachers/$teacherId/approve', {});
      
      // Remove from pending list
      _pendingTeachers.removeWhere((teacher) => teacher.id == teacherId);
      
      // Refresh all users list to show updated status
      await loadAllUsers(token: token);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error approving teacher: $e');
      return false;
    }
  }

  // Reject teacher
  Future<bool> rejectTeacher(String teacherId, {String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      await _apiService.post('/admin/teachers/$teacherId/reject', {});
      
      // Remove from pending list
      _pendingTeachers.removeWhere((teacher) => teacher.id == teacherId);
      
      // Refresh all users list
      await loadAllUsers(token: token);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error rejecting teacher: $e');
      return false;
    }
  }

  // Change user role
  Future<bool> changeUserRole(String userId, String newRole, {String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      debugPrint('Attempting to change user role: $userId -> $newRole');
      
      final response = await _apiService.changeUserRole(userId, newRole);
      
      debugPrint('Role change response received: $response');
      
      // Check if the response indicates success
      bool success = false;
      
      if (response != null) {
        // If response is a Map and has the expected structure
        if (response is Map<String, dynamic>) {
          // Check for success message
          final message = response['message'];
          if (message != null && message.toString().toLowerCase().contains('success')) {
            success = true;
          }
          
          // Try to update the user locally if we have user data
          Map<String, dynamic>? userData = response['data'] ?? response['user'];
          if (userData != null) {
            final userIndex = _allUsers.indexWhere((user) => user.id == userId);
            if (userIndex != -1) {
              try {
                final updatedUser = User.fromJson(userData);
                _allUsers[userIndex] = updatedUser;
                debugPrint('Updated user locally: ${updatedUser.name} -> ${updatedUser.role}');
                notifyListeners();
              } catch (parseError) {
                debugPrint('Error parsing updated user data: $parseError');
              }
            }
          }
        } else {
          // If response is not a Map, assume success if no exception was thrown
          success = true;
        }
      }
      
      // Always refresh all users to ensure consistency, but don't wait for it
      loadAllUsers(token: token).catchError((error) {
        debugPrint('Error refreshing users after role change: $error');
      });
      
      debugPrint('Role change success: $success');
      return success;
      
    } catch (e) {
      debugPrint('Error changing user role: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return false;
    }
  }

  // Get approval statistics summary
  Map<String, int> getApprovalStatsSummary() {
    if (_approvedStudents.isEmpty) {
      return {
        'totalStudents': 0,
        'totalApprovedRequests': 0,
        'totalPendingRequests': 0,
        'averageApprovalRate': 0,
      };
    }

    final totalStudents = _approvedStudents.length;
    final totalApprovedRequests = _approvedStudents
        .fold<int>(0, (sum, s) => sum + s.stats.approvedRequests);
    final totalPendingRequests = _approvedStudents
        .fold<int>(0, (sum, s) => sum + s.stats.pendingRequests);
    final averageApprovalRate = totalStudents > 0 
        ? (_approvedStudents
            .fold<int>(0, (sum, s) => sum + s.stats.approvalRate) / totalStudents).round()
        : 0;

    return {
      'totalStudents': totalStudents,
      'totalApprovedRequests': totalApprovedRequests,
      'totalPendingRequests': totalPendingRequests,
      'averageApprovalRate': averageApprovalRate,
    };
  }

  // Get top approving teachers
  List<String> getTopApprovingTeachers({int limit = 5}) {
    final teacherCounts = <String, int>{};
    
    for (final student in _approvedStudents) {
      for (final teacher in student.stats.approvingTeachers) {
        teacherCounts[teacher] = (teacherCounts[teacher] ?? 0) + 1;
      }
    }

    final sortedTeachers = teacherCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTeachers
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  // Get user statistics
  Map<String, int> getUserStats() {
    final students = _allUsers.where((u) => u.role == 'STUDENT').length;
    final teachers = _allUsers.where((u) => u.role == 'TEACHER' && u.isApproved == true).length;
    final security = _allUsers.where((u) => u.role == 'SECURITY').length;
    final pending = _allUsers.where((u) => u.isApproved == false && u.role != 'STUDENT').length;

    return {
      'total': _allUsers.length,
      'students': students,
      'teachers': teachers,
      'security': security,
      'pending': pending,
    };
  }
}