import 'package:shamsi_date/shamsi_date.dart';

/// قالب‌بندی فارسی: ارقام، تاریخ شمسی، ساعت و زمان نسبی.
class Fa {
  Fa._();

  static const List<String> _digits = [
    '۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹', //
  ];

  static const List<String> _months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', //
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند', //
  ];

  /// همه‌ی ارقام لاتین داخل متن را فارسی می‌کند.
  static String digits(Object? value) {
    final text = value?.toString() ?? '';
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final digit = int.tryParse(char);
      buffer.write(digit == null ? char : _digits[digit]);
    }
    return buffer.toString();
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// مثل «۱۰ آبان ۱۴۰۵»
  static String date(DateTime dateTime) {
    final j = Jalali.fromDateTime(dateTime);
    return '${digits(j.day)} ${_months[j.month - 1]} ${digits(j.year)}';
  }

  /// مثل «۱۴۰۵/۰۸/۱۰»
  static String shortDate(DateTime dateTime) {
    final j = Jalali.fromDateTime(dateTime);
    return digits('${j.year}/${_two(j.month)}/${_two(j.day)}');
  }

  /// مثل «۰۷:۳۰»
  static String time(DateTime dateTime) {
    return digits('${_two(dateTime.hour)}:${_two(dateTime.minute)}');
  }

  /// «امروز»، «فردا»، «دیروز» یا روز و ماه شمسی.
  static String dayLabel(DateTime dateTime, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final target = _dateOnly(dateTime);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'امروز';
    if (diff == 1) return 'فردا';
    if (diff == -1) return 'دیروز';

    final j = Jalali.fromDateTime(dateTime);
    return '${digits(j.day)} ${_months[j.month - 1]}';
  }

  /// مثل «امروز، ۰۷:۳۰»
  static String dayAndTime(DateTime dateTime, {DateTime? now}) {
    return '${dayLabel(dateTime, now: now)}، ${time(dateTime)}';
  }

  /// زمان نسبی برای اعلان‌ها: «۵ دقیقه پیش».
  static String relative(DateTime dateTime, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(dateTime);

    if (diff.inSeconds < 60) return 'همین الان';
    if (diff.inMinutes < 60) return '${digits(diff.inMinutes)} دقیقه پیش';
    if (diff.inHours < 24) return '${digits(diff.inHours)} ساعت پیش';
    if (diff.inDays < 7) return '${digits(diff.inDays)} روز پیش';
    return shortDate(dateTime);
  }

  /// مثل «۴ دقیقه» یا «کمتر از ۱ دقیقه».
  static String duration(int seconds) {
    if (seconds < 60) return 'کمتر از ۱ دقیقه';
    return '${digits((seconds / 60).round())} دقیقه';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
