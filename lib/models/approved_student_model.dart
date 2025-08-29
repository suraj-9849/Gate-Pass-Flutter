// lib/models/approved_student_model.dart

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
    return ApprovedStudent(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      rollNo: json['rollNo'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      stats: ApprovalStats.fromJson(json['stats'] ?? {}),
    );
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
    return ApprovalStats(
      totalRequests: json['totalRequests'] ?? 0,
      approvedRequests: json['approvedRequests'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
      rejectedRequests: json['rejectedRequests'] ?? 0,
      approvalRate: json['approvalRate'] ?? 0,
      approvingTeachers: List<String>.from(json['approvingTeachers'] ?? []),
    );
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
}