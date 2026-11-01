import 'package:hammasir_student/core/utils/json_utils.dart';

/// پاسخ `GET /students/me` (از بک‌اند اصلاح‌شده).
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.studentNumber,
    required this.gender,
    required this.noShowCount,
    required this.negativeScore,
    required this.isBlocked,
    this.blockedUntil,
  });

  final int id;
  final String studentNumber;
  final String gender;
  final int noShowCount;
  final int negativeScore;
  final bool isBlocked;
  final DateTime? blockedUntil;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: asInt(json['id']) ?? 0,
      studentNumber: asString(json['student_number']),
      gender: asString(json['gender']),
      noShowCount: asInt(json['no_show_count']) ?? 0,
      negativeScore: asInt(json['negative_score']) ?? 0,
      isBlocked: asBool(json['is_blocked']),
      blockedUntil: asDate(json['blocked_until']),
    );
  }
}
