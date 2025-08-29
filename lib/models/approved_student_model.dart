class ApprovedStudent {
  final String id;
  final String email;
  final String name;
  final String? rollNo;
  final DateTime createdAt;
  final ApprovalStats stats;

  ApprovedStudent({
    required this.id,
    required this.email,
    required this.name,
    this.rollNo,
    required this.createdAt,
    required this.stats,
  });

  factory ApprovedStudent.fromJson(Map<String, dynamic> json) {
    try {
      return ApprovedStudent(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        rollNo: json['rollNo']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        stats: ApprovalStats.fromJson(json['stats'] ?? {}),
      );
    } catch (e) {
      print('Error parsing ApprovedStudent from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'rollNo': rollNo,
      'createdAt': createdAt.toIso8601String(),
      'stats': stats.toJson(),
    };
  }

  @override
  String toString() {
    return 'ApprovedStudent(id: $id, name: $name, email: $email, stats: $stats)';
  }
}

class ApprovalStats {
  final int totalRequests;
  final int approvedRequests;
  final int pendingRequests;
  final int rejectedRequests;
  final int approvalRate;
  final List<String> approvingTeachers;

  ApprovalStats({
    required this.totalRequests,
    required this.approvedRequests,
    required this.pendingRequests,
    required this.rejectedRequests,
    required this.approvalRate,
    required this.approvingTeachers,
  });

  factory ApprovalStats.fromJson(Map<String, dynamic> json) {
    try {
      // Handle approvingTeachers as both List and potential other types
      List<String> teachers = [];
      final teachersData = json['approvingTeachers'];
      
      if (teachersData is List) {
        teachers = teachersData
            .map((item) => item?.toString() ?? '')
            .where((item) => item.isNotEmpty)
            .toList();
      } else if (teachersData is String && teachersData.isNotEmpty) {
        teachers = [teachersData];
      }

      final totalReq = _parseIntSafely(json['totalRequests'], 0);
      final approvedReq = _parseIntSafely(json['approvedRequests'], 0);
      final pendingReq = _parseIntSafely(json['pendingRequests'], 0);
      final rejectedReq = _parseIntSafely(json['rejectedRequests'], 0);
      final approvalRt = _parseIntSafely(json['approvalRate'], 0);

      // Debug logging
      print('Parsing ApprovalStats: total=$totalReq, approved=$approvedReq, pending=$pendingReq, rate=$approvalRt%, teachers=${teachers.length}');

      return ApprovalStats(
        totalRequests: totalReq,
        approvedRequests: approvedReq,
        pendingRequests: pendingReq,
        rejectedRequests: rejectedReq,
        approvalRate: approvalRt,
        approvingTeachers: teachers,
      );
    } catch (e) {
      print('Error parsing ApprovalStats from JSON: $e');
      print('JSON data: $json');
      // Return default stats instead of throwing
      return ApprovalStats(
        totalRequests: 0,
        approvedRequests: 0,
        pendingRequests: 0,
        rejectedRequests: 0,
        approvalRate: 0,
        approvingTeachers: [],
      );
    }
  }

  static int _parseIntSafely(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRequests': totalRequests,
      'approvedRequests': approvedRequests,
      'pendingRequests': pendingRequests,
      'rejectedRequests': rejectedRequests,
      'approvalRate': approvalRate,
      'approvingTeachers': approvingTeachers,
    };
  }

  @override
  String toString() {
    return 'ApprovalStats(total: $totalRequests, approved: $approvedRequests, '
           'pending: $pendingRequests, rate: $approvalRate%, '
           'teachers: [${approvingTeachers.join(", ")}])';
  }
}