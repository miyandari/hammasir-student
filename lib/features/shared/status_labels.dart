import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/data/models/reservation.dart';
import 'package:hammasir_student/data/models/trip.dart';

/// متن و رنگ وضعیت‌ها؛ تنها جایی که ترجمه‌ی وضعیت‌ها نوشته شده است.
class StatusLabel {
  const StatusLabel(this.text, this.tone);

  final String text;
  final Tone tone;

  static StatusLabel trip(String status) {
    switch (status) {
      case TripStatus.boarding:
        return const StatusLabel('در حال سوار کردن', Tone.warning);
      case TripStatus.inProgress:
        return const StatusLabel('در مسیر', Tone.success);
      case TripStatus.completed:
        return const StatusLabel('انجام شد', Tone.neutral);
      case TripStatus.cancelled:
        return const StatusLabel('لغو شد', Tone.danger);
      default:
        return const StatusLabel('برنامه‌ریزی‌شده', Tone.brand);
    }
  }

  static StatusLabel reservation(String status) {
    switch (status) {
      case ReservationStatus.waitlisted:
        return const StatusLabel('لیست انتظار', Tone.warning);
      case ReservationStatus.cancelled:
        return const StatusLabel('لغو شده', Tone.danger);
      default:
        return const StatusLabel('تأیید شده', Tone.success);
    }
  }
}

/// آیا سرویس با جنسیت دانشجو سازگار است؟ اگر جنسیت نامعلوم باشد همه را نشان می‌دهیم.
bool serviceAllowsGender(String restriction, String? gender) {
  if (restriction.isEmpty || restriction == 'mixed') return true;
  if (gender == null || gender.isEmpty) return true;
  return restriction.toLowerCase() == gender.toLowerCase();
}
