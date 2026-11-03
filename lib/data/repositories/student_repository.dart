import 'package:hammasir_student/core/network/api_client.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/utils/json_utils.dart';
import 'package:hammasir_student/data/models/student_profile.dart';
import 'package:hammasir_student/l10n/l10n.dart';

class StudentRepository {
  StudentRepository(this._api);

  final ApiClient _api;

  /// وضعیت دانشجو (تخلف‌ها و مسدودی).
  /// اگر بک‌اند هنوز endpoint جدید را ندارد null برمی‌گرداند و اپ بدون این کارت کار می‌کند.
  ///
  /// اگر بک‌اند هنوز `/students/me` را ندارد، از `/students/{id}` فقط اطلاعات
  /// پایه (جنسیت و شماره دانشجویی) خوانده می‌شود تا فیلتر جنسیت کار کند.
  Future<StudentProfile?> profile({int? fallbackStudentId}) async {
    try {
      final data = await _api.get('/students/me');
      final map = asMap(data);
      return map == null ? null : StudentProfile.fromJson(map);
    } on ApiException catch (e) {
      final missing = e.statusCode == 404 ||
          e.statusCode == 405 ||
          e.statusCode == 422;
      if (!missing) rethrow;
    }

    if (fallbackStudentId == null) return null;

    try {
      final data = await _api.get('/students/$fallbackStudentId');
      final map = asMap(data);
      return map == null ? null : StudentProfile.basic(map);
    } on ApiException catch (e) {
      if (e.isNetwork || e.isUnauthorized) rethrow;
      return null;
    }
  }

  /// توکن QR دانشجو. مسیر `/students/{id}/qr` قبل و بعد از اصلاح بک‌اند کار می‌کند.
  Future<String> qrToken(int studentId) async {
    final data = await _api.get('/students/$studentId/qr');
    final token = asString(asMap(data)?['qr_token']);
    if (token.isEmpty) {
      throw ApiException(L10n.t('err.qr_failed'));
    }
    return token;
  }
}
