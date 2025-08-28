class User {
  final String id;
  final String email;
  final String name;
  final String? rollNo;
  final String role;
  final bool isApproved;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.rollNo,
    required this.role,
    required this.isApproved,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      rollNo: json['rollNo'] ?? json['roll_no'],
      role: json['role'] ?? 'STUDENT',
      isApproved: json['isApproved'] ?? json['is_approved'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'rollNo': rollNo,
      'role': role,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get roleDisplayName {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'TEACHER':
        return 'Teacher';
      case 'STUDENT':
        return 'Student';
      case 'SECURITY':
        return 'Security';
      default:
        return role;
    }
  }

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isTeacher => role == 'TEACHER';
  bool get isStudent => role == 'STUDENT';
  bool get isSecurity => role == 'SECURITY';
}