import 'user_model.dart';

class GatePass {
  final String id;
  final String studentId;
  final String? teacherId;
  final String reason;
  final String status;
  final String? remarks;
  final DateTime requestDate;
  final DateTime validUntil;
  final String? qrCode;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? student;
  final User? teacher;

  GatePass({
    required this.id,
    required this.studentId,
    this.teacherId,
    required this.reason,
    required this.status,
    this.remarks,
    required this.requestDate,
    required this.validUntil,
    this.qrCode,
    this.usedAt,
    required this.createdAt,
    required this.updatedAt,
    this.student,
    this.teacher,
  });

  factory GatePass.fromJson(Map<String, dynamic> json) {
    return GatePass(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? json['student_id'] ?? '',
      teacherId: json['teacherId'] ?? json['teacher_id'],
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      remarks: json['remarks'],
      requestDate: DateTime.parse(json['requestDate'] ?? json['request_date'] ?? DateTime.now().toIso8601String()),
      validUntil: DateTime.parse(json['validUntil'] ?? json['valid_until'] ?? DateTime.now().toIso8601String()),
      qrCode: json['qrCode'] ?? json['qr_code'],
      usedAt: json['usedAt'] != null || json['used_at'] != null 
          ? DateTime.parse(json['usedAt'] ?? json['used_at'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String()),
      student: json['student'] != null ? User.fromJson(json['student']) : null,
      teacher: json['teacher'] != null ? User.fromJson(json['teacher']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'teacherId': teacherId,
      'reason': reason,
      'status': status,
      'remarks': remarks,
      'requestDate': requestDate.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'qrCode': qrCode,
      'usedAt': usedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'student': student?.toJson(),
      'teacher': teacher?.toJson(),
    };
  }

  String get statusDisplayName {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'USED':
        return 'Used';
      case 'EXPIRED':
        return 'Expired';
      default:
        return status;
    }
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isUsed => status == 'USED';
  bool get isExpired => status == 'EXPIRED';
  bool get isActive => isApproved && !isUsed && !isExpired && validUntil.isAfter(DateTime.now());
}

class Teacher {
  final String id;
  final String name;
  final String email;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}