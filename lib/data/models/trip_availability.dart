import 'package:hammasir_student/core/utils/json_utils.dart';

/// پاسخ `GET /trips/{id}/availability` (از بک‌اند اصلاح‌شده).
class TripAvailability {
  const TripAvailability({
    required this.seatedAvailable,
    required this.allowStanding,
    required this.standingAvailable,
    required this.waitlistCount,
  });

  final int seatedAvailable;
  final bool allowStanding;
  final int standingAvailable;
  final int waitlistCount;

  bool get hasSeat => seatedAvailable > 0;
  bool get hasStanding => allowStanding && standingAvailable > 0;

  /// نه صندلی خالی هست نه جای ایستاده؛ رزرو وارد لیست انتظار می‌شود.
  bool get isFull => !hasSeat && !hasStanding;

  factory TripAvailability.fromJson(Map<String, dynamic> json) {
    return TripAvailability(
      seatedAvailable: asInt(json['seated_available']) ?? 0,
      allowStanding: asBool(json['allow_standing']),
      standingAvailable: asInt(json['standing_available']) ?? 0,
      waitlistCount: asInt(json['waitlist_count']) ?? 0,
    );
  }
}
