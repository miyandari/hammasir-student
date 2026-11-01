import 'package:hammasir_student/core/utils/json_utils.dart';

/// وضعیت‌های سفر در بک‌اند.
class TripStatus {
  TripStatus._();

  static const String scheduled = 'scheduled';
  static const String boarding = 'boarding';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class Trip {
  const Trip({
    required this.id,
    required this.serviceId,
    required this.status,
    required this.plannedDeparture,
    required this.tripDate,
    required this.allowStanding,
    this.seatedCapacity,
    this.standingCapacity,
    this.actualDeparture,
    this.actualArrival,
  });

  final int id;
  final int serviceId;
  final String status;
  final DateTime plannedDeparture;
  final DateTime tripDate;
  final bool allowStanding;
  final int? seatedCapacity;
  final int? standingCapacity;
  final DateTime? actualDeparture;
  final DateTime? actualArrival;

  /// سفر الان فعال است و ردیابی زنده معنی دارد.
  bool get isLive =>
      status == TripStatus.boarding || status == TripStatus.inProgress;

  bool get isFinished =>
      status == TripStatus.completed || status == TripStatus.cancelled;

  /// هنوز می‌توان رزرو کرد یا لغو کرد.
  bool get isOpen => status == TripStatus.scheduled;

  factory Trip.fromJson(Map<String, dynamic> json) {
    final planned = asDate(json['planned_departure_time']) ??
        asDate(json['trip_date']) ??
        DateTime.now();

    return Trip(
      id: asInt(json['id']) ?? 0,
      serviceId: asInt(json['service_id']) ?? 0,
      status: asString(json['status'], TripStatus.scheduled),
      plannedDeparture: planned,
      tripDate: asDate(json['trip_date']) ?? planned,
      allowStanding: asBool(json['allow_standing']),
      seatedCapacity: asInt(json['seated_capacity']),
      standingCapacity: asInt(json['standing_capacity']),
      actualDeparture: asDate(json['actual_departure_time']),
      actualArrival: asDate(json['actual_arrival_time']),
    );
  }
}
