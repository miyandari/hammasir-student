import 'package:hammasir_student/core/utils/json_utils.dart';

/// پاسخ `GET /users/me/`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.role,
    this.firstName,
    this.lastName,
    this.studentId,
    this.universityId,
  });

  final int id;
  final String username;
  final String role;
  final String? firstName;
  final String? lastName;
  final int? studentId;
  final int? universityId;

  bool get isStudent => role == 'student';

  String get fullName {
    final name = [firstName, lastName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
    return name.isEmpty ? username : name;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: asInt(json['id']) ?? 0,
      username: asString(json['username']),
      role: asString(json['role']),
      firstName: asNullableString(json['first_name']),
      lastName: asNullableString(json['last_name']),
      studentId: asInt(json['student_id']),
      universityId: asInt(json['university_id']),
    );
  }
}
