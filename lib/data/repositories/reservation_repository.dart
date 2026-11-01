import 'package:hammasir_student/core/network/api_client.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/utils/json_utils.dart';
import 'package:hammasir_student/data/models/boarding_request.dart';
import 'package:hammasir_student/data/models/reservation.dart';

class ReservationRepository {
  ReservationRepository(this._api);

  final ApiClient _api;

  /// همه‌ی رزروهای دانشجو (بک‌اند خودش فقط رزروهای همین دانشجو را می‌دهد).
  Future<List<Reservation>> mine() async {
    final data = await _api.get(
      '/reservations/',
      query: {'only_active': 'false'},
    );
    return [for (final item in asMapList(data)) Reservation.fromJson(item)];
  }

  Future<Reservation> create({
    required int tripId,
    required int studentId,
    required int stationId,
    required bool standing,
  }) async {
    final data = await _api.post(
      '/reservations/',
      body: {
        'trip_id': tripId,
        'student_id': studentId,
        'station_id': stationId,
        'reservation_type': standing ? 'standing' : 'seated',
      },
    );
    final map = asMap(data);
    if (map == null) throw const ApiException('رزرو ثبت نشد');
    return Reservation.fromJson(map);
  }

  Future<void> cancel(int reservationId) async {
    await _api.patch('/reservations/$reservationId/cancel');
  }

  /// درخواست سوار شدن با اسکن QR ایستگاه (بدون رزرو قبلی).
  Future<BoardingRequest> scanStation({
    required int tripId,
    required int stationId,
    required bool standing,
  }) async {
    final data = await _api.post(
      '/boarding-requests/scan',
      body: {
        'trip_id': tripId,
        'boarding_station_id': stationId,
        'is_standing': standing,
      },
    );
    final map = asMap(data);
    if (map == null) throw const ApiException('درخواست ثبت نشد');
    return BoardingRequest.fromJson(map);
  }
}
