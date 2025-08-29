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

  // FIXED: Load approved students
  Future<void> loadApprovedStudents({String? token}) async {
    _isLoadingApprovedStudents = true;
    notifyListeners();

    try {
      _ensureAuthenticated(token);
      
      debugPrint('Loading approved students...');
      
      // Try both endpoints to ensure we get data
      dynamic response;
      bool success = false;
      
      // Try the approval stats endpoint first
      try {
        response = await _apiService.get('/admin/students/approval-stats');
        debugPrint('Approved students response from /approval-stats: $response');
        success = true;
      } catch (e) {
        debugPrint('Approval stats endpoint failed: $e');
        
        // Try alternative endpoint
        try {
          response = await _apiService.get('/admin/students/approved');
          debugPrint('Approved students response from /approved: $response');
          success = true;
        } catch (e2) {
          debugPrint('Both endpoints failed: $e2');
          throw e2;
        }
      }
      
      if (!success) {
        throw Exception('Failed to fetch approved students from both endpoints');
      }

      // Handle the response data properly
      List<dynamic> studentsData = [];
      
      if (response is List) {
        // Direct array response
        studentsData = response;
        debugPrint('Got direct array response with ${studentsData.length} items');
      } else if (response is Map<String, dynamic>) {
        // Wrapped response
        studentsData = response['data'] ?? 
                      response['students'] ?? 
                      response['approvedStudents'] ?? 
                      [];
        
        debugPrint('Got wrapped response with ${studentsData.length} items in data field');
        
        // Log the structure for debugging
        debugPrint('Response structure: ${response.keys.toList()}');
        
        // Also check for any error message
        if (response['error'] != null) {
          debugPrint('Server reported error: ${response['error']}');
        }
      } else {
        debugPrint('Unexpected response type: ${response.runtimeType}');
        studentsData = [];
      }

      debugPrint('Processing ${studentsData.length} students data items');

      // Parse each student
      List<ApprovedStudent> parsedStudents = [];
      for (int i = 0; i < studentsData.length; i++) {
        try {
          final studentJson = studentsData[i];
          if (studentJson != null) {
            final student = ApprovedStudent.fromJson(studentJson as Map<String, dynamic>);
            parsedStudents.add(student);
            debugPrint('Successfully parsed student ${i + 1}: ${student.name}');
          }
        } catch (e) {
          debugPrint('Error parsing approved student at index $i: $e');
          debugPrint('Student data that failed: ${studentsData[i]}');
        }
      }

      _approvedStudents = parsedStudents;

      debugPrint('Successfully loaded ${_approvedStudents.length} approved students');
      
      // Debug: Print first student details if available
      if (_approvedStudents.isNotEmpty) {
        final firstStudent = _approvedStudents.first;
        debugPrint('First student example: ${firstStudent.name}');
        debugPrint('  - Approved requests: ${firstStudent.stats.approvedRequests}');
        debugPrint('  - Approving teachers: ${firstStudent.stats.approvingTeachers}');
      }

    } catch (e) {
      debugPrint('Error loading approved students: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('Exception details: ${e.toString()}');
      }
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
      
      debugPrint('Changing user role for $userId to $newRole');
      
      final response = await _apiService.patch('/admin/users/$userId/role', {
        'role': newRole,
      });

      debugPrint('Change role response: $response');
      
      bool success = false;
      
      // Handle different response formats
      if (response is Map<String, dynamic>) {
        // Check if response indicates success
        if (response['message']?.toString().contains('successfully') == true ||
            response['data'] != null ||
            response['user'] != null) {
          success = true;
        }
        
        // Try to update local user data if available
        final userData = response['data'] ?? response['user'];
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

  // Get approval statistics summary - FIXED NULL VALUES
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
    
    // Safe calculation with null checks
    final totalApprovedRequests = _approvedStudents.fold<int>(0, (sum, student) {
      final approved = student.stats.approvedRequests ?? 0;
      return sum + approved;
    });
    
    final totalPendingRequests = _approvedStudents.fold<int>(0, (sum, student) {
      final pending = student.stats.pendingRequests ?? 0;
      return sum + pending;
    });
    
    final averageApprovalRate = totalStudents > 0 
        ? _approvedStudents.fold<int>(0, (sum, student) {
            final rate = student.stats.approvalRate ?? 0;
            return sum + rate;
          }) ~/ totalStudents  // Use integer division
        : 0;

    debugPrint('Approval Stats Summary:');
    debugPrint('  Total Students: $totalStudents');
    debugPrint('  Total Approved Requests: $totalApprovedRequests');
    debugPrint('  Total Pending Requests: $totalPendingRequests');
    debugPrint('  Average Approval Rate: $averageApprovalRate%');

    return {
      'totalStudents': totalStudents,
      'totalApprovedRequests': totalApprovedRequests,
      'totalPendingRequests': totalPendingRequests,
      'averageApprovalRate': averageApprovalRate,
    };
  }

  // Filter approved students based on search query
  List<ApprovedStudent> getFilteredApprovedStudents(String searchQuery) {
    if (searchQuery.isEmpty) {
      return _approvedStudents;
    }

    final query = searchQuery.toLowerCase();
    return _approvedStudents.where((student) {
      final name = student.name.toLowerCase();
      final email = student.email.toLowerCase();
      final rollNo = student.rollNo?.toLowerCase() ?? '';
      
      return name.contains(query) || 
             email.contains(query) || 
             rollNo.contains(query);
    }).toList();
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

  // Get user statistics for admin dashboard
  Map<String, int> getUserStats() {
    final students = _allUsers.where((u) => u.role == 'STUDENT').length;
    final teachers = _allUsers.where((u) => u.role == 'TEACHER').length;
    final security = _allUsers.where((u) => u.role == 'SECURITY').length;
    final admins = _allUsers.where((u) => u.role == 'SUPER_ADMIN').length;
    final pending = _pendingTeachers.length;
    final approvedStudents = _approvedStudents.length;

    return {
      'students': students,
      'teachers': teachers,
      'security': security,
      'admins': admins,
      'pending': pending,
      'approvedStudents': approvedStudents,
    };
  }

  // Alternative getter method for user stats if needed
  Map<String, int> get userStats => getUserStats();
}