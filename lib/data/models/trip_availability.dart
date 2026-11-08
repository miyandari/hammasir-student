import 'package:hammasir_student/core/utils/json_utils.dart';

/// پاسخ `GET /trips/{id}/availability` (از بک‌اند اصلاح‌شده).
class TripAvailability {
  const TripAvailability({
    required this.seatedAvailable,
    required this.allowStanding,
    required this.standingAvailable,
    required this.waitlistCount,
  });

  /// null یعنی ظرفیت سفر هنوز مشخص نیست (خودرو تخصیص نیافته).
  final int? seatedAvailable;
  final bool allowStanding;
  final int standingAvailable;
  final int waitlistCount;

  bool get capacityUnknown => seatedAvailable == null;
  bool get hasSeat => (seatedAvailable ?? 0) > 0;
  bool get hasStanding => allowStanding && standingAvailable > 0;

  /// نه صندلی خالی هست نه جای ایستاده؛ رزرو وارد لیست انتظار می‌شود.
  bool get isFull => !capacityUnknown && !hasSeat && !hasStanding;

  factory TripAvailability.fromJson(Map<String, dynamic> json) {
    return TripAvailability(
      seatedAvailable: asInt(json['seated_available']),
      allowStanding: asBool(json['allow_standing']),
      standingAvailable: asInt(json['standing_available']) ?? 0,
      waitlistCount: asInt(json['waitlist_count']) ?? 0,
    );
  }
}
