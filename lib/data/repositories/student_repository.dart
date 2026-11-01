import 'package:hammasir_student/core/network/api_client.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/utils/json_utils.dart';
import 'package:hammasir_student/data/models/student_profile.dart';

class StudentRepository {
  StudentRepository(this._api);

  final ApiClient _api;

  /// وضعیت دانشجو (تخلف‌ها و مسدودی).
  /// اگر بک‌اند هنوز endpoint جدید را ندارد null برمی‌گرداند و اپ بدون این کارت کار می‌کند.
  Future<StudentProfile?> profile() async {
    try {
      final data = await _api.get('/students/me');
      final map = asMap(data);
      return map == null ? null : StudentProfile.fromJson(map);
    } on ApiException catch (e) {
      final missing = e.statusCode == 404 ||
          e.statusCode == 405 ||
          e.statusCode == 422;
      if (missing) return null;
      rethrow;
    }
  }

  /// توکن QR دانشجو. مسیر `/students/{id}/qr` قبل و بعد از اصلاح بک‌اند کار می‌کند.
  Future<String> qrToken(int studentId) async {
    final data = await _api.get('/students/$studentId/qr');
    final token = asString(asMap(data)?['qr_token']);
    if (token.isEmpty) {
      throw const ApiException('کد QR دریافت نشد');
    }
    return token;
  }
}
