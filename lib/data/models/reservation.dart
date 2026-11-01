import 'package:hammasir_student/core/utils/json_utils.dart';

class ReservationStatus {
  ReservationStatus._();

  static const String active = 'active';
  static const String waitlisted = 'waitlisted';
  static const String cancelled = 'cancelled';
}

class Reservation {
  const Reservation({
    required this.id,
    required this.tripId,
    required this.status,
    required this.isStanding,
    required this.reservedAt,
    this.stationId,
  });

  final int id;
  final int tripId;
  final int? stationId;
  final String status;
  final bool isStanding;
  final DateTime reservedAt;

  bool get isActive => status == ReservationStatus.active;
  bool get isWaitlisted => status == ReservationStatus.waitlisted;
  bool get isCancelled => status == ReservationStatus.cancelled;

  /// فعال یا در لیست انتظار.
  bool get isLiveBooking => isActive || isWaitlisted;

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: asInt(json['id']) ?? 0,
      tripId: asInt(json['trip_id']) ?? 0,
      stationId: asInt(json['station_id']),
      status: asString(json['status'], ReservationStatus.active),
      isStanding: asBool(json['is_standing']),
      reservedAt: asDate(json['reservation_time']) ?? DateTime.now(),
    );
  }
}
