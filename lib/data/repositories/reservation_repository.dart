import 'package:hammasir_student/core/network/api_client.dart';
import 'package:hammasir_student/core/network/api_exception.dart';
import 'package:hammasir_student/core/utils/json_utils.dart';
import 'package:hammasir_student/data/models/boarding_request.dart';
import 'package:hammasir_student/data/models/reservation.dart';
import 'package:hammasir_student/l10n/l10n.dart';

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

  /// سفرهایی که دانشجو واقعاً سوار شده است (برای اجازه‌ی امتیازدهی).
  Future<Set<int>> boardedTripIds() async {
    final data = await _api.get('/trip-passengers/');
    return {
      for (final item in asMapList(data))
        if (item['boarding_time'] != null) asInt(item['trip_id']) ?? 0,
    };
  }

  /// سفرهایی که دانشجو برایشان قبلاً امتیاز داده است.
  Future<Set<int>> ratedTripIds() async {
    final data = await _api.get('/feedbacks/');
    return {for (final item in asMapList(data)) asInt(item['trip_id']) ?? 0};
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
    if (map == null) throw ApiException(L10n.t('err.reserve_failed'));
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
    if (map == null) throw ApiException(L10n.t('err.request_failed'));
    return BoardingRequest.fromJson(map);
  }
}
