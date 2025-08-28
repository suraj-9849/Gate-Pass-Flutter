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

  // Student Methods
  Future<void> loadStudentPasses() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/gate-pass/student/passes');
      _studentPasses = (response as List)
          .map((json) => GatePass.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading student passes: $e');
      _studentPasses = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTeachers() async {
    try {
      final response = await _apiService.get('/students/teachers');
      _teachers = (response as List)
          .map((json) => Teacher.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading teachers: $e');
      _teachers = [];
    }
  }

  Future<bool> createGatePass({
    required String reason,
    required String teacherId,
    required DateTime requestDate,
    required DateTime validUntil,
  }) async {
    try {
      await _apiService.post('/gate-pass/request', {
        'reason': reason,
        'teacherId': teacherId,
        'requestDate': requestDate.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
      });
      
      // Reload passes after creating new one
      await loadStudentPasses();
      return true;
    } catch (e) {
      debugPrint('Error creating gate pass: $e');
      return false;
    }
  }

  Future<bool> deleteGatePass(String passId) async {
    try {
      await _apiService.delete('/gate-pass/request/$passId');
      
      // Remove from local list and reload
      _studentPasses.removeWhere((pass) => pass.id == passId);
      notifyListeners();
      await loadStudentPasses();
      return true;
    } catch (e) {
      debugPrint('Error deleting gate pass: $e');
      return false;
    }
  }

  // Teacher Methods
  Future<void> loadPendingApprovals() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/gate-pass/teacher/pending');
      _pendingApprovals = (response as List)
          .map((json) => GatePass.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading pending approvals: $e');
      _pendingApprovals = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadApprovedRequests() async {
    try {
      final response = await _apiService.get('/gate-pass/teacher/approved');
      _approvedRequests = (response as List)
          .map((json) => GatePass.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading approved requests: $e');
      _approvedRequests = [];
    }
  }

  Future<bool> approveGatePass(String gatePassId, String remarks) async {
    try {
      await _apiService.post('/gate-pass/approve/$gatePassId', {
        'remarks': remarks,
      });
      
      // Reload data after approval
      await Future.wait([
        loadPendingApprovals(),
        loadApprovedRequests(),
      ]);
      return true;
    } catch (e) {
      debugPrint('Error approving gate pass: $e');
      return false;
    }
  }

  Future<bool> rejectGatePass(String gatePassId, String remarks) async {
    try {
      await _apiService.post('/gate-pass/reject/$gatePassId', {
        'remarks': remarks,
      });
      
      // Reload data after rejection
      await Future.wait([
        loadPendingApprovals(),
        loadApprovedRequests(),
      ]);
      return true;
    } catch (e) {
      debugPrint('Error rejecting gate pass: $e');
      return false;
    }
  }

  // Security Methods
  Future<List<GatePass>> loadActivePasses() async {
    try {
      final response = await _apiService.get('/security/active-passes');
      return (response as List)
          .map((json) => GatePass.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading active passes: $e');
      return [];
    }
  }

  Future<List<GatePass>> loadScannedPasses() async {
    try {
      final response = await _apiService.get('/security/scanned-passes');
      return (response as List)
          .map((json) => GatePass.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading scanned passes: $e');
      return [];
    }
  }

  Future<bool> scanGatePass(String qrCode) async {
    try {
      final response = await _apiService.post('/security/scan-pass', {
        'qrCode': qrCode,
      });
      
      // Return success if we got a valid response
      return response['message'] != null;
    } catch (e) {
      debugPrint('Error scanning gate pass: $e');
      return false;
    }
  }

  // Admin Methods
  Future<List<User>> loadPendingTeachers() async {
    try {
      final response = await _apiService.get('/admin/teachers/pending');
      return (response as List)
          .map((json) => User.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading pending teachers: $e');
      return [];
    }
  }

  Future<List<User>> loadAllUsers() async {
    try {
      final response = await _apiService.get('/admin/teachers');
      return (response as List)
          .map((json) => User.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading all users: $e');
      return [];
    }
  }

  Future<bool> approveTeacher(String teacherId) async {
    try {
      await _apiService.post('/admin/teachers/$teacherId/approve', {});
      return true;
    } catch (e) {
      debugPrint('Error approving teacher: $e');
      return false;
    }
  }

  Future<bool> rejectTeacher(String teacherId) async {
    try {
      await _apiService.post('/admin/teachers/$teacherId/reject', {});
      return true;
    } catch (e) {
      debugPrint('Error rejecting teacher: $e');
      return false;
    }
  }

  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      await _apiService.patch('/admin/users/$userId/role', {
        'role': newRole,
      });
      return true;
    } catch (e) {
      debugPrint('Error changing user role: $e');
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