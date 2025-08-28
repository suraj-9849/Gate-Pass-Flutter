import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/gate_pass_model.dart';
import '../models/user_model.dart';

class GatePassProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<GatePass> _studentPasses = [];
  List<GatePass> _pendingApprovals = [];
  List<GatePass> _approvedRequests = [];
  List<Teacher> _teachers = [];
  bool _isLoading = false;

  // Getters
  List<GatePass> get studentPasses => _studentPasses;
  List<GatePass> get pendingApprovals => _pendingApprovals;
  List<GatePass> get approvedRequests => _approvedRequests;
  List<Teacher> get teachers => _teachers;
  bool get isLoading => _isLoading;

  void _ensureAuthenticated(String? token) {
    if (token == null) {
      throw Exception('No authentication token available');
    }
    _apiService.setToken(token);
  }

  // Student Methods
  Future<void> loadStudentPasses({String? token}) async {
    _setLoading(true);
    try {
      _ensureAuthenticated(token);
      
      final response = await _apiService.get('/gate-pass/student/passes');
      _studentPasses = (response as List)
          .map((json) => GatePass.fromJson(json))
          .toList();
    } catch (e) {
      _studentPasses = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTeachers({String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      final response = await _apiService.get('/students/teachers');
      
      // Handle both List and Map responses
      List<dynamic> teachersList;
      if (response is List) {
        teachersList = response;
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          teachersList = response['data'] as List;
        } else if (response.containsKey('teachers')) {
          teachersList = response['teachers'] as List;
        } else {
          teachersList = [];
        }
      } else {
        teachersList = [];
      }
      
      _teachers = teachersList
          .map((json) {
            try {
              return Teacher.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .where((teacher) => teacher != null)
          .cast<Teacher>()
          .toList();
      
      notifyListeners();
    } catch (e) {
      _teachers = [];
      notifyListeners();
    }
  }

  Future<bool> createGatePass({
    required String reason,
    required String teacherId,
    required DateTime requestDate,
    required DateTime validUntil,
    String? token,
  }) async {
    try {
      _ensureAuthenticated(token);
      
      await _apiService.post('/gate-pass/request', {
        'reason': reason,
        'teacherId': teacherId,
        'requestDate': requestDate.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
      });
      
      await loadStudentPasses(token: token);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteGatePass(String passId, {String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      await _apiService.delete('/gate-pass/request/$passId');
      
      _studentPasses.removeWhere((pass) => pass.id == passId);
      notifyListeners();
      await loadStudentPasses(token: token);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Teacher Methods
  Future<void> loadPendingApprovals({String? token}) async {
    _setLoading(true);
    try {
      _ensureAuthenticated(token);
      
      final response = await _apiService.get('/gate-pass/teacher/pending');
      _pendingApprovals = (response as List)
          .map((json) => GatePass.fromJson(json))
          .toList();
    } catch (e) {
      _pendingApprovals = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadApprovedRequests({String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      final response = await _apiService.get('/gate-pass/teacher/approved');
      _approvedRequests = (response as List)
          .map((json) => GatePass.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _approvedRequests = [];
    }
  }

  Future<bool> approveGatePass(String gatePassId, String remarks, {String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      await _apiService.post('/gate-pass/approve/$gatePassId', {
        'remarks': remarks,
      });
      
      await Future.wait([
        loadPendingApprovals(token: token),
        loadApprovedRequests(token: token),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectGatePass(String gatePassId, String remarks, {String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      await _apiService.post('/gate-pass/reject/$gatePassId', {
        'remarks': remarks,
      });
      
      await Future.wait([
        loadPendingApprovals(token: token),
        loadApprovedRequests(token: token),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Security Methods
  Future<List<GatePass>> loadActivePasses({String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      final response = await _apiService.get('/security/active-passes');
      return (response as List)
          .map((json) => GatePass.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<GatePass>> loadScannedPasses({String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      final response = await _apiService.get('/security/scanned-passes');
      return (response as List)
          .map((json) => GatePass.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> scanGatePass(String qrCode, {String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      final response = await _apiService.post('/security/scan-pass', {
        'qrCode': qrCode,
      });
      
      return response['message'] != null;
    } catch (e) {
      return false;
    }
  }

  // Admin Methods
  Future<List<User>> loadPendingTeachers({String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      final response = await _apiService.get('/admin/teachers/pending');
      return (response as List)
          .map((json) => User.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<User>> loadAllUsers({String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      final response = await _apiService.get('/admin/teachers');
      return (response as List)
          .map((json) => User.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> approveTeacher(String teacherId, {String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      await _apiService.post('/admin/teachers/$teacherId/approve', {});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectTeacher(String teacherId, {String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      await _apiService.post('/admin/teachers/$teacherId/reject', {});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changeUserRole(String userId, String newRole, {String? token}) async {
    try {
      _ensureAuthenticated(token);
      
      await _apiService.patch('/admin/users/$userId/role', {
        'role': newRole,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearData() {
    _studentPasses.clear();
    _pendingApprovals.clear();
    _approvedRequests.clear();
    _teachers.clear();
    _isLoading = false;
    notifyListeners();
  }
}