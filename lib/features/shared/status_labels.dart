import 'package:hammasir_student/core/widgets/status_chip.dart';
import 'package:hammasir_student/data/models/reservation.dart';
import 'package:hammasir_student/data/models/trip.dart';
import 'package:hammasir_student/l10n/l10n.dart';

/// متن و رنگ وضعیت‌ها؛ تنها جایی که ترجمه‌ی وضعیت‌ها نوشته شده است.
class StatusLabel {
  const StatusLabel(this.text, this.tone);

  final String text;
  final Tone tone;

  static StatusLabel trip(String status) {
    switch (status) {
      case TripStatus.boarding:
        return StatusLabel(L10n.t('trip.boarding'), Tone.warning);
      case TripStatus.inProgress:
        return StatusLabel(L10n.t('trip.in_progress'), Tone.success);
      case TripStatus.completed:
        return StatusLabel(L10n.t('trip.completed'), Tone.neutral);
      case TripStatus.cancelled:
        return StatusLabel(L10n.t('trip.cancelled'), Tone.danger);
      default:
        return StatusLabel(L10n.t('trip.scheduled'), Tone.brand);
    }
  }

  static StatusLabel reservation(String status) {
    switch (status) {
      case ReservationStatus.waitlisted:
        return StatusLabel(L10n.t('res.waitlisted'), Tone.warning);
      case ReservationStatus.cancelled:
        return StatusLabel(L10n.t('res.cancelled'), Tone.danger);
      default:
        return StatusLabel(L10n.t('res.active'), Tone.success);
    }
  }

  /// برچسب محدودیت جنسیتی سرویس؛ برای سرویس مختلط null.
  static StatusLabel? gender(String restriction) {
    switch (restriction) {
      case 'female':
        return StatusLabel(L10n.t('gender.female_only'), Tone.brand);
      case 'male':
        return StatusLabel(L10n.t('gender.male_only'), Tone.brand);
      default:
        return null;
    }
  }
}

/// آیا سرویس را می‌توان به دانشجو نشان داد؟ سرویس مختلط برای همه؛ سرویس ویژه‌ی
/// یک جنس فقط برای همان جنس. اگر جنسیت دانشجو نامعلوم باشد فقط سرویس مختلط.
bool serviceAllowsGender(String restriction, String? gender) {
  if (restriction.isEmpty || restriction == 'mixed') return true;
  if (gender == null || gender.isEmpty) return false;
  return restriction.toLowerCase() == gender.toLowerCase();
}
